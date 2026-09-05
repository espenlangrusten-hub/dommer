--!strict
--[[
	CardSystem client
	Wires the pieces together: the roll button and the 3D hand, the hotbar,
	the inventory panel, and the item showcase.

	The client never decides what is rolled or what it owns - it renders the
	profile the server sends and asks for changes.
]]

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local CardSystem = ReplicatedStorage:WaitForChild("CardSystem")
local Cards = require(CardSystem:WaitForChild("Cards"))
local Config = require(CardSystem:WaitForChild("Config"))
local Rarities = require(CardSystem:WaitForChild("Rarities"))
local Theme = require(CardSystem:WaitForChild("Theme"))
local Remotes = require(CardSystem:WaitForChild("Remotes")).get()

local CardVisual = require(script:WaitForChild("CardVisual"))
local Hotbar = require(script:WaitForChild("Hotbar"))
local InventoryUI = require(script:WaitForChild("InventoryUI"))
local Profile = require(script:WaitForChild("Profile"))
local RollUI = require(script:WaitForChild("RollUI"))
local Showcase = require(script:WaitForChild("Showcase"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local HAND_FOLDER_NAME = "CardHand"
local RAY_LENGTH = 500
local UNHOVERED_TILT = 0.5 -- neighbours tilt less than the card under the cursor

type State = "idle" | "requesting" | "choosing" | "resolving" | "cooldown"

--[[
	The stock backpack occupies the same strip of screen as our hotbar. It can
	refuse the call for the first frames after join, so keep asking briefly.
]]
if Config.HideDefaultBackpack then
	task.spawn(function()
		for _ = 1, 10 do
			local ok = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			end)
			if ok then
				return
			end
			task.wait(0.3)
		end
	end)
end

-- Panels -------------------------------------------------------------------
local ui = RollUI.new()
local hotbar = Hotbar.new()
local inventory = InventoryUI.new()
local showcase = Showcase.new()

-- Roll state ---------------------------------------------------------------
local visuals: { CardVisual.CardVisual } = {}
local handFolder: Folder? = nil
local state: State = "idle"
local activeRollId: number? = nil
local stateToken = 0

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.IgnoreWater = true
raycastParams.FilterDescendantsInstances = {}

--[[
	Movement lock
	The character is frozen while a hand of cards or the showcase is up, so
	you cannot walk away and leave them floating behind you.

	PlayerModule's control object is the supported way to do this and covers
	keyboard, touch and gamepad in one call. When a place has replaced the
	PlayerModule we fall back to zeroing the humanoid, remembering the old
	values so the game's own speed survives the round trip.
]]
local movementLocks: { [string]: boolean? } = {}
local cachedControls: any = nil
local savedWalkSpeed: number? = nil
local savedJumpPower: number? = nil

local function getControls(): any
	if cachedControls then
		return cachedControls
	end
	local scripts = player:FindFirstChild("PlayerScripts")
	local playerModule = scripts and scripts:FindFirstChild("PlayerModule")
	if not playerModule then
		return nil
	end
	-- Indirect so the analyser does not try to resolve a runtime path.
	local requireModule: (Instance) -> any = require :: any
	local ok, result = pcall(function()
		return requireModule(playerModule):GetControls()
	end)
	if ok then
		cachedControls = result
	end
	return cachedControls
end

local function applyMovementLock()
	local locked = next(movementLocks) ~= nil

	local controls = getControls()
	if controls then
		local ok = pcall(function()
			if locked then
				controls:Disable()
			else
				controls:Enable()
			end
		end)
		if ok then
			return
		end
		cachedControls = nil
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	if locked then
		if savedWalkSpeed == nil then
			savedWalkSpeed = humanoid.WalkSpeed
			savedJumpPower = humanoid.JumpPower
		end
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
	elseif savedWalkSpeed then
		humanoid.WalkSpeed = savedWalkSpeed
		humanoid.JumpPower = savedJumpPower or humanoid.JumpPower
		savedWalkSpeed = nil
		savedJumpPower = nil
	end
end

local function setMovementLock(reason: string, locked: boolean)
	if not Config.LockMovementDuringCards then
		return
	end
	movementLocks[reason] = if locked then true else nil
	applyMovementLock()
end

-- Helpers ------------------------------------------------------------------
--[[
	Fire-and-forget 2D sound. PlayOnRemove means the engine plays it as the
	instance is destroyed, so nothing has to be cleaned up afterwards and a
	card being removed mid-sound cannot cut it off.
]]
local function playSound(id: string, pitch: number?)
	if id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = Config.SoundVolume
	sound.PlaybackSpeed = pitch or 1
	sound.PlayOnRemove = true
	sound.Parent = SoundService
	sound:Destroy()
end

local function setState(newState: State)
	state = newState
	stateToken += 1
	setMovementLock("cards", newState == "choosing" or newState == "resolving")
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
	return camera.CFrame * CFrame.new(0, Config.CameraHeightOffset, -Config.CameraDistance)
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
	local middle = (#cardIds + 1) / 2

	for slot, cardId in cardIds do
		local card = Cards.get(cardId)
		if not card then
			warn(`[CardSystem] server sent unknown card "{cardId}"`)
			continue
		end

		local offset = (slot - middle) * Config.CardSpacing
		local position = origin.Position + origin.RightVector * offset
		-- lookAt puts the part's Front face (its -Z) toward the camera.
		local visual = CardVisual.new(card, slot, CFrame.lookAt(position, eye), folder)

		-- Each card ticks as it turns face up, a step higher than the last.
		visual.OnRevealed = function(revealedSlot: number)
			playSound(Config.Sounds.Reveal, 1 + (revealedSlot - 1) * Config.RevealPitchStep)
		end

		table.insert(visuals, visual)
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

-- Roll ---------------------------------------------------------------------
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

-- One timer owns the whole cooldown, including the hand back to idle.
local function returnToIdle(delay: number)
	setState("cooldown")
	ui:runCooldown(delay, currentTokenGuard(), function()
		setState("idle")
		ui:setStatus(`Roll for {Config.CardsPerRoll} cards`)
	end)
end

-- Remote handlers ----------------------------------------------------------
Remotes.ProfileSync.OnClientEvent:Connect(function(snapshot: Profile.Snapshot)
	Profile.set(snapshot)
end)

Remotes.Notice.OnClientEvent:Connect(function(text: string, isError: boolean?)
	ui:showNotice(text, isError)
end)

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
		returnToIdle(retryAfter)
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

	ui:setStatus("Added to your collection")
	returnToIdle(Config.RollCooldown)
end)

-- Panel wiring -------------------------------------------------------------
Profile.onChanged(function()
	hotbar:refresh()
	if inventory.Open then
		inventory:refresh()
	end
end)

ui.OnRoll = requestRoll
ui.OnInventory = function()
	inventory:toggle()
	playSound(if inventory.Open then Config.Sounds.Open else Config.Sounds.Close)
end

inventory.OnView = function(cardId: string)
	inventory:close()
	setMovementLock("showcase", true)
	showcase:show(cardId)
end

inventory.OnEquip = function(cardId: string)
	-- Fill the selected slot when it is free, otherwise the first open one.
	local slot = hotbar.Selected
	if Profile.equippedAt(slot) then
		for index = 1, Config.Hotbar.Slots do
			if not Profile.equippedAt(index) then
				slot = index
				break
			end
		end
	end
	Remotes.EquipCard:FireServer(slot, cardId)
end

inventory.OnUnequip = function(cardId: string)
	local slot = Profile.slotOf(cardId)
	if slot then
		Remotes.EquipCard:FireServer(slot, nil)
	end
end

hotbar.OnSlotActivated = function(_slot: number, cardId: string?)
	if cardId then
		setMovementLock("showcase", true)
		showcase:show(cardId)
	end
end

showcase.OnClosed = function()
	setMovementLock("showcase", false)
	playSound(Config.Sounds.Close)
end

-- Input --------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	local isClick = input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch

	-- The showcase eats the next click wherever it lands.
	if showcase.Open and isClick then
		showcase:hide()
		return
	end

	if gameProcessed then
		return
	end

	if isClick and state == "choosing" then
		local visual = cardUnderPoint(input.Position.X, input.Position.Y)
		if visual then
			selectCard(visual)
		end
		return
	end

	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if input.KeyCode == Config.Keys.Inventory then
		inventory:toggle()
		playSound(if inventory.Open then Config.Sounds.Open else Config.Sounds.Close)
	elseif input.KeyCode == Enum.KeyCode.Escape and inventory.Open then
		inventory:close()
		playSound(Config.Sounds.Close)
	end
end)

ContextActionService:BindAction("CardSystemRoll", function(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin and state == "idle" then
		requestRoll()
	end
	return Enum.ContextActionResult.Pass
end, false, Config.Keys.Roll)

-- Number keys pick a hotbar slot.
local hotbarKeys = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
}

ContextActionService:BindAction("CardSystemHotbar", function(_, inputState: Enum.UserInputState, inputObject: InputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local index = table.find(hotbarKeys, inputObject.KeyCode)
	if index then
		hotbar:activate(index)
	end
	return Enum.ContextActionResult.Pass
end, false, table.unpack(hotbarKeys))

-- Screen fit ---------------------------------------------------------------
local function applyScale()
	local factor = Theme.scaleFor(camera.ViewportSize.Y)
	ui:setScale(factor)
	hotbar:setScale(factor)
	inventory:setScale(factor)
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(applyScale)
applyScale()

-- Render -------------------------------------------------------------------
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
	showcase:hide()
	-- A new humanoid starts at full speed, so re-assert whatever lock holds.
	savedWalkSpeed = nil
	savedJumpPower = nil
	applyMovementLock()

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
hotbar:refresh()
