-- Picks a brainrot: first a rarity using weights, then a brainrot of that
-- rarity from a pool. Luck makes Rare and better more likely.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Brainrots = require(Shared.Brainrots)

local Picker = {}

local LUCKY = { Rare = true, Epic = true, Legendary = true, Mythic = true }

-- `odds`: rarity -> weight. `pool`: brainrot ids (default: everything that hatches).
function Picker.pick(odds: { [string]: number }, pool: { string }?, luck: number?): Brainrots.Def
	local byRarity = {}
	if pool then
		for _, id in pool do
			local def = Brainrots.byId[id]
			if def and not def.questOnly then
				byRarity[def.rarity] = byRarity[def.rarity] or {}
				table.insert(byRarity[def.rarity], def)
			end
		end
	else
		for _, rarity in Brainrots.RARITY_ORDER do
			byRarity[rarity] = Brainrots.byRarity[rarity]
		end
	end

	local tiers, total = {}, 0
	for _, rarity in Brainrots.RARITY_ORDER do
		local list = byRarity[rarity]
		local weight = (odds[rarity] or 0) * (if LUCKY[rarity] then luck or 1 else 1)
		if list and #list > 0 and weight > 0 then
			table.insert(tiers, { weight = weight, list = list })
			total += weight
		end
	end
	assert(#tiers > 0, "[ChaiChaos] nothing to pick from")
	local roll = math.random() * total
	for _, tier in tiers do
		roll -= tier.weight
		if roll <= 0 then
			return tier.list[math.random(#tier.list)]
		end
	end
	local last = tiers[#tiers]
	return last.list[math.random(#last.list)]
end

return Picker
