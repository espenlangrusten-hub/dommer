--[[
	EGG SYSTEM  (Server Script)
	Put this Script in ServerScriptService.

	What it does:
	  1. Spawns random eggs (weighted by rarity) on the parts inside the "spawn area" folder.
	  2. Press E (PC) or tap the prompt / the egg (phone) to pick an egg up. It is carried above your head.
	  3. Walk onto your base: the egg is set down on a random spot and starts a hatch timer.
	  4. When the timer is done, press E to open it: the egg wobbles right, left, right (2 s)
	     and a random pet from the "Pet's" folder pops out of the top.

	All text uses the Fredoka One font with a black outline.
	Everything runs on the server, so no LocalScripts or RemoteEvents are needed.
]]

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

---------------------------------------------------------------------
-- SETTINGS (change these freely)
---------------------------------------------------------------------
local CONFIG = {
	SPAWN_AREA_NAME = "spawn area", -- folder with the platform(s) eggs spawn on
	PETS_FOLDER_NAME = "Pet's", -- folder with the pet models
	BASES_FOLDER_NAME = "Bases", -- folder in Workspace with one Part/Model per player base

	MAX_EGGS_IN_WORLD = 12, -- max eggs lying in the spawn area at once
	SPAWN_INTERVAL = 4, -- seconds between spawn attempts
	EGG_DESPAWN_TIME = 120, -- an egg nobody picks up disappears after this many seconds
	MAX_EGGS_PER_BASE = 10, -- max eggs incubating on one base

	INTERACT_DISTANCE = 10, -- how close you must be to pick up / open
	CARRY_HEIGHT = 3, -- studs above the HumanoidRootPart the egg is carried at

	FONT = Enum.Font.FredokaOne, -- "Fredoka" font
	OUTLINE_THICKNESS = 2,

	-- Only used if there is no "Bases" folder: simple bases are created automatically.
	AUTO_BASE_COUNT = 6,
	AUTO_BASE_SIZE = Vector3.new(30, 1, 30),
	AUTO_BASE_START = Vector3.new(-100, 0.5, 80),
	AUTO_BASE_SPACING = 40,
}

-- Rarity -> label colour (Uncommon = white, Rare = blue, ...)
local RARITIES = {
	Common = Color3.fromRGB(170, 170, 170),
	Uncommon = Color3.fromRGB(255, 255, 255),
	Rare = Color3.fromRGB(45, 140, 255),
	Epic = Color3.fromRGB(170, 70, 255),
	Legendary = Color3.fromRGB(255, 150, 30),
	Mythic = Color3.fromRGB(255, 50, 50),
	Godly = Color3.fromRGB(255, 215, 0),
}

-- Egg name (must match the model name) -> rarity, hatch time, spawn chance and pet chances.
-- SpawnWeight / pet weights are relative: higher = more likely.
local EGGS = {
	["Basic egg"] = {
		Rarity = "Common", HatchTime = 10, SpawnWeight = 40,
		Pets = { chicken = 60, parrot = 30, horse = 10 },
	},
	["Green egg"] = {
		Rarity = "Uncommon", HatchTime = 20, SpawnWeight = 25,
		Pets = { chicken = 40, parrot = 35, horse = 20, spider = 5 },
	},
	["Blue egg"] = {
		Rarity = "Rare", HatchTime = 30, SpawnWeight = 15,
		Pets = { parrot = 35, horse = 35, spider = 25, scorpion = 5 },
	},
	["Purple egg"] = {
		Rarity = "Epic", HatchTime = 45, SpawnWeight = 10,
		Pets = { horse = 30, spider = 35, scorpion = 30, walrus = 5 },
	},
	["Orange egg"] = {
		Rarity = "Legendary", HatchTime = 60, SpawnWeight = 5,
		Pets = { spider = 30, scorpion = 40, walrus = 25, goldenpeacock = 5 },
	},
	["Red egg"] = {
		Rarity = "Mythic", HatchTime = 90, SpawnWeight = 3,
		Pets = { scorpion = 35, walrus = 45, goldenpeacock = 20 },
	},
	["Gold egg"] = {
		Rarity = "Godly", HatchTime = 120, SpawnWeight = 2,
		Pets = { walrus = 40, goldenpeacock = 60 },
	},
}

