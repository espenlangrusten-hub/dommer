--[[
	LobbyQueueClient  (LocalScript -> StarterPlayer > StarterPlayerScripts)

	Builds the "Create Party" menu (party size buttons, Create, X)
	and the red "exit" button shown while you're in a queue.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("LobbyQueueRemotes")
local OpenCreateParty = remotes:WaitForChild("OpenCreateParty")
local CreateParty = remotes:WaitForChild("CreateParty")
local CancelCreate = remotes:WaitForChild("CancelCreate")
local LeaveQueue = remotes:WaitForChild("LeaveQueue")
local QueueStatus = remotes:WaitForChild("QueueStatus")

local YELLOW = Color3.fromRGB(255, 220, 40)
local GRAY = Color3.fromRGB(190, 190, 190)
local GREEN = Color3.fromRGB(110, 200, 50)
local RED = Color3.fromRGB(225, 25, 25)
local FONT = Enum.Font.FredokaOne

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function textButton(props)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.Font = FONT
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	for key, value in props do
		button[key] = value
	end
	corner(button, 10)
	return button
end

---------------------------------------------------------------------
-- GUI
---------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "LobbyQueueGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Create Party menu
local menu = Instance.new("Frame")
menu.Name = "CreatePartyMenu"
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Position = UDim2.fromScale(0.5, 0.5)
menu.Size = UDim2.fromOffset(500, 260)
menu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
menu.BackgroundTransparency = 0.15
menu.Visible = false
menu.Parent = gui
corner(menu, 8)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(500, 260)
sizeConstraint.Parent = menu
local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 500 / 260
aspect.Parent = menu

local function menuLabel(text, y, height, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, y)
	label.Size = UDim2.fromScale(1, height)
	label.Font = FONT
	label.TextScaled = true
	label.TextColor3 = color
	label.Text = text
	label.Parent = menu
end
menuLabel("Create Party", 0.02, 0.12, Color3.fromRGB(170, 170, 170))
menuLabel("Party Size", 0.16, 0.14, Color3.new(1, 1, 1))

local sizeRow = Instance.new("Frame")
sizeRow.BackgroundTransparency = 1
sizeRow.Position = UDim2.fromScale(0.05, 0.36)
sizeRow.Size = UDim2.fromScale(0.9, 0.2)
sizeRow.Parent = menu
local rowLayout = Instance.new("UIListLayout")
rowLayout.FillDirection = Enum.FillDirection.Horizontal
rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
rowLayout.Padding = UDim.new(0.02, 0)
rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
rowLayout.Parent = sizeRow

local createButton = textButton({
	Name = "Create",
	Text = "Create",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.64),
	Size = UDim2.fromScale(0.38, 0.16),
	BackgroundColor3 = GREEN,
	Parent = menu,
})

local closeButton = textButton({
	Name = "Close",
	Text = "X",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.fromScale(0.09, 0.17),
	BackgroundColor3 = RED,
	Parent = menu,
})

-- Exit button shown while queued
local exitButton = textButton({
	Name = "Exit",
	Text = "exit",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -40),
	Size = UDim2.fromOffset(160, 50),
	BackgroundColor3 = RED,
	Visible = false,
	Parent = gui,
})

---------------------------------------------------------------------
-- Menu logic
---------------------------------------------------------------------
local selectedSize = 1
local sizeButtons = {}

local function refreshSizeButtons()
	for size, button in sizeButtons do
		button.BackgroundColor3 = size == selectedSize and YELLOW or GRAY
	end
end

local function buildSizeButtons(maxSize)
	for _, button in sizeButtons do
		button:Destroy()
	end
	table.clear(sizeButtons)

	local width = (1 - 0.02 * (maxSize - 1)) / math.max(maxSize, 5)
	for size = 1, maxSize do
		local button = textButton({
			Name = "Size" .. size,
			Text = tostring(size),
			LayoutOrder = size,
			Size = UDim2.fromScale(width, 1),
			BackgroundColor3 = GRAY,
			Parent = sizeRow,
		})
		local aspectButton = Instance.new("UIAspectRatioConstraint")
		aspectButton.AspectRatio = 1
		aspectButton.Parent = button
		button.Activated:Connect(function()
			selectedSize = size
			refreshSizeButtons()
		end)
		sizeButtons[size] = button
	end
	selectedSize = maxSize
	refreshSizeButtons()
end

OpenCreateParty.OnClientEvent:Connect(function(maxSize)
	if maxSize <= 0 then
		menu.Visible = false
		return
	end
	buildSizeButtons(maxSize)
	exitButton.Visible = false
	menu.Visible = true
end)

createButton.Activated:Connect(function()
	menu.Visible = false
	CreateParty:FireServer(selectedSize)
end)

closeButton.Activated:Connect(function()
	menu.Visible = false
	CancelCreate:FireServer()
end)

exitButton.Activated:Connect(function()
	exitButton.Visible = false
	LeaveQueue:FireServer()
end)

QueueStatus.OnClientEvent:Connect(function(inQueue)
	exitButton.Visible = inQueue
	if not inQueue then
		menu.Visible = false
	end
end)
