-- Gear sold at the Chowk's Gear shop. Gear is bought once and kept forever,
-- even after a Naya Safar. It works by itself; nothing needs equipping.
--
-- kind:
--   speed    : run faster on foot (the best one you own counts)
--   egg      : eggs last longer before breaking (the best one counts)
--   treasure : needed to open some treasure chests
--   hazard   : protects you from one biome hazard

local Gear = {}

export type Item = {
	id: string,
	name: string,
	kind: string,
	cost: number,
	text: string,
	value: number?,
	protects: string?,
}

Gear.list = {
	{ id = "Joggers", name = "Joggers", kind = "speed", value = 1.1, cost = 3_000, text = "Run 10% faster" },
	{ id = "Tokri", name = "Padded Tokri", kind = "egg", value = 1.25, cost = 6_000, text = "Eggs last 25% longer" },
	{
		id = "GumBoots",
		name = "Gum Boots",
		kind = "hazard",
		protects = "mud",
		cost = 5_000,
		text = "Walk through mud without getting stuck",
	},
	{
		id = "LifeJacket",
		name = "Life Jacket",
		kind = "hazard",
		protects = "water",
		cost = 8_000,
		text = "Swim fast and keep eggs safe from water and waves",
	},
	{ id = "Shovel", name = "Belcha", kind = "treasure", cost = 20_000, text = "Dig up buried treasure chests" },
	{
		id = "SandGoggles",
		name = "Sand Goggles",
		kind = "hazard",
		protects = "sandstorm",
		cost = 30_000,
		text = "See and run through sandstorms",
	},
	{
		id = "RopeLadder",
		name = "Rassi Seedhi",
		kind = "treasure",
		cost = 40_000,
		text = "Climb to cliff-top treasure",
	},
	{
		id = "PeshawariChappal",
		name = "Peshawari Chappal",
		kind = "speed",
		value = 1.25,
		cost = 60_000,
		text = "Run 25% faster",
	},
	{ id = "Thermos", name = "Thermos Dabba", kind = "egg", value = 1.6, cost = 80_000, text = "Eggs last 60% longer" },
	{
		id = "SnowBoots",
		name = "Snow Boots",
		kind = "hazard",
		protects = "ice",
		cost = 120_000,
		text = "No slipping on ice, and snowballs miss you",
	},
	{
		id = "Lantern",
		name = "Lantern",
		kind = "hazard",
		protects = "dark",
		cost = 200_000,
		text = "Light up the salt caves and dodge falling salt",
	},
} :: { Item }

Gear.byId = {} :: { [string]: Item }
for _, item in Gear.list do
	Gear.byId[item.id] = item
end

-- The best multiplier of a kind ("speed" or "egg") among the gear owned.
function Gear.best(owned: { [string]: boolean }, kind: string): number
	local best = 1
	for id in owned do
		local item = Gear.byId[id]
		if item and item.kind == kind and item.value and item.value > best then
			best = item.value
		end
	end
	return best
end

-- Does the owned gear protect against this hazard?
function Gear.protects(owned: { [string]: boolean }, hazard: string): boolean
	for id in owned do
		local item = Gear.byId[id]
		if item and item.protects == hazard then
			return true
		end
	end
	return false
end

-- Gear owned as "Joggers,Lantern" for player attributes.
function Gear.encode(owned: { [string]: boolean }): string
	local ids = {}
	for id in owned do
		table.insert(ids, id)
	end
	table.sort(ids)
	return table.concat(ids, ",")
end

function Gear.decode(text: string?): { [string]: boolean }
	local owned = {}
	for id in string.gmatch(text or "", "[^,]+") do
		owned[id] = true
	end
	return owned
end

return Gear
