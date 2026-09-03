--[[
	Statistical check on the roll math. Run it with roblox/tests/run.py, which
	stubs the handful of Roblox globals the pure modules touch and executes this
	file in the standalone Luau interpreter.

	It asserts three things:
	  1. observed rarity frequencies match the configured weights,
	  2. the pity counter caps how long a dry streak can run,
	  3. every card in the catalogue is actually reachable.
]]

-- ---------------------------------------------------------------- assertions
local Rarities, Cards, RollLogic, Config = MODS.Rarities, MODS.Cards, MODS.RollLogic, MODS.Config
math.randomseed(20260903)
local rng = Random.new()

local N = 300000
local counts = {}
for _, r in Rarities.List do counts[r.Id] = 0 end

local pity = 0
local hands, handsWithRarePlus, maxDry = 0, 0, 0
local dry = 0
local minRank = Rarities.get(Config.PityMinimumRarity).Rank

for _ = 1, N do
	local hand, nextPity = RollLogic.rollHand(rng, pity)
	pity = nextPity
	hands += 1
	assert(#hand == Config.CardsPerRoll, "hand size")
	local best = 0
	for _, card in hand do
		counts[card.Rarity] += 1
		best = math.max(best, Rarities.get(card.Rarity).Rank)
	end
	if best >= minRank then
		handsWithRarePlus += 1
		dry = 0
	else
		dry += 1
		maxDry = math.max(maxDry, dry)
	end
end

print(string.format("%-11s %10s %10s %8s", "rarity", "expected%", "actual%", "n"))
local total = N * Config.CardsPerRoll
for _, r in Rarities.List do
	local expected = Rarities.chancePercent(r.Id)
	local actual = counts[r.Id] / total * 100
	print(string.format("%-11s %9.3f%% %9.3f%% %8d", r.Id, expected, actual, counts[r.Id]))
	-- allow 8% relative drift on rare tiers, 2% on common ones
	local tolerance = if expected < 1 then expected * 0.15 else expected * 0.03
	assert(math.abs(actual - expected) < tolerance,
		string.format("%s drifted: expected %.3f got %.3f", r.Id, expected, actual))
end

print(string.format("hands with %s+ : %.2f%%", Config.PityMinimumRarity, handsWithRarePlus / hands * 100))
print(string.format("longest dry streak: %d (pity limit %d)", maxDry, Config.PityRolls))
assert(maxDry < Config.PityRolls, "pity failed to cap the dry streak")

-- every catalogue entry must be reachable
local seen = {}
for _ = 1, 200000 do seen[RollLogic.pickCard(rng).Id] = true end
local missing = {}
for _, card in Cards.List do
	if not seen[card.Id] then table.insert(missing, card.Id) end
end
assert(#missing == 0, "unreachable cards: " .. table.concat(missing, ", "))
print(string.format("all %d cards reachable", #Cards.List))
print("OK")
