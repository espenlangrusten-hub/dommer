-- PressFAnimation
-- Press F once: the arm moves into the animation's final pose and stays there.
-- Press F again: the arm goes back down.
-- This is a Script with RunContext = Client, so it runs on each player's
-- computer from Workspace or ReplicatedStorage. Do NOT put it in
-- StarterPlayerScripts (it would run twice there).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ANIMATION_ID = "rbxassetid://95203507058611" -- must be owned by the game's owner (your group)
local KEY = Enum.KeyCode.F

local RAISE_TIME = 0.1 -- seconds to move into the pose
local LOWER_TIME = 0.15 -- seconds to move back down

-- Which frame to hold: nil = the last frame, or a time in seconds (e.g. 0.1)
local HOLD_AT = nil

local player = Players.LocalPlayer

local animation = Instance.new("Animation")
animation.AnimationId = ANIMATION_ID

local track = nil
local trackAnimator = nil -- the Animator the track was loaded on
local holding = false

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
		result.Looped = true -- never ends by itself; we freeze it instead
		track = result
		trackAnimator = animator
	end
	return track
end

local function holdPose()
	local current = getTrack()
	if not current then
		return
	end
	holding = true

	-- Start at speed 0; the fade-in blends the arm smoothly into the pose
	current:Play(RAISE_TIME, 1, 0)

	-- Wait until the animation has loaded so we know its length
	local waited = 0
	while current.Length == 0 and waited < 3 do
		waited += task.wait()
	end
	if current.Length == 0 then
		warn("[PressF] Animation did not load (Length = 0). Check the ID and that the "
			.. "animation is owned by the same owner as the game (your group).")
		holding = false
		return
	end
	if not holding or track ~= current then
		return -- F was pressed again (or respawned) while loading
	end

	-- Jump to the final frame and keep it there
	local holdTime = HOLD_AT or current.Length
	current.TimePosition = math.clamp(holdTime, 0, current.Length * 0.999)
	current:AdjustSpeed(0)
	print(string.format("[PressF] Holding pose at %.2fs (animation length %.2fs)",
		current.TimePosition, current.Length))
end

local function release()
	holding = false
	if track then
		track:Stop(LOWER_TIME)
	end
	print("[PressF] Released")
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- gameProcessed is true while typing in chat or a TextBox
	if gameProcessed or input.KeyCode ~= KEY then
		return
	end
	if holding then
		release()
	else
		holdPose()
	end
end)

-- Reset when the character respawns
player.CharacterAdded:Connect(function()
	holding = false
	track = nil
	trackAnimator = nil
end)

print("[PressF] Loaded. Press F to raise, F again to lower.")
