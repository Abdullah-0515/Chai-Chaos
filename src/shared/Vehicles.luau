-- Vehicles: how you get out to the zones and back with your eggs.
--
-- Buy them at the Gaari Showroom (Rickshaw Stand, in the bazaar), upgrade them
-- at Ustad's Workshop (Chai Dhaba Bazaar) and fill up at the petrol pumps.
-- Everything is bought with rupees and kept forever, even after a Naya Safar.
-- Robux only buys paint jobs, which change how vehicles look and nothing else.
--
-- speed : top speed in studs per second (walking is Config.WALK_SPEED)
-- tank  : how far it drives on a full tank, in studs
-- eggs  : eggs it carries in the boot
-- grip  : 0-3. 1 drives through mud, 2 through sand, 3 on ice without sliding
-- seats : friends who can ride along

local Vehicles = {}

export type Def = {
	id: string,
	name: string,
	cost: number,
	speed: number,
	tank: number,
	eggs: number,
	grip: number,
	seats: number,
	upgradeBase: number,
	text: string,
}

export type Upgrade = {
	id: string,
	name: string,
	max: number,
	costMult: number,
	text: string,
}

export type Levels = { speed: number, tank: number, eggs: number, grip: number }

Vehicles.list = {
	{
		id = "Motorbike",
		name = "Motorbike",
		cost = 3_000,
		speed = 34,
		tank = 1_500,
		eggs = 1,
		grip = 0,
		seats = 1,
		upgradeBase = 1_500,
		text = "Cheap and quick. Carries 1 egg and a friend on the back.",
	},
	{
		id = "Rickshaw",
		name = "Rickshaw",
		cost = 25_000,
		speed = 38,
		tank = 2_000,
		eggs = 2,
		grip = 0,
		seats = 2,
		upgradeBase = 8_000,
		text = "Pon pon! Carries 2 eggs and 2 friends.",
	},
	{
		id = "PiliTaxi",
		name = "Pili Taxi",
		cost = 150_000,
		speed = 46,
		tank = 2_800,
		eggs = 3,
		grip = 1,
		seats = 3,
		upgradeBase = 40_000,
		text = "A yellow city taxi. Fast, 3 eggs, 3 friends, drives through mud.",
	},
	{
		id = "PhoolPattiTruck",
		name = "Phool Patti Truck",
		cost = 1_200_000,
		speed = 42,
		tank = 4_500,
		eggs = 6,
		grip = 2,
		seats = 1,
		upgradeBase = 250_000,
		text = "A painted truck with bells. 6 eggs, a huge tank, drives through sand.",
	},
} :: { Def }

Vehicles.byId = {} :: { [string]: Def }
for _, def in Vehicles.list do
	Vehicles.byId[def.id] = def
end

Vehicles.UPGRADES = {
	{ id = "speed", name = "Engine", max = 5, costMult = 1, text = "+10% top speed" },
	{ id = "tank", name = "Fuel Tank", max = 5, costMult = 0.6, text = "+25% range" },
	{ id = "eggs", name = "Egg Space", max = 3, costMult = 1.4, text = "+1 egg in the boot" },
	{ id = "grip", name = "Tyres", max = 3, costMult = 1.2, text = "Better grip on mud, sand and ice" },
} :: { Upgrade }

Vehicles.upgradeById = {} :: { [string]: Upgrade }
for _, upgrade in Vehicles.UPGRADES do
	Vehicles.upgradeById[upgrade.id] = upgrade
end

Vehicles.GRIP_MAX = 3
Vehicles.SPEED_PER_LEVEL = 0.1
Vehicles.TANK_PER_LEVEL = 0.25
Vehicles.UPGRADE_GROWTH = 1.8 -- every level costs this many times more than the last

-- Paint jobs: bought with Robux (see Config.PAINT_PRODUCTS). Looks only.
Vehicles.PAINTS = {
	{ id = "Factory", name = "Factory Paint", text = "The colours it came with." },
	{ id = "PhoolPatti", name = "Phool Patti", text = "Bright truck-art colours on every panel." },
	{ id = "Sona", name = "Sona", text = "Shiny gold all over." },
	{ id = "Rangeela", name = "Rangeela", text = "Every colour of the rainbow, always changing." },
	{ id = "Chamak", name = "Chamak", text = "Glows in the dark." },
}
Vehicles.paintById = {}
for _, paint in Vehicles.PAINTS do
	Vehicles.paintById[paint.id] = paint
end

-- How many levels an upgrade can go up on this vehicle.
function Vehicles.maxLevel(def: Def, upgradeId: string): number
	local upgrade = Vehicles.upgradeById[upgradeId]
	if upgradeId == "grip" then
		return math.max(0, Vehicles.GRIP_MAX - def.grip)
	end
	return upgrade and upgrade.max or 0
end

-- What the next level of an upgrade costs (`level` is the level being bought).
function Vehicles.upgradeCost(def: Def, upgradeId: string, level: number): number
	local upgrade = Vehicles.upgradeById[upgradeId]
	local raw = def.upgradeBase * upgrade.costMult * Vehicles.UPGRADE_GROWTH ^ (level - 1)
	return math.floor(raw / 50 + 0.5) * 50
end

function Vehicles.levels(saved: any): Levels
	local t = if type(saved) == "table" then saved else {}
	return {
		speed = t.speed or 0,
		tank = t.tank or 0,
		eggs = t.eggs or 0,
		grip = t.grip or 0,
	}
end

-- A vehicle's stats with its upgrades.
function Vehicles.speed(def: Def, levels: Levels): number
	return def.speed * (1 + Vehicles.SPEED_PER_LEVEL * levels.speed)
end

function Vehicles.tank(def: Def, levels: Levels): number
	return math.floor(def.tank * (1 + Vehicles.TANK_PER_LEVEL * levels.tank))
end

function Vehicles.eggs(def: Def, levels: Levels): number
	return def.eggs + levels.eggs
end

function Vehicles.grip(def: Def, levels: Levels): number
	return math.min(Vehicles.GRIP_MAX, def.grip + levels.grip)
end

-- Does this grip get through this surface at full speed?
-- mud needs grip 1, sand 2, ice 3. Deep water always slows you down.
Vehicles.GRIP_NEEDED = { mud = 1, sand = 2, sandstorm = 2, ice = 3 }

function Vehicles.handles(grip: number, surface: string): boolean
	local needed = Vehicles.GRIP_NEEDED[surface]
	return needed ~= nil and grip >= needed
end

return Vehicles
