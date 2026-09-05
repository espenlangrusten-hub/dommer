--!strict
--[[
	Hotbar
	Six slots along the bottom of the screen, laid out like the reference UI.

	Number keys 1-6 select a slot. Selection is cosmetic here - it is the hook
	you use when you give equipped cards an in-game effect.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CardSystem = ReplicatedStorage:WaitForChild("CardSystem")
local Cards = require(CardSystem:WaitForChild("Cards"))
local Config = require(CardSystem:WaitForChild("Config"))
local Rarities = require(CardSystem:WaitForChild("Rarities"))
local Theme = require(CardSystem:WaitForChild("Theme"))

local Profile = require(script.Parent:WaitForChild("Profile"))

local make = Theme.make
local L = Config.Layout

type SlotViews = {
	Button: TextButton,
	Surface: Frame,
	Stroke: UIStroke,
	Icon: GuiObject?,
	KeyFrame: Frame,
	NameLabel: TextLabel,
	CountLabel: TextLabel,
	Content: Frame,
}

local Hotbar = {}
Hotbar.__index = Hotbar

export type Hotbar = typeof(setmetatable(
	{} :: {
		Gui: ScreenGui,
		Scale: UIScale,
		Slots: { SlotViews },
		Selected: number,
		OnSlotActivated: ((slot: number, cardId: string?) -> ())?,
	},
	Hotbar
))

local function buildSlot(index: number, parent: Instance): SlotViews
	local size = L.HotbarSlot

	local button = make("TextButton", {
		Name = `Slot{index}`,
		LayoutOrder = index,
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Parent = parent,
	}) :: TextButton

	local surface = Theme.slotFrame({
		Name = "Surface",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, Theme.Colors.SlotEmpty) :: Frame
	surface.Parent = button

	local stroke = surface:FindFirstChildOfClass("UIStroke") :: UIStroke

	-- Everything that only shows on a filled slot.
	local content = make("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = surface,
	}) :: Frame

	local nameLabel = Theme.label({
		Name = "ItemName",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.98),
		Size = UDim2.fromScale(0.94, 0.19),
		Text = "",
		Parent = content,
	}, 3)

	local countLabel = Theme.label({
		Name = "Count",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.8),
		Size = UDim2.fromScale(0.9, 0.2),
		Text = "",
		TextColor3 = Theme.Colors.Count,
		Parent = content,
	}, 3)

	-- The key number badge, top left, like the level badge in the reference.
	local keyFrame = make("Frame", {
		Name = "KeyBadge",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0.05, 0.05),
		Size = UDim2.fromScale(0.28, 0.28),
		BackgroundColor3 = Color3.fromRGB(12, 13, 17),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Parent = surface,
	}, {
		Theme.corner(6),
		Theme.stroke(Theme.Colors.Outline, 2),
	})

	Theme.label({
		Name = "Key",
		Size = UDim2.fromScale(1, 1),
		Text = tostring(index),
		Parent = keyFrame,
	}, 2)

	return {
		Button = button,
		Surface = surface,
		Stroke = stroke,
		Icon = nil,
		KeyFrame = keyFrame,
		NameLabel = nameLabel,
		CountLabel = countLabel,
		Content = content,
	}
end

function Hotbar.new(): Hotbar
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local gui = make("ScreenGui", {
		Name = "CardHotbar",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 8,
	}) :: ScreenGui

	local rowWidth = Config.Hotbar.Slots * L.HotbarSlot + (Config.Hotbar.Slots - 1) * L.HotbarGap

	local root = make("Frame", {
		Name = "Root",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.fromOffset(rowWidth, L.HotbarBottom + L.HotbarSlot),
		Parent = gui,
	})

	local scale = make("UIScale", { Scale = 1, Parent = root }) :: UIScale

	-- Slot row.
	local row = make("Frame", {
		Name = "Slots",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -L.HotbarBottom),
		Size = UDim2.fromOffset(rowWidth, L.HotbarSlot),
		Parent = root,
	}, {
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, L.HotbarGap),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local slots: { SlotViews } = {}
	for index = 1, Config.Hotbar.Slots do
		slots[index] = buildSlot(index, row)
	end

	gui.Parent = playerGui

	local self = setmetatable({
		Gui = gui,
		Scale = scale,
		Slots = slots,
		Selected = 1,
		OnSlotActivated = nil,
	}, Hotbar)

	for index, slot in slots do
		slot.Button.MouseButton1Click:Connect(function()
			self:activate(index)
		end)
		slot.Button.MouseEnter:Connect(function()
			TweenService:Create(slot.Surface, TweenInfo.new(0.12), {
				Size = UDim2.fromScale(1.06, 1.06),
			}):Play()
		end)
		slot.Button.MouseLeave:Connect(function()
			TweenService:Create(slot.Surface, TweenInfo.new(0.12), {
				Size = UDim2.fromScale(1, 1),
			}):Play()
		end)
	end

	self:refresh()
	return (self :: any) :: Hotbar
end

function Hotbar.activate(self: Hotbar, index: number)
	self.Selected = index
	self:refresh()
	if self.OnSlotActivated then
		(self.OnSlotActivated :: any)(index, Profile.equippedAt(index))
	end
end

function Hotbar.setScale(self: Hotbar, scale: number)
	self.Scale.Scale = scale
end

-- Redraws every slot from the current profile.
function Hotbar.refresh(self: Hotbar)
	for index, views in self.Slots do
		local cardId = Profile.equippedAt(index)
		local card = if cardId then Cards.get(cardId) else nil

		if views.Icon then
			views.Icon:Destroy()
			views.Icon = nil
		end

		if card then
			local rarity = Rarities.get(card.Rarity)
			local top = select(1, Theme.rarityBackdrop(rarity.Color))
			views.Surface.BackgroundColor3 = top
			views.Stroke.Color = rarity.Color
			views.Stroke.Transparency = 0
			views.KeyFrame.Visible = true
			views.Content.Visible = true
			views.NameLabel.Text = card.Name
			views.CountLabel.Text = `x{Profile.count(card.Id)}`

			views.Icon = Theme.iconFor(card.Name, card.Icon, rarity.Color, {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.14),
				Size = UDim2.fromScale(0.62, 0.44),
				Parent = views.Surface,
			})
		else
			views.Surface.BackgroundColor3 = Theme.Colors.SlotEmpty
			views.Stroke.Color = Color3.fromRGB(90, 96, 112)
			views.Stroke.Transparency = 0.2
			views.Content.Visible = false
			views.KeyFrame.Visible = true
		end

		-- Selection reads as a brighter, thicker edge.
		local selected = index == self.Selected
		views.Stroke.Thickness = if selected then 5 else 3
		views.Surface.Position = if selected
			then UDim2.new(0.5, 0, 0.5, -4)
			else UDim2.fromScale(0.5, 0.5)
	end
end

return Hotbar
