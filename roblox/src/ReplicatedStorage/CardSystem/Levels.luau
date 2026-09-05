--!strict
--[[
	Levels
	XP curve behind the bar under the hotbar, and the gates on the locked
	hotbar slots.

	The curve is quadratic: early levels come fast, later ones stretch out.
]]

local Rarities = require(script.Parent.Rarities)

local Levels = {}

Levels.MaxLevel = 200

-- XP needed to go from `level` to `level + 1`.
function Levels.xpForNext(level: number): number
	local n = math.max(1, math.floor(level))
	return 15 + (n - 1) * 10 + math.floor((n - 1) ^ 2 * 0.6)
end

-- Total XP banked at the start of `level`.
function Levels.totalXpForLevel(level: number): number
	local total = 0
	for n = 1, math.max(1, math.floor(level)) - 1 do
		total += Levels.xpForNext(n)
	end
	return total
end

export type Progress = {
	Level: number,
	IntoLevel: number,
	Needed: number,
	Fraction: number,
}

-- Splits a total XP figure into the level and the progress inside it.
function Levels.progress(totalXp: number): Progress
	local remaining = math.max(0, math.floor(totalXp))
	local level = 1
	while level < Levels.MaxLevel do
		local needed = Levels.xpForNext(level)
		if remaining < needed then
			break
		end
		remaining -= needed
		level += 1
	end

	local needed = if level >= Levels.MaxLevel then 0 else Levels.xpForNext(level)
	return {
		Level = level,
		IntoLevel = remaining,
		Needed = needed,
		Fraction = if needed > 0 then math.clamp(remaining / needed, 0, 1) else 1,
	}
end

-- XP paid out for keeping a card of this rarity.
function Levels.xpForRarity(rarityId: string): number
	local rarity = Rarities.get(rarityId)
	return 5 + (rarity.Rank - 1) * 6
end

return Levels
