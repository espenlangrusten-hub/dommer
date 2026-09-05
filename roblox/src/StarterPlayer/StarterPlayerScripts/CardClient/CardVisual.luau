--!strict
--[[
	CardVisual
	One 3D card: an anchored Part with a SurfaceGui on each face.

	Nothing here uses TweenService for the CFrame. The controller drives every
	card from a single RenderStepped pass, so entrance, flip, cursor tilt and
	hover compose into one transform instead of fighting each other.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardSystem = ReplicatedStorage:WaitForChild("CardSystem")
local Cards = require(CardSystem:WaitForChild("Cards"))
local Config = require(CardSystem:WaitForChild("Config"))
local Rarities = require(CardSystem:WaitForChild("Rarities"))
local Theme = require(CardSystem:WaitForChild("Theme"))

type Card = Cards.Card

local BACKDROP = Color3.fromRGB(16, 17, 22)

-- Easing -----------------------------------------------------------------
local function clamp01(n: number): number
	return math.clamp(n, 0, 1)
end

local function easeOutCubic(t: number): number
	return 1 - (1 - t) ^ 3
end

local function easeOutBack(t: number): number
	local c1, c3 = 1.70158, 2.70158
	return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

local function easeInOutCubic(t: number): number
	return if t < 0.5 then 4 * t ^ 3 else 1 - (-2 * t + 2) ^ 3 / 2
end

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Face building ----------------------------------------------------------
local make = Theme.make

--[[
	The card face. Everything here is fully opaque once the entrance finishes:
	a saturated rarity backdrop, a large icon, and heavy black outlines on
	every string, so the card reads at a glance instead of washing out against
	the sky.
]]
local function buildFront(card: Card, rarity: Rarities.Rarity): CanvasGroup
	local top, bottom = Theme.rarityBackdrop(rarity.Color)

	local children: { any } = {
		Theme.corner(10),
		Theme.gradient(top, bottom, 135),
		Theme.stroke(rarity.Color, 7),
	}

	local dots = Theme.dots()
	if dots then
		table.insert(children, dots)
	end

	-- Rarity band behind the icon, solid rather than a faint wash.
	table.insert(
		children,
		make("Frame", {
			Name = "Band",
			BackgroundColor3 = rarity.Color:Lerp(Color3.new(0, 0, 0), 0.22),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 0.44),
		}, {
			Theme.gradient(
				rarity.Color:Lerp(Color3.new(1, 1, 1), 0.15),
				rarity.Color:Lerp(Color3.new(0, 0, 0), 0.45)
			),
		})
	)

	table.insert(
		children,
		Theme.iconFor(card.Name, card.Icon, rarity.Color, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.05),
			Size = UDim2.fromScale(0.66, 0.34),
		})
	)

	table.insert(
		children,
		Theme.label({
			Name = "CardName",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromScale(0.9, 0.1),
			Text = card.Name,
		}, 4)
	)

	table.insert(
		children,
		Theme.label({
			Name = "RarityLabel",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.56),
			Size = UDim2.fromScale(0.82, 0.075),
			Text = rarity.Name,
			TextColor3 = rarity.TextColor,
		}, 4)
	)

	table.insert(
		children,
		make("Frame", {
			Name = "Divider",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.65),
			Size = UDim2.fromScale(0.62, 0.008),
			BackgroundColor3 = rarity.Color,
			BorderSizePixel = 0,
		})
	)

	table.insert(
		children,
		Theme.label({
			Name = "Flavor",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.675),
			Size = UDim2.fromScale(0.84, 0.15),
			Text = card.Flavor,
			TextColor3 = Color3.fromRGB(236, 240, 248),
			TextWrapped = true,
			TextScaled = false,
			TextSize = 34,
		}, 3)
	)

	-- Footer call to action.
	table.insert(
		children,
		make("Frame", {
			Name = "Footer",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.96),
			Size = UDim2.fromScale(0.76, 0.085),
			BackgroundColor3 = Color3.fromRGB(10, 11, 15),
			BorderSizePixel = 0,
		}, {
			Theme.corner(999),
			Theme.stroke(rarity.Color, 3),
			Theme.label({
				Name = "Prompt",
				Size = UDim2.fromScale(1, 1),
				Text = "Click to Select",
			}, 3),
		})
	)

	return make("CanvasGroup", {
		Name = "Face",
		BackgroundColor3 = top,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 1,
		ClipsDescendants = true,
	}, children)
