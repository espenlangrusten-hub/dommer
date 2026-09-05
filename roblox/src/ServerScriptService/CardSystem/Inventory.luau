--!strict
--[[
	Inventory
	The player's saved profile: what they own, their XP, and what sits on the
	hotbar. Mirrors the headline numbers into leaderstats and hands the client
	a snapshot to render.

	Persistence is opt-in and best effort: every DataStore call is wrapped in
	pcall, and a failure degrades to an in-memory session profile rather than
	breaking the roll flow. DataStore access requires a published place with
	Studio API access enabled.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CardSystem = ReplicatedStorage:WaitForChild("CardSystem")
local Cards = require(CardSystem:WaitForChild("Cards"))
local Config = require(CardSystem:WaitForChild("Config"))
local Levels = require(CardSystem:WaitForChild("Levels"))
local Rarities = require(CardSystem:WaitForChild("Rarities"))

local SAVE_ENABLED = true
local STORE_NAME = "CardInventory_v2"
local LOAD_RETRIES = 3

export type Record = {
	Counts: { [string]: number },
	Equipped: { [string]: string }, -- slot index (as a string key) -> card id
	Xp: number,
	Pity: number,
	Rolls: number,
}

--[[
	What the client gets. Equipped is sent as an array with holes filled by
	false, because RemoteEvents drop nil holes in a table.
]]
export type Snapshot = {
	Counts: { [string]: number },
	Equipped: { string | boolean },
	Xp: number,
	Level: number,
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
		warn(`[CardSystem] DataStore unavailable, profiles are session only: {result}`)
	end
end

local function emptyRecord(): Record
	return { Counts = {}, Equipped = {}, Xp = 0, Pity = 0, Rolls = 0 }
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

	if typeof(raw.Equipped) == "table" then
		for slotKey, cardId in raw.Equipped do
			local slot = tonumber(slotKey)
			if
				slot
				and slot == math.floor(slot)
				and slot >= 1
				and slot <= Config.Hotbar.Slots
				and typeof(cardId) == "string"
				and Cards.get(cardId)
				and (record.Counts[cardId] or 0) > 0
			then
				record.Equipped[tostring(slot)] = cardId
			end
		end
	end

	for _, key in { "Xp", "Pity", "Rolls" } do
		if typeof(raw[key]) == "number" then
			(record :: any)[key] = math.max(0, math.floor(raw[key]))
		end
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
	local stats = player:FindFirstChild("leaderstats")
	if not record or not stats then
		return
	end

	local cardsStat = stats:FindFirstChild("Cards") :: IntValue?
	if cardsStat then
		cardsStat.Value = totalCards(record)
	end
	local levelStat = stats:FindFirstChild("Level") :: IntValue?
	if levelStat then
		levelStat.Value = Levels.progress(record.Xp).Level
	end
	local bestStat = stats:FindFirstChild("Best") :: StringValue?
	if bestStat then
		bestStat.Value = bestRarityName(record)
	end
end

function Inventory.snapshot(player: Player): Snapshot?
	local record = records[player]
	if not record then
		return nil
	end

	local counts = {}
	for cardId, count in record.Counts do
		counts[cardId] = count
	end

	-- false marks an empty slot; a nil would collapse the array in transit.
	local equipped: { string | boolean } = {}
	for slot = 1, Config.Hotbar.Slots do
		equipped[slot] = record.Equipped[tostring(slot)] or false
	end

	return {
		Counts = counts,
		Equipped = equipped,
		Xp = record.Xp,
		Level = Levels.progress(record.Xp).Level,
		Rolls = record.Rolls,
	}
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
					warn(`[CardSystem] profile load failed for {player.Name}: {result}`)
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

	local levelStat = Instance.new("IntValue")
	levelStat.Name = "Level"
	levelStat.Parent = stats

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
		warn(`[CardSystem] profile save failed for {player.Name}: {err}`)
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

function Inventory.owns(player: Player, cardId: string): boolean
	local record = records[player]
	return record ~= nil and (record.Counts[cardId] or 0) > 0
end

function Inventory.level(player: Player): number
	local record = records[player]
	return if record then Levels.progress(record.Xp).Level else 1
end

--[[
	Grants a card and the XP that comes with it.
	Returns the xp awarded, or nil when the card could not be granted.
]]
function Inventory.award(player: Player, cardId: string): number?
	local record = records[player]
	local card = Cards.get(cardId)
	if not record or not card then
		return nil
	end

	record.Counts[cardId] = (record.Counts[cardId] or 0) + 1
	local xp = Levels.xpForRarity(card.Rarity)
	record.Xp += xp
	refreshStats(player)
	return xp
end

--[[
	Puts a card on a hotbar slot, or clears it when cardId is nil.
	Returns ok plus a reason to show the player when it is refused.
]]
function Inventory.equip(player: Player, slot: number, cardId: string?): (boolean, string?)
	local record = records[player]
	if not record then
		return false, "Profile still loading"
	end
	if slot ~= math.floor(slot) or slot < 1 or slot > Config.Hotbar.Slots then
		return false, "No such slot"
	end

	local gate = Config.Hotbar.LevelGates[slot] or 1
	if Levels.progress(record.Xp).Level < gate then
		return false, `Slot unlocks at level {gate}`
	end

	if cardId == nil then
		record.Equipped[tostring(slot)] = nil
		return true, nil
	end

	if not Cards.get(cardId) then
		return false, "Unknown card"
	end
	if (record.Counts[cardId] or 0) <= 0 then
		return false, "You do not own that"
	end

	-- A card lives on one slot at a time.
	for otherSlot, otherCard in record.Equipped do
		if otherCard == cardId then
			record.Equipped[otherSlot] = nil
		end
	end
	record.Equipped[tostring(slot)] = cardId
	return true, nil
end

-- The lowest slot the player can use that has nothing on it.
function Inventory.firstFreeSlot(player: Player): number?
	local record = records[player]
	if not record then
		return nil
	end
	local level = Levels.progress(record.Xp).Level
	for slot = 1, Config.Hotbar.Slots do
		local gate = Config.Hotbar.LevelGates[slot] or 1
		if level >= gate and record.Equipped[tostring(slot)] == nil then
			return slot
		end
	end
	return nil
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
