--!strict
--[[
	CardSystem server
	Authoritative half of the roll: it owns the Random object, the cooldown,
	the pity counter and the inventory. The client only asks for a hand and
	says which slot it wants.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardSystem = ReplicatedStorage:WaitForChild("CardSystem")
local Cards = require(CardSystem:WaitForChild("Cards"))
local Config = require(CardSystem:WaitForChild("Config"))
local RollLogic = require(CardSystem:WaitForChild("RollLogic"))
local Remotes = require(CardSystem:WaitForChild("Remotes")).get()

local Inventory = require(script:WaitForChild("Inventory"))

type PendingRoll = {
	Id: number,
	CardIds: { string },
}

local rng = Random.new()
local pending: { [Player]: PendingRoll } = {}
local nextRollAt: { [Player]: number } = {}
local nextRollId = 0

local function reject(player: Player, reason: string, retryAfter: number?)
	Remotes.RollRejected:FireClient(player, reason, retryAfter or 0)
end

local function onRequestRoll(player: Player)
	if not Inventory.get(player) then
		reject(player, "Still loading your inventory, try again.")
		return
	end

	if pending[player] then
		reject(player, "Pick a card first.")
		return
	end

	local now = os.clock()
	local readyAt = nextRollAt[player] or 0
	if now < readyAt then
		reject(player, "Rolling too fast.", readyAt - now)
		return
	end

	-- Reserve the cooldown immediately so a burst of requests cannot stack.
	nextRollAt[player] = now + Config.RollCooldown

	local hand, newPity = RollLogic.rollHand(rng, Inventory.getPity(player))
	Inventory.setPity(player, newPity)

	nextRollId += 1
	local cardIds = {}
	for _, card in hand do
		table.insert(cardIds, card.Id)
	end

	pending[player] = { Id = nextRollId, CardIds = cardIds }
	Remotes.RollResult:FireClient(player, nextRollId, cardIds)
end

local function onSelectCard(player: Player, rollId: any, slot: any)
	local roll = pending[player]
	if not roll then
		Remotes.SelectionResult:FireClient(player, false, nil, nil)
		return
	end

	if typeof(rollId) ~= "number" or rollId ~= roll.Id then
		Remotes.SelectionResult:FireClient(player, false, nil, nil)
		return
	end

	if typeof(slot) ~= "number" or slot ~= math.floor(slot) or slot < 1 or slot > #roll.CardIds then
		Remotes.SelectionResult:FireClient(player, false, nil, nil)
		return
	end

	local cardId = roll.CardIds[slot]
	pending[player] = nil
	nextRollAt[player] = os.clock() + Config.RollCooldown

	local awarded = Inventory.award(player, cardId)
	if not awarded then
		warn(`[CardSystem] could not award "{cardId}" to {player.Name}`)
		Remotes.SelectionResult:FireClient(player, false, nil, nil)
		return
	end

	Remotes.SelectionResult:FireClient(player, true, cardId, slot)
end

local function onPlayerAdded(player: Player)
	Inventory.load(player)
end

local function onPlayerRemoving(player: Player)
	pending[player] = nil
	nextRollAt[player] = nil
	Inventory.release(player)
end

Remotes.RequestRoll.OnServerEvent:Connect(onRequestRoll)
Remotes.SelectCard.OnServerEvent:Connect(onSelectCard)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Players who joined before this script finished loading.
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Inventory.bindShutdown()

print(`[CardSystem] ready - {#Cards.List} cards, {Config.CardsPerRoll} per roll`)
