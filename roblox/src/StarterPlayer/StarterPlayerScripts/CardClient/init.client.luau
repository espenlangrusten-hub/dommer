--!strict
--[[
	CardSystem client
	Owns the roll button, spawns the 3D hand in front of the camera, drives
	every card from one render pass, and reports the player's pick to the
	server.

	The client never decides what is rolled - it only renders what the server
	sends and asks for a slot.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local CardSystem = ReplicatedStorage:WaitForChild("CardSystem")
local Cards = require(CardSystem:WaitForChild("Cards"))
local Config = require(CardSystem:WaitForChild("Config"))
local Rarities = require(CardSystem:WaitForChild("Rarities"))
local Remotes = require(CardSystem:WaitForChild("Remotes")).get()

local CardVisual = require(script:WaitForChild("CardVisual"))
local RollUI = require(script:WaitForChild("RollUI"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local HAND_FOLDER_NAME = "CardHand"
local RAY_LENGTH = 500
local UNHOVERED_TILT = 0.5 -- neighbours tilt less than the card under the cursor

-- State ------------------------------------------------------------------
type State = "idle" | "requesting" | "choosing" | "resolving" | "cooldown"

local ui = RollUI.new()
local visuals: { CardVisual.CardVisual } = {}
local handFolder: Folder? = nil
local state: State = "idle"
local activeRollId: number? = nil
local stateToken = 0

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.IgnoreWater = true
raycastParams.FilterDescendantsInstances = {}

-- Helpers ----------------------------------------------------------------
local function playSound(id: string)
	if id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = 0.5
	sound.PlayOnRemove = true
	sound.Parent = SoundService
	sound:Destroy()
end

local function setState(newState: State)
	state = newState
	stateToken += 1
end

local function currentTokenGuard(): () -> boolean
	local token = stateToken
	return function()
		return token == stateToken
	end
end

local function refreshFilter()
	local parts: { Instance } = {}
	for _, visual in visuals do
		table.insert(parts, visual.Part)
	end
	raycastParams.FilterDescendantsInstances = parts
end

local function clearHand()
	for _, visual in visuals do
		visual:destroy()
	end
	table.clear(visuals)
	refreshFilter()
	if handFolder then
		handFolder:Destroy()
		handFolder = nil
	end
end

-- Where the hand sits: frozen in world space at the moment of the roll, so
-- the cards stay put if the player turns the camera.
local function handOrigin(): CFrame
	local cf = camera.CFrame
	return cf * CFrame.new(0, Config.CameraHeightOffset, -Config.CameraDistance)
end

local function spawnHand(cardIds: { string })
	clearHand()
	camera = workspace.CurrentCamera -- may have been replaced since the last hand

	local folder = Instance.new("Folder")
	folder.Name = HAND_FOLDER_NAME
	folder.Parent = workspace
	handFolder = folder

	local origin = handOrigin()
	local eye = camera.CFrame.Position
	local count = #cardIds
	local middle = (count + 1) / 2

	for slot, cardId in cardIds do
		local card = Cards.get(cardId)
		if not card then
			warn(`[CardSystem] server sent unknown card "{cardId}"`)
			continue
		end

		local offset = (slot - middle) * Config.CardSpacing
		local position = origin.Position + origin.RightVector * offset
		-- lookAt puts the part's Front face (its -Z) toward the camera.
		local base = CFrame.lookAt(position, eye)

		table.insert(visuals, CardVisual.new(card, slot, base, folder))
	end

	refreshFilter()
	playSound(Config.Sounds.Roll)
end

local function cardUnderPoint(screenX: number, screenY: number): CardVisual.CardVisual?
	if #visuals == 0 then
		return nil
	end
	local ray = camera:ViewportPointToRay(screenX, screenY)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * RAY_LENGTH, raycastParams)
	if not hit then
		return nil
	end
	for _, visual in visuals do
		if visual.Part == hit.Instance then
			return visual
		end
	end
	return nil
end

-- Roll -------------------------------------------------------------------
local function requestRoll()
	if state ~= "idle" then
		return
	end
	setState("requesting")
	ui:setEnabled(false, "...")
	ui:setStatus("Dealing...")
	Remotes.RequestRoll:FireServer()

	-- Never leave the button dead if the reply is lost. The guard only holds
	-- while no other state change happened, so it still being true here means
	-- the request was never answered.
	local guard = currentTokenGuard()
	task.delay(5, function()
		if guard() then
			setState("idle")
			ui:setEnabled(true)
			ui:setStatus("No answer from the server, try again")
		end
	end)
end

ui.OnRoll = requestRoll

local function selectCard(visual: CardVisual.CardVisual)
	if state ~= "choosing" or activeRollId == nil then
		return
	end
	if not visual:isInteractive() then
		return
	end

	setState("resolving")
	ui:setStatus("...")
	Remotes.SelectCard:FireServer(activeRollId, visual.Slot)
end

-- Remote handlers --------------------------------------------------------
Remotes.RollResult.OnClientEvent:Connect(function(rollId: number, cardIds: { string })
	activeRollId = rollId
	setState("choosing")
	spawnHand(cardIds)
	ui:setEnabled(false, "PICK")
	ui:setStatus("Click a card to keep it")
end)

Remotes.RollRejected.OnClientEvent:Connect(function(reason: string, retryAfter: number)
	if state == "choosing" or state == "resolving" then
		-- A stale request; the hand on screen is still the one that matters.
		ui:setStatus(reason)
		return
	end

	ui:setStatus(reason)
	if retryAfter > 0.05 then
		setState("cooldown")
		local guard = currentTokenGuard()
		ui:runCooldown(retryAfter, guard)
		task.delay(retryAfter, function()
			if guard() then
				setState("idle")
				ui:setStatus(`Roll for {Config.CardsPerRoll} cards`)
			end
		end)
	else
		setState("idle")
		ui:setEnabled(true)
	end
end)

Remotes.SelectionResult.OnClientEvent:Connect(function(ok: boolean, cardId: string?, slot: number?)
	if not ok then
		-- Server refused the pick: hand the choice back rather than freezing.
		if state == "resolving" then
			setState("choosing")
			ui:setStatus("That pick did not go through, try again")
		end
		return
	end

	local card = if cardId then Cards.get(cardId) else nil
	activeRollId = nil

	for _, visual in visuals do
		visual:beginExit(if visual.Slot == slot then "chosen" else "discarded")
	end

	if card then
		local rarity = Rarities.get(card.Rarity)
		ui:showBanner(card.Name, rarity)
		playSound(if rarity.Sparkle then Config.Sounds.Rare else Config.Sounds.Select)
	end

	setState("cooldown")
	local guard = currentTokenGuard()
	ui:setStatus("Added to your collection")
	ui:runCooldown(Config.RollCooldown, guard)
	task.delay(Config.RollCooldown, function()
		if guard() then
			setState("idle")
			ui:setStatus(`Roll for {Config.CardsPerRoll} cards`)
		end
	end)
end)

-- Input ------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed or state ~= "choosing" then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local visual = cardUnderPoint(input.Position.X, input.Position.Y)
	if visual then
		selectCard(visual)
	end
end)

ContextActionService:BindAction("CardSystemRoll", function(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin and state == "idle" then
		requestRoll()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.R)

-- Render -----------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt: number)
	if #visuals == 0 then
		return
	end

	camera = workspace.CurrentCamera
	local viewport = camera.ViewportSize
	local mouse = UserInputService:GetMouseLocation()

	local hovered: CardVisual.CardVisual? = nil
	if state == "choosing" then
		hovered = cardUnderPoint(mouse.X, mouse.Y)
	end

	for index = #visuals, 1, -1 do
		local visual = visuals[index]

		local screenPoint = camera:WorldToViewportPoint(visual.Part.Position)
		local dx = math.clamp((mouse.X - screenPoint.X) / (viewport.X * 0.5), -1, 1)
		local dy = math.clamp((mouse.Y - screenPoint.Y) / (viewport.Y * 0.5), -1, 1)
		-- Screen Y grows downward, so the pitch is inverted to lean the card
		-- toward the cursor rather than away from it.
		local tilt = Vector2.new(dx, -dy)

		local isHovered = hovered == visual
		if not isHovered then
			tilt *= UNHOVERED_TILT
		end

		visual:update(dt, tilt, isHovered)

		if visual:isFinished() then
			visual:destroy()
			table.remove(visuals, index)
			refreshFilter()
		end
	end

	if #visuals == 0 and handFolder then
		handFolder:Destroy()
		handFolder = nil
	end
end)

--[[
	Respawning teleports the camera away from an un-picked hand, which would
	strand the pending roll on the server. Move the hand to the new camera
	instead of deleting it.
]]
local function repositionHand()
	if #visuals == 0 then
		return
	end
	local origin = handOrigin()
	local eye = camera.CFrame.Position
	local middle = (#visuals + 1) / 2
	for index, visual in visuals do
		local offset = (index - middle) * Config.CardSpacing
		local position = origin.Position + origin.RightVector * offset
		visual.BaseCFrame = CFrame.lookAt(position, eye)
	end
end

player.CharacterAdded:Connect(function(character: Model)
	if state ~= "choosing" then
		return
	end
	character:WaitForChild("HumanoidRootPart", 10)
	task.wait(0.5) -- let the camera settle on the new spawn
	if state == "choosing" then
		camera = workspace.CurrentCamera
		repositionHand()
	end
end)

ui:setEnabled(true)