-- Nicer names shown over the hatched pet (optional)
local PET_DISPLAY_NAMES = {
	chicken = "Chicken",
	goldenpeacock = "Golden Peacock",
	horse = "Horse",
	parrot = "Parrot",
	scorpion = "Scorpion",
	spider = "Spider",
	walrus = "Walrus",
}

---------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------
local rng = Random.new()

local function findInGame(name)
	for _, root in ipairs({ workspace, ServerStorage, ReplicatedStorage }) do
		local found = root:FindFirstChild(name, true)
		if found then
			return found
		end
	end
	return nil
end

-- Templates lying in Workspace are moved here so they are not visible in the game.
local templateStorage = Instance.new("Folder")
templateStorage.Name = "EggSystemTemplates"
templateStorage.Parent = ServerStorage

local function hideTemplate(template)
	if template:IsDescendantOf(workspace) then
		template.Parent = templateStorage
	end
end

local function weightedPick(weights)
	local total = 0
	for _, weight in pairs(weights) do
		total += weight
	end
	if total <= 0 then
		return nil
	end
	local roll = rng:NextNumber(0, total)
	for key, weight in pairs(weights) do
		roll -= weight
		if roll <= 0 then
			return key
		end
	end
	return next(weights)
end

local function largestPart(model)
	local best, bestVolume = nil, -1
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local volume = d.Size.X * d.Size.Y * d.Size.Z
			if volume > bestVolume then
				best, bestVolume = d, volume
			end
		end
	end
	return best
end

-- Clones a template and always returns a Model with a PrimaryPart and all parts welded together.
local function cloneAsModel(template)
	local clone = template:Clone()
	local model = clone
	if clone:IsA("BasePart") then
		model = Instance.new("Model")
		model.Name = template.Name
		clone.Parent = model
		model.PrimaryPart = clone
	end
	if not model.PrimaryPart then
		model.PrimaryPart = largestPart(model)
	end
	local primary = model.PrimaryPart
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			if d ~= primary then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = primary
				weld.Part1 = d
				weld.Parent = primary
			end
		elseif d:IsA("Script") then
			d:Destroy() -- stop leftover scripts inside templates from running on clones
		end
	end
	return model
end

local function setParts(model, props)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			for key, value in pairs(props) do
				d[key] = value
			end
		end
	end
end

-- Puts a model so that its bottom touches `point`.
local function placeOnSurface(model, point, yaw)
	model:PivotTo(CFrame.new(point) * CFrame.Angles(0, yaw, 0))
	local cf, size = model:GetBoundingBox()
	local offset = Vector3.new(point.X - cf.Position.X, point.Y - (cf.Position.Y - size.Y / 2), point.Z - cf.Position.Z)
	model:PivotTo(model:GetPivot() + offset)
end

local function randomPointOnTop(part, margin)
	local halfX = math.max(part.Size.X / 2 - margin, 0)
	local halfZ = math.max(part.Size.Z / 2 - margin, 0)
	local localPoint = Vector3.new(rng:NextNumber(-halfX, halfX), part.Size.Y / 2, rng:NextNumber(-halfZ, halfZ))
	return part.CFrame:PointToWorldSpace(localPoint)
end

-- Runs onStep(alpha) from 0 to 1 using TweenService easing, and yields until finished.
local function animate(duration, style, direction, onStep)
	local value = Instance.new("NumberValue")
	value.Value = 0
	local conn = value.Changed:Connect(onStep)
	local tween = TweenService:Create(value, TweenInfo.new(duration, style, direction), { Value = 1 })
	tween:Play()
	tween.Completed:Wait()
	conn:Disconnect()
	value:Destroy()
	onStep(1)
end

