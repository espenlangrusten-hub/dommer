-- Place this script in ServerScriptService.
-- Prompts every player to purchase a gamepass as soon as they join the game.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

-- TODO: replace with the numeric ID of your gamepass (Create page -> Gamepasses)
local GAMEPASS_ID = 000000000

local function promptGamepass(player)
	MarketplaceService:PromptGamePassPurchase(player, GAMEPASS_ID)
end

Players.PlayerAdded:Connect(promptGamepass)

-- Also prompt players who are already in the game (useful when testing in Studio)
for _, player in ipairs(Players:GetPlayers()) do
	promptGamepass(player)
end
