-- The 12 zones (biomes) of the world and its layout: the "biome slices" map.
--
-- One big circle. In the middle: the Chowk, the 8 havelis around it and the
-- Lahore bazaar (the town ring). Outside the town wall the circle is cut into
-- 4 regions of Pakistan (Punjab, Sindh, Thar, KPK), and each region into 3
-- rings, so there are 12 zones:
--
--            RING 1 (rupees)            RING 2 (more rupees)        RING 3 (rebirths)
--   Punjab   Mango Bagh       free      Sarson Fields   Rs 200k     Lahore Qila    1 rebirth
--   Sindh    Railway Junction Rs 10k    Sahil Beach     Rs 400k     Karachi Port   2 rebirths
--   Thar     Camel Mela       Rs 30k    Thar Desert     Rs 750k     Mohenjo-daro   3 rebirths
--   KPK      Qissa Khawani    Rs 75k    Namak Caves     Rs 1.5M     Barfani Pahar  4 rebirths
--
-- Farther out always costs more and has rarer brainrots. The gate into a ring 1
-- zone is in the town wall in the middle of its region; the gate into ring 2 is
-- turned 30 degrees one way and the gate into ring 3 30 degrees the other way,
-- so you zigzag through every zone. Shortcut doors between neighbouring
-- regions open once you have unlocked the zones on both sides.
--
-- Angles are in degrees: 0 points along +X, and they grow towards +Z
-- (clockwise when you look down with -Z at the top). Punjab is at -90 (-Z).
--
-- eggTime   : seconds an egg lasts once you pick it up (before gear and events)
-- hatchTime : seconds it takes to hatch in an incubator
-- odds      : rarity weights for this zone's eggs
-- pool      : which brainrots can hatch from this zone's eggs
-- hazards   : train, water, waves, mud, sandstorm, dark, salt, ice, snowballs (see Hazards.luau)
-- price     : rupees to unlock it at its gate (0 = free)
-- rebirths  : Naya Safars needed to open its gate (ring 3)

local Biomes = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- World layout (studs). The Chowk is centred on x = 0, z = 0.
Biomes.GROUND_Y = 1
Biomes.PLAZA_RADIUS = 70
Biomes.HAVELI_RADIUS = 150
Biomes.HUB_RADIUS = 200 -- the town ring (Lahore bazaar) starts here
Biomes.MANDI_RADIUS = 100 -- the Mandi lane runs round the Chowk here, in front of the haveli doors
Biomes.MANDI_START = -83 -- brainrots come out of the Mandi arch here (just beside the Punjab road)
Biomes.TOWN_RADIUS = 290 -- the town wall; the zones are outside it
Biomes.RINGS = { { 290, 450 }, { 450, 610 }, { 610, 740 } }
Biomes.WORLD_RADIUS = 740
Biomes.SPAN = 45 -- every zone reaches this many degrees either side of its region's middle
Biomes.GATE_WIDTH = 30 -- wide enough for a truck

Biomes.REGIONS = {
	{ id = "Punjab", name = "Punjab", angle = -90 },
	{ id = "Sindh", name = "Sindh", angle = 0 },
	{ id = "Thar", name = "Thar and Balochistan", angle = 90 },
	{ id = "KPK", name = "KPK and the North", angle = 180 },
}
Biomes.regionById = {}
for index, region in Biomes.REGIONS do
	region.index = index
	Biomes.regionById[region.id] = region
end

-- The 6 sectors of the Lahore bazaar (the town ring), by the angle of their middle.
Biomes.TOWN_SECTORS = {
	{ id = "BrainrotMandi", name = "Brainrot Mandi", angle = -90 },
	{ id = "KitePoint", name = "Kite Point", angle = -30 },
	{ id = "CricketGali", name = "Cricket Gali", angle = 30 },
	{ id = "MelaGround", name = "Mela Ground", angle = 90 },
	{ id = "ChaiDhabaBazaar", name = "Chai Dhaba Bazaar", angle = 150 },
	{ id = "RickshawStand", name = "Rickshaw Stand", angle = 210 },
}

export type Biome = {
	id: string,
	name: string,
	title: string,
	region: string,
	ring: number,
	tier: number,
	price: number,
	rebirths: number,
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
	angle: number?, -- the middle of its region, in degrees
}

