--!strict
--[[
	RollUI
	Bottom-centre ROLL button, a status line above it, an odds strip, and the
	"you got X" banner shown after a pick.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CardSystem = ReplicatedStorage:WaitForChild("CardSystem")
local Config = require(CardSystem:WaitForChild("Config"))
local Rarities = require(CardSystem:WaitForChild("Rarities"))

local IDLE_COLOR = Color3.fromRGB(96, 132, 255)
local BUSY_COLOR = Color3.fromRGB(58, 62, 78)
local BUTTON_WIDTH = 236
local BUTTON_HEIGHT = 62

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
	if parent then
		instance.Parent = parent
	end
	return instance
end

local RollUI = {}
RollUI.__index = RollUI

export type RollUI = typeof(setmetatable(
	{} :: {
		Gui: ScreenGui,
		Button: TextButton,
		ButtonLabel: TextLabel,
		Status: TextLabel,
		Banner: Frame,
		BannerLabel: TextLabel,
		Stroke: UIStroke,
		Enabled: boolean,
		OnRoll: (() -> ())?,
	},
	RollUI
))

local function buildOdds(): Frame
	local row = make("Frame", {
		Name = "Odds",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(0, 540, 0, 18),
	}, {
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	for index, rarity in Rarities.List do
		local percent = Rarities.chancePercent(rarity.Id)
		local text = if percent >= 1
			then `{rarity.Name} {string.format("%.0f", percent)}%`
			else `{rarity.Name} {string.format("%.2f", percent)}%`

		make("TextLabel", {
			Name = rarity.Id,
			LayoutOrder = index,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = text,
			TextSize = 12,
			TextColor3 = rarity.TextColor,
			TextTransparency = 0.25,
			Parent = row,
		}, {
			make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2, Transparency = 0.55 }),
		})
	end

	return row
end

function RollUI.new(): RollUI
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local gui = make("ScreenGui", {
		Name = "CardRollUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 10,
	}) :: ScreenGui

	local dock = make("Frame", {
		Name = "Dock",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.new(0, 560, 0, 132),
		Parent = gui,
	})

	local status = make("TextLabel", {
		Name = "Status",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.new(1, 0, 0, 20),
		Font = Enum.Font.GothamMedium,
		Text = "",
		TextSize = 15,
		TextColor3 = Color3.fromRGB(226, 230, 240),
		Parent = dock,
	}, {
		make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2, Transparency = 0.4 }),
	}) :: TextLabel

	local buttonLabel = make("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBold,
		Text = "ROLL",
		TextSize = 26,
		TextColor3 = Color3.fromRGB(255, 255, 255),
	}) :: TextLabel

	local stroke = make("UIStroke", {
		Color = Color3.fromRGB(150, 180, 255),
		Thickness = 2,
		Transparency = 0.2,
	}) :: UIStroke

	local button = make("TextButton", {
		Name = "RollButton",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 28),
		Size = UDim2.new(0, BUTTON_WIDTH, 0, BUTTON_HEIGHT),
		BackgroundColor3 = IDLE_COLOR,
		AutoButtonColor = false,
		Text = "",
		Parent = dock,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 14) }),
		make("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 195, 215)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.7),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
		stroke,
		buttonLabel,
	}) :: TextButton

	buildOdds().Parent = dock

	local bannerLabel = make("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBold,
		Text = "",
		TextSize = 20,
		TextColor3 = Color3.fromRGB(255, 255, 255),
	}, {
		make("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Thickness = 2, Transparency = 0.4 }),
	}) :: TextLabel

	local banner = make("Frame", {
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 74),
		Size = UDim2.new(0, 380, 0, 52),
		BackgroundColor3 = Color3.fromRGB(14, 15, 20),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	}, {
		make("UICorner", { CornerRadius = UDim.new(0, 12) }),
		make("UIStroke", { Name = "Edge", Color = Color3.fromRGB(255, 255, 255), Thickness = 2, Transparency = 1 }),
		bannerLabel,
	}) :: Frame

	gui.Parent = playerGui

	local self = setmetatable({
		Gui = gui,
		Button = button,
		ButtonLabel = buttonLabel,
		Status = status,
		Banner = banner,
		BannerLabel = bannerLabel,
		Stroke = stroke,
		Enabled = true,
		OnRoll = nil,
	}, RollUI)

	button.MouseButton1Click:Connect(function()
		if self.Enabled and self.OnRoll then
			self.OnRoll()
		end
	end)

	local function scaleTo(scale: number)
		TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, math.floor(BUTTON_WIDTH * scale), 0, math.floor(BUTTON_HEIGHT * scale)),
		}):Play()
	end

	button.MouseEnter:Connect(function()
		if self.Enabled then
			scaleTo(1.04)
		end
	end)
	button.MouseLeave:Connect(function()
		scaleTo(1)
	end)
	button.MouseButton1Down:Connect(function()
		if self.Enabled then
			scaleTo(0.96)
		end
	end)
	button.MouseButton1Up:Connect(function()
		scaleTo(1)
	end)

	self:setStatus(`Roll for {Config.CardsPerRoll} cards`)

	return (self :: any) :: RollUI
end

function RollUI.setEnabled(self: RollUI, enabled: boolean, label: string?)
	local changed = self.Enabled ~= enabled
	self.Enabled = enabled
	self.ButtonLabel.Text = label or "ROLL"
	self.ButtonLabel.TextTransparency = if enabled then 0 else 0.35

	-- The cooldown calls this ten times a second; only recolour on a real
	-- state change so it is not spawning a tween every tick.
	if changed then
		TweenService:Create(self.Button, TweenInfo.new(0.18), {
			BackgroundColor3 = if enabled then IDLE_COLOR else BUSY_COLOR,
		}):Play()
		self.Stroke.Transparency = if enabled then 0.2 else 0.75
	end
end

function RollUI.setStatus(self: RollUI, text: string)
	self.Status.Text = text
end

--[[
	Counts the cooldown down on the button face, then re-enables it.
	`isCurrent` returns false when a newer state took over, so a stale
	countdown never re-enables the button behind the caller's back.
]]
function RollUI.runCooldown(self: RollUI, seconds: number, isCurrent: () -> boolean)
	task.spawn(function()
		local remaining = seconds
		while remaining > 0 do
			if not isCurrent() then
				return
			end
			self:setEnabled(false, string.format("%.1fs", remaining))
			remaining -= task.wait(0.1)
		end
		if isCurrent() then
			self:setEnabled(true)
		end
	end)
end

function RollUI.showBanner(self: RollUI, cardName: string, rarity: Rarities.Rarity)
	local banner = self.Banner
	local edge = banner:FindFirstChild("Edge") :: UIStroke
	self.BannerLabel.Text = `{cardName}  -  {rarity.Name}`
	self.BannerLabel.TextColor3 = rarity.TextColor
	edge.Color = rarity.Color
	banner.Visible = true
	banner.BackgroundTransparency = 1
	self.BannerLabel.TextTransparency = 1
	edge.Transparency = 1

	local inInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(banner, inInfo, { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(self.BannerLabel, inInfo, { TextTransparency = 0 }):Play()
	TweenService:Create(edge, inInfo, { Transparency = 0.1 }):Play()

	task.delay(2.4, function()
		local outInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(banner, outInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(self.BannerLabel, outInfo, { TextTransparency = 1 }):Play()
		local fade = TweenService:Create(edge, outInfo, { Transparency = 1 })
		fade.Completed:Connect(function()
			banner.Visible = false
		end)
		fade:Play()
	end)
end

return RollUI
