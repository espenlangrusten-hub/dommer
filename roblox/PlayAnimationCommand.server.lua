-- PlayAnimationCommand (Script)
-- Put this in ServerScriptService.
-- Type in chat:  /play pickup   -> plays the pickup animation
--                /play stop     -> stops the current animation
-- Watch the Output window (View > Output) for [PlayAnim] messages.

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

-- Add more animations here: name = "rbxassetid://ID"
local ANIMATIONS = {
	pickup = "rbxassetid://95203507058611",
}

local currentTracks = {} -- [player] = AnimationTrack
local lastCommand = {} -- [player] = os.clock(), stops double triggers

local function log(...)
	print("[PlayAnim]", ...)
end

local function stopCurrent(player)
	local track = currentTracks[player]
	if track then
		track:Stop()
		track:Destroy()
		currentTracks[player] = nil
	end
end

local function playAnimation(player, name)
	name = string.lower(name or "")
	log(player.Name, "requested:", name)

	if name == "stop" then
		stopCurrent(player)
		return
	end

	local animationId = ANIMATIONS[name]
	if not animationId then
		warn("[PlayAnim] Unknown animation name: " .. name)
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("[PlayAnim] No Humanoid found for " .. player.Name)
		return
	end
	log("Rig type:", humanoid.RigType.Name)

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	stopCurrent(player)

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not track then
		warn("[PlayAnim] LoadAnimation failed: " .. tostring(track))
		return
	end

	track.Priority = Enum.AnimationPriority.Action4
	track:Play()
	currentTracks[player] = track
	log("Playing", animationId)

	-- If the animation never loads, Length stays 0
	task.delay(3, function()
		if currentTracks[player] == track and track.Length == 0 then
			warn("[PlayAnim] Animation " .. animationId .. " did not load (Length = 0). "
				.. "Check the ID, that the game owner owns it, and that the rig type (R6/R15) matches.")
		end
	end)
end

local function handleMessage(player, message)
	local arg = string.match(message or "", "^%s*/[Pp][Ll][Aa][Yy]%s+(%S+)")
	if not arg then
		return
	end
	-- Both chat hooks below may fire for the same message; only act once
	local now = os.clock()
	if lastCommand[player] and now - lastCommand[player] < 0.5 then
		return
	end
	lastCommand[player] = now
	playAnimation(player, arg)
end

-- New chat system: register /play so it is not rejected as an unknown command
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	local command = Instance.new("TextChatCommand")
	command.Name = "PlayAnimationCommand"
	command.PrimaryAlias = "/play"
	command.Parent = TextChatService

	command.Triggered:Connect(function(textSource, message)
		local player = Players:GetPlayerByUserId(textSource.UserId)
		if player then
			handleMessage(player, message)
		end
	end)
end

-- Works with legacy chat (and as a fallback with the new chat)
local function onPlayerAdded(player)
	player.Chatted:Connect(function(message)
		handleMessage(player, message)
	end)
	player.CharacterAdded:Connect(function()
		currentTracks[player] = nil
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	currentTracks[player] = nil
	lastCommand[player] = nil
end)

log("Loaded. Chat version:", TextChatService.ChatVersion.Name)
