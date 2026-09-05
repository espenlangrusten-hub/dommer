--!strict
--[[
	RollUI
	The ROLL button and its odds strip, plus the inventory button on the left
	edge and the one-line notice toast.

	The button sits just above the hotbar rather than on the bottom edge, so
	the two never overlap.

	Each anchored group carries its own UIScale. A UIScale scales its object
	about that object's AnchorPoint, so one on a full-screen frame would drag
	everything bottom-anchored up toward the top-left as the factor drops.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CardSystem = ReplicatedStorage:WaitForChild("CardSystem")
local Config = require(CardSystem:WaitForChild("Config"))
local Rarities = require(CardSystem:WaitForChild("Rarities"))
local Theme = require(CardSystem:WaitForChild("Theme"))

local make = Theme.make
local L = Config.Layout

local IDLE_COLOR = Color3.fromRGB(96, 132, 255)
local BUSY_COLOR = Color3.fromRGB(58, 62, 78)
local BUTTON_WIDTH = 236
local BUTTON_HEIGHT = 62
local ODDS_GAP = 8
local ODDS_HEIGHT = 18

local RollUI = {}
RollUI.__index = RollUI

export type RollUI = typeof(setmetatable(
	{} :: {
		Gui: ScreenGui,
		Scales: { UIScale },
		Button: TextButton,
		ButtonLabel: TextLabel,
		Status: TextLabel,
		InventoryButton: TextButton,
		Banner: Frame,
		BannerLabel: TextLabel,
		Notice: TextLabel,
		Stroke: UIStroke,
		Enabled: boolean,
		OnRoll: (() -> ())?,
		OnInventory: (() -> ())?,
	},
	RollUI
))

local function buildOdds(parent: Instance): Frame
	local row = make("Frame", {
		Name = "Odds",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, BUTTON_HEIGHT + ODDS_GAP),
		Size = UDim2.new(0, 560, 0, ODDS_HEIGHT),
		Parent = parent,
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

		Theme.label({
			Name = rarity.Id,
			LayoutOrder = index,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			TextScaled = false,
			TextSize = 13,
			Text = text,
			TextColor3 = rarity.TextColor,
			Parent = row,
		}, 2)
	end

	return row
end

-- The square icon tile on the left edge, like the reference side menu.
local function buildSideButton(parent: Instance): TextButton
	local size = L.SideButton

	local button = make("TextButton", {
		Name = "InventoryButton",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.42, 0),
		Size = UDim2.fromOffset(size, size + 16),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	}) :: TextButton

	local tile = Theme.slotFrame({
		Name = "Tile",
		Size = UDim2.fromOffset(size, size),
	}, Color3.fromRGB(120, 90, 255)) :: Frame
	tile.Parent = button

	-- A small bag drawn from two rounded frames.
	make("Frame", {
		Name = "BagBody",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.82),
		Size = UDim2.fromScale(0.6, 0.44),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Parent = tile,
	}, {
		Theme.corner(6),
		Theme.stroke(Theme.Colors.Outline, 2),
	})

	make("Frame", {
		Name = "BagHandle",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.44),
		Size = UDim2.fromScale(0.32, 0.3),
		BackgroundTransparency = 1,
		Parent = tile,
	}, {
		Theme.corner(999),
		Theme.stroke(Color3.new(1, 1, 1), 4),
	})

	Theme.label({
		Name = "Caption",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(size + 20, 16),
		TextScaled = false,
		TextSize = 14,
		Text = "Items",
		Parent = button,
	}, 2.5)

	-- The keybind hint above the tile.
	Theme.label({
		Name = "Key",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 2, 0, 2),
		Size = UDim2.fromOffset(16, 16),
		TextScaled = false,
		TextSize = 14,
		Text = Config.Keys.Inventory.Name,
		Parent = button,
	}, 2)

	return button
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

	-- Roll button sits just above the hotbar, not on the bottom edge. The dock
	-- is sized to its contents so its bottom edge is the odds strip.
	local dock = make("Frame", {
		Name = "Dock",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -L.RollBottom),
		Size = UDim2.fromOffset(600, BUTTON_HEIGHT + ODDS_GAP + ODDS_HEIGHT),
		Parent = gui,
	})

	local status = Theme.label({
		Name = "Status",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -4),
		Size = UDim2.fromOffset(560, 20),
		TextScaled = false,
		TextSize = 16,
		Text = "",
		Parent = dock,
	}, 2.5)

	local buttonLabel = Theme.label({
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		TextScaled = false,
		TextSize = 28,
		Text = "ROLL",
	}, 3.5)

	local stroke = Theme.stroke(Theme.Colors.Outline, 3)

	local button = make("TextButton", {
		Name = "RollButton",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(BUTTON_WIDTH, BUTTON_HEIGHT),
		BackgroundColor3 = IDLE_COLOR,
		AutoButtonColor = false,
		Text = "",
		Parent = dock,
	}, {
		Theme.corner(14),
		Theme.gradient(Color3.new(1, 1, 1), Color3.fromRGB(178, 184, 206)),
		stroke,
		buttonLabel,
	}) :: TextButton

	buildOdds(dock)
	local sideButton = buildSideButton(gui)

	local bannerLabel = Theme.label({
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		TextScaled = false,
		TextSize = 22,
		Text = "",
	}, 3)

	local banner = Theme.panel({
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 74),
		Size = UDim2.fromOffset(400, 54),
		Visible = false,
		Parent = gui,
	}, Color3.new(1, 1, 1), { bannerLabel })

	local notice = Theme.label({
		Name = "Notice",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 140),
		Size = UDim2.fromOffset(520, 24),
		TextScaled = false,
		TextSize = 18,
		Text = "",
		Visible = false,
		Parent = gui,
	}, 3)

	-- One scale per anchored group, so each pivots on its own anchor.
	local scales: { UIScale } = {}
	for _, host in { dock, sideButton, banner, notice } do
		table.insert(scales, make("UIScale", { Scale = 1, Parent = host }) :: UIScale)
	end

	gui.Parent = playerGui

	local self = setmetatable({
		Gui = gui,
		Scales = scales,
		Button = button,
		ButtonLabel = buttonLabel,
		Status = status,
		InventoryButton = sideButton,
		Banner = banner,
		BannerLabel = bannerLabel,
		Notice = notice,
		Stroke = stroke,
		Enabled = true,
		OnRoll = nil,
		OnInventory = nil,
	}, RollUI)

	button.MouseButton1Click:Connect(function()
		if self.Enabled and self.OnRoll then
			(self.OnRoll :: any)()
		end
	end)

	sideButton.MouseButton1Click:Connect(function()
		if self.OnInventory then
			(self.OnInventory :: any)()
		end
	end)

	local function scaleTo(factor: number)
		TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
			Size = UDim2.fromOffset(math.floor(BUTTON_WIDTH * factor), math.floor(BUTTON_HEIGHT * factor)),
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

