--!strict
--[[
	Profile
	The client's copy of what the server says the player owns. Every panel
	reads from here instead of tracking its own state, so the hotbar, the
	inventory and the showcase can never disagree.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CardSystem = ReplicatedStorage:WaitForChild("CardSystem")
local Config = require(CardSystem:WaitForChild("Config"))

export type Snapshot = {
	Counts: { [string]: number },
	Equipped: { string | boolean },
	Rolls: number,
}

local Profile = {}

local current: Snapshot = {
	Counts = {},
	Equipped = {},
	Rolls = 0,
}

local listeners: { (Snapshot) -> () } = {}

function Profile.get(): Snapshot
	return current
end

function Profile.set(snapshot: Snapshot)
	current = snapshot
	for _, listener in listeners do
		task.spawn(listener, snapshot)
	end
end

-- Returns a function that stops the subscription.
function Profile.onChanged(listener: (Snapshot) -> ()): () -> ()
	table.insert(listeners, listener)
	return function()
		local index = table.find(listeners, listener)
		if index then
			table.remove(listeners, index)
		end
	end
end

function Profile.count(cardId: string): number
	return current.Counts[cardId] or 0
end

function Profile.owns(cardId: string): boolean
	return Profile.count(cardId) > 0
end

-- The card on a hotbar slot, or nil when the slot is empty.
function Profile.equippedAt(slot: number): string?
	local value = current.Equipped[slot]
	return if typeof(value) == "string" then value else nil
end

function Profile.slotOf(cardId: string): number?
	for slot = 1, Config.Hotbar.Slots do
		if Profile.equippedAt(slot) == cardId then
			return slot
		end
	end
	return nil
end

-- Owned cards, sorted rarest first and then by name, for the inventory grid.
function Profile.ownedSorted(rank: (string) -> number): { { Id: string, Count: number } }
	local out = {}
	for cardId, count in current.Counts do
		if count > 0 then
			table.insert(out, { Id = cardId, Count = count })
		end
	end
	table.sort(out, function(a, b)
		local rankA, rankB = rank(a.Id), rank(b.Id)
		if rankA ~= rankB then
			return rankA > rankB
		end
		return a.Id < b.Id
	end)
	return out
end

return Profile
