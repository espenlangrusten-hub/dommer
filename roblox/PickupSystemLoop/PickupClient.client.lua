-- PickupClient (Script, RunContext = Client)
-- Plays a looping animation the whole time you carry something,
-- and sends "drop" to the server when you press G again.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local ANIMATION_ID = "rbxassetid://124289987102699"
local DROP_KEY = Enum.KeyCode.G

local FADE_IN = 0.15 -- seconds to blend into the animation
local FADE_OUT = 0.15 -- seconds to blend out when dropping

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
		result.Looped = true -- keeps repeating until you drop the object
		track = result
		trackAnimator = animator
	end
	return track
end

local function startLoop()
	local current = getTrack()
	if not current then
		return
	end
	current:Play(FADE_IN)

	task.delay(3, function()
		if track == current and current.Length == 0 then
			warn("[Pickup] Animation did not load (Length = 0). Check ANIMATION_ID and that "
				.. "the animation is owned by the same owner as the game (your group).")
		end
	end)
end

local function stopLoop()
	if track then
		track:Stop(FADE_OUT)
	end
end

remote.OnClientEvent:Connect(function(action)
	if action == "hold" then
		carrying = true
		ProximityPromptService.Enabled = false -- hide other "Pick up" prompts
		startLoop()
	elseif action == "release" then
		carrying = false
		ProximityPromptService.Enabled = true
		stopLoop()
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

print("[Pickup] Client loaded (looping animation)")