function RollUI.setScale(self: RollUI, factor: number)
	for _, scale in self.Scales do
		scale.Scale = factor
	end
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
		self.Stroke.Transparency = if enabled then 0 else 0.45
	end
end

function RollUI.setStatus(self: RollUI, text: string)
	self.Status.Text = text
end

--[[
	Counts the cooldown down on the button face, re-enables it, and then runs
	`onFinished`.

	`isCurrent` returns false when a newer state took over, so a stale
	countdown never re-enables the button behind the caller's back. The
	caller must not run its own timer alongside this one: two timers racing
	on the same guard means whichever lands first invalidates the other, and
	the button stays dead. That is why the state change is a callback here
	rather than a separate `task.delay`.
]]
function RollUI.runCooldown(
	self: RollUI,
	seconds: number,
	isCurrent: () -> boolean,
	onFinished: (() -> ())?
)
	task.spawn(function()
		local remaining = seconds
		while remaining > 0 do
			if not isCurrent() then
				return
			end
			self:setEnabled(false, string.format("%.1fs", remaining))
			remaining -= task.wait(0.1)
		end
		if not isCurrent() then
			return
		end
		self:setEnabled(true)
		if onFinished then
			onFinished()
		end
	end)
end

function RollUI.showBanner(self: RollUI, cardName: string, rarity: Rarities.Rarity)
	local banner = self.Banner
	local edge = banner:FindFirstChildOfClass("UIStroke")
	self.BannerLabel.Text = `{cardName}  -  {rarity.Name}`
	self.BannerLabel.TextColor3 = rarity.TextColor
	if edge then
		edge.Color = rarity.Color
	end

	banner.Visible = true
	banner.BackgroundTransparency = 1
	self.BannerLabel.TextTransparency = 1

	local inInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(banner, inInfo, { BackgroundTransparency = 0.05 }):Play()
	TweenService:Create(self.BannerLabel, inInfo, { TextTransparency = 0 }):Play()

	task.delay(2.4, function()
		local outInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(self.BannerLabel, outInfo, { TextTransparency = 1 }):Play()
		local fade = TweenService:Create(banner, outInfo, { BackgroundTransparency = 1 })
		fade.Completed:Connect(function()
			banner.Visible = false
		end)
		fade:Play()
	end)
end

-- One-line toast for server messages like a locked hotbar slot.
function RollUI.showNotice(self: RollUI, text: string, isError: boolean?)
	self.Notice.Text = text
	self.Notice.TextColor3 = if isError then Theme.Colors.Danger else Theme.Colors.Text
	self.Notice.Visible = true
	self.Notice.TextTransparency = 0

	task.delay(2.2, function()
		if self.Notice.Text ~= text then
			return -- a newer notice took over
		end
		local fade = TweenService:Create(self.Notice, TweenInfo.new(0.3), { TextTransparency = 1 })
		fade.Completed:Connect(function()
			if self.Notice.Text == text then
				self.Notice.Visible = false
			end
		end)
		fade:Play()
	end)
end

return RollUI
