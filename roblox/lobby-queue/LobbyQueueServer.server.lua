--[[
	LobbyQueueServer  (Script -> ServerScriptService)

	Lobby queue pads like the ones in the video:
	  * Walk onto an empty pad -> you are placed in it and get the "Create Party" menu.
	  * Pick a party size (1..MAX_PARTY_SIZE) and press Create -> the countdown starts.
	  * Other players who touch the pad are placed in it until it is full.
	  * The countdown runs FULL_SPEED_MULTIPLIER times faster (5x) while the pad is full.
	  * When the timer hits 0 the party is sent to the game.

	Setup: put one or more Parts in a Folder named "LobbyPads" in Workspace.
	If that folder does not exist, a demo pad is created so you can test right away.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local CONFIG = {
	MAX_PARTY_SIZE = 5, -- biggest party a host can choose
	COUNTDOWN = 20, -- seconds before the match starts
	FULL_SPEED_MULTIPLIER = 5, -- timer speed while the pad is full
	CHOOSE_TIMEOUT = 30, -- host is removed if they never press Create
	REJOIN_COOLDOWN = 2, -- seconds before a player who left can touch a pad again
	GAME_PLACE_ID = 0, -- set to your game's PlaceId to teleport parties there
}

---------------------------------------------------------------------
-- Remotes
---------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "LobbyQueueRemotes"

local function newRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local OpenCreateParty = newRemote("OpenCreateParty") -- server -> client (maxSize)
local CreateParty = newRemote("CreateParty") -- client -> server (size)
local CancelCreate = newRemote("CancelCreate") -- client -> server
local LeaveQueue = newRemote("LeaveQueue") -- client -> server
local QueueStatus = newRemote("QueueStatus") -- server -> client (inQueue)

-- Hook your own game code into this when GAME_PLACE_ID is 0:
-- MatchStarted.Event:Connect(function(players, pad) ... end)
local MatchStarted = Instance.new("BindableEvent")
MatchStarted.Name = "MatchStarted"
MatchStarted.Parent = remotes

remotes.Parent = ReplicatedStorage

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
local pads = {} -- [BasePart] = padState
local playerPad = {} -- [Player] = padState
local cooldownUntil = {} -- [Player] = os.clock() time
local savedMovement = {} -- [Player] = {WalkSpeed, JumpPower, JumpHeight}

local function formatTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function updateBillboard(state)
	local countText, timerText
	if state.status == "Idle" then
		countText = "0/" .. CONFIG.MAX_PARTY_SIZE
		timerText = ""
	elseif state.status == "Choosing" then
		countText = "1/?"
		timerText = "creating..."
	else
		countText = #state.players .. "/" .. state.maxPlayers
		timerText = formatTime(state.timeLeft)
	end
	if state.countLabel.Text ~= countText then
		state.countLabel.Text = countText
	end
	if state.timerLabel.Text ~= timerText then
		state.timerLabel.Text = timerText
	end
end

local function freezeMovement(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	savedMovement[player] = {
		WalkSpeed = humanoid.WalkSpeed,
		JumpPower = humanoid.JumpPower,
		JumpHeight = humanoid.JumpHeight,
	}
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
end

local function restoreMovement(player)
	local saved = savedMovement[player]
	savedMovement[player] = nil
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not (saved and humanoid) then
		return
	end
	humanoid.WalkSpeed = saved.WalkSpeed
	humanoid.JumpPower = saved.JumpPower
	humanoid.JumpHeight = saved.JumpHeight
end

local function standHeight(character, pad)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	return pad.Size.Y / 2 + (humanoid and humanoid.HipHeight or 2) + (root and root.Size.Y / 2 or 1)
end

-- Spread players in a ring on the pad so they don't stand inside each other.
local function placeOnPad(player, state, index)
	local character = player.Character
	if not character then
		return
	end
	local pad = state.part
	local radius = 0
	if index > 1 then
		radius = math.min(pad.Size.X, pad.Size.Z) * 0.3
	end
	local angle = (index - 2) / math.max(CONFIG.MAX_PARTY_SIZE - 1, 1) * math.pi * 2
	local offset = Vector3.new(math.cos(angle) * radius, standHeight(character, pad), math.sin(angle) * radius)
	character:PivotTo(pad.CFrame * CFrame.new(offset))
end

-- Put a player just outside the pad's front edge.
local function placeOutside(player, state)
	local character = player.Character
	if not character then
		return
	end
	local pad = state.part
	local offset = Vector3.new(0, standHeight(character, pad), -(pad.Size.Z / 2 + 4))
	character:PivotTo(pad.CFrame * CFrame.new(offset) * CFrame.Angles(0, math.pi, 0))
end

local removePlayer -- defined below, used by addPlayer's Died handler

local function addPlayer(state, player)
	table.insert(state.players, player)
	playerPad[player] = state

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	state.connections[player] = humanoid.Died:Connect(function()
		removePlayer(player, false)
	end)

	placeOnPad(player, state, #state.players)
	freezeMovement(player)
	updateBillboard(state)
end

local function resetPad(state)
	state.status = "Idle"
	state.host = nil
	state.maxPlayers = 0
	state.timeLeft = 0
	state.chooseDeadline = 0
	updateBillboard(state)
end

-- `moveOut` is true when the player chose to leave and should be put outside the pad.
function removePlayer(player, moveOut)
	local state = playerPad[player]
	if not state then
		return
	end
	playerPad[player] = nil

	local index = table.find(state.players, player)
	if index then
		table.remove(state.players, index)
	end
	if state.connections[player] then
		state.connections[player]:Disconnect()
		state.connections[player] = nil
	end

	restoreMovement(player)
	if moveOut then
		placeOutside(player, state)
	end
	cooldownUntil[player] = os.clock() + CONFIG.REJOIN_COOLDOWN
	if player.Parent then
		QueueStatus:FireClient(player, false)
	end

	if #state.players == 0 or state.status == "Choosing" then
		resetPad(state)
	else
		if state.host == player then
			state.host = state.players[1]
		end
		updateBillboard(state)
	end
end

local function startMatch(state)
	local party = table.clone(state.players)
	local pad = state.part

	for _, player in party do
		removePlayer(player, false)
	end
	resetPad(state)

	if CONFIG.GAME_PLACE_ID ~= 0 then
		task.spawn(function()
			local options = Instance.new("TeleportOptions")
			options.ShouldReserveServer = true
			local ok, err = pcall(function()
				TeleportService:TeleportAsync(CONFIG.GAME_PLACE_ID, party, options)
			end)
			if not ok then
				warn("[LobbyQueue] Teleport failed:", err)
			end
		end)
	else
		-- No place set: move the party to a part named "MatchSpawn" if there is one.
		local spawnPart = workspace:FindFirstChild("MatchSpawn")
		for i, player in party do
			if spawnPart and player.Character then
				player.Character:PivotTo(spawnPart.CFrame * CFrame.new((i - 1) * 3, 4, 0))
			end
		end
		print(string.format("[LobbyQueue] Match started on %s with %d player(s)", pad.Name, #party))
	end

	MatchStarted:Fire(party, pad)
end

local function onPadTouched(state, hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player or playerPad[player] then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	if os.clock() < (cooldownUntil[player] or 0) then
		return
	end

	if state.status == "Idle" then
		state.status = "Choosing"
		state.host = player
		state.chooseDeadline = os.clock() + CONFIG.CHOOSE_TIMEOUT
		addPlayer(state, player)
		OpenCreateParty:FireClient(player, CONFIG.MAX_PARTY_SIZE)
	elseif state.status == "Countdown" and #state.players < state.maxPlayers then
		addPlayer(state, player)
		QueueStatus:FireClient(player, true)
	end
end

---------------------------------------------------------------------
-- Pads
---------------------------------------------------------------------
local function makeBillboard(pad)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "QueueBillboard"
	billboard.Size = UDim2.fromOffset(200, 90)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
	billboard.MaxDistance = 100
	billboard.AlwaysOnTop = true
	billboard.Parent = pad

	local function label(name, y, height, color)
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = name
		textLabel.BackgroundTransparency = 1
		textLabel.Position = UDim2.fromScale(0, y)
		textLabel.Size = UDim2.fromScale(1, height)
		textLabel.Font = Enum.Font.FredokaOne
		textLabel.TextScaled = true
		textLabel.TextColor3 = color
		textLabel.TextStrokeTransparency = 0.3
		textLabel.Text = ""
		textLabel.Parent = billboard
		return textLabel
	end

	local countLabel = label("Count", 0, 0.55, Color3.fromRGB(255, 220, 40))
	local timerLabel = label("Timer", 0.55, 0.45, Color3.new(1, 1, 1))
	return countLabel, timerLabel
end

local function setupPad(pad)
	if not pad:IsA("BasePart") or pads[pad] then
		return
	end
	pad.Anchored = true
	pad.CanTouch = true

	-- Yellow outline like in the video.
	if not pad:FindFirstChildOfClass("SelectionBox") then
		local outline = Instance.new("SelectionBox")
		outline.Adornee = pad
		outline.Color3 = Color3.fromRGB(255, 220, 40)
		outline.LineThickness = 0.08
		outline.SurfaceTransparency = 1
		outline.Parent = pad
	end

	local countLabel, timerLabel = makeBillboard(pad)
	local state = {
		part = pad,
		status = "Idle", -- Idle | Choosing | Countdown
		host = nil,
		players = {},
		connections = {},
		maxPlayers = 0,
		timeLeft = 0,
		chooseDeadline = 0,
		countLabel = countLabel,
		timerLabel = timerLabel,
	}
	pads[pad] = state
	updateBillboard(state)

	pad.Touched:Connect(function(hit)
		onPadTouched(state, hit)
	end)
end

local padFolder = workspace:FindFirstChild("LobbyPads")
if not padFolder then
	padFolder = Instance.new("Folder")
	padFolder.Name = "LobbyPads"
	local demo = Instance.new("Part")
	demo.Name = "DemoPad"
	demo.Size = Vector3.new(12, 0.4, 12)
	demo.Position = Vector3.new(0, 0.2, 25)
	demo.Color = Color3.fromRGB(190, 170, 230)
	demo.Material = Enum.Material.SmoothPlastic
	demo.Transparency = 0.4
	demo.CanCollide = false
	demo.Parent = padFolder
	padFolder.Parent = workspace
end

for _, pad in padFolder:GetChildren() do
	setupPad(pad)
end
padFolder.ChildAdded:Connect(setupPad)

---------------------------------------------------------------------
-- Remote handlers
---------------------------------------------------------------------
CreateParty.OnServerEvent:Connect(function(player, size)
	local state = playerPad[player]
	if not state or state.status ~= "Choosing" or state.host ~= player then
		return
	end
	if typeof(size) ~= "number" or size ~= size or size % 1 ~= 0 then
		return
	end
	if size < 1 or size > CONFIG.MAX_PARTY_SIZE then
		return
	end

	state.status = "Countdown"
	state.maxPlayers = size
	state.timeLeft = CONFIG.COUNTDOWN
	updateBillboard(state)
	QueueStatus:FireClient(player, true)
end)

CancelCreate.OnServerEvent:Connect(function(player)
	local state = playerPad[player]
	if state and state.status == "Choosing" and state.host == player then
		removePlayer(player, true)
	end
end)

LeaveQueue.OnServerEvent:Connect(function(player)
	removePlayer(player, true)
end)

Players.PlayerRemoving:Connect(function(player)
	removePlayer(player, false)
	cooldownUntil[player] = nil
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function()
		removePlayer(player, false)
	end)
end)
for _, player in Players:GetPlayers() do
	player.CharacterRemoving:Connect(function()
		removePlayer(player, false)
	end)
end

---------------------------------------------------------------------
-- Timer loop
---------------------------------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	for _, state in pads do
		if state.status == "Choosing" then
			if now > state.chooseDeadline and state.host then
				OpenCreateParty:FireClient(state.host, 0) -- 0 closes the menu
				removePlayer(state.host, true)
			end
		elseif state.status == "Countdown" then
			local isFull = #state.players >= state.maxPlayers
			local speed = isFull and CONFIG.FULL_SPEED_MULTIPLIER or 1
			state.timeLeft -= dt * speed
			if state.timeLeft <= 0 then
				startMatch(state)
			else
				updateBillboard(state)
			end
		end
	end
end)
