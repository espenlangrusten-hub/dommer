--[[
	CustomWalkAnimation  (Script -> ServerScriptService)

	Replaces the default walk/run animation on every player's character
	with your own animation.

	1. Publish your animation from the Animation Editor (Looping ON, Priority: Movement).
	2. Copy its Asset ID and paste the number below.
]]

local Players = game:GetService("Players")

local WALK_ANIMATION_ID = "rbxassetid://0000000000" -- <- put your animation id here

-- R15 characters blend "walk" and "run" depending on speed (default speed 16 mostly
-- plays "run"), and R6 characters use "run" too, so both are replaced.
local ANIMATIONS_TO_REPLACE = {
	{ folder = "walk", animation = "WalkAnim" },
	{ folder = "run", animation = "RunAnim" },
}

local function applyWalkAnimation(character)
	local animate = character:WaitForChild("Animate", 10)
	if not animate then
		warn("[CustomWalk] No Animate script in", character.Name)
		return
	end

	for _, entry in ANIMATIONS_TO_REPLACE do
		local folder = animate:WaitForChild(entry.folder, 5)
		local animation = folder and folder:FindFirstChild(entry.animation)
		if animation then
			animation.AnimationId = WALK_ANIMATION_ID
		end
	end
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(applyWalkAnimation)
	if player.Character then
		task.spawn(applyWalkAnimation, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end