end

local function buildBack(): CanvasGroup
	local children: { any } = {
		Theme.corner(10),
		Theme.gradient(Color3.fromRGB(40, 43, 56), Color3.fromRGB(13, 14, 19)),
		Theme.stroke(Color3.fromRGB(120, 128, 150), 6),
	}

	local dots = Theme.dots()
	if dots then
		table.insert(children, dots)
	end

	table.insert(
		children,
		make("Frame", {
			Name = "Emblem",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.36, 0.26),
			Rotation = 45,
			BackgroundColor3 = Color3.fromRGB(140, 148, 172),
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
		}, {
			Theme.stroke(Color3.fromRGB(190, 198, 220), 3),
		})
	)

	return make("CanvasGroup", {
		Name = "Back",
		BackgroundColor3 = Color3.fromRGB(22, 23, 30),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 1,
		ClipsDescendants = true,
	}, children)
end

-- Class ------------------------------------------------------------------
local CardVisual = {}
CardVisual.__index = CardVisual

export type CardVisual = typeof(setmetatable(
	{} :: {
		Card: Card,
		Rarity: Rarities.Rarity,
		Slot: number,
		Part: BasePart,
		BaseCFrame: CFrame,
		StartTime: number,
		EnterDelay: number,
		FlipDelay: number,
		State: string,
		ExitStart: number,
		ExitMode: string,
		Revealed: boolean,
		Tilt: Vector2,
		Hover: number,
		OnRevealed: ((slot: number) -> ())?,
		Front: CanvasGroup,
		BackFace: CanvasGroup,
		Light: PointLight,
		Glow: Highlight,
		Sparks: ParticleEmitter,
	},
	CardVisual
))

function CardVisual.new(card: Card, slot: number, baseCFrame: CFrame, parent: Instance): CardVisual
	local rarity = Rarities.get(card.Rarity)

	local part = make("Part", {
		Name = `Card_{card.Id}`,
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = true, -- the controller raycasts against this
		CastShadow = false,
		Material = Enum.Material.SmoothPlastic,
		Color = BACKDROP,
		Transparency = 1,
		Size = Config.CardSize,
		CFrame = baseCFrame,
	}) :: BasePart

	local front = buildFront(card, rarity)
	local back = buildBack()

	make("SurfaceGui", {
		Name = "FrontGui",
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = Config.PixelsPerStud,
		LightInfluence = 0,
		Brightness = 1.9,
		MaxDistance = 250,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = part,
	}, { front })

	make("SurfaceGui", {
		Name = "BackGui",
		Face = Enum.NormalId.Back,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = Config.PixelsPerStud,
		LightInfluence = 0,
		Brightness = 1.6,
		MaxDistance = 250,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = part,
	}, { back })

	local light = make("PointLight", {
		Color = rarity.GlowColor,
		Brightness = 0,
		Range = 10,
		Shadows = false,
		Parent = part,
	}) :: PointLight

	local glow = make("Highlight", {
		Name = "Hover",
		Adornee = part,
		FillTransparency = 1,
		OutlineColor = rarity.GlowColor,
		OutlineTransparency = 1,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		Parent = part,
	}) :: Highlight

	local attachment = make("Attachment", { Name = "SparkPoint", Parent = part }) :: Attachment
	local sparks = make("ParticleEmitter", {
		Name = "Sparks",
		Enabled = false,
		Color = ColorSequence.new(rarity.GlowColor),
		LightEmission = 1,
		Lifetime = NumberRange.new(0.5, 1.1),
		Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(180, 180),
		Rate = 0,
		Rotation = NumberRange.new(0, 360),
		Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = attachment,
	}) :: ParticleEmitter

	part.Parent = parent

	local self = setmetatable({
		Card = card,
		Rarity = rarity,
		Slot = slot,
		Part = part,
		BaseCFrame = baseCFrame,
		StartTime = os.clock(),
		EnterDelay = (slot - 1) * Config.EnterStagger,
		FlipDelay = Config.EnterDuration + (slot - 1) * Config.FlipStagger + rarity.RevealDelay,
		State = "entering",
		ExitStart = 0,
		ExitMode = "discarded",
		Revealed = false,
		Tilt = Vector2.zero,
		Hover = 0,
		OnRevealed = nil,
		Front = front,
		BackFace = back,
		Light = light,
		Glow = glow,
		Sparks = sparks,
	}, CardVisual)

	return (self :: any) :: CardVisual
