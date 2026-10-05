--[[
	Freecam chat command
	Type /freecam (or /fc) in chat to toggle freecam on and off.

	Controls while in freecam:
	  W / A / S / D      move
	  E / Q              up / down
	  Hold right mouse   look around
	  Hold Shift         move faster
	  Hold Ctrl          move slower

	Put this LocalScript in StarterPlayer > StarterPlayerScripts.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local NORMAL_SPEED = 32 -- studs per second
local FAST_SPEED = 96
local SLOW_SPEED = 8
local LOOK_SENSITIVITY = 0.004 -- radians per pixel of mouse movement
local RENDER_STEP_NAME = "FreecamChatCommand"

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local active = false
local position = Vector3.zero
local pitch, yaw = 0, 0
local savedCameraType
local savedCameraSubject

local function getControls()
	local ok, controls = pcall(function()
		local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5))
		return playerModule:GetControls()
	end)
	if ok then
		return controls
	end
	return nil
end

local function isTyping()
	return UserInputService:GetFocusedTextBox() ~= nil
end

local function isDown(keyCode)
	return UserInputService:IsKeyDown(keyCode)
end

local function step(dt)
	camera = workspace.CurrentCamera

	-- Look around while the right mouse button is held
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		local delta = UserInputService:GetMouseDelta()
		yaw -= delta.X * LOOK_SENSITIVITY
		pitch = math.clamp(pitch - delta.Y * LOOK_SENSITIVITY, -math.rad(89), math.rad(89))
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	local rotation = CFrame.fromOrientation(pitch, yaw, 0)

	if not isTyping() then
		local localMove = Vector3.zero
		if isDown(Enum.KeyCode.W) then localMove += Vector3.new(0, 0, -1) end
		if isDown(Enum.KeyCode.S) then localMove += Vector3.new(0, 0, 1) end
		if isDown(Enum.KeyCode.A) then localMove += Vector3.new(-1, 0, 0) end
		if isDown(Enum.KeyCode.D) then localMove += Vector3.new(1, 0, 0) end

		local worldMove = rotation:VectorToWorldSpace(localMove)
		if isDown(Enum.KeyCode.E) then worldMove += Vector3.yAxis end
		if isDown(Enum.KeyCode.Q) then worldMove -= Vector3.yAxis end

		local speed = NORMAL_SPEED
		if isDown(Enum.KeyCode.LeftShift) or isDown(Enum.KeyCode.RightShift) then
			speed = FAST_SPEED
		elseif isDown(Enum.KeyCode.LeftControl) or isDown(Enum.KeyCode.RightControl) then
			speed = SLOW_SPEED
		end

		if worldMove.Magnitude > 0 then
			position += worldMove.Unit * speed * dt
		end
	end

	camera.CFrame = CFrame.new(position) * rotation
end

local function enterFreecam()
	if active then
		return
	end
	active = true
	camera = workspace.CurrentCamera

	savedCameraType = camera.CameraType
	savedCameraSubject = camera.CameraSubject

	position = camera.CFrame.Position
	local x, y = camera.CFrame:ToOrientation()
	pitch, yaw = x, y

	local controls = getControls()
	if controls then
		controls:Disable()
	end

	camera.CameraType = Enum.CameraType.Scriptable
	-- Run after the default camera so it can't override us
	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, step)
end

local function exitFreecam()
	if not active then
		return
	end
	active = false

	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	camera = workspace.CurrentCamera
	camera.CameraType = savedCameraType or Enum.CameraType.Custom
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	camera.CameraSubject = humanoid or savedCameraSubject

	local controls = getControls()
	if controls then
		controls:Enable()
	end
end

local function toggleFreecam()
	if active then
		exitFreecam()
	else
		enterFreecam()
	end
end

-- Leave freecam cleanly if the character respawns
player.CharacterAdded:Connect(function()
	exitFreecam()
end)

-- Chat command hookup
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	local command = Instance.new("TextChatCommand")
	command.Name = "FreecamCommand"
	command.PrimaryAlias = "/freecam"
	command.SecondaryAlias = "/fc"
	command.Triggered:Connect(function(textSource)
		if textSource.UserId == player.UserId then
			toggleFreecam()
		end
	end)
	command.Parent = TextChatService
else
	-- Legacy chat fallback
	player.Chatted:Connect(function(message)
		local text = string.lower(message)
		if text == "/freecam" or text == "/fc" then
			toggleFreecam()
		end
	end)
end
