--!strict
--[[
	Rarities
	Ordered from most common to rarest. `Weight` is a relative number, not a
	percent - the roll math normalises it, so you can add a tier without
	rebalancing the others.
]]

export type Rarity = {
	Id: string,
	Name: string,
	Weight: number,
	Color: Color3, -- border / accent
	TextColor: Color3, -- rarity label
	GlowColor: Color3, -- PointLight + hover highlight
	GlowBrightness: number,
	RevealDelay: number, -- extra suspense before this card flips
	Sparkle: boolean, -- particles on reveal
	Rank: number, -- filled in below, 1 = most common
}

local list: { Rarity } = {
	{
		Id = "Common",
		Name = "COMMON",
		Weight = 1000,
		Color = Color3.fromRGB(168, 172, 180),
		TextColor = Color3.fromRGB(226, 229, 235),
		GlowColor = Color3.fromRGB(180, 186, 198),
		GlowBrightness = 0.6,
		RevealDelay = 0,
		Sparkle = false,
		Rank = 0,
	},
	{
		Id = "Uncommon",
		Name = "UNCOMMON",
		Weight = 520,
		Color = Color3.fromRGB(80, 214, 120),
		TextColor = Color3.fromRGB(140, 245, 170),
		GlowColor = Color3.fromRGB(70, 220, 120),
		GlowBrightness = 0.9,
		RevealDelay = 0.05,
		Sparkle = false,
		Rank = 0,
	},
	{
		Id = "Rare",
		Name = "RARE",
		Weight = 220,
		Color = Color3.fromRGB(70, 150, 255),
		TextColor = Color3.fromRGB(135, 190, 255),
		GlowColor = Color3.fromRGB(70, 150, 255),
		GlowBrightness = 1.2,
		RevealDelay = 0.12,
		Sparkle = false,
		Rank = 0,
	},
	{
		Id = "Epic",
		Name = "EPIC",
		Weight = 90,
		Color = Color3.fromRGB(168, 85, 247),
		TextColor = Color3.fromRGB(206, 152, 255),
		GlowColor = Color3.fromRGB(168, 85, 247),
		GlowBrightness = 1.7,
		RevealDelay = 0.22,
		Sparkle = true,
		Rank = 0,
	},
	{
		Id = "Legendary",
		Name = "LEGENDARY",
		Weight = 22,
		Color = Color3.fromRGB(240, 190, 40),
		TextColor = Color3.fromRGB(255, 214, 92),
		GlowColor = Color3.fromRGB(255, 190, 40),
		GlowBrightness = 2.4,
		RevealDelay = 0.4,
		Sparkle = true,
		Rank = 0,
	},
	{
		Id = "Mythic",
		Name = "MYTHIC",
		Weight = 4,
		Color = Color3.fromRGB(255, 70, 110),
		TextColor = Color3.fromRGB(255, 130, 165),
		GlowColor = Color3.fromRGB(255, 60, 110),
		GlowBrightness = 3,
		RevealDelay = 0.6,
		Sparkle = true,
		Rank = 0,
	},
}

local Rarities = {}

Rarities.List = list
Rarities.ById = {} :: { [string]: Rarity }

local totalWeight = 0
for index, rarity in list do
	rarity.Rank = index
	totalWeight += rarity.Weight
	Rarities.ById[rarity.Id] = rarity
end

Rarities.TotalWeight = totalWeight

function Rarities.get(id: string): Rarity
	local rarity = Rarities.ById[id]
	assert(rarity, `unknown rarity "{id}"`)
	return rarity
end

-- Chance of a single card landing on this tier, as a percentage.
function Rarities.chancePercent(id: string): number
	return Rarities.get(id).Weight / totalWeight * 100
end

-- "1 in N" phrasing for the odds panel.
function Rarities.oneInN(id: string): number
	return totalWeight / Rarities.get(id).Weight
end

return Rarities