-- stylua: ignore start
Biomes.list = {
	-------------------------------------------------------------------- Ring 1
	{
		id = "MangoBagh", name = "Mango Bagh", title = "Punjab Mango Orchards", region = "Punjab", ring = 1, tier = 1,
		price = 0, rebirths = 0,
		blurb = "Shady mango trees, a tube well and charpais. Free for everyone!",
		color = rgb(110, 170, 70), eggColor = rgb(255, 225, 120), spotColor = rgb(120, 190, 70),
		eggTime = 60, hatchTime = 15,
		odds = { Common = 72, Uncommon = 24, Rare = 4 },
		pool = { "KulfiKangaroo", "PakoraPanda", "GolGappaGhostu", "NaanNinja", "LassiLlama", "GajarHalwaGorilla", "CricketBatBhaijaan" },
		hazards = { "mud" },
	},
	{
		id = "RailwayJunction", name = "Railway Junction", title = "Sindh Railway Junction", region = "Sindh", ring = 1, tier = 2,
		price = 15_000, rebirths = 0,
		blurb = "A busy station. Watch the crossing light: the train comes through!",
		color = rgb(150, 140, 130), eggColor = rgb(230, 210, 180), spotColor = rgb(200, 60, 50),
		eggTime = 58, hatchTime = 20,
		odds = { Common = 62, Uncommon = 30, Rare = 7, Epic = 1 },
		pool = { "ChaiyooKettlesaurus", "SamosaSupremo", "ChanaChaatChacha", "RickshawRaptor", "ParathaPilot", "GeneratorGainda", "LoadSheddingLattoo", "TongaTornado" },
		hazards = { "train" },
	},
	{
		id = "CamelMela", name = "Camel Mela", title = "Thar Camel Fair", region = "Thar", ring = 1, tier = 3,
		price = 50_000, rebirths = 0,
		blurb = "Colourful tents, bunting and dancing camels at the desert fair.",
		color = rgb(215, 160, 95), eggColor = rgb(255, 200, 150), spotColor = rgb(220, 50, 80),
		eggTime = 56, hatchTime = 28,
		odds = { Common = 45, Uncommon = 38, Rare = 14, Epic = 3 },
		pool = { "PyaazPehelwan", "NaanNinja", "SamosaSupremo", "BunKebabBhai", "RoohAfzaRhino", "DhabaDragon", "DholakDino" },
		hazards = {},
	},
	{
		id = "QissaKhawani", name = "Qissa Khawani", title = "Peshawar Storytellers' Bazaar", region = "KPK", ring = 1, tier = 4,
		price = 150_000, rebirths = 0,
		blurb = "Tall wooden balconies, kahwa stalls and the old clock tower.",
		color = rgb(205, 160, 110), eggColor = rgb(240, 200, 160), spotColor = rgb(150, 40, 50),
		eggTime = 54, hatchTime = 35,
		odds = { Common = 35, Uncommon = 40, Rare = 19, Epic = 5, Legendary = 1 },
		pool = { "ChanaChaatChacha", "PyaazPehelwan", "GolGappaGhostu", "DoodhPattiDolphin", "ParathaPilot", "BiryaniBadshah", "LoadSheddingLattoo", "ChipaSahab", "ChilgozaChachaChipka" },
		hazards = {},
	},
	-------------------------------------------------------------------- Ring 2
	{
		id = "SarsonFields", name = "Sarson Fields", title = "Punjab Mustard Fields", region = "Punjab", ring = 2, tier = 5,
		price = 500_000, rebirths = 0,
		blurb = "Rows and rows of yellow sarson, a tractor and muddy paths.",
		color = rgb(232, 216, 74), eggColor = rgb(255, 240, 150), spotColor = rgb(110, 160, 50),
		eggTime = 50, hatchTime = 42,
		odds = { Common = 22, Uncommon = 33, Rare = 30, Epic = 12, Legendary = 3 },
		pool = { "KulfiKangaroo", "PakoraPanda", "LassiLlama", "GajarHalwaGorilla", "CricketBatBhaijaan", "GeneratorGainda", "DholakDino", "TikkaTiger", "SixerSher" },
		hazards = { "mud" },
	},
	{
		id = "SahilBeach", name = "Sahil Beach", title = "Arabian Sea Beach", region = "Sindh", ring = 2, tier = 6,
		price = 1_200_000, rebirths = 0,
		blurb = "Sand, camels and beach umbrellas. Big waves roll in every so often!",
		color = rgb(240, 220, 160), eggColor = rgb(160, 220, 255), spotColor = rgb(60, 150, 220),
		eggTime = 48, hatchTime = 50,
		odds = { Common = 15, Uncommon = 30, Rare = 33, Epic = 16, Legendary = 5, Mythic = 1 },
		pool = { "GolGappaGhostu", "ChaiyooKettlesaurus", "DoodhPattiDolphin", "RoohAfzaRhino", "ShaadiShehnaiShark", "DhabaDragon", "JalebiJinn", "TruckArtTotaa", "KiteKaptaan" },
		hazards = { "water", "waves" },
	},
	{
		id = "TharDesert", name = "Thar Desert", title = "Thar Sand Dunes", region = "Thar", ring = 2, tier = 7,
		price = 3_000_000, rebirths = 0,
		blurb = "Rolling dunes and an old desert fort. Sandstorms blow through!",
		color = rgb(224, 176, 112), eggColor = rgb(240, 200, 140), spotColor = rgb(200, 100, 50),
		eggTime = 46, hatchTime = 60,
		odds = { Uncommon = 22, Rare = 34, Epic = 30, Legendary = 11, Mythic = 3 },
		pool = { "RickshawRaptor", "BunKebabBhai", "DhabaDragon", "BiryaniBadshah", "TongaTornado", "MehndiMummy", "CylinderCycleChacha", "MelaMaharaja", "ChandRaatCheetah" },
		hazards = { "sandstorm" },
	},
	{
		id = "NamakCaves", name = "Namak Caves", title = "Pink Salt Caves", region = "KPK", ring = 2, tier = 8,
		price = 7_000_000, rebirths = 0,
		blurb = "Glowing pink salt rocks deep in the hills. Dark, with falling salt!",
		color = rgb(230, 170, 180), eggColor = rgb(255, 190, 215), spotColor = rgb(200, 60, 120),
		eggTime = 44, hatchTime = 70,
		odds = { Uncommon = 12, Rare = 32, Epic = 36, Legendary = 15, Mythic = 5 },
		pool = { "RoohAfzaRhino", "GajarHalwaGorilla", "LoadSheddingLattoo", "GeneratorGainda", "RishtaAuntyRobot", "ChipaSahab", "ChilgozaChachaChipka", "AmmiKiUdtiChappal" },
		hazards = { "dark", "salt" },
	},
	-------------------------------------------------------------------- Ring 3
	{
		id = "LahoreQila", name = "Lahore Qila", title = "The Old Fort of Lahore", region = "Punjab", ring = 3, tier = 9,
		price = 0, rebirths = 1,
		blurb = "Red sandstone walls, a giant gate and a moat all around.",
		color = rgb(192, 112, 90), eggColor = rgb(255, 170, 140), spotColor = rgb(160, 70, 50),
		eggTime = 42, hatchTime = 80,
		odds = { Rare = 25, Epic = 38, Legendary = 30, Mythic = 7 },
		pool = { "BiryaniBadshah", "CricketBatBhaijaan", "JalebiJinn", "TikkaTiger", "DholakDino", "MelaMaharaja", "SixerSher", "KiteKaptaan" },
		hazards = { "water" },
	},
	{
		id = "KarachiPort", name = "Karachi Port", title = "The Big Harbour", region = "Sindh", ring = 3, tier = 10,
		price = 0, rebirths = 2,
		blurb = "Stacks of shipping containers, giant cranes and a cargo ship.",
		color = rgb(90, 140, 200), eggColor = rgb(150, 200, 255), spotColor = rgb(240, 160, 40),
		eggTime = 40, hatchTime = 90,
		odds = { Rare = 18, Epic = 36, Legendary = 35, Mythic = 11 },
		pool = { "ShaadiShehnaiShark", "GeneratorGainda", "RishtaAuntyRobot", "TongaTornado", "TruckArtTotaa", "CylinderCycleChacha", "AmmiKiUdtiChappal" },
		hazards = { "water" },
	},
	{
		id = "MohenjoDaro", name = "Mohenjo-daro", title = "The Ancient Brick City", region = "Thar", ring = 3, tier = 11,
		price = 0, rebirths = 3,
		blurb = "Brick ruins thousands of years old and the Great Bath. Dusty storms!",
		color = rgb(168, 134, 106), eggColor = rgb(220, 180, 140), spotColor = rgb(170, 100, 70),
		eggTime = 38, hatchTime = 100,
		odds = { Epic = 35, Legendary = 40, Mythic = 25 },
		pool = { "MehndiMummy", "JalebiJinn", "ChilgozaChachaChipka", "MelaMaharaja", "ChandRaatCheetah", "AmmiKiUdtiChappal" },
		hazards = { "sandstorm" },
	},
	{
		id = "BarfaniPahar", name = "Barfani Pahar", title = "The Snowy North", region = "KPK", ring = 3, tier = 12,
		price = 0, rebirths = 4,
		blurb = "Ice caves, frozen lakes and flying snowballs. The Secret brainrots live here!",
		color = rgb(235, 245, 255), eggColor = rgb(225, 240, 255), spotColor = rgb(110, 160, 230),
		eggTime = 36, hatchTime = 120,
		odds = { Epic = 25, Legendary = 40, Mythic = 28, Secret = 7 },
		pool = { "ChipaSahab", "RishtaAuntyRobot", "SixerSher", "TruckArtTotaa", "KiteKaptaan", "ChandRaatCheetah", "KahwaYeti", "GolaGandaGolem", "BarfiBarfaniBagh", "JalebiMarkhor" },
		hazards = { "ice", "snowballs" },
	},
} :: { Biome }
-- stylua: ignore end

