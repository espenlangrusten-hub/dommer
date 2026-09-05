--!strict
--[[
	Cards
	The catalogue. Add an entry and it is instantly rollable and shows up in the
	inventory - nothing else needs editing.

	Icon: a Roblox image id ("rbxassetid://123..."). Leave it "" and the card
	draws a large letter glyph instead, so the system works before art exists.
	Category: must match an id in Categories.luau. It drives the inventory tabs.
	Flavor: the italic line on the card face.
	Description: the plain line in the inventory tooltip and the showcase.
]]

local Categories = require(script.Parent.Categories)
local Rarities = require(script.Parent.Rarities)

export type Card = {
	Id: string,
	Name: string,
	Rarity: string,
	Category: string,
	Icon: string,
	Flavor: string,
	Description: string,
}

local list: { Card } = {
	-- Weapons -----------------------------------------------------------
	{ Id = "emberstrike", Name = "Emberstrike", Rarity = "Common", Category = "Weapons", Icon = "", Flavor = "Why was the rock so confident? It was rock solid.", Description = "A starter blade that never quite cools down." },
	{ Id = "oak_cudgel", Name = "Oak Cudgel", Rarity = "Common", Category = "Weapons", Icon = "", Flavor = "Simple, heavy, and entirely without opinions.", Description = "Heavy, blunt, and impossible to break." },
	{ Id = "field_dagger", Name = "Field Dagger", Rarity = "Common", Category = "Weapons", Icon = "", Flavor = "Sharp enough for bread. Mostly used for bread.", Description = "Quick strikes, short reach." },
	{ Id = "frostbite", Name = "Frostbite", Rarity = "Uncommon", Category = "Weapons", Icon = "", Flavor = "It does not cut. It convinces things to stop moving.", Description = "Slows whatever it touches." },
	{ Id = "gale_edge", Name = "Gale Edge", Rarity = "Uncommon", Category = "Weapons", Icon = "", Flavor = "Swing it twice and the second one arrives first.", Description = "Swings faster the longer you hold it." },
	{ Id = "stormpiercer", Name = "Stormpiercer", Rarity = "Rare", Category = "Weapons", Icon = "", Flavor = "Lightning takes the shortest path. This is the path.", Description = "Calls down a strike on a critical hit." },
	{ Id = "ironwake", Name = "Ironwake", Rarity = "Rare", Category = "Weapons", Icon = "", Flavor = "Leaves a trail even the ground remembers.", Description = "Leaves a damaging trail behind you." },
	{ Id = "rocksplitter", Name = "Rocksplitter", Rarity = "Epic", Category = "Weapons", Icon = "", Flavor = "What did the stone say to the pickaxe? \"I'm stoned.\"", Description = "Breaks armour and terrain alike." },
	{ Id = "voidlash", Name = "Voidlash", Rarity = "Epic", Category = "Weapons", Icon = "", Flavor = "Cracks the air. The air files a complaint.", Description = "Pulls distant enemies toward you." },
	{ Id = "kingsfall", Name = "Kingsfall", Rarity = "Legendary", Category = "Weapons", Icon = "", Flavor = "Crowns are only heavy until this removes them.", Description = "Deals bonus damage to bosses." },

	-- Relics ------------------------------------------------------------
	{ Id = "ashen_idol", Name = "Ashen Idol", Rarity = "Common", Category = "Relics", Icon = "", Flavor = "Still warm. It has been still warm for centuries.", Description = "A small passive boost to fire damage." },
	{ Id = "verdant_totem", Name = "Verdant Totem", Rarity = "Uncommon", Category = "Relics", Icon = "", Flavor = "Grows one leaf for every fight you survive.", Description = "Regenerates health out of combat." },
	{ Id = "tidecaller", Name = "Tidecaller", Rarity = "Rare", Category = "Relics", Icon = "", Flavor = "The sea answers. It is not always polite about it.", Description = "Grants a water shield when low." },
	{ Id = "sunspire", Name = "Sunspire", Rarity = "Epic", Category = "Relics", Icon = "", Flavor = "Warm to hold. Warmer to be hit by.", Description = "Burns everything within a short radius." },
	{ Id = "the_devourer", Name = "The Devourer", Rarity = "Legendary", Category = "Relics", Icon = "", Flavor = "It's not hungry. It's just always hungry.", Description = "Heals you for part of the damage you deal." },
	{ Id = "worldroot", Name = "Worldroot", Rarity = "Mythic", Category = "Relics", Icon = "", Flavor = "Older than the map it is standing on.", Description = "Boosts every other relic you carry." },

	-- Trinkets ----------------------------------------------------------
	{ Id = "tin_buckler", Name = "Tin Buckler", Rarity = "Common", Category = "Trinkets", Icon = "", Flavor = "Dents are just the shield remembering things.", Description = "Blocks one hit every few seconds." },
	{ Id = "glass_charm", Name = "Glass Charm", Rarity = "Common", Category = "Trinkets", Icon = "", Flavor = "Beautiful. Fragile. Mostly beautiful.", Description = "More damage dealt, more damage taken." },
	{ Id = "luck_coin", Name = "Luck Coin", Rarity = "Uncommon", Category = "Trinkets", Icon = "", Flavor = "Lands on its edge more often than it should.", Description = "Slightly better roll luck while held." },
	{ Id = "ember_ring", Name = "Ember Ring", Rarity = "Rare", Category = "Trinkets", Icon = "", Flavor = "Keeps one spark from every fire it has seen.", Description = "Your first hit each fight burns." },

	-- Tickets -----------------------------------------------------------
	{ Id = "summon_pass", Name = "Summon Pass", Rarity = "Uncommon", Category = "Tickets", Icon = "", Flavor = "One free look at whatever the machine has today.", Description = "Can be used for a free roll." },
	{ Id = "raid_ticket", Name = "Raid Ticket", Rarity = "Rare", Category = "Tickets", Icon = "", Flavor = "Admits one. Return trip not guaranteed.", Description = "Can be used in Raids." },
	{ Id = "golden_voucher", Name = "Golden Voucher", Rarity = "Epic", Category = "Tickets", Icon = "", Flavor = "Worth exactly as much as someone will give you.", Description = "Trades for high tier rewards." },
	{ Id = "eclipse_seal", Name = "Eclipse Seal", Rarity = "Legendary", Category = "Tickets", Icon = "", Flavor = "Opens the door that is only there sometimes.", Description = "Unlocks the eclipse event." },
}

