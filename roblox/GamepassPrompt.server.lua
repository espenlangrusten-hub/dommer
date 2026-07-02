-- Place this script in ServerScriptService.
-- Prompts every player to purchase a gamepass as soon as they join the game.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

-- TODO: replace with the numeric ID of your gamepass (Create page -> Gamepasses)
local GAMEPASS_ID = 000000000

if GAMEPASS_ID == 0 then
	warn("[GamepassPrompt] GAMEPASS_ID is still 0 - set it to your real gamepass ID.")
end

local function promptGamepass(player)
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(GAMEPASS_ID, Enum.InfoType.GamePass)
	end)

	if not ok then
		warn(("[GamepassPrompt] GetProductInfo failed for id %d: %s"):format(GAMEPASS_ID, tostring(info)))
		return
	end

	print(("[GamepassPrompt] Prompting %s to buy '%s' (id %d)"):format(player.Name, info.Name, GAMEPASS_ID))
	MarketplaceService:PromptGamePassPurchase(player, GAMEPASS_ID)
end

Players.PlayerAdded:Connect(promptGamepass)

-- Also prompt players who are already in the game (useful when testing in Studio)
for _, player in ipairs(Players:GetPlayers()) do
	promptGamepass(player)
end
