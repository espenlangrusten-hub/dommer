--!strict
--[[
	Inventory
	Counts what each player has pulled and mirrors the total into leaderstats.

	Persistence is opt-in and best effort: every DataStore call is wrapped in
	pcall, and a failure degrades to an in-memory session inventory rather than
	breaking the roll flow. DataStore access requires a published place with
	Studio API access enabled.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CardSystem = ReplicatedStorage:WaitForChild("CardSystem")
local Cards = require(CardSystem:WaitForChild("Cards"))
local Rarities = require(CardSystem:WaitForChild("Rarities"))

local SAVE_ENABLED = true
local STORE_NAME = "CardInventory_v1"
local LOAD_RETRIES = 3

export type Record = {
	Counts: { [string]: number },
	Pity: number,
	Rolls: number,
}

local Inventory = {}

local store: DataStore? = nil
local storeWarned = false
local records: { [Player]: Record } = {}

if SAVE_ENABLED then
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn(`[CardSystem] DataStore unavailable, inventories are session only: {result}`)
	end
end

local function emptyRecord(): Record
	return { Counts = {}, Pity = 0, Rolls = 0 }
end

local function sanitise(raw: any): Record
	local record = emptyRecord()
	if typeof(raw) ~= "table" then
		return record
	end

	if typeof(raw.Counts) == "table" then
		for cardId, count in raw.Counts do
			-- Drop cards that were removed from the catalogue since the save.
			if typeof(cardId) == "string" and typeof(count) == "number" and Cards.get(cardId) then
				record.Counts[cardId] = math.max(0, math.floor(count))
			end
		end
	end
	if typeof(raw.Pity) == "number" then
		record.Pity = math.max(0, math.floor(raw.Pity))
	end
	if typeof(raw.Rolls) == "number" then
		record.Rolls = math.max(0, math.floor(raw.Rolls))
	end
	return record
end

local function keyFor(player: Player): string
	return `player_{player.UserId}`
end

local function totalCards(record: Record): number
	local total = 0
	for _, count in record.Counts do
		total += count
	end
	return total
end

local function bestRarityName(record: Record): string
	local bestRank, bestName = 0, "-"
	for cardId, count in record.Counts do
		local card = Cards.get(cardId)
		if card and count > 0 then
			local rarity = Rarities.get(card.Rarity)
			if rarity.Rank > bestRank then
				bestRank, bestName = rarity.Rank, rarity.Name
			end
		end
	end
	return bestName
end

local function refreshStats(player: Player)
	local record = records[player]
	if not record then
		return
	end
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	local cardsStat = stats:FindFirstChild("Cards") :: IntValue?
	if cardsStat then
		cardsStat.Value = totalCards(record)
	end
	local bestStat = stats:FindFirstChild("Best") :: StringValue?
	if bestStat then
		bestStat.Value = bestRarityName(record)
	end
end

function Inventory.load(player: Player)
	local record = emptyRecord()

	if store then
		for attempt = 1, LOAD_RETRIES do
			local ok, result = pcall(function()
				return (store :: DataStore):GetAsync(keyFor(player))
			end)
			if ok then
				record = sanitise(result)
				break
			end
			if attempt == LOAD_RETRIES then
				if not storeWarned then
					storeWarned = true
					warn(`[CardSystem] inventory load failed for {player.Name}: {result}`)
				end
			else
				task.wait(attempt)
			end
		end
	end

	if not player:IsDescendantOf(Players) then
		return -- left while the load was retrying
	end

	records[player] = record

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"

	local cardsStat = Instance.new("IntValue")
	cardsStat.Name = "Cards"
	cardsStat.Parent = stats

	local bestStat = Instance.new("StringValue")
	bestStat.Name = "Best"
	bestStat.Parent = stats

	stats.Parent = player
	refreshStats(player)
end

function Inventory.save(player: Player)
	local record = records[player]
	if not record or not store then
		return
	end
	local ok, err = pcall(function()
		(store :: DataStore):SetAsync(keyFor(player), record)
	end)
	if not ok and not storeWarned then
		storeWarned = true
		warn(`[CardSystem] inventory save failed for {player.Name}: {err}`)
	end
end

function Inventory.release(player: Player)
	Inventory.save(player)
	records[player] = nil
end

function Inventory.get(player: Player): Record?
	return records[player]
end

function Inventory.getPity(player: Player): number
	local record = records[player]
	return if record then record.Pity else 0
end

function Inventory.setPity(player: Player, value: number)
	local record = records[player]
	if record then
		record.Pity = value
		record.Rolls += 1
	end
end

function Inventory.award(player: Player, cardId: string): boolean
	local record = records[player]
	if not record or not Cards.get(cardId) then
		return false
	end
	record.Counts[cardId] = (record.Counts[cardId] or 0) + 1
	refreshStats(player)
	return true
end

-- Flush everything on shutdown so a server close does not eat a pull.
function Inventory.bindShutdown()
	game:BindToClose(function()
		if RunService:IsStudio() then
			return
		end
		for _, player in Players:GetPlayers() do
			Inventory.save(player)
		end
		task.wait(1)
	end)
end

return Inventory