local Cards = {}

Cards.List = list
Cards.ById = {} :: { [string]: Card }
Cards.ByRarity = {} :: { [string]: { Card } }
Cards.ByCategory = {} :: { [string]: { Card } }

for _, card in list do
	assert(Cards.ById[card.Id] == nil, `duplicate card id "{card.Id}"`)
	Rarities.get(card.Rarity) -- errors early on a typo'd rarity
	assert(Categories.exists(card.Category), `card "{card.Id}" has unknown category "{card.Category}"`)
	Cards.ById[card.Id] = card

	local byRarity = Cards.ByRarity[card.Rarity]
	if not byRarity then
		byRarity = {}
		Cards.ByRarity[card.Rarity] = byRarity
	end
	table.insert(byRarity, card)

	local byCategory = Cards.ByCategory[card.Category]
	if not byCategory then
		byCategory = {}
		Cards.ByCategory[card.Category] = byCategory
	end
	table.insert(byCategory, card)
end

function Cards.get(id: string): Card?
	return Cards.ById[id]
end

-- Every tier needs at least one card or the roll can dead-end.
for _, rarity in Rarities.List do
	assert(Cards.ByRarity[rarity.Id], `rarity "{rarity.Id}" has no cards`)
end

-- An empty tab would just look broken.
for _, category in Categories.List do
	assert(Cards.ByCategory[category.Id], `category "{category.Id}" has no cards`)
end

return Cards