local function formatTime(seconds)
	seconds = math.max(0, math.ceil(seconds))
	if seconds >= 60 then
		return string.format("%d:%02d", seconds // 60, seconds % 60)
	end
	return seconds .. "s"
end

---------------------------------------------------------------------
-- TEXT TAGS (Fredoka One + black outline)
---------------------------------------------------------------------
local function makeLabel(parent, name, text, color, position, size)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = CONFIG.FONT
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = CONFIG.OUTLINE_THICKNESS
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = label

	label.Parent = parent
	return label
end

-- Billboard over a model: [timer] / name / rarity
local function makeEggTag(model, eggName, rarity)
	local cf, size = model:GetBoundingBox()
	local topAbovePrimary = (cf.Position.Y + size.Y / 2) - model.PrimaryPart.Position.Y

	local gui = Instance.new("BillboardGui")
	gui.Name = "EggTag"
	gui.Adornee = model.PrimaryPart
	gui.Size = UDim2.fromScale(8, 3) -- in studs, so it keeps its size in the world
	gui.StudsOffsetWorldSpace = Vector3.new(0, topAbovePrimary + 1.6, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 80

	local timer = makeLabel(gui, "Timer", "", Color3.new(1, 1, 1), UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.4))
	timer.Visible = false
	makeLabel(gui, "EggName", eggName, Color3.new(1, 1, 1), UDim2.fromScale(0, 0.4), UDim2.fromScale(1, 0.33))
	makeLabel(gui, "Rarity", rarity, RARITIES[rarity] or Color3.new(1, 1, 1), UDim2.fromScale(0, 0.73), UDim2.fromScale(1, 0.27))

	gui.Parent = model
	return gui, timer
end

---------------------------------------------------------------------
-- LOAD TEMPLATES
---------------------------------------------------------------------
local eggTemplates = {}
for eggName in pairs(EGGS) do
	local template = findInGame(eggName)
	if template then
		eggTemplates[eggName] = template
	else
		warn("[EggSystem] Could not find egg model named '" .. eggName .. "'")
	end
end
for _, template in pairs(eggTemplates) do
	hideTemplate(template)
end

local petTemplates = {}
local petsFolder = findInGame(CONFIG.PETS_FOLDER_NAME)
if petsFolder then
	for _, pet in ipairs(petsFolder:GetChildren()) do
		if pet:IsA("Model") or pet:IsA("BasePart") then
			petTemplates[pet.Name] = pet
		end
	end
	hideTemplate(petsFolder)
else
	warn("[EggSystem] Could not find the pets folder '" .. CONFIG.PETS_FOLDER_NAME .. "'")
end

local spawnArea = findInGame(CONFIG.SPAWN_AREA_NAME)
local spawnParts = {}
if spawnArea then
	if spawnArea:IsA("BasePart") then
		table.insert(spawnParts, spawnArea)
	end
	for _, d in ipairs(spawnArea:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(spawnParts, d)
		end
	end
end
if #spawnParts == 0 then
	warn("[EggSystem] No parts found in '" .. CONFIG.SPAWN_AREA_NAME .. "' - eggs cannot spawn")
end

local eggContainer = Instance.new("Folder")
eggContainer.Name = "ActiveEggs"
eggContainer.Parent = workspace

---------------------------------------------------------------------
-- BASES
---------------------------------------------------------------------
local bases = {} -- { Floor = BasePart, Owner = Player?, Sign = BillboardGui? }
local playerBase = {} -- [Player] = base

local function floorOf(baseInstance)
	if baseInstance:IsA("BasePart") then
		return baseInstance
	end
	if baseInstance:IsA("Model") then
		return baseInstance:FindFirstChild("Floor", true) or baseInstance.PrimaryPart or largestPart(baseInstance)
	end
	return nil
end

local basesFolder = workspace:FindFirstChild(CONFIG.BASES_FOLDER_NAME)
if not basesFolder then
	warn("[EggSystem] No '" .. CONFIG.BASES_FOLDER_NAME .. "' folder in Workspace - creating simple bases")
	basesFolder = Instance.new("Folder")
	basesFolder.Name = CONFIG.BASES_FOLDER_NAME
	for i = 1, CONFIG.AUTO_BASE_COUNT do
		local part = Instance.new("Part")
		part.Name = "Base" .. i
		part.Anchored = true
		part.Size = CONFIG.AUTO_BASE_SIZE
		part.Position = CONFIG.AUTO_BASE_START + Vector3.new((i - 1) * CONFIG.AUTO_BASE_SPACING, 0, 0)
		part.Color = Color3.fromRGB(90, 160, 90)
		part.Material = Enum.Material.Grass
		part.Parent = basesFolder
	end
	basesFolder.Parent = workspace
end
for _, child in ipairs(basesFolder:GetChildren()) do
	local floor = floorOf(child)
	if floor then
		table.insert(bases, { Floor = floor })
	end
end

local function assignBase(player)
	for _, base in ipairs(bases) do
		if not base.Owner then
			base.Owner = player
			playerBase[player] = base

			local sign = Instance.new("BillboardGui")
			sign.Name = "BaseSign"
			sign.Adornee = base.Floor
			sign.Size = UDim2.fromScale(14, 3)
			sign.StudsOffsetWorldSpace = Vector3.new(0, base.Floor.Size.Y / 2 + 8, 0)
			sign.LightInfluence = 0
			sign.MaxDistance = 150
			makeLabel(sign, "Owner", player.DisplayName .. "'s Base", Color3.new(1, 1, 1), UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
			sign.Parent = base.Floor
			base.Sign = sign
			return
		end
	end
	warn("[EggSystem] No free base for " .. player.Name)
end

local function isInsideBase(floor, position)
	local rel = floor.CFrame:PointToObjectSpace(position)
	return math.abs(rel.X) <= floor.Size.X / 2
		and math.abs(rel.Z) <= floor.Size.Z / 2
		and rel.Y > -2
		and rel.Y < 25
end

---------------------------------------------------------------------
-- EGG STATE
---------------------------------------------------------------------
-- egg = { Model, Name, Data, State = "World"|"Carried"|"Incubating"|"Ready"|"Hatching",
--         Owner, Prompt, Click, TimerLabel, ReadyAt, CarryWeld, SpawnedAt }
local activeEggs = {} -- [Model] = egg
local carrying = {} -- [Player] = egg
local hatchedPets = {} -- [Player] = { Model, ... }

local function removeEgg(egg)
	activeEggs[egg.Model] = nil
	if egg.Owner and carrying[egg.Owner] == egg then
		carrying[egg.Owner] = nil
	end
	egg.Model:Destroy()
end

local function countEggs(predicate)
	local n = 0
	for _, egg in pairs(activeEggs) do
		if predicate(egg) then
			n += 1
		end
	end
	return n
end

local function getAliveRoot(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and root and humanoid.Health > 0 then
		return root
	end
	return nil
end

local function makePrompt(egg, actionText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = egg.Name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = CONFIG.INTERACT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = egg.Model.PrimaryPart
	return prompt
end

---------------------------------------------------------------------
-- PICK UP / CARRY
---------------------------------------------------------------------
local function pickUp(player, egg)
	if egg.State ~= "World" or carrying[player] then
		return
	end
	local root = getAliveRoot(player)
	if not root then
		return
	end
	local model = egg.Model
	if (root.Position - model:GetPivot().Position).Magnitude > CONFIG.INTERACT_DISTANCE + 4 then
		return
	end

	egg.State = "Carried"
	egg.Owner = player
	carrying[player] = egg
	if egg.Prompt then
		egg.Prompt:Destroy()
		egg.Prompt = nil
	end
	if egg.Click then
		egg.Click:Destroy()
		egg.Click = nil
	end

	-- Move above the player's head and weld it on
	local cf, size = model:GetBoundingBox()
	local pivotOffset = cf:ToObjectSpace(model:GetPivot())
	local target = root.CFrame * CFrame.new(0, CONFIG.CARRY_HEIGHT + size.Y / 2, 0)
	model:PivotTo(target * pivotOffset)

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
	egg.CarryWeld = weld

	setParts(model, { CanCollide = false, CanTouch = false, Massless = true, Anchored = false })
end

local function dropCarried(player)
	local egg = carrying[player]
	if egg then
		removeEgg(egg) -- the egg breaks if you die / leave while carrying it
	end
end

---------------------------------------------------------------------
-- HATCHING
---------------------------------------------------------------------
local function popParticles(position, color)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.Position = position
	holder.Parent = workspace

	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	emitter.Color = ColorSequence.new(color)
	emitter.Lifetime = NumberRange.new(0.5, 0.9)
	emitter.Speed = NumberRange.new(8, 16)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	emitter.LightEmission = 0.6
	emitter.Parent = holder
	emitter:Emit(40)

	Debris:AddItem(holder, 2)
end

local function choosePet(eggData)
	local weights = {}
	for petName, weight in pairs(eggData.Pets) do
		if petTemplates[petName] then
			weights[petName] = weight
		end
	end
	local pick = weightedPick(weights)
	if not pick then
		-- none of the listed pets exist -> any pet
		local names = {}
		for name in pairs(petTemplates) do
			table.insert(names, name)
		end
		pick = names[rng:NextInteger(1, math.max(#names, 1))]
	end
	return pick
end

local function hatch(egg)
	local model = egg.Model
	local player = egg.Owner
	local rarityColor = RARITIES[egg.Data.Rarity] or Color3.new(1, 1, 1)

	local tag = model:FindFirstChild("EggTag")
	if tag then
		tag:Destroy()
	end

	-- 1) Wobble: right, left, right, back to centre (rotates around the bottom of the egg)
	local startPivot = model:GetPivot()
	local cf, size = model:GetBoundingBox()
	local bottom = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0)) * startPivot.Rotation
	local rel = bottom:ToObjectSpace(startPivot)
	local function tiltTo(fromAngle, toAngle, duration)
		animate(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, function(a)
			local angle = fromAngle + (toAngle - fromAngle) * a
			model:PivotTo(bottom * CFrame.Angles(0, 0, angle) * rel)
		end)
	end
	local tilt = math.rad(25)
	tiltTo(0, -tilt, 0.3) -- right
	tiltTo(-tilt, tilt, 0.4) -- left
	tiltTo(tilt, -tilt, 0.4) -- right
	tiltTo(-tilt, 0, 0.2) -- centre   (total 1.3 s)

	-- 2) Open: egg fades away, pet pops out of the top (0.45 s) and lands (0.3 s)
	local eggTop = cf.Position + Vector3.new(0, size.Y / 2, 0)
	local groundPoint = cf.Position - Vector3.new(0, size.Y / 2, 0)
	popParticles(eggTop, rarityColor)

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") or d:IsA("Decal") or d:IsA("Texture") then
			TweenService:Create(d, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		end
	end

	local petName = choosePet(egg.Data)
	local petTemplate = petName and petTemplates[petName]
	local pet
	if petTemplate then
		pet = cloneAsModel(petTemplate)
		setParts(pet, { Anchored = true, CanCollide = false })
		pet.Name = petName
		local yaw = select(2, startPivot:ToEulerAnglesYXZ())
		placeOnSurface(pet, groundPoint, yaw)
		local finalPivot = pet:GetPivot()
		local _, petSize = pet:GetBoundingBox()
		local emergePivot = finalPivot + Vector3.new(0, size.Y * 0.5, 0)
		local peakPivot = finalPivot + Vector3.new(0, size.Y + 1.5, 0)

		local canScale = pcall(function()
			pet:ScaleTo(0.15)
		end)
		pet:PivotTo(emergePivot)
		pet.Parent = eggContainer

		animate(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out, function(a)
			if canScale then
				pet:ScaleTo(math.max(0.15 + 0.85 * a, 0.05))
			end
			pet:PivotTo(emergePivot:Lerp(peakPivot, math.clamp(a, 0, 1.2)))
		end)
		removeEgg(egg)
		animate(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, function(a)
			pet:PivotTo(peakPivot:Lerp(finalPivot, a))
		end)

		-- Name tag over the pet
		local petGui = Instance.new("BillboardGui")
		petGui.Name = "PetTag"
		petGui.Adornee = pet.PrimaryPart
		petGui.Size = UDim2.fromScale(8, 1.4)
		petGui.StudsOffsetWorldSpace = Vector3.new(0, petSize.Y / 2 + 1.5, 0)
		petGui.AlwaysOnTop = true
		petGui.LightInfluence = 0
		petGui.MaxDistance = 80
		makeLabel(petGui, "PetName", PET_DISPLAY_NAMES[petName] or petName, rarityColor, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
		petGui.Parent = pet

		if player and player.Parent then
			hatchedPets[player] = hatchedPets[player] or {}
			table.insert(hatchedPets[player], pet)
		else
			pet:Destroy()
		end
	else
		warn("[EggSystem] No pet models found in '" .. CONFIG.PETS_FOLDER_NAME .. "'")
		task.wait(0.75)
		removeEgg(egg)
	end
end

---------------------------------------------------------------------
-- PLACING ON BASE
---------------------------------------------------------------------
local function findFreeSpot(player, floor)
	local taken = {}
	for _, egg in pairs(activeEggs) do
		if egg.Owner == player and egg.State ~= "Carried" then
			table.insert(taken, egg.Model:GetPivot().Position)
		end
	end
	for _, pet in ipairs(hatchedPets[player] or {}) do
		if pet.Parent then
			table.insert(taken, pet:GetPivot().Position)
		end
	end

	local margin = math.min(3, floor.Size.X / 4, floor.Size.Z / 4)
	local point = randomPointOnTop(floor, margin)
	for _ = 1, 20 do
		local ok = true
		for _, pos in ipairs(taken) do
			if (Vector3.new(pos.X, point.Y, pos.Z) - point).Magnitude < 5 then
				ok = false
				break
			end
		end
		if ok then
			break
		end
		point = randomPointOnTop(floor, margin)
	end
	return point
end

local function placeAtBase(player, egg)
	local base = playerBase[player]
	local model = egg.Model

	setParts(model, { Anchored = true, CanCollide = true, CanTouch = true, Massless = false })
	if egg.CarryWeld then
		egg.CarryWeld:Destroy()
		egg.CarryWeld = nil
	end
	placeOnSurface(model, findFreeSpot(player, base.Floor), rng:NextNumber(0, math.pi * 2))

	carrying[player] = nil
	egg.State = "Incubating"
	egg.ReadyAt = os.clock() + egg.Data.HatchTime
	egg.TimerLabel.Visible = true
	egg.TimerLabel.TextColor3 = Color3.new(1, 1, 1)
	egg.TimerLabel.Text = formatTime(egg.Data.HatchTime)

	local prompt = makePrompt(egg, "Open")
	prompt.Enabled = false
	egg.Prompt = prompt
	prompt.Triggered:Connect(function(who)
		if who ~= egg.Owner or egg.State ~= "Ready" then
			return
		end
		local root = getAliveRoot(who)
		if not root or (root.Position - model:GetPivot().Position).Magnitude > CONFIG.INTERACT_DISTANCE + 4 then
			return
		end
		egg.State = "Hatching"
		prompt:Destroy()
		egg.Prompt = nil
		task.spawn(hatch, egg)
	end)
end

---------------------------------------------------------------------
-- SPAWNING
---------------------------------------------------------------------
local function pickSpawnPart()
	local weights = {}
	for i, part in ipairs(spawnParts) do
		weights[i] = part.Size.X * part.Size.Z
	end
	return spawnParts[weightedPick(weights)]
end

local function spawnEgg()
	if #spawnParts == 0 then
		return
	end
	local weights = {}
	for eggName, data in pairs(EGGS) do
		if eggTemplates[eggName] then
			weights[eggName] = data.SpawnWeight
		end
	end
	local eggName = weightedPick(weights)
	if not eggName then
		return
	end
	local data = EGGS[eggName]

	-- Find a spot that is not on top of another egg
	local part = pickSpawnPart()
	local point = randomPointOnTop(part, 2)
	for _ = 1, 10 do
		local clear = true
		for _, other in pairs(activeEggs) do
			if other.State == "World" and (other.Model:GetPivot().Position - point).Magnitude < 4 then
				clear = false
				break
			end
		end
		if clear then
			break
		end
		part = pickSpawnPart()
		point = randomPointOnTop(part, 2)
	end

	local model = cloneAsModel(eggTemplates[eggName])
	model.Name = eggName
	setParts(model, { Anchored = true, CanCollide = true })
	placeOnSurface(model, point, rng:NextNumber(0, math.pi * 2))
	model.Parent = eggContainer

	local egg = {
		Model = model,
		Name = eggName,
		Data = data,
		State = "World",
		SpawnedAt = os.clock(),
	}
	local _, timerLabel = makeEggTag(model, eggName, data.Rarity)
	egg.TimerLabel = timerLabel
	activeEggs[model] = egg

	-- PC: press E  |  Phone: tap the prompt button
	egg.Prompt = makePrompt(egg, "Pick up")
	egg.Prompt.Triggered:Connect(function(player)
		pickUp(player, egg)
	end)

	-- Phone/PC: tap or click directly on the egg
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = CONFIG.INTERACT_DISTANCE + 4
	click.Parent = model
	click.MouseClick:Connect(function(player)
		pickUp(player, egg)
	end)
	egg.Click = click
end

task.spawn(function()
	while true do
		if countEggs(function(e) return e.State == "World" end) < CONFIG.MAX_EGGS_IN_WORLD then
			spawnEgg()
		end
		task.wait(CONFIG.SPAWN_INTERVAL)
	end
end)

---------------------------------------------------------------------
-- MAIN LOOPS
---------------------------------------------------------------------
-- Timers + despawning
task.spawn(function()
	while true do
		local now = os.clock()
		for _, egg in pairs(activeEggs) do
			if egg.State == "Incubating" then
				local left = egg.ReadyAt - now
				if left <= 0 then
					egg.State = "Ready"
					egg.TimerLabel.Text = "READY!"
					egg.TimerLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
					if egg.Prompt then
						egg.Prompt.Enabled = true
					end
				else
					local text = formatTime(left)
					if egg.TimerLabel.Text ~= text then
						egg.TimerLabel.Text = text
					end
				end
			elseif egg.State == "World" and now - egg.SpawnedAt > CONFIG.EGG_DESPAWN_TIME then
				removeEgg(egg)
			end
		end
		task.wait(0.2)
	end
end)

-- Put the carried egg down when the player walks onto their base
RunService.Heartbeat:Connect(function()
	for player, egg in pairs(carrying) do
		local root = getAliveRoot(player)
		local base = playerBase[player]
		if root and base and isInsideBase(base.Floor, root.Position) then
			local onBase = countEggs(function(e)
				return e.Owner == player and (e.State == "Incubating" or e.State == "Ready" or e.State == "Hatching")
			end)
			if onBase < CONFIG.MAX_EGGS_PER_BASE then
				placeAtBase(player, egg)
			else
				egg.TimerLabel.Visible = true
				egg.TimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				egg.TimerLabel.Text = "Base full!"
			end
		elseif egg.TimerLabel.Visible then
			egg.TimerLabel.Visible = false
		end
	end
end)

---------------------------------------------------------------------
-- PLAYERS
---------------------------------------------------------------------
local function onPlayerAdded(player)
	assignBase(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			dropCarried(player)
		end)
	end)
	player.CharacterRemoving:Connect(function()
		dropCarried(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	dropCarried(player)
	for _, egg in pairs(activeEggs) do
		if egg.Owner == player then
			removeEgg(egg)
		end
	end
	for _, pet in ipairs(hatchedPets[player] or {}) do
		pet:Destroy()
	end
	hatchedPets[player] = nil

	local base = playerBase[player]
	if base then
		base.Owner = nil
		if base.Sign then
			base.Sign:Destroy()
			base.Sign = nil
		end
	end
	playerBase[player] = nil
end)
