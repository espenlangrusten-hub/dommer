-- PickupClient (Script, RunContext = Client)
-- Plays the holding animation while you carry something,
-- and sends "drop" to the server when you press G again.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

-- Use the same animation ID that works in your F script
local ANIMATION_ID = "rbxassetid://95203507058611"
local DROP_KEY = Enum.KeyCode.G

local RAISE_TIME = 0.1 -- seconds to move into the pose
local LOWER_TIME = 0.15 -- seconds to move back down
local HOLD_AT = nil -- nil = hold the last frame, or a time in seconds

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("PickupRemote")

local animation = Instance.new("Animation")
animation.AnimationId = ANIMATION_ID

local track = nil
local trackAnimator = nil
local carrying = false

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
		return nil
	end
	if not track or trackAnimator ~= animator then
		local ok, result = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if not ok or not result then
			warn("[Pickup] LoadAnimation failed: " .. tostring(result))
			return nil
		end
		result.Priority = Enum.AnimationPriority.Action4
		result.Looped = true
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
	current:Play(RAISE_TIME, 1, 0)

	local waited = 0
	while current.Length == 0 and waited < 3 do
		waited += task.wait()
	end
	if current.Length == 0 then
		warn("[Pickup] Animation did not load (Length = 0). Check ANIMATION_ID.")
		return
	end
	if not carrying or track ~= current then
		return
	end
	local holdTime = HOLD_AT or current.Length
	current.TimePosition = math.clamp(holdTime, 0, current.Length * 0.999)
	current:AdjustSpeed(0)
end

local function lowerArms()
	if track then
		track:Stop(LOWER_TIME)
	end
end

remote.OnClientEvent:Connect(function(action)
	if action == "hold" then
		carrying = true
		ProximityPromptService.Enabled = false -- hide other "Pick up" prompts
		holdPose()
	elseif action == "release" then
		carrying = false
		ProximityPromptService.Enabled = true
		lowerArms()
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or input.KeyCode ~= DROP_KEY then
		return
	end
	if carrying then
		remote:FireServer("drop")
	end
end)

player.CharacterAdded:Connect(function()
	carrying = false
	ProximityPromptService.Enabled = true
	track = nil
	trackAnimator = nil
end)

print("[Pickup] Client loaded")