end

function CardVisual.isInteractive(self: CardVisual): boolean
	return self.Revealed and self.State ~= "exiting"
end

function CardVisual.beginExit(self: CardVisual, mode: string)
	if self.State == "exiting" then
		return
	end
	self.State = "exiting"
	self.ExitMode = mode
	self.ExitStart = os.clock()
end

function CardVisual.isFinished(self: CardVisual): boolean
	return self.State == "exiting" and os.clock() - self.ExitStart > Config.ExitDuration
end

--[[
	One frame of animation.
	tiltTarget: -1..1 on each axis, how far the cursor sits from the card.
	hovered: is the cursor actually over this card.
]]
function CardVisual.update(self: CardVisual, dt: number, tiltTarget: Vector2, hovered: boolean)
	local now = os.clock()
	local elapsed = now - self.StartTime

	local enter = clamp01((elapsed - self.EnterDelay) / Config.EnterDuration)
	local enterEase = easeOutBack(enter)
	local flip = clamp01((elapsed - self.FlipDelay) / Config.FlipDuration)
	local flipEase = easeInOutCubic(flip)

	if flip >= 1 and not self.Revealed then
		self.Revealed = true
		if self.Rarity.Sparkle then
			self.Sparks:Emit(28 + self.Rarity.Rank * 8)
		end
		if self.OnRevealed then
			(self.OnRevealed :: any)(self.Slot)
		end
	end

	-- Cursor tilt and hover only once the face is up.
	local interactive = self.Revealed and self.State ~= "exiting"
	local wantHover = if interactive and hovered then 1 else 0
	local smoothing = clamp01(dt * Config.TiltSmoothing)
	local tiltWeight = if interactive then 1 else 0
	self.Tilt = self.Tilt:Lerp(tiltTarget * tiltWeight, smoothing)
	self.Hover = lerp(self.Hover, wantHover, smoothing)

	local scale = lerp(Config.EnterScale, 1, math.min(enterEase, 1))
	scale *= lerp(1, Config.HoverScale, self.Hover)

	local rise = (1 - easeOutCubic(enter)) * -Config.EnterDrop + self.Hover * Config.HoverLift
	local alpha = 1 - enter
	local pushToCamera = self.Hover * Config.HoverPop

	if self.State == "exiting" then
		local exit = clamp01((now - self.ExitStart) / Config.ExitDuration)
		local exitEase = easeOutCubic(exit)
		alpha = math.max(alpha, exitEase)
		if self.ExitMode == "chosen" then
			pushToCamera += exitEase * 5
			scale *= lerp(1, 1.35, exitEase)
		else
			rise -= exitEase * 3
			scale *= lerp(1, 0.85, exitEase)
		end
	end

	local flipAngle = math.pi * (1 - flipEase)

	local cframe = CFrame.new(0, rise, 0)
		* self.BaseCFrame
		* CFrame.Angles(0, flipAngle, 0)
		* CFrame.Angles(self.Tilt.Y * Config.MaxTilt, self.Tilt.X * Config.MaxTilt, 0)
		* CFrame.new(0, 0, -pushToCamera)

	self.Part.CFrame = cframe
	self.Part.Size = Config.CardSize * scale
	self.Part.Transparency = alpha

	self.Front.GroupTransparency = alpha
	self.BackFace.GroupTransparency = alpha

	self.Light.Brightness = self.Rarity.GlowBrightness * flipEase * (1 - alpha)
	self.Glow.OutlineTransparency = 1 - self.Hover * 0.85
end

function CardVisual.destroy(self: CardVisual)
	self.Part:Destroy()
end

return CardVisual
