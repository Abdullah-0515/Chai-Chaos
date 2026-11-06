-- The 8 biomes around the Chowk, and the world's layout.
--
-- The Chowk is in the middle, the 8 havelis stand in a ring around it, and 8
-- roads lead out between the havelis, one to each biome. Biomes further out
-- have rarer brainrots in their eggs, but their eggs break sooner on the way home.
--
-- eggTime   : seconds an egg lasts once you pick it up (before gear and events)
-- hatchTime : seconds it takes to hatch in an incubator
-- odds      : rarity weights for this biome's eggs
-- pool      : which brainrots can hatch from this biome's eggs
-- hazards   : water, mud, ice, sandstorm, waves, snowballs, dark, salt (see Hazards.luau)

local Biomes = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- World layout (studs). The Chowk is centred on x = 0, z = 0.
Biomes.GROUND_Y = 1
Biomes.PLAZA_RADIUS = 70
Biomes.HAVELI_RADIUS = 150
Biomes.HUB_RADIUS = 200 -- inside this you are at home in the bazaar
Biomes.DEPTH = 280 -- how far each biome reaches outward
Biomes.WORLD_RADIUS = 860

export type Biome = {
	id: string,
	name: string,
	title: string,
	tier: number,
	blurb: string,
	color: Color3,
	eggColor: Color3,
	spotColor: Color3,
	eggTime: number,
	hatchTime: number,
	odds: { [string]: number },
	pool: { string },
	hazards: { string },
	index: number?,
	angle: number?,
}

