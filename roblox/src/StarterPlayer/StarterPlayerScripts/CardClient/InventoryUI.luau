--!strict
--[[
	InventoryUI
	The panel from the reference clip: angled green header banner, red close
	button, a coloured tab strip, a search field, and a scrolling grid of
	tinted item slots with a gold count in the corner.

	Hovering a slot raises a tooltip with the name, rarity, description and
	the buttons for viewing and equipping the item.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local CardSystem = ReplicatedStorage:WaitForChild("CardSystem")
local Cards = require(CardSystem:WaitForChild("Cards"))
local Categories = require(CardSystem:WaitForChild("Categories"))
local Config = require(CardSystem:WaitForChild("Config"))
local Rarities = require(CardSystem:WaitForChild("Rarities"))
local Theme = require(CardSystem:WaitForChild("Theme"))

local Profile = require(script.Parent:WaitForChild("Profile"))

local make = Theme.make
local INV = Config.Inventory

local function panelWidth(): number
	return INV.Columns * INV.SlotSize + (INV.Columns - 1) * INV.SlotGap + INV.PanelPadding * 2
end

local function gridHeight(): number
	return INV.VisibleRows * INV.SlotSize + (INV.VisibleRows - 1) * INV.SlotGap
end

type SlotViews = {
	Button: TextButton,
	Surface: Frame,
	Stroke: UIStroke,
	Count: TextLabel,
	Icon: GuiObject?,
	CardId: string?,
}

local InventoryUI = {}
InventoryUI.__index = InventoryUI

export type InventoryUI = typeof(setmetatable(
	{} :: {
		Gui: ScreenGui,
		Scale: UIScale,
		Root: Frame,
		Grid: ScrollingFrame,
		Search: TextBox,
		Tabs: { [string]: TextButton },
		Slots: { SlotViews },
		EmptyLabel: TextLabel,
		Tooltip: Frame,
		TipName: TextLabel,
		TipRarity: TextLabel,
		TipBody: TextLabel,
		TipOwned: TextLabel,
		ViewButton: TextButton,
		EquipButton: TextButton,
		Category: string,
		Query: string,
		HoveredCard: string?,
		Open: boolean,
		OnView: ((cardId: string) -> ())?,
		OnEquip: ((cardId: string) -> ())?,
		OnUnequip: ((cardId: string) -> ())?,
		OnClosed: (() -> ())?,
	},
	InventoryUI
))

-- Header ------------------------------------------------------------------
local function buildHeader(parent: Instance): Frame
	local header = make("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, -18),
		Size = UDim2.new(1, 0, 0, 44),
		Parent = parent,
	})

	-- The angled banner behind the title.
	local banner = make("Frame", {
		Name = "Banner",
		BackgroundColor3 = Theme.Colors.HeaderLight,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(-6, 0),
		Size = UDim2.new(0, 250, 1, 0),
		Rotation = -1.2,
		Parent = header,
	}, {
		Theme.corner(8),
		Theme.gradient(Theme.Colors.HeaderLight, Theme.Colors.HeaderDark),
		Theme.stroke(Theme.Colors.Outline, 2.5),
	})

	Theme.label({
		Name = "Title",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.06, 0.5),
		Size = UDim2.fromScale(0.9, 0.62),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Inventory",
		Parent = banner,
	}, 3.5)

	-- The little angled shards to the right of the banner.
	for index = 1, 3 do
		make("Frame", {
			Name = `Shard{index}`,
			BackgroundColor3 = Theme.Colors.HeaderLight,
			BorderSizePixel = 0,
			Rotation = -22,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 244 + index * 26, 0.5, 0),
			Size = UDim2.fromOffset(14, 30),
			Parent = header,
		}, {
			Theme.corner(3),
			Theme.gradient(Theme.Colors.HeaderLight, Theme.Colors.HeaderDark),
			Theme.stroke(Theme.Colors.Outline, 2),
		})
	end

	return header
end

local function buildCloseButton(parent: Instance): TextButton
	local button = make("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -2, 0, -6),
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = Theme.Colors.Close,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	}, {
		Theme.corner(999),
		Theme.stroke(Theme.Colors.CloseDark, 3),
		Theme.label({
			Name = "X",
			Size = UDim2.fromScale(0.72, 0.72),
			Position = UDim2.fromScale(0.14, 0.14),
			Text = "X",
		}, 3),
	}) :: TextButton
	return button
end

