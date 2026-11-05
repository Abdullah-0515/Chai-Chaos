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
			"CycleWalaCyclops",
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
			"CycleWalaCyclops",
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

-- A point in a biome: `distance` from the Chowk, `side` degrees off its road.
function Biomes.point(biome: Biome, distance: number, side: number?): Vector3
	local a = (biome.angle :: number) + math.rad(side or 0)
	return Vector3.new(math.cos(a) * distance, Biomes.GROUND_Y, math.sin(a) * distance)
end

-- The biome a position is in, or nil in the bazaar and the countryside.
function Biomes.at(position: Vector3): Biome?
	local r = math.sqrt(position.X * position.X + position.Z * position.Z)
	if r < Biomes.HUB_RADIUS then
		return nil
	end
	local angle = math.deg(math.atan2(position.Z, position.X)) % 360
	local biome = Biomes.list[math.floor(angle / 45) + 1]
	local inner = Biomes.innerRadius(biome)
	if biome and r >= inner and r <= inner + Biomes.DEPTH then
		return biome
	end
	return nil
end

-- The angle of haveli `index` (1-8) around the Chowk; it faces the middle.
function Biomes.haveliAngle(index: number): number
	return math.rad(45 * (index - 1))
end

return Biomes