Biomes.list = {
	{
		id = "Khet",
		name = "Khet",
		title = "Punjab Fields",
		tier = 1,
		blurb = "Golden wheat and yellow sarson. Watch out for muddy paddies!",
		color = rgb(250, 205, 60),
		eggColor = rgb(255, 230, 130),
		spotColor = rgb(110, 175, 60),
		eggTime = 60,
		hatchTime = 15,
		odds = { Common = 70, Uncommon = 25, Rare = 5 },
		pool = {
			"PyaazPehelwan",
			"ChanaChaatChacha",
			"SamosaSupremo",
			"NaanNinja",
			"LassiLlama",
			"BunKebabBhai",
			"CricketBatBhaijaan",
			"GeneratorGainda",
		},
		hazards = { "mud" },
	},
	{
		id = "Jungle",
		name = "Jungle",
		title = "Forest and River",
		tier = 2,
		blurb = "Thick trees, a rushing river and a waterfall with a secret.",
		color = rgb(60, 160, 70),
		eggColor = rgb(120, 210, 110),
		spotColor = rgb(40, 110, 50),
		eggTime = 55.5,
		hatchTime = 25,
		odds = { Common = 55, Uncommon = 30, Rare = 12, Epic = 3 },
		pool = {
			"PakoraPanda",
			"KulfiKangaroo",
			"ParathaPilot",
			"RickshawRaptor",
			"DhabaDragon",
			"TikkaTiger",
			"DholakDino",
		},
		hazards = { "water" },
	},
	{
		id = "Samandar",
		name = "Samandar",
		title = "Arabian Sea Beach",
		tier = 3,
		blurb = "Sand, boats and crabs. Big waves crash in every so often!",
		color = rgb(80, 180, 230),
		eggColor = rgb(150, 220, 255),
		spotColor = rgb(255, 240, 200),
		eggTime = 51,
		hatchTime = 35,
		odds = { Common = 40, Uncommon = 33, Rare = 18, Epic = 7, Legendary = 2 },
		pool = {
			"GolGappaGhostu",
			"ChaiyooKettlesaurus",
			"DoodhPattiDolphin",
			"RoohAfzaRhino",
			"ShaadiShehnaiShark",
			"BiryaniBadshah",
			"JalebiJinn",
			"SixerSher",
		},
		hazards = { "water", "waves" },
	},
	{
		id = "Jheel",
		name = "Jheel",
		title = "Lake and Meadows",
		tier = 4,
		blurb = "A blue mountain lake and meadows full of wildflowers.",
		color = rgb(90, 200, 160),
		eggColor = rgb(180, 240, 220),
		spotColor = rgb(255, 150, 200),
		eggTime = 46.5,
		hatchTime = 45,
		odds = { Common = 30, Uncommon = 32, Rare = 22, Epic = 12, Legendary = 4 },
		pool = {
			"KulfiKangaroo",
			"GolGappaGhostu",
			"LassiLlama",
			"ParathaPilot",
			"LoadSheddingLattoo",
			"MehndiMummy",
			"TongaTornado",
			"MelaMaharaja",
		},
		hazards = { "water" },
	},
	{
		id = "Registan",
		name = "Registan",
		title = "Cholistan Desert",
		tier = 5,
		blurb = "Rolling dunes, camels and an old fort. Sandstorms blow through!",
		color = rgb(235, 180, 100),
		eggColor = rgb(240, 200, 140),
		spotColor = rgb(200, 100, 50),
		eggTime = 42,
		hatchTime = 55,
		odds = { Common = 18, Uncommon = 28, Rare = 28, Epic = 18, Legendary = 7, Mythic = 1 },
		pool = {
			"SamosaSupremo",
			"PyaazPehelwan",
			"RickshawRaptor",
			"GajarHalwaGorilla",
			"BiryaniBadshah",
			"DhabaDragon",
			"TongaTornado",
			"ChipaSahab",
			"CylinderCycleChacha",
			"ChandRaatCheetah",
		},
		hazards = { "sandstorm" },
	},
	{
		id = "Delta",
		name = "Delta",
		title = "Indus Mangroves",
		tier = 6,
		blurb = "Mangrove trees in shallow water and huts on stilts. Very muddy!",
		color = rgb(110, 140, 80),
		eggColor = rgb(160, 190, 120),
		spotColor = rgb(90, 70, 50),
		eggTime = 37.5,
		hatchTime = 65,
		odds = { Common = 10, Uncommon = 22, Rare = 30, Epic = 25, Legendary = 11, Mythic = 2 },
		pool = {
			"PakoraPanda",
			"ChaiyooKettlesaurus",
			"DoodhPattiDolphin",
			"BunKebabBhai",
			"ShaadiShehnaiShark",
			"GeneratorGainda",
			"RishtaAuntyRobot",
			"DholakDino",
			"ChilgozaChachaChipka",
			"AmmiKiUdtiChappal",
		},
		hazards = { "mud", "water" },
	},
	{
		id = "Pahar",
		name = "Pahar",
		title = "Karakoram Mountains",
		tier = 7,
		blurb = "Snowy peaks and frozen lakes. Slippery ice and flying snowballs!",
		color = rgb(220, 235, 255),
		eggColor = rgb(235, 245, 255),
		spotColor = rgb(110, 160, 230),
		eggTime = 33,
		hatchTime = 75,
		odds = { Uncommon = 15, Rare = 30, Epic = 33, Legendary = 18, Mythic = 4 },
		pool = {
			"GajarHalwaGorilla",
			"RoohAfzaRhino",
			"LoadSheddingLattoo",
			"CricketBatBhaijaan",
			"JalebiJinn",
			"RishtaAuntyRobot",
			"TruckArtTotaa",
			"MelaMaharaja",
			"KiteKaptaan",
		},
		hazards = { "ice", "snowballs" },
	},
	{
		id = "NamakKaan",
		name = "Namak Kaan",
		title = "Pink Salt Caves",
		tier = 8,
		blurb = "Glowing pink salt tunnels deep underground. Dark, with falling salt!",
		color = rgb(255, 150, 190),
		eggColor = rgb(255, 190, 215),
		spotColor = rgb(200, 60, 120),
		eggTime = 28.5,
		hatchTime = 85,
		odds = { Rare = 25, Epic = 38, Legendary = 28, Mythic = 9 },
		pool = {
			"LoadSheddingLattoo",
			"GeneratorGainda",
			"BiryaniBadshah",
			"ChipaSahab",
			"MehndiMummy",
			"TikkaTiger",
			"SixerSher",
			"CylinderCycleChacha",
			"ChilgozaChachaChipka",
			"ChandRaatCheetah",
			"AmmiKiUdtiChappal",
			"KiteKaptaan",
		},
		hazards = { "dark", "salt" },
	},
} :: { Biome }