-- Slots -------------------------------------------------------------------
local function buildSlot(index: number, parent: Instance): SlotViews
	local button = make("TextButton", {
		Name = `Slot{index}`,
		LayoutOrder = index,
		Size = UDim2.fromOffset(INV.SlotSize, INV.SlotSize),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		Parent = parent,
	}) :: TextButton

	local surface = Theme.slotFrame({
		Name = "Surface",
		Size = UDim2.fromScale(1, 1),
	}, Theme.Colors.SlotEmpty) :: Frame
	surface.Parent = button

	local count = Theme.label({
		Name = "Count",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(0.96, 0.98),
		Size = UDim2.fromScale(0.62, 0.26),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = Theme.Colors.Count,
		Text = "",
		Parent = surface,
	}, 3)

	return {
		Button = button,
		Surface = surface,
		Stroke = surface:FindFirstChildOfClass("UIStroke") :: UIStroke,
		Count = count,
		Icon = nil,
		CardId = nil,
	}
end

-- Tooltip -----------------------------------------------------------------
local function buildTooltip(parent: Instance): (Frame, TextLabel, TextLabel, TextLabel, TextLabel, TextButton, TextButton)
	local tip = Theme.panel({
		Name = "Tooltip",
		Size = UDim2.fromOffset(230, 168),
		Visible = false,
		ZIndex = 50,
		Parent = parent,
	}, Color3.fromRGB(70, 74, 90))
	tip.BackgroundTransparency = 0.05

	local name = Theme.label({
		Name = "ItemName",
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.new(1, -24, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		TextSize = 18,
		Text = "",
		ZIndex = 51,
		Parent = tip,
	}, 2.5)

	local rarity = Theme.label({
		Name = "Rarity",
		Position = UDim2.fromOffset(12, 32),
		Size = UDim2.new(1, -24, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		TextSize = 14,
		Text = "",
		ZIndex = 51,
		Parent = tip,
	}, 2)

	local body = Theme.label({
		Name = "Body",
		Position = UDim2.fromOffset(12, 52),
		Size = UDim2.new(1, -24, 0, 40),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextScaled = false,
		TextSize = 14,
		TextColor3 = Theme.Colors.TextDim,
		Text = "",
		ZIndex = 51,
		Parent = tip,
	}, 2)

	local owned = Theme.label({
		Name = "Owned",
		Position = UDim2.fromOffset(12, 94),
		Size = UDim2.new(1, -24, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		TextSize = 14,
		TextColor3 = Theme.Colors.Count,
		Text = "",
		ZIndex = 51,
		Parent = tip,
	}, 2)

	local view = Theme.pill({
		Name = "View",
		Position = UDim2.fromOffset(12, 118),
		Size = UDim2.fromOffset(96, 34),
		ZIndex = 51,
		Parent = tip,
	}, Theme.Colors.Equip, "View")

	local equip = Theme.pill({
		Name = "Equip",
		Position = UDim2.new(1, -108, 0, 118),
		Size = UDim2.fromOffset(96, 34),
		ZIndex = 51,
		Parent = tip,
	}, Theme.Colors.PanelBorder, "Equip")

	return tip, name, rarity, body, owned, view, equip
end

-- Construction ------------------------------------------------------------
function InventoryUI.new(): InventoryUI
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local width = panelWidth()

	local gui = make("ScreenGui", {
		Name = "CardInventory",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 12,
		Enabled = false,
	}) :: ScreenGui

	local holder = make("Frame", {
		Name = "Holder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Size = UDim2.fromOffset(width, 1),
		Parent = gui,
	})

	local scale = make("UIScale", { Scale = 1, Parent = holder }) :: UIScale

	-- Search field above the panel, like the reference.
	local searchBox = Theme.panel({
		Name = "Search",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -46),
		Size = UDim2.fromOffset(width - 60, 34),
		BackgroundColor3 = Theme.Colors.Search,
		Parent = holder,
	}, Color3.fromRGB(58, 62, 76))

	Theme.searchIcon({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		Parent = searchBox,
	})

	local search = make("TextBox", {
		Name = "Input",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(36, 0),
		Size = UDim2.new(1, -46, 1, 0),
		Font = Theme.Font,
		Text = "",
		PlaceholderText = "Search..",
		PlaceholderColor3 = Theme.Colors.TextDim,
		TextColor3 = Theme.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 16,
		ClearTextOnFocus = false,
		Parent = searchBox,
	}) :: TextBox

	-- The panel body.
	local tabHeight = 34
	local headerRoom = 16
	local bodyHeight = headerRoom + tabHeight + gridHeight() + INV.PanelPadding * 3

	local root = Theme.panel({
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(width, bodyHeight),
		Parent = holder,
	}) :: Frame

	buildHeader(root)
	local close = buildCloseButton(root)

	-- Tab strip.
	local tabRow = make("Frame", {
		Name = "Tabs",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(INV.PanelPadding, INV.PanelPadding + 16),
		Size = UDim2.new(1, -INV.PanelPadding * 2, 0, tabHeight),
		Parent = root,
	}, {
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local tabCount = #Categories.List + 1
	local tabWidth = math.floor((panelWidth() - INV.PanelPadding * 2 - (tabCount - 1) * 6) / tabCount)

	local tabs: { [string]: TextButton } = {}
	tabs[Categories.AllId] = Theme.pill({
		Name = Categories.AllId,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(tabWidth, tabHeight),
		Parent = tabRow,
	}, Categories.AllColor, "All")

	for index, category in Categories.List do
		tabs[category.Id] = Theme.pill({
			Name = category.Id,
			LayoutOrder = index + 1,
			Size = UDim2.fromOffset(tabWidth, tabHeight),
			Parent = tabRow,
		}, category.Color, category.Name)
	end

	-- Item grid.
	local grid = make("ScrollingFrame", {
		Name = "Grid",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(INV.PanelPadding, INV.PanelPadding * 2 + tabHeight + 16),
		Size = UDim2.new(1, -INV.PanelPadding * 2, 0, gridHeight()),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.Colors.PanelBorder,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = root,
	}, {
		make("UIGridLayout", {
			CellSize = UDim2.fromOffset(INV.SlotSize, INV.SlotSize),
			CellPadding = UDim2.fromOffset(INV.SlotGap, INV.SlotGap),
			FillDirectionMaxCells = INV.Columns,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}) :: ScrollingFrame

	-- One button per catalogue entry, shown or hidden as the filter changes.
	local slots: { SlotViews } = {}
	for index = 1, #Cards.List do
		slots[index] = buildSlot(index, grid)
	end

	local empty = Theme.label({
		Name = "Empty",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(360, 30),
		TextScaled = false,
		TextSize = 18,
		TextColor3 = Theme.Colors.TextDim,
		Text = "Nothing here yet - go roll some cards",
		Visible = false,
		Parent = root,
	}, 2)

	local tip, tipName, tipRarity, tipBody, tipOwned, viewButton, equipButton = buildTooltip(gui)

	gui.Parent = playerGui

	local self = setmetatable({
		Gui = gui,
		Scale = scale,
		Root = root,
		Grid = grid,
		Search = search,
		Tabs = tabs,
		Slots = slots,
		EmptyLabel = empty,
		Tooltip = tip,
		TipName = tipName,
		TipRarity = tipRarity,
		TipBody = tipBody,
		TipOwned = tipOwned,
		ViewButton = viewButton,
		EquipButton = equipButton,
		Category = Categories.AllId,
		Query = "",
		HoveredCard = nil,
		Open = false,
		OnView = nil,
		OnEquip = nil,
		OnUnequip = nil,
		OnClosed = nil,
	}, InventoryUI)

	close.MouseButton1Click:Connect(function()
		self:close()
	end)

	for id, button in tabs do
		button.MouseButton1Click:Connect(function()
			self.Category = id
			self:refresh()
		end)
	end

	search:GetPropertyChangedSignal("Text"):Connect(function()
		self.Query = string.lower(search.Text)
		self:refresh()
	end)

	for _, views in slots do
		views.Button.MouseEnter:Connect(function()
			if views.CardId then
				self:showTooltip(views.CardId)
			end
		end)
		views.Button.MouseLeave:Connect(function()
			self:hideTooltip()
		end)
		views.Button.MouseButton1Click:Connect(function()
			if views.CardId and self.OnView then
				(self.OnView :: any)(views.CardId)
			end
		end)
	end

	viewButton.MouseButton1Click:Connect(function()
		local cardId = self.HoveredCard
		if cardId and self.OnView then
			(self.OnView :: any)(cardId)
		end
	end)

	equipButton.MouseButton1Click:Connect(function()
		local cardId = self.HoveredCard
		if not cardId then
			return
		end
		if Profile.slotOf(cardId) then
			if self.OnUnequip then
				(self.OnUnequip :: any)(cardId)
			end
		elseif self.OnEquip then
			(self.OnEquip :: any)(cardId)
		end
	end)

	RunService.Heartbeat:Connect(function()
		if self.Tooltip.Visible then
			self:moveTooltip()
		end
	end)

	return (self :: any) :: InventoryUI
end

-- Behaviour ---------------------------------------------------------------
function InventoryUI.setScale(self: InventoryUI, scale: number)
	self.Scale.Scale = scale
end

function InventoryUI.showTooltip(self: InventoryUI, cardId: string)
	local card = Cards.get(cardId)
	if not card then
		return
	end
	local rarity = Rarities.get(card.Rarity)

	self.HoveredCard = cardId
	self.TipName.Text = card.Name
	self.TipRarity.Text = rarity.Name
	self.TipRarity.TextColor3 = rarity.TextColor
	self.TipBody.Text = card.Description
	self.TipOwned.Text = `Owned: {Profile.count(cardId)}x`

	local equipLabel = self.EquipButton:FindFirstChild("Label") :: TextLabel
	equipLabel.Text = if Profile.slotOf(cardId) then "Unequip" else "Equip"

	local stroke = self.Tooltip:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = rarity.Color
	end

	self.Tooltip.Visible = true
	self:moveTooltip()
end

function InventoryUI.moveTooltip(self: InventoryUI)
	if not self.Tooltip.Visible then
		return
	end
	local mouse = UserInputService:GetMouseLocation()
	local camera = workspace.CurrentCamera
	local viewport = camera.ViewportSize
	local size = self.Tooltip.AbsoluteSize

	-- Flip the tooltip when it would run off the screen edge.
	local x = mouse.X + 16
	if x + size.X > viewport.X - 8 then
		x = mouse.X - size.X - 16
	end
	local y = mouse.Y + 12
	if y + size.Y > viewport.Y - 8 then
		y = viewport.Y - size.Y - 8
	end

	self.Tooltip.Position = UDim2.fromOffset(x, y)
end

function InventoryUI.hideTooltip(self: InventoryUI)
	self.Tooltip.Visible = false
	self.HoveredCard = nil
end

-- Repaints every slot from the profile, the active tab and the search text.
function InventoryUI.refresh(self: InventoryUI)
	for id, button in self.Tabs do
		local active = id == self.Category
		button.BackgroundTransparency = if active then 0 else 0.45
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = if active then 3.5 else 2
		end
	end

	local owned = Profile.ownedSorted(function(cardId: string): number
		local card = Cards.get(cardId)
		return if card then Rarities.get(card.Rarity).Rank else 0
	end)

	local shown = 0
	for _, entry in owned do
		local card = Cards.get(entry.Id)
		if not card then
			continue
		end
		if self.Category ~= Categories.AllId and card.Category ~= self.Category then
			continue
		end
		if self.Query ~= "" and not string.find(string.lower(card.Name), self.Query, 1, true) then
			continue
		end

		shown += 1
		local views = self.Slots[shown]
		if not views then
			break -- more owned entries than catalogue slots should not happen
		end

		local rarity = Rarities.get(card.Rarity)
		local top = select(1, Theme.rarityBackdrop(rarity.Color))

		views.CardId = card.Id
		views.Button.Visible = true
		views.Button.LayoutOrder = shown
		views.Surface.BackgroundColor3 = top
		views.Stroke.Color = rarity.Color
		views.Count.Text = `x{entry.Count}`

		if views.Icon then
			views.Icon:Destroy()
		end
		views.Icon = Theme.iconFor(card.Name, card.Icon, rarity.Color, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.44),
			Size = UDim2.fromScale(0.6, 0.5),
			Parent = views.Surface,
		})
	end

	for index = shown + 1, #self.Slots do
		local views = self.Slots[index]
		views.Button.Visible = false
		views.CardId = nil
	end

	self.EmptyLabel.Visible = shown == 0

	if self.HoveredCard and not Profile.owns(self.HoveredCard) then
		self:hideTooltip()
	elseif self.HoveredCard then
		self:showTooltip(self.HoveredCard)
	end
end

function InventoryUI.open(self: InventoryUI)
	self.Open = true
	self.Gui.Enabled = true
	self:refresh()

	local scale = make("UIScale", { Scale = 0.9, Parent = self.Root }) :: UIScale
	local tween = TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	})
	tween.Completed:Connect(function()
		scale:Destroy()
	end)
	tween:Play()
end

function InventoryUI.close(self: InventoryUI)
	self.Open = false
	self.Gui.Enabled = false
	self:hideTooltip()
	if self.OnClosed then
		(self.OnClosed :: any)()
	end
end

function InventoryUI.toggle(self: InventoryUI)
	if self.Open then
		self:close()
	else
		self:open()
	end
end

return InventoryUI