Biomes.byId = {} :: { [string]: Biome }
Biomes.byRegion = {} :: { [string]: { Biome } } -- byRegion.Punjab[ring]
for index, biome in Biomes.list do
	biome.index = index
	biome.angle = Biomes.regionById[biome.region].angle
	Biomes.byId[biome.id] = biome
	Biomes.byRegion[biome.region] = Biomes.byRegion[biome.region] or {}
	Biomes.byRegion[biome.region][biome.ring] = biome
end

---------------------------------------------------------------------------
-- Geometry
---------------------------------------------------------------------------
-- A ground point `r` studs from the Chowk at `angle` degrees.
function Biomes.polar(angle: number, r: number): Vector3
	local a = math.rad(angle)
	return Vector3.new(math.cos(a) * r, Biomes.GROUND_Y, math.sin(a) * r)
end

-- The Mandi lane round the Chowk: points every `step` degrees, starting at the
-- Mandi arch and going clockwise (seen from above) all the way round.
function Biomes.mandiLane(step: number): { Vector3 }
	local points = {}
	for d = 0, 360, step do
		table.insert(points, Biomes.polar(Biomes.MANDI_START + d, Biomes.MANDI_RADIUS))
	end
	return points
end

-- The angle (degrees, -180 to 180) and distance of a position from the Chowk.
function Biomes.angleOf(position: Vector3): number
	return math.deg(math.atan2(position.Z, position.X))