Biomes.byId = {} :: { [string]: Biome }
for index, biome in Biomes.list do
	biome.index = index
	biome.angle = math.rad(22.5 + 45 * (index - 1)) -- the direction of its road from the Chowk
	Biomes.byId[biome.id] = biome
end

-- How far from the Chowk a biome starts.
function Biomes.innerRadius(biome: Biome): number
	return 230 + 45 * (biome.tier - 1)
end

-- The direction (x, z) of a biome's road.
function Biomes.direction(biome: Biome): Vector3
	return Vector3.new(math.cos(biome.angle :: number), 0, math.sin(biome.angle :: number))
end

-- A point `distance` from the Chowk along a biome's road, turned `side` degrees off it.
function Biomes.point(biome: Biome, distance: number, side: number?): Vector3
	local a = (biome.angle :: number) + math.rad(side or 0)
	return Vector3.new(math.cos(a) * distance, Biomes.GROUND_Y, math.sin(a) * distance)
end

---------------------------------------------------------------------------
-- Zones. Each biome is its own rounded area at the end of its road, with
-- countryside between it and its neighbours. The shape is an oval (long
-- along the road, narrower across) with a wobbly edge, so it looks natural.
---------------------------------------------------------------------------
Biomes.ZONE_WIDTH = 0.28 -- half the zone's width, as a share of its distance from the Chowk

-- How far the middle of a biome is from the Chowk.
function Biomes.centerDistance(biome: Biome): number
	return Biomes.innerRadius(biome) + Biomes.DEPTH / 2
end

function Biomes.center(biome: Biome): Vector3
	return Biomes.direction(biome) * Biomes.centerDistance(biome) + Vector3.new(0, Biomes.GROUND_Y, 0)
end

-- Half the zone's size along its road and across it.
function Biomes.halfSize(biome: Biome): (number, number)
	return Biomes.DEPTH / 2, Biomes.centerDistance(biome) * Biomes.ZONE_WIDTH
end

-- The direction across a biome: to the right when walking out along its road.
local function across(biome: Biome): Vector3
	local dir = Biomes.direction(biome)
	return Vector3.new(-dir.Z, 0, dir.X)
end

-- A world position from zone coordinates: `along` the road from the zone's
-- middle (positive = further from the Chowk) and `side` across it.
function Biomes.fromLocal(biome: Biome, along: number, side: number): Vector3
	return Biomes.center(biome) + Biomes.direction(biome) * along + across(biome) * side
end

function Biomes.toLocal(biome: Biome, position: Vector3): (number, number)
	local offset = position - Biomes.center(biome)
	local dir, side = Biomes.direction(biome), across(biome)
	return offset.X * dir.X + offset.Z * dir.Z, offset.X * side.X + offset.Z * side.Z
end

-- How far out a position is: 0 in the middle, 1 on the zone's edge.
function Biomes.zoneDistance(biome: Biome, position: Vector3): number
	local along, side = Biomes.toLocal(biome, position)
	local a, b = Biomes.halfSize(biome)
	local u, v = along / a, side / b
	local theta = math.atan2(v, u)
	local index = biome.index :: number
	local edge = 1 + 0.07 * math.sin(3 * theta + index) + 0.04 * math.sin(5 * theta + 2 * index)
	return math.sqrt(u * u + v * v) / edge
end

-- Is the position inside this biome's zone? `margin` shrinks the zone (0.1 = 10%).
function Biomes.contains(biome: Biome, position: Vector3, margin: number?): boolean
	return Biomes.zoneDistance(biome, position) <= 1 - (margin or 0)
end

-- The biome a position is in, or nil in the bazaar and the countryside.
function Biomes.at(position: Vector3): Biome?
	local r = math.sqrt(position.X * position.X + position.Z * position.Z)
	if r < Biomes.HUB_RADIUS then
		return nil
	end
	for _, biome in Biomes.list do
		if Biomes.contains(biome, position) then
			return biome
		end
	end
	return nil
end

-- The angle of haveli `index` (1-8) around the Chowk; it faces the middle.
function Biomes.haveliAngle(index: number): number
	return math.rad(45 * (index - 1))
end

return Biomes
