--!strict
--[[
	CardSystem server
	Authoritative half of the system: it owns the Random object, the cooldown,
	the pity counter, the inventory and the hotbar. The client only asks
	for a hand, says which slot it wants, and asks to equip things.
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

local function sync(player: Player)
	local snapshot = Inventory.snapshot(player)
	if snapshot then
		Remotes.ProfileSync:FireClient(player, snapshot)
	end
end

local function reject(player: Player, reason: string, retryAfter: number?)
	Remotes.RollRejected:FireClient(player, reason, retryAfter or 0)
end

local function onRequestRoll(player: Player)
	if not Inventory.get(player) then
		reject(player, "Still loading your profile, try again.")
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
	local function refuse()
		Remotes.SelectionResult:FireClient(player, false, nil, nil)
	end

	if not roll then
		refuse()
		return
	end
	if typeof(rollId) ~= "number" or rollId ~= roll.Id then
		refuse()
		return
	end
	if typeof(slot) ~= "number" or slot ~= math.floor(slot) or slot < 1 or slot > #roll.CardIds then
		refuse()
		return
	end

	local cardId = roll.CardIds[slot]
	pending[player] = nil
	nextRollAt[player] = os.clock() + Config.RollCooldown

	if not Inventory.award(player, cardId) then
		warn(`[CardSystem] could not award "{cardId}" to {player.Name}`)
		refuse()
		return
	end

	Remotes.SelectionResult:FireClient(player, true, cardId, slot)
	sync(player)
end

local function onEquipCard(player: Player, slot: any, cardId: any)
	if typeof(slot) ~= "number" then
		return
	end
	if cardId ~= nil and typeof(cardId) ~= "string" then
		return
	end

	local ok, reason = Inventory.equip(player, slot, cardId)
	if not ok then
		Remotes.Notice:FireClient(player, reason or "Could not equip that", true)
		return
	end
	sync(player)
end

local function onPlayerAdded(player: Player)
	Inventory.load(player)
	sync(player)
end

local function onPlayerRemoving(player: Player)
	pending[player] = nil
	nextRollAt[player] = nil
	Inventory.release(player)
end

Remotes.RequestRoll.OnServerEvent:Connect(onRequestRoll)
Remotes.SelectCard.OnServerEvent:Connect(onSelectCard)
Remotes.EquipCard.OnServerEvent:Connect(onEquipCard)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Players who joined before this script finished loading.
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Inventory.bindShutdown()

print(`[CardSystem] ready - {#Cards.List} cards, {Config.CardsPerRoll} per roll`)