end

function Biomes.radiusOf(position: Vector3): number
	return math.sqrt(position.X * position.X + position.Z * position.Z)
end

-- How far apart two angles are, from -180 to 180.
function Biomes.angleDiff(a: number, b: number): number
	return (a - b + 180) % 360 - 180
end

function Biomes.innerRadius(biome: Biome): number
	return Biomes.RINGS[biome.ring][1]
end

function Biomes.outerRadius(biome: Biome): number
	return Biomes.RINGS[biome.ring][2]
end

-- The direction (x, z) of a zone's middle from the Chowk.
function Biomes.direction(biome: Biome): Vector3
	local a = math.rad(biome.angle :: number)
	return Vector3.new(math.cos(a), 0, math.sin(a))
end

-- A point `distance` from the Chowk, turned `side` degrees off the middle of the zone.
function Biomes.point(biome: Biome, distance: number, side: number?): Vector3
	return Biomes.polar((biome.angle :: number) + (side or 0), distance)
end

function Biomes.center(biome: Biome): Vector3
	return Biomes.point(biome, (Biomes.innerRadius(biome) + Biomes.outerRadius(biome)) / 2)
end

-- Is the position inside this zone? `margin` (studs) keeps away from its edges.
function Biomes.contains(biome: Biome, position: Vector3, margin: number?): boolean
	local m = margin or 0
	local r = Biomes.radiusOf(position)
	if r < Biomes.innerRadius(biome) + m or r > Biomes.outerRadius(biome) - m then
		return false
	end
	local off = math.abs(Biomes.angleDiff(Biomes.angleOf(position), biome.angle :: number))
	return off * math.pi * r / 180 <= Biomes.SPAN * math.pi * r / 180 - m
