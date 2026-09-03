--!strict
--[[
	Cards
	The catalogue. Add an entry and it is instantly rollable - nothing else
	needs editing.

	Icon: a Roblox image id ("rbxassetid://123..."). Leave it "" and the card
	draws a large letter glyph instead, so the system works before art exists.
]]

local Rarities = require(script.Parent.Rarities)

export type Card = {
	Id: string,
	Name: string,
	Rarity: string,
	Icon: string,
	Flavor: string,
}

local list: { Card } = {
	-- Common ------------------------------------------------------------
	{ Id = "emberstrike", Name = "Emberstrike", Rarity = "Common", Icon = "", Flavor = "Why was the rock so confident? It was rock solid." },
	{ Id = "oak_cudgel", Name = "Oak Cudgel", Rarity = "Common", Icon = "", Flavor = "Simple, heavy, and entirely without opinions." },
	{ Id = "tin_buckler", Name = "Tin Buckler", Rarity = "Common", Icon = "", Flavor = "Dents are just the shield remembering things." },
	{ Id = "field_dagger", Name = "Field Dagger", Rarity = "Common", Icon = "", Flavor = "Sharp enough for bread. Mostly used for bread." },

	-- Uncommon ----------------------------------------------------------
	{ Id = "frostbite", Name = "Frostbite", Rarity = "Uncommon", Icon = "", Flavor = "It does not cut. It convinces things to stop moving." },
	{ Id = "gale_edge", Name = "Gale Edge", Rarity = "Uncommon", Icon = "", Flavor = "Swing it twice and the second one arrives first." },
	{ Id = "verdant_totem", Name = "Verdant Totem", Rarity = "Uncommon", Icon = "", Flavor = "Grows one leaf for every fight you survive." },

	-- Rare --------------------------------------------------------------
	{ Id = "tidecaller", Name = "Tidecaller", Rarity = "Rare", Icon = "", Flavor = "The sea answers. It is not always polite about it." },
	{ Id = "stormpiercer", Name = "Stormpiercer", Rarity = "Rare", Icon = "", Flavor = "Lightning takes the shortest path. This is the path." },
	{ Id = "ironwake", Name = "Ironwake", Rarity = "Rare", Icon = "", Flavor = "Leaves a trail even the ground remembers." },

	-- Epic --------------------------------------------------------------
	{ Id = "rocksplitter", Name = "Rocksplitter", Rarity = "Epic", Icon = "", Flavor = "What did the stone say to the pickaxe? \"I'm stoned.\"" },
	{ Id = "voidlash", Name = "Voidlash", Rarity = "Epic", Icon = "", Flavor = "Cracks the air. The air files a complaint." },
	{ Id = "sunspire", Name = "Sunspire", Rarity = "Epic", Icon = "", Flavor = "Warm to hold. Warmer to be hit by." },

	-- Legendary ---------------------------------------------------------
	{ Id = "the_devourer", Name = "The Devourer", Rarity = "Legendary", Icon = "", Flavor = "It's not hungry. It's just always hungry." },
	{ Id = "kingsfall", Name = "Kingsfall", Rarity = "Legendary", Icon = "", Flavor = "Crowns are only heavy until this removes them." },

	-- Mythic ------------------------------------------------------------
	{ Id = "worldroot", Name = "Worldroot", Rarity = "Mythic", Icon = "", Flavor = "Older than the map it is standing on." },
}

local Cards = {}

Cards.List = list
Cards.ById = {} :: { [string]: Card }
Cards.ByRarity = {} :: { [string]: { Card } }

for _, card in list do
	assert(Cards.ById[card.Id] == nil, `duplicate card id "{card.Id}"`)
	Rarities.get(card.Rarity) -- errors early on a typo'd rarity
	Cards.ById[card.Id] = card

	local bucket = Cards.ByRarity[card.Rarity]
	if not bucket then
		bucket = {}
		Cards.ByRarity[card.Rarity] = bucket
	end
	table.insert(bucket, card)
end

function Cards.get(id: string): Card?
	return Cards.ById[id]
end

-- Every rarity tier needs at least one card or the roll can dead-end.
for _, rarity in Rarities.List do
	assert(Cards.ByRarity[rarity.Id], `rarity "{rarity.Id}" has no cards`)
end

return Cards
