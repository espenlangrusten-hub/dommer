--!strict
--[[
	Showcase
	The full-screen "here is the item" moment from the reference clip: the item
	floats in front of the camera on a lit panel, gold sparks burst out of it,
	and the name, rarity and owned count sit to the right. A click anywhere
	closes it.

	It is a real world part rather than a flat image so the sparks and the
	lighting read the same way they do in the clip.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CardSystem = ReplicatedStorage:WaitForChild("CardSystem")
local Cards = require(CardSystem:WaitForChild("Cards"))
local Config = require(CardSystem:WaitForChild("Config"))
local Rarities = require(CardSystem:WaitForChild("Rarities"))
local Theme = require(CardSystem:WaitForChild("Theme"))

local Profile = require(script.Parent:WaitForChild("Profile"))

local make = Theme.make
local SHOW = Config.Showcase

local Showcase = {}
Showcase.__index = Showcase

export type Showcase = typeof(setmetatable(
	{} :: {
		Gui: ScreenGui,
		NameLabel: TextLabel,
		RarityLabel: TextLabel,
		OwnedLabel: TextLabel,
		TagLabel: TextLabel,
		Hint: TextLabel,
		Part: BasePart?,
		Sparks: ParticleEmitter?,
		Base: CFrame,
		StartTime: number,
		Open: boolean,
		Connection: RBXScriptConnection?,
		OnClosed: (() -> ())?,
	},
	Showcase
))

function Showcase.new(): Showcase
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local gui = make("ScreenGui", {
		Name = "CardShowcase",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 20,
		Enabled = false,
	}) :: ScreenGui

	-- Text column, right of centre, matching the reference layout.
	local column = make("Frame", {
		Name = "Details",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.58, 0.46),
		Size = UDim2.fromOffset(420, 160),
		Parent = gui,
	})

	local nameLabel = Theme.label({
		Name = "ItemName",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 34),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		TextSize = 30,
		Text = "",
		Parent = column,
	}, 3)

	local rarityLabel = Theme.label({
		Name = "Rarity",
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		TextSize = 18,
		Text = "",
		Parent = column,
	}, 2.5)

	local ownedLabel = Theme.label({
		Name = "Owned",
		Position = UDim2.fromOffset(0, 58),
		Size = UDim2.new(1, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		TextSize = 18,
		Text = "",
		Parent = column,
	}, 2.5)

	local tagLabel = Theme.label({
		Name = "Tagline",
		Position = UDim2.fromOffset(0, 92),
		Size = UDim2.new(1, 0, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		TextSize = 24,
		TextWrapped = true,
		Text = "",
		Parent = column,
	}, 3)

	local hint = Theme.label({
		Name = "Hint",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -70),
		Size = UDim2.fromOffset(400, 24),
		TextScaled = false,
		TextSize = 18,
		Text = "(Click anywhere to continue)",
		Parent = gui,
	}, 2.5)

	gui.Parent = playerGui

	local self = setmetatable({
		Gui = gui,
		NameLabel = nameLabel,
		RarityLabel = rarityLabel,
		OwnedLabel = ownedLabel,
		TagLabel = tagLabel,
		Hint = hint,
		Part = nil,
		Sparks = nil,
		Base = CFrame.new(),
		StartTime = 0,
		Open = false,
		Connection = nil,
		OnClosed = nil,
	}, Showcase)

	return (self :: any) :: Showcase
end

local function buildFace(card: Cards.Card, rarity: Rarities.Rarity): CanvasGroup
	local top, bottom = Theme.rarityBackdrop(rarity.Color)
	return make("CanvasGroup", {
		Name = "Face",
		BackgroundColor3 = top,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
	}, {
		Theme.corner(10),
		Theme.gradient(top, bottom, 135),
		Theme.stroke(rarity.Color, 6),
		Theme.iconFor(card.Name, card.Icon, rarity.Color, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.5, 0.66),
		}),
	})
end

function Showcase.show(self: Showcase, cardId: string)
	local card = Cards.get(cardId)
	if not card then
		return
	end
	local rarity = Rarities.get(card.Rarity)

	self:hide(true)

	local camera = workspace.CurrentCamera
	local base = camera.CFrame * CFrame.new(0, 0.2, -SHOW.Distance)
	self.Base = CFrame.lookAt(base.Position, camera.CFrame.Position)

	local part = make("Part", {
		Name = "ShowcaseItem",
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		CastShadow = false,
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(14, 15, 20),
		Size = SHOW.Size,
		CFrame = self.Base,
		Parent = workspace,
	}) :: BasePart

	make("SurfaceGui", {
		Name = "FaceGui",
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = Config.PixelsPerStud,
		LightInfluence = 0,
		Brightness = 1.6,
		MaxDistance = 250,
		Parent = part,
	}, { buildFace(card, rarity) })

	make("PointLight", {
		Color = rarity.GlowColor,
		Brightness = 3,
		Range = 16,
		Shadows = false,
		Parent = part,
	})

	local attachment = make("Attachment", { Name = "SparkPoint", Parent = part }) :: Attachment
	local sparks = make("ParticleEmitter", {
		Name = "Sparks",
		Color = ColorSequence.new(rarity.GlowColor),
		LightEmission = 1,
		Lifetime = NumberRange.new(0.6, 1.4),
		Speed = NumberRange.new(9, 20),
		SpreadAngle = Vector2.new(180, 180),
		Rate = 26,
		Rotation = NumberRange.new(0, 360),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = attachment,
	}) :: ParticleEmitter
	sparks:Emit(60)

	self.Part = part
	self.Sparks = sparks
	self.StartTime = os.clock()

	self.NameLabel.Text = card.Name
	self.RarityLabel.Text = rarity.Name
	self.RarityLabel.TextColor3 = rarity.TextColor
	self.OwnedLabel.Text = `Owned: {Profile.count(cardId)}x`
	self.TagLabel.Text = card.Description

	self.Gui.Enabled = true
	self.Open = true

	-- Fade the text in rather than popping it.
	for _, label in { self.NameLabel, self.RarityLabel, self.OwnedLabel, self.TagLabel } do
		label.TextTransparency = 1
		TweenService:Create(label, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	end

	self.Connection = RunService.RenderStepped:Connect(function()
		self:step()
	end)
end

function Showcase.step(self: Showcase)
	local part = self.Part
	if not part then
		return
	end
	local elapsed = os.clock() - self.StartTime
	local bob = math.sin(elapsed * SHOW.BobSpeed) * SHOW.BobHeight
	local spin = math.sin(elapsed * SHOW.SpinSpeed) * 0.25

	part.CFrame = CFrame.new(0, bob, 0) * self.Base * CFrame.Angles(0, spin, 0)
end

--[[
	Tears the showcase down. `silent` skips the closed callback, which the
	show path uses when it replaces an already open showcase.
]]
function Showcase.hide(self: Showcase, silent: boolean?)
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	if self.Part then
		self.Part:Destroy()
		self.Part = nil
	end
	self.Sparks = nil

	local wasOpen = self.Open
	self.Open = false
	self.Gui.Enabled = false

	if wasOpen and not silent and self.OnClosed then
		(self.OnClosed :: any)()
	end
end

return Showcase