end

-- The zone a position is in, or nil in the Chowk and the bazaar.
function Biomes.at(position: Vector3): Biome?
	local r = Biomes.radiusOf(position)
	if r < Biomes.TOWN_RADIUS or r > Biomes.WORLD_RADIUS then
		return nil
	end
	for _, biome in Biomes.list do
		if Biomes.contains(biome, position) then
			return biome
		end
	end
	return nil
end

-- The bazaar sector a position is in (in the town ring), or nil.
function Biomes.townSectorAt(position: Vector3)
	local r = Biomes.radiusOf(position)
	if r < Biomes.HUB_RADIUS or r > Biomes.TOWN_RADIUS then
		return nil
	end
	local angle = Biomes.angleOf(position)
	for _, sector in Biomes.TOWN_SECTORS do
		if math.abs(Biomes.angleDiff(angle, sector.angle)) <= 30 then
			return sector
		end
	end
	return nil
end

-- The gate into a zone: its angle (degrees) and radius (on the wall it is in).
function Biomes.gate(biome: Biome): (number, number)
	local mid = biome.angle :: number
	if biome.ring == 1 then
		return mid, Biomes.TOWN_RADIUS
	elseif biome.ring == 2 then
		return mid + 30, Biomes.RINGS[2][1]
	end
	return mid - 30, Biomes.RINGS[3][1]
end

