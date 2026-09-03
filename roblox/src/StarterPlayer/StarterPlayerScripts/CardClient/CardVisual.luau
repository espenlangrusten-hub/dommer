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

type Card = Cards.Card

local BACKDROP = Color3.fromRGB(16, 17, 22)
local PANEL = Color3.fromRGB(26, 28, 36)

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

-- Instance helper --------------------------------------------------------
local function make(className: string, props: { [string]: any }, children: { any }?): any
	local instance = Instance.new(className)
	local parent = props.Parent
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	-- Parent last: setting it first makes Roblox replicate every later property.
	if parent then
		instance.Parent = parent
	end
	return instance
end

-- Face building ----------------------------------------------------------
local function diagonalSheen(): Instance
	-- The soft X-fold shading the reference cards use.
	return make("Frame", {
		Name = "Sheen",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, {
		make("Frame", {
			Name = "A",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1.6, 0.5),
			Rotation = 34,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.94,
			BorderSizePixel = 0,
		}),
		make("Frame", {
			Name = "B",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1.6, 0.5),
			Rotation = -34,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.94,
			BorderSizePixel = 0,
		}),
	})
end

local function buildFront(card: Card, rarity: Rarities.Rarity): CanvasGroup
	local iconHolder: Instance
	if card.Icon ~= "" then
		iconHolder = make("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Image = card.Icon,
			ScaleType = Enum.ScaleType.Fit,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.07),
			Size = UDim2.fromScale(0.64, 0.3),
		})
	else
		-- No art yet: draw the card's initial so the layout still reads.
		iconHolder = make("TextLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.07),
			Size = UDim2.fromScale(0.64, 0.3),
			Font = Enum.Font.GothamBold,
			Text = string.upper(string.sub(card.Name, 1, 1)),
			TextColor3 = rarity.Color,
			TextScaled = true,
			TextTransparency = 0.25,
		})
	end

	return make("CanvasGroup", {
		Name = "Face",
		BackgroundColor3 = PANEL,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 1,
		ClipsDescendants = true,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0.04, 0) }),
		make("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(44, 46, 58)),
				ColorSequenceKeypoint.new(0.55, Color3.fromRGB(22, 23, 30)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 16)),
			}),
		}),
		make("UIStroke", {
			Name = "Border",
			Color = rarity.Color,
			Thickness = 5,
			Transparency = 0.05,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		diagonalSheen(),
		-- Rarity wash behind the icon.
		make("Frame", {
			Name = "Wash",
			BackgroundColor3 = rarity.Color,
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 0.42),
		}, {
			make("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.35),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		}),
		iconHolder,
		make("TextLabel", {
			Name = "CardName",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.4),
			Size = UDim2.fromScale(0.88, 0.09),
			Font = Enum.Font.GothamBold,
			Text = card.Name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,
		}, {
			make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2, Transparency = 0.45 }),
		}),
		make("TextLabel", {
			Name = "RarityLabel",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.505),
			Size = UDim2.fromScale(0.8, 0.07),
			Font = Enum.Font.GothamBold,
			Text = rarity.Name,
			TextColor3 = rarity.TextColor,
			TextScaled = true,
		}, {
			make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2, Transparency = 0.5 }),
		}),
		make("Frame", {
			Name = "Divider",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.6),
			Size = UDim2.fromScale(0.6, 0.006),
			BackgroundColor3 = rarity.Color,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
		}),
		make("TextLabel", {
			Name = "Flavor",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.63),
			Size = UDim2.fromScale(0.82, 0.16),
			Font = Enum.Font.SourceSansItalic,
			Text = card.Flavor,
			TextColor3 = Color3.fromRGB(214, 218, 228),
			TextScaled = true,
			TextWrapped = true,
		}),
		-- Footer call to action.
		make("Frame", {
			Name = "Footer",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.955),
			Size = UDim2.fromScale(0.72, 0.075),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
		}, {
			make("UICorner", { CornerRadius = UDim.new(0.3, 0) }),
			make("UIStroke", { Color = rarity.Color, Thickness = 2, Transparency = 0.55 }),
			make("TextLabel", {
				Name = "Prompt",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Font = Enum.Font.GothamMedium,
				Text = "Click to Select",
				TextColor3 = Color3.fromRGB(236, 239, 245),
				TextScaled = true,
			}, {
				make("UIPadding", {
					PaddingTop = UDim.new(0.2, 0),
					PaddingBottom = UDim.new(0.2, 0),
				}),
			}),
		}),
	})
end

local function buildBack(): CanvasGroup
	return make("CanvasGroup", {
		Name = "Back",
		BackgroundColor3 = Color3.fromRGB(20, 21, 28),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 1,
		ClipsDescendants = true,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0.04, 0) }),
		make("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(38, 40, 52), Color3.fromRGB(12, 12, 17)),
		}),
		make("UIStroke", {
			Color = Color3.fromRGB(92, 98, 116),
			Thickness = 4,
			Transparency = 0.3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		diagonalSheen(),
		make("Frame", {
			Name = "Emblem",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.34, 0.24),
			Rotation = 45,
			BackgroundColor3 = Color3.fromRGB(120, 128, 150),
			BackgroundTransparency = 0.75,
			BorderSizePixel = 0,
		}, {
			make("UIStroke", { Color = Color3.fromRGB(160, 168, 190), Thickness = 2, Transparency = 0.5 }),
		}),
	})
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
		Brightness = 1.4,
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
		Brightness = 1.2,
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
