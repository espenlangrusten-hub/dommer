-- PlayAnimationCommand (LocalScript)
-- Put this in StarterPlayer > StarterPlayerScripts.
-- Type in chat:  /play pickup   -> plays the pickup animation
--                /play stop     -> stops the current animation

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer

-- Add more animations here: ["name"] = "rbxassetid://ID"
local ANIMATIONS = {
	pickup = "rbxassetid://95203507058611",
}

local currentTrack = nil

local function getAnimator()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 5)
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

local function stopCurrent()
	if currentTrack then
		currentTrack:Stop()
		currentTrack:Destroy()
		currentTrack = nil
	end
end

local function playAnimation(name)
	name = string.lower(name or "")

	if name == "stop" then
		stopCurrent()
		return
	end

	local animationId = ANIMATIONS[name]
	if not animationId then
		warn("[PlayAnimationCommand] Unknown animation: " .. tostring(name))
		return
	end

	local animator = getAnimator()
	if not animator then
		return
	end

	stopCurrent()

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not track then
		warn("[PlayAnimationCommand] Could not load animation " .. animationId)
		return
	end

	track.Priority = Enum.AnimationPriority.Action
	track:Play()
	currentTrack = track
end

-- Returns the argument after "/play", or nil if the message is not a /play command
local function parseCommand(message)
	local arg = string.match(message, "^%s*/play%s+(%S+)")
	return arg
end

player.CharacterAdded:Connect(function()
	currentTrack = nil
end)

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	-- New chat system: register /play as a chat command
	local command = Instance.new("TextChatCommand")
	command.Name = "PlayAnimationCommand"
	command.PrimaryAlias = "/play"
	command.Parent = TextChatService

	command.Triggered:Connect(function(textSource, message)
		if textSource.UserId ~= player.UserId then
			return
		end
		local arg = parseCommand(message)
		if arg then
			playAnimation(arg)
		end
	end)
else
	-- Legacy chat system
	player.Chatted:Connect(function(message)
		local arg = parseCommand(message)
		if arg then
			playAnimation(arg)
		end
	end)
end