-- The shortcut doors between neighbouring regions: one in every ring, on the
-- fence between region i and the next one clockwise.
function Biomes.shortcuts(): { { angle: number, radius: number, a: Biome, b: Biome } }
	local list = {}
	for i, region in Biomes.REGIONS do
		local nextRegion = Biomes.REGIONS[i % #Biomes.REGIONS + 1]
		for ring, span in Biomes.RINGS do
			table.insert(list, {
				angle = region.angle + Biomes.SPAN,
				radius = (span[1] + span[2]) / 2,
				a = Biomes.byRegion[region.id][ring],
				b = Biomes.byRegion[nextRegion.id][ring],
			})
		end
	end
	return list
end

-- The angle of haveli `index` (1-8) around the Chowk; it faces the middle.
-- The havelis sit between the 4 roads that lead out to the regions.
function Biomes.haveliAngle(index: number): number
	return math.rad(-67.5 + 45 * (index - 1))
end

---------------------------------------------------------------------------
-- Roads: from the Chowk out through the town gates, then zigzagging from
-- gate to gate through each region, and the bazaar street round the town.
---------------------------------------------------------------------------
Biomes.ROAD_WIDTH = 16
Biomes.BAZAAR_STREET = 245 -- the radius of the street round the bazaar

export type Road = { a: Vector3, b: Vector3, width: number, kind: string }

local roadCache: { Road }? = nil

function Biomes.roads(): { Road }
	if roadCache then
		return roadCache
	end
	local list: { Road } = {}
	local function add(a: Vector3, b: Vector3, width: number?, kind: string)
		table.insert(list, { a = a, b = b, width = width or Biomes.ROAD_WIDTH, kind = kind })
	end
	for _, region in Biomes.REGIONS do
		local mid = region.angle
		local zones = Biomes.byRegion[region.id]
		add(Biomes.polar(mid, Biomes.PLAZA_RADIUS - 4), Biomes.polar(mid, Biomes.TOWN_RADIUS), nil, "spoke")
		local a1, r1 = Biomes.gate(zones[2])
		local a2, r2 = Biomes.gate(zones[3])
		local p0, p1, p2 = Biomes.polar(mid, Biomes.TOWN_RADIUS), Biomes.polar(a1, r1), Biomes.polar(a2, r2)
		add(p0, p1, nil, "zone")
		add(p1, p2, nil, "zone")
		add(p2, Biomes.roadEnd(zones[3]), nil, "zone")
		-- an alley into the bazaar between this region and the next
		add(
			Biomes.polar(mid + Biomes.SPAN, Biomes.PLAZA_RADIUS - 4),
			Biomes.polar(mid + Biomes.SPAN, Biomes.HUB_RADIUS + 8),
			12,
			"alley"
		)
	end
	local steps = 48
	for i = 0, steps - 1 do
		add(
			Biomes.polar(i * 360 / steps, Biomes.BAZAAR_STREET),
			Biomes.polar((i + 1) * 360 / steps, Biomes.BAZAAR_STREET),
			18,
			"street"
		)
	end
	roadCache = list
	return list
end

-- Where the road ends in a ring 3 zone (the rickshaw stand that takes you home).
function Biomes.roadEnd(biome: Biome): Vector3
	return Biomes.polar(biome.angle :: number, Biomes.WORLD_RADIUS - 45)
end

-- How far a position is from the nearest road's edge (negative = on the road).
function Biomes.roadDistance(position: Vector3): number
	local best = math.huge
	local p = Vector3.new(position.X, 0, position.Z)
	for _, road in Biomes.roads() do
		local a = Vector3.new(road.a.X, 0, road.a.Z)
		local ab = Vector3.new(road.b.X, 0, road.b.Z) - a
		local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
		local d = (p - (a + ab * t)).Magnitude - road.width / 2
		if d < best then
			best = d
		end
	end
	return best
end

-- Petrol pumps: one in the bazaar by every town gate, and one by every gate
-- out of ring 1 and ring 2, a little way off the road.
function Biomes.pumps(): { Vector3 }
	local list = {}
	for _, region in Biomes.REGIONS do
		local zones = Biomes.byRegion[region.id]
		local a1 = Biomes.gate(zones[2])
		local a2 = Biomes.gate(zones[3])
		table.insert(list, Biomes.polar(region.angle + 10, 272))
		table.insert(list, Biomes.polar(a1 + 6, 425))
		table.insert(list, Biomes.polar(a2 - 7, 530))
	end
	return list
end

---------------------------------------------------------------------------
-- The train in Railway Junction. It waits at one end, the crossing light
-- blinks, then it runs the curved track to the other end, and back again.
-- The server and every player's screen work out where it is from the clock,
-- so it is smooth everywhere and costs nothing to send.
---------------------------------------------------------------------------
Biomes.TRAIN = { zone = "RailwayJunction", radius = 372, from = -40, to = 40, length = 40 }

-- The train's angle (degrees), whether it is moving, the crossing light
-- ("green", "blink" or "red") and which way it faces (1 or -1) at server time `t`.
function Biomes.trainAt(t: number, wait: number, blink: number, speed: number): (number, boolean, string, number)
	local train = Biomes.TRAIN
	local mid = Biomes.byId[train.zone].angle :: number
	local from, to = mid + train.from, mid + train.to
	local runTime = (to - from) * math.pi * train.radius / 180 / speed
	local half = wait + blink + runTime
	local phase = t % (2 * half)
	local outward = phase < half
	local p = phase % half
	local start, finish = if outward then from else to, if outward then to else from
	local dir = if outward then 1 else -1
	if p < wait then
		return start, false, "green", dir
	elseif p < wait + blink then
		return start, false, "blink", dir
	end
	return start + (finish - start) * (p - wait - blink) / runTime, true, "red", dir
end

---------------------------------------------------------------------------
-- Unlocking
---------------------------------------------------------------------------
-- Is the zone open to a player with these unlocked zones and rebirths?
function Biomes.isOpen(biome: Biome, unlocked: { [string]: boolean }, rebirths: number): boolean
	if biome.rebirths > 0 then
		return rebirths >= biome.rebirths
	end
	return biome.price == 0 or unlocked[biome.id] == true
end

-- The zone you must have open before this one (the next ring in, same region).
function Biomes.before(biome: Biome): Biome?
	if biome.ring == 1 then
		return nil
	end
	return Biomes.byRegion[biome.region][biome.ring - 1]
end

-- What the gate costs, as text: "Free", "Rs 10,000" or "1 rebirth".
function Biomes.costText(biome: Biome): string
	if biome.rebirths > 0 then
		return ("%d rebirth%s"):format(biome.rebirths, if biome.rebirths == 1 then "" else "s")
	elseif biome.price == 0 then
		return "Free"
	end
	local text = tostring(biome.price):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return "Rs " .. text
end

-- Unlocked zones as "MangoBagh,RailwayJunction" for player attributes.
function Biomes.encode(unlocked: { [string]: boolean }): string
	local ids = {}
	for _, biome in Biomes.list do
		if unlocked[biome.id] then
			table.insert(ids, biome.id)
		end
	end
	return table.concat(ids, ",")
end

function Biomes.decode(text: string?): { [string]: boolean }
	local unlocked = {}
	for id in string.gmatch(text or "", "[^,]+") do
		unlocked[id] = true
	end
	return unlocked
end

return Biomes
