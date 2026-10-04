-- PressFAnimation
-- Press F once: plays the animation and holds the pose (arm stays up).
-- Press F again: lets go (arm goes back down).
-- This is a Script with RunContext = Client, so it runs on each player's
-- computer from Workspace or ReplicatedStorage. Do NOT put it in
-- StarterPlayerScripts (it would run twice there).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ANIMATION_ID = "rbxassetid://95203507058611" -- replace with the group-owned ID
local KEY = Enum.KeyCode.F

-- Where to freeze the pose:
--   nil   = freeze on the last frame of the animation
--   a number (seconds) = freeze at that time, e.g. 0.5
--   Use a number if your animation lowers the arm again at the end.
local HOLD_AT = nil

local FADE_TIME = 0.15

local player = Players.LocalPlayer

local animation = Instance.new("Animation")
animation.AnimationId = ANIMATION_ID

local track = nil
local trackAnimator = nil -- the Animator the track was loaded on
local holding = false
local holdConnection = nil

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

local function getTrack()
	local animator = getAnimator()
	if not animator then
		warn("[PressF] No character/Humanoid yet")
		return nil
	end
	-- Load the track once per character, then reuse it
	if not track or trackAnimator ~= animator then
		local ok, result = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if not ok or not result then
			warn("[PressF] LoadAnimation failed: " .. tostring(result))
			return nil
		end
		result.Priority = Enum.AnimationPriority.Action4
		result.Looped = false
		track = result
		trackAnimator = animator
	end
	return track
end

local function clearHoldConnection()
	if holdConnection then
		holdConnection:Disconnect()
		holdConnection = nil
	end
end

local function release()
	clearHoldConnection()
	holding = false
	if track then
		track:Stop(FADE_TIME)
		track:AdjustSpeed(1)
	end
	print("[PressF] Released")
end

local function playAndHold()
	local current = getTrack()
	if not current then
		return
	end

	clearHoldConnection()
	holding = true
	current:Play(FADE_TIME)
	current:AdjustSpeed(1)
	print("[PressF] Playing and holding " .. ANIMATION_ID)

	-- Each frame, check whether we reached the hold point; if so, freeze there
	holdConnection = RunService.Heartbeat:Connect(function()
		if current.Length == 0 then
			return -- still loading
		end
		local holdTime = HOLD_AT or (current.Length - 0.05)
		holdTime = math.clamp(holdTime, 0, current.Length - 0.05)
		if current.TimePosition >= holdTime then
			current:AdjustSpeed(0)
			current.TimePosition = holdTime
			clearHoldConnection()
		end
	end)

	task.delay(3, function()
		if track == current and current.Length == 0 then
			warn("[PressF] Animation did not load (Length = 0). Check the ID, "
				.. "ownership (game and animation must have the same owner), and the rig type.")
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- gameProcessed is true while typing in chat or a TextBox
	if gameProcessed or input.KeyCode ~= KEY then
		return
	end
	if holding then
		release()
	else
		playAndHold()
	end
end)

-- Reset when the character respawns
player.CharacterAdded:Connect(function()
	clearHoldConnection()
	holding = false
	track = nil
	trackAnimator = nil
end)

print("[PressF] Loaded. Press F to raise, F again to lower.")
