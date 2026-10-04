-- PressFAnimation
-- Press F to play the pickup animation.
-- This is a Script with RunContext = Client, so it runs on each player's
-- computer from Workspace or ReplicatedStorage. Do NOT put it in
-- StarterPlayerScripts (it would run twice there).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ANIMATION_ID = "rbxassetid://95203507058611"
local KEY = Enum.KeyCode.F

local player = Players.LocalPlayer

local animation = Instance.new("Animation")
animation.AnimationId = ANIMATION_ID

local currentTrack = nil
local trackOwner = nil -- the Animator the track was loaded on

local function getAnimator()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

local function playAnimation()
	local animator = getAnimator()
	if not animator then
		warn("[PressF] No character/Humanoid yet")
		return
	end

	-- Load the track once per character, then reuse it
	if not currentTrack or trackOwner ~= animator then
		local ok, track = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if not ok or not track then
			warn("[PressF] LoadAnimation failed: " .. tostring(track))
			return
		end
		track.Priority = Enum.AnimationPriority.Action4
		currentTrack = track
		trackOwner = animator
	end

	currentTrack:Stop(0)
	currentTrack:Play()
	print("[PressF] Playing " .. ANIMATION_ID)

	local track = currentTrack
	task.delay(3, function()
		if track.Length == 0 then
			warn("[PressF] Animation did not load (Length = 0). Check the ID, "
				.. "ownership, and that the rig type (R6/R15) matches.")
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- gameProcessed is true while typing in chat or a TextBox
	if gameProcessed then
		return
	end
	if input.KeyCode == KEY then
		playAnimation()
	end
end)

print("[PressF] Loaded. Press F to play the animation.")
