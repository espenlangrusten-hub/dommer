--!strict
--[[
	RollLogic
	Pure functions - no Instances, no yielding. The server owns the Random
	object, so the client can never influence an outcome.
]]

local Cards = require(script.Parent.Cards)
local Config = require(script.Parent.Config)
local Rarities = require(script.Parent.Rarities)

type Card = Cards.Card
type Rarity = Rarities.Rarity

local RollLogic = {}

-- Weighted pick across every rarity tier.
function RollLogic.pickRarity(rng: Random): Rarity
	local roll = rng:NextNumber(0, Rarities.TotalWeight)
	local running = 0
	for _, rarity in Rarities.List do
		running += rarity.Weight
		if roll <= running then
			return rarity
		end
	end
	-- Float rounding can overshoot the last bucket by a hair.
	return Rarities.List[#Rarities.List]
end

function RollLogic.pickCardOfRarity(rng: Random, rarityId: string): Card
	local pool = Cards.ByRarity[rarityId]
	assert(pool and #pool > 0, `no cards for rarity "{rarityId}"`)
	return pool[rng:NextInteger(1, #pool)]
end

function RollLogic.pickCard(rng: Random): Card
	return RollLogic.pickCardOfRarity(rng, RollLogic.pickRarity(rng).Id)
end

--[[
	Deals one hand.

	pityCounter: rolls since the player last saw Config.PityMinimumRarity or
	better. When it reaches Config.PityRolls, one card in the hand is upgraded.

	Returns the hand and the new pity counter.
]]
function RollLogic.rollHand(rng: Random, pityCounter: number): ({ Card }, number)
	local hand: { Card } = {}
	for _ = 1, Config.CardsPerRoll do
		table.insert(hand, RollLogic.pickCard(rng))
	end

	local minRank = Rarities.get(Config.PityMinimumRarity).Rank
	local best = 0
	for _, card in hand do
		best = math.max(best, Rarities.get(card.Rarity).Rank)
	end

	local pityActive = Config.PityRolls > 0
	if pityActive and best < minRank and pityCounter + 1 >= Config.PityRolls then
		-- Upgrade one random slot to exactly the pity floor.
		local slot = rng:NextInteger(1, #hand)
		hand[slot] = RollLogic.pickCardOfRarity(rng, Config.PityMinimumRarity)
		best = minRank
	end

	local nextPity = if best >= minRank then 0 else pityCounter + 1
	return hand, nextPity
end

return RollLogic
