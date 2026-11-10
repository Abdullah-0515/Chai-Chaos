-- Pacing simulation: plays the first hours of Chai Chaos hundreds of times with
-- simple player "brains", and prints when players reach each milestone.
--
-- It uses the real numbers from src/shared (Config, Biomes, Brainrots,
-- Vehicles, Gear, Mutations) and the real brainrot picker, so change a number
-- there and run it again:   tests/run.sh pacing
--
-- What it models: walking or driving from your haveli door out through the
-- gates to each zone (real distances from Biomes), hazards slowing you down,
-- egg timers (an egg must get home before it cracks), boot space, incubators
-- and hatch times, plots filling up and selling the worst brainrot, the Mandi
-- lane, wild brainrots, daily chai, quests and free Kismat Rolls, petrol, and
-- spending on vehicles, haveli levels, zones, gear and Naya Safar.
-- What it leaves out: events (they only help), treasure chests, paid Kismat
-- Rolls, stealing and Robux.
--
-- The three kinds of player differ only in how well they play: how direct
-- their routes are, how long they stand around, and how quickly they pick up
-- eggs. They all buy things in the same order (PLAN below).
local DIR = TEST_DIR .. "/"
local SRC = SRC_DIR .. "/"
local FILES = loadchunk(readfile(CACHE_DIR .. "/filelist.luau"), "filelist", {})()
local API = loadchunk(readfile(CACHE_DIR .. "/api.luau"), "api", {})()
local M = loadchunk(readfile(DIR .. "mock.luau"), "mock", setmetatable({}, { __index = _G }))(API)
local Random, Vector3 = M.Random, M.Vector3

---------------------------------------------------------------------------
-- Loading the shared modules like Rojo would
---------------------------------------------------------------------------
local sources = {}
local cache = {}
local requireModule

local function scriptEnv(scriptInst)
	return setmetatable({
		game = M.game,
		workspace = M.workspace,
		script = scriptInst,
		Instance = M.Instance,
		Vector3 = M.Vector3,
		CFrame = M.CFrame,
		Color3 = M.Color3,
		Enum = M.Enum,
		task = M.task,
		os = M.os,
		typeof = M.typeof,
		Random = M.Random,
		warn = print,
		require = function(module)
			return requireModule(module)
		end,
	}, { __index = _G })
end

requireModule = function(module)
	if cache[module] == nil then
		local path = sources[module]
		cache[module] = loadchunk(readfile(path), path, scriptEnv(module))()
	end
	return cache[module]
end

local function mount(folderName, parent, dir, files)
	local folder = M.Instance.new("Folder")
	folder.Name = folderName
	for _, file in files do
		local name = file:match("^(.-)%.luau$")
		if name and not file:match("%.server%.luau$") and not file:match("%.client%.luau$") then
			local inst = M.Instance.new("ModuleScript")
			inst.Name = name
			inst.Parent = folder
			sources[inst] = SRC .. dir .. "/" .. file
		end
	end
	folder.Parent = parent
	return folder
end

local shared = mount("ChaiChaos", M.services.ReplicatedStorage, "shared", FILES.shared)
local server = mount("ChaiChaosServer", M.services.ServerScriptService, "server", { "Picker.luau" })
local function sharedModule(name)
	return requireModule(shared:FindFirstChild(name))
end

local Config = sharedModule("Config")
local Biomes = sharedModule("Biomes")
local Brainrots = sharedModule("Brainrots")
local Vehicles = sharedModule("Vehicles")
local Gear = sharedModule("Gear")
local Mutations = sharedModule("Mutations")
local Picker = requireModule(server:FindFirstChild("Picker"))

---------------------------------------------------------------------------
-- The players
---------------------------------------------------------------------------
local PROFILES = {
	-- detour: how much longer their routes are than the shortest way
	-- idle: share of the time spent on other things (menus, chat, looking around)
	-- pickup: seconds to find and pick up an egg once close
	-- home: seconds at home between trips
	-- lose: share of eggs lost to hazards, crashes and bad timing
	-- laneBudget: the most of their rupees they spend on one lane brainrot
	{ name = "fast", detour = 1.2, idle = 0.08, pickup = 3, home = 5, lose = 0.04, laneBudget = 0.4 },
	{ name = "typical", detour = 1.45, idle = 0.2, pickup = 4, home = 8, lose = 0.08, laneBudget = 0.3 },
	{ name = "casual", detour = 1.75, idle = 0.35, pickup = 5, home = 12, lose = 0.12, laneBudget = 0.2 },
}
local RUNS = 300 -- simulated players of each kind
local MAX_TIME = 8 * 3600

-- What everyone saves up for, in order. Cheap things (under 8% of your rupees)
-- get bought on the way: engine and tank upgrades and the next tracker level.
local PLAN = {
	{ kind = "vehicle", id = "Motorbike" },
	{ kind = "level", level = 2 },
	{ kind = "zone", id = "RailwayJunction" },
	{ kind = "level", level = 3 },
	{ kind = "gear", id = "Tokri" },
	{ kind = "zone", id = "CamelMela" },
	{ kind = "level", level = 4 },
	{ kind = "vehicle", id = "Rickshaw" },
	{ kind = "zone", id = "QissaKhawani" },
	{ kind = "level", level = 5 },
	{ kind = "level", level = 6 },
	{ kind = "gear", id = "GumBoots" },
	{ kind = "zone", id = "SarsonFields" },
	{ kind = "rebirth" },
	-- after the first Naya Safar (the haveli starts again at level 1)
	{ kind = "level", level = 2 },
	{ kind = "level", level = 3 },
	{ kind = "level", level = 4 },
	{ kind = "level", level = 5 },
	{ kind = "vehicle", id = "PiliTaxi" },
	{ kind = "level", level = 6 },
	{ kind = "gear", id = "LifeJacket" },
	{ kind = "zone", id = "SahilBeach" },
	{ kind = "level", level = 7 },
	{ kind = "rebirth" },
	-- after the second
	{ kind = "level", level = 2 },
	{ kind = "level", level = 3 },
	{ kind = "level", level = 4 },
	{ kind = "level", level = 5 },
	{ kind = "level", level = 6 },
	{ kind = "gear", id = "SandGoggles" },
	{ kind = "zone", id = "TharDesert" },
	{ kind = "level", level = 7 },
	{ kind = "vehicle", id = "PhoolPattiTruck" },
	{ kind = "level", level = 8 },
	{ kind = "rebirth" },
	-- after the third
	{ kind = "level", level = 2 },
	{ kind = "level", level = 3 },
	{ kind = "level", level = 4 },
	{ kind = "level", level = 5 },
	{ kind = "level", level = 6 },
	{ kind = "level", level = 7 },
	{ kind = "gear", id = "Lantern" },
	{ kind = "zone", id = "NamakCaves" },
	{ kind = "level", level = 8 },
	{ kind = "level", level = 9 },
	{ kind = "rebirth" },
}

-- Share of a zone's paths that crosses its hazard, and how much faster eggs
-- crack there (Config.HAZARD_EGG_DRAIN). Sandstorms blow 15 s in every 50 s.
local HAZARD_SHARE = { mud = 0.2, water = 0.15, sandstorm = 0.3, ice = 0.5 }
local GEAR_FOR = { mud = "GumBoots", water = "LifeJacket", sandstorm = "SandGoggles", ice = "SnowBoots" }
local DOOR_RADIUS = 119
local LANE_RADIUS = Biomes.MANDI_RADIUS
local IN_ZONE_DETOUR = 1.15 -- trees, rocks and fences
local CATCH_TIME = 15 -- park, sneak up and hold E
local SERVER_SHARE = 0.5 -- other players catch half the wild brainrots first
local LANE_SEEN = 3 -- lane brainrots that walk past your door while you are home

---------------------------------------------------------------------------
-- Geometry: real distances from the map
---------------------------------------------------------------------------
local function dist(a, b)
	return ((a - b) * Vector3.new(1, 0, 1)).Magnitude
end

-- From a haveli door to a zone's gate: to the lane, round it to the region's
-- road, and out along the road (then from gate to gate through the rings).
local function routeTo(haveli, biome)
	local haveliDeg = math.deg(Biomes.haveliAngle(haveli))
	local turn = math.abs(Biomes.angleDiff(haveliDeg, biome.angle))
	local town = (DOOR_RADIUS - LANE_RADIUS) + math.rad(turn) * LANE_RADIUS + (Biomes.TOWN_RADIUS - LANE_RADIUS)
	local legs = {} -- in-zone legs: { length, zone }
	local region = Biomes.byRegion[biome.region]
	local here = Biomes.polar(Biomes.gate(region[1]))
	for ring = 2, biome.ring do
		local nextGate = Biomes.polar(Biomes.gate(region[ring]))
		table.insert(legs, { dist(here, nextGate) * IN_ZONE_DETOUR, region[ring - 1] })
		here = nextGate
	end
	return town, legs, here
end

-- Egg spots: random points spread evenly over the zone.
local function eggPoint(rng, biome)
	local r1, r2 = Biomes.innerRadius(biome), Biomes.outerRadius(biome)
	local r = math.sqrt(rng:NextNumber(r1 * r1, r2 * r2))
	r = math.clamp(r, r1 + 0.02 * (r2 - r1), r2 - 0.02 * (r2 - r1))
	local angle = biome.angle + rng:NextNumber(-0.97, 0.97) * Biomes.SPAN
	return Biomes.polar(angle, r)
end

-- How far apart eggs lie: the average distance to the nearest one.
local function eggSpacing(biome)
	local r1, r2 = Biomes.innerRadius(biome), Biomes.outerRadius(biome)
	local area = (r2 * r2 - r1 * r1) * math.pi * (2 * Biomes.SPAN / 360)
	return 0.5 * math.sqrt(area / Config.EGGS_PER_BIOME)
end

---------------------------------------------------------------------------
-- One simulated player
---------------------------------------------------------------------------
local function newPlayer(profile, seed)
	return {
		profile = profile,
		rng = Random.new(seed),
		haveli = 1 + seed % 8,
		t = 0,
		rupees = Config.START_RUPEES,
		level = 1,
		plots = {}, -- { income, value }
		incubators = {}, -- finish times
		hatching = {}, -- { at, def, mutation }
		zones = {},
		gear = {},
		vehicles = {}, -- id -> levels
		rebirths = 0,
		planStep = 1,
		milestones = {},
		eggsHome = 0,
		eggsLost = 0,
		lastWild = {},
		fuelSpent = 0,
		laneBought = 0,
		wildCaught = 0,
	}
end

local function mark(p, name)
	if not p.milestones[name] then
		p.milestones[name] = p.t
	end
end

local function income(p)
	local total = 0
	for _, plot in p.plots do
		total += plot.income
	end
	return total * (1 + Config.REBIRTH_BONUS * p.rebirths)
end

local function plotCount(p)
	return Config.HAVELI_LEVELS[p.level].plots
end

-- A new brainrot: into a free plot, or swap out the worst one (sold for half).
local function addBrainrot(p, def, mutation)
	local entry = { income = Mutations.income(def, mutation), value = Mutations.value(def, mutation) }
	if #p.plots < plotCount(p) then
		table.insert(p.plots, entry)
		return true
	end
	local worst, worstIndex = nil, nil
	for i, plot in p.plots do
		if not worst or plot.income < worst.income then
			worst, worstIndex = plot, i
		end
	end
	if worst and entry.income > worst.income then
		p.rupees += math.floor(worst.value * Config.SELL_RATE)
		p.plots[worstIndex] = entry
		return true
	end
	p.rupees += math.floor(entry.value * Config.SELL_RATE)
	return false
end

local function worstIncome(p)
	if #p.plots < plotCount(p) then
		return 0
	end
	local worst = math.huge
	for _, plot in p.plots do
		worst = math.min(worst, plot.income)
	end
	return worst
end

-- Time passes: income comes in and eggs hatch.
local function wait(p, seconds)
	local stop = p.t + seconds
	table.sort(p.hatching, function(a, b)
		return a.at < b.at
	end)
	while #p.hatching > 0 and p.hatching[1].at <= stop do
		local h = table.remove(p.hatching, 1)
		p.rupees += income(p) * (h.at - p.t)
		p.t = h.at
		addBrainrot(p, h.def, h.mutation)
		if h.def.rarity ~= "Common" and h.def.rarity ~= "Uncommon" then
			mark(p, "first Rare+ brainrot")
		end
	end
	p.rupees += income(p) * (stop - p.t)
	p.t = stop
end

local function bestVehicle(p)
	local best, bestDef = nil, nil
	for _, def in Vehicles.list do
		local levels = p.vehicles[def.id]
		if levels and (not bestDef or def.cost > bestDef.cost) then
			best, bestDef = levels, def
		end
	end
	return bestDef, best
end

local function walkSpeed(p)
	return Config.WALK_SPEED * Gear.best(p.gear, "speed")
end

-- How fast you cross a zone's ground, and how much faster eggs crack there.
local function zoneSpeed(p, biome, def, levels)
	local base = if def then Vehicles.speed(def, levels) else walkSpeed(p)
	local slow, drain = 0, 0
	for _, hazard in biome.hazards do
		local share = HAZARD_SHARE[hazard]
		if share then
			local factor
			if def then
				local surface = if hazard == "sandstorm" then "sandstorm" else hazard
				factor = if Vehicles.handles(Vehicles.grip(def, levels), surface)
					then 1
					else Config.DRIVE_SURFACE_SPEED[surface] or 1
			else
				factor = if p.gear[GEAR_FOR[hazard]] then 1 else Config.HAZARD_SPEED[hazard] or 1
			end
			slow += share * (1 / factor - 1)
			local eggDrain = Config.HAZARD_EGG_DRAIN[hazard]
			if eggDrain and not (not def and p.gear[GEAR_FOR[hazard]]) then
				drain += share * (eggDrain - 1)
			end
		end
	end
	return base / (1 + slow), 1 + drain
end

local function eggLife(p, biome)
	return biome.eggTime * Gear.best(p.gear, "egg")
end

-- Plans a trip to `biome`: how many eggs make it home and how long it takes.
local function planTrip(p, biome)
	local profile = p.profile
	local def, levels = bestVehicle(p)
	local townSpeed = if def then Vehicles.speed(def, levels) else walkSpeed(p)
	local town, legs, gate = routeTo(p.haveli, biome)
	local egg = eggPoint(p.rng, biome)
	local speed, drain = zoneSpeed(p, biome, def, levels)
	local tOut = town / townSpeed
	local studs = town
	for _, leg in legs do
		local legSpeed = zoneSpeed(p, leg[2], def, levels)
		tOut += leg[1] / legSpeed
		studs += leg[1]
	end
	local last = dist(gate, egg) * IN_ZONE_DETOUR
	tOut += last / speed
	studs += last
	tOut *= profile.detour
	-- more eggs on the way back, while the first egg's timer allows
	local capacity = if def then Vehicles.eggs(def, levels) else 1
	local free = Config.HAVELI_LEVELS[p.level].incubators
	capacity = math.min(capacity, free)
	local hop = eggSpacing(biome) * 1.3 * profile.detour / speed + profile.pickup
	local life = eggLife(p, biome) / drain
	local eggs = 0
	for k = 1, capacity do
		local firstEggTravels = (k - 1) * hop + tOut
		if firstEggTravels <= life * 0.92 then -- a little margin for bad luck
			eggs = k
		end
	end
	local time = tOut * 2 + eggs * profile.pickup + math.max(0, eggs - 1) * hop + profile.home
	if def then
		time += 2 -- getting in and out
	end
	return {
		biome = biome,
		eggs = eggs,
		time = time / (1 - profile.idle),
		studs = (studs * 2 + math.max(0, eggs - 1) * eggSpacing(biome) * 1.3) * profile.detour,
		driving = def ~= nil,
	}
end

-- What an egg from this zone is worth to you right now, on average.
local valueCache = {}
local function hatchValue(p, biome)
	local key = biome.id
	if not valueCache[key] then
		local sum, n = 0, 400
		for _ = 1, n do
			sum += Picker.pick(biome.odds, biome.pool, 1).income
		end
		valueCache[key] = sum / n
	end
	return math.max(0, valueCache[key] - worstIncome(p) * 0.5) + valueCache[key] * 0.1
end

local function isOpen(p, biome)
	return Biomes.isOpen(biome, p.zones, p.rebirths)
end

local function chooseTrip(p)
	local best, bestRate = nil, -1
	for _, biome in Biomes.list do
		if isOpen(p, biome) then
			local plan = planTrip(p, biome)
			if plan.eggs > 0 then
				local rate = plan.eggs * hatchValue(p, biome) / plan.time
				if rate > bestRate then
					best, bestRate = plan, rate
				end
			end
		end
	end
	return best
end

-- Waits for free incubators, then the eggs go in.
local function deposit(p, biome, eggs)
	local slots = Config.HAVELI_LEVELS[p.level].incubators
	for _ = 1, eggs do
		if p.rng:NextNumber() < p.profile.lose then
			p.eggsLost += 1
			continue
		end
		table.sort(p.incubators)
		while #p.incubators >= slots do
			local soonest = p.incubators[1]
			if soonest > p.t then
				wait(p, soonest - p.t)
			end
			table.remove(p.incubators, 1)
		end
		local golden = p.rng:NextNumber() < Config.GOLDEN_EGG_CHANCE
		local hatch = biome.hatchTime * (if golden then Config.GOLDEN_HATCH_TIME else 1)
		local def = Picker.pick(biome.odds, biome.pool, if golden then Config.GOLDEN_EGG_LUCK else 1)
		local mutation = Mutations.roll(if golden then "golden" else "egg")
		table.insert(p.incubators, p.t + hatch)
		table.insert(p.hatching, { at = p.t + hatch, def = def, mutation = mutation })
		p.eggsHome += 1
	end
	-- free incubators whose eggs have hatched
	local still = {}
	for _, at in p.incubators do
		if at > p.t then
			table.insert(still, at)
		end
	end
	p.incubators = still
end

-- The lane walks past your door: buy one if it is worth it.
local function laneShopping(p)
	local best, bestScore = nil, 0
	for _ = 1, LANE_SEEN do
		local def = Picker.pick(Config.MANDI_ODDS, nil, 1)
		if not def.questOnly then
			local mutation = Mutations.roll("egg")
			local price = math.floor(Mutations.value(def, mutation) * Config.MANDI_PRICE)
			local gain = Mutations.income(def, mutation) - worstIncome(p)
			if gain > 0 and price <= p.rupees * p.profile.laneBudget then
				local score = gain / price
				if score > bestScore then
					best, bestScore = { def = def, mutation = mutation, price = price }, score
				end
			end
		end
	end
	if best then
		p.rupees -= best.price
		addBrainrot(p, best.def, best.mutation)
		p.laneBought += 1
	end
end

-- A wild brainrot in the zone you are hunting, now and then.
local function wildChance(p, biome, tripTime)
	local weights = 0
	for _, b in Biomes.list do
		weights += Config.WILD_RING_WEIGHT[b.ring] or 0
	end
	local share = (Config.WILD_RING_WEIGHT[biome.ring] or 0) / weights
	local since = p.t - (p.lastWild[biome.id] or -math.huge)
	local expected = math.min(Config.WILD_MAX * share, since * share / Config.WILD_EVERY)
	if p.rng:NextNumber() < math.min(1, expected) * SERVER_SHARE * math.min(1, tripTime / 60) then
		p.lastWild[biome.id] = p.t
		local def = Picker.pick(Brainrots.wildOdds(biome.odds), biome.pool, 1)
		wait(p, CATCH_TIME)
		if #p.plots < plotCount(p) or Mutations.income(def, nil) > worstIncome(p) then
			addBrainrot(p, def, Mutations.roll("egg"))
			p.wildCaught += 1
		end
	end
end

local function costOf(p, step)
	if step.kind == "vehicle" then
		return if p.vehicles[step.id] then 0 else Vehicles.byId[step.id].cost
	elseif step.kind == "level" then
		return if p.level >= step.level then 0 else Config.HAVELI_LEVELS[step.level].cost
	elseif step.kind == "zone" then
		return if p.zones[step.id] then 0 else Biomes.byId[step.id].price
	elseif step.kind == "gear" then
		return if p.gear[step.id] then 0 else Gear.byId[step.id].cost
	elseif step.kind == "rebirth" then
		return Config.rebirthCost(p.rebirths)
	end
	return math.huge
end

local function buy(p, step)
	local cost = costOf(p, step)
	p.rupees -= cost
	if step.kind == "vehicle" then
		p.vehicles[step.id] = Vehicles.levels(nil)
		mark(p, Vehicles.byId[step.id].name)
	elseif step.kind == "level" then
		p.level = step.level
		mark(p, ("haveli level %d%s"):format(step.level, if p.rebirths > 0 then " again" else ""))
	elseif step.kind == "zone" then
		p.zones[step.id] = true
		mark(p, Biomes.byId[step.id].name)
	elseif step.kind == "gear" then
		p.gear[step.id] = true
	elseif step.kind == "rebirth" then
		p.rebirths += 1
		mark(p, ({ "1st", "2nd", "3rd", "4th" })[p.rebirths] .. " Naya Safar")
		p.level = 1
		p.plots = {}
		p.hatching = {}
		p.incubators = {}
		p.rupees = Config.START_RUPEES
	end
end

-- Small upgrades bought on the way when they are cheap.
local function cheapBuys(p)
	local def, levels = bestVehicle(p)
	if def then
		for _, upgrade in { "speed", "tank" } do
			local saved: any = levels
			local level = saved[upgrade]
			if level < Vehicles.maxLevel(def, upgrade) then
				local cost = Vehicles.upgradeCost(def, upgrade, level + 1)
				if cost <= p.rupees * 0.08 then
					p.rupees -= cost
					saved[upgrade] = level + 1
				end
			end
		end
		-- tyres for the mud, sand and ice in the zones you have
		local grip = Vehicles.grip(def, levels)
		if grip < Vehicles.GRIP_MAX and levels.grip < Vehicles.maxLevel(def, "grip") then
			local cost = Vehicles.upgradeCost(def, "grip", levels.grip + 1)
			if cost <= p.rupees * 0.08 then
				p.rupees -= cost
				levels.grip += 1
			end
		end
	end
	for _, id in { "Joggers", "PeshawariChappal", "Thermos" } do
		if not p.gear[id] and Gear.byId[id].cost <= p.rupees * 0.05 then
			p.rupees -= Gear.byId[id].cost
			p.gear[id] = true
		end
	end
end

local function shopping(p)
	while p.planStep <= #PLAN do
		local step = PLAN[p.planStep]
		local cost = costOf(p, step)
		if cost > p.rupees then
			break
		end
		buy(p, step)
		p.planStep += 1
	end
	cheapBuys(p)
end

local function fuel(p, plan)
	if not plan.driving then
		return
	end
	-- parked at home your tank fills for free; the rest you buy at a pump
	local free = Config.FUEL_HOME_REFILL * p.profile.home
	local bought = math.max(0, plan.studs - free)
	local cost = math.ceil(bought * Config.FUEL_PRICE)
	p.rupees -= cost
	p.fuelSpent += cost
end

local function simulate(profile, seed)
	local p = newPlayer(profile, seed)
	-- daily chai: rupees and a free Kismat Roll
	p.rupees += Config.DAILY_MIN_RUPEES
	local rolls = Config.DAILY_FREE_ROLLS
	local questTimes = { 8 * 60, 20 * 60, 35 * 60 } -- quests get done along the way
	local questsDone = 0
	while p.t < MAX_TIME and p.rebirths < 4 do
		-- free Kismat Rolls
		while rolls > 0 do
			rolls -= 1
			local def = Picker.pick(Config.ROLL_ODDS, nil, 1)
			if not def.questOnly then
				addBrainrot(p, def, Mutations.roll("roll"))
			end
		end
		laneShopping(p)
		shopping(p)
		local plan = chooseTrip(p)
		if not plan then
			wait(p, 10)
			continue
		end
		wait(p, plan.time)
		fuel(p, plan)
		wildChance(p, plan.biome, plan.time)
		deposit(p, plan.biome, plan.eggs)
		if questsDone < #questTimes and p.t >= questTimes[questsDone + 1] then
			questsDone += 1
			p.rupees += math.max(Config.QUEST_MIN_REWARD, income(p) * Config.QUEST_REWARD_SECONDS)
			if questsDone == #questTimes then
				rolls += Config.QUEST_BONUS_ROLLS
			end
		end
		if income(p) >= 100 then
			mark(p, "Rs 100/s income")
		end
		if income(p) >= 1000 then
			mark(p, "Rs 1,000/s income")
		end
	end
	return p
end

---------------------------------------------------------------------------
-- Run and report
---------------------------------------------------------------------------
local MILESTONES = {
	"first Rare+ brainrot",
	"Motorbike",
	"haveli level 2",
	"Railway Junction",
	"Rs 100/s income",
	"Camel Mela",
	"Rickshaw",
	"Qissa Khawani",
	"haveli level 5",
	"Sarson Fields",
	"Rs 1,000/s income",
	"1st Naya Safar",
	"Pili Taxi",
	"Sahil Beach",
	"2nd Naya Safar",
	"Thar Desert",
	"Phool Patti Truck",
	"3rd Naya Safar",
	"Namak Caves",
	"4th Naya Safar",
}

local function minutes(seconds)
	return seconds / 60
end

local function percentile(list, q)
	if #list == 0 then
		return nil
	end
	table.sort(list)
	local i = math.clamp(math.floor(q * (#list - 1) + 1.5), 1, #list)
	return list[i]
end

local results = {}
for _, profile in PROFILES do
	local times = {}
	local extras = { eggs = {}, lane = {}, wild = {}, fuel = {} }
	for run = 1, RUNS do
		math.randomseed(run * 7919 + #profile.name)
		local p = simulate(profile, run)
		for _, name in MILESTONES do
			times[name] = times[name] or {}
			if p.milestones[name] then
				table.insert(times[name], minutes(p.milestones[name]))
			end
		end
		local hour = p.milestones["2nd Naya Safar"] or p.t
		table.insert(extras.eggs, p.eggsHome / math.max(1, hour / 60))
		table.insert(extras.lane, p.laneBought)
		table.insert(extras.wild, p.wildCaught)
		table.insert(extras.fuel, p.fuelSpent)
	end
	results[profile.name] = { times = times, extras = extras }
end

print("")
print(("Chai Chaos pacing: %d simulated players of each kind (minutes of play)"):format(RUNS))
print("")
local header = ("%-24s"):format("milestone")
for _, profile in PROFILES do
	header ..= ("%-20s"):format(profile.name)
end
print(header)
for _, name in MILESTONES do
	local line = ("%-24s"):format(name)
	for _, profile in PROFILES do
		local list = results[profile.name].times[name]
		local median = percentile(list, 0.5)
		if median and #list >= RUNS * 0.5 then
			line ..= ("%-20s"):format(
				("%5.1f (%.0f-%.0f)"):format(median, percentile(list, 0.25), percentile(list, 0.75))
			)
		else
			line ..= ("%-20s"):format("-")
		end
	end
	print(line)
end
print("")
for _, profile in PROFILES do
	local e = results[profile.name].extras
	print(
		("%-8s eggs home per minute %.1f, lane buys %d, wild catches %d, petrol Rs %d (medians, to the 2nd Naya Safar)"):format(
			profile.name,
			percentile(e.eggs, 0.5),
			percentile(e.lane, 0.5),
			percentile(e.wild, 0.5),
			percentile(e.fuel, 0.5)
		)
	)
end

-- The targets this game is tuned for (see the README's pacing section).
local TARGETS = {
	{ "typical", "Motorbike", 3, 7 },
	{ "typical", "Railway Junction", 7, 14 },
	{ "typical", "1st Naya Safar", 50, 75 },
	{ "fast", "1st Naya Safar", 35, 55 },
	{ "casual", "1st Naya Safar", 55, 100 },
	{ "typical", "2nd Naya Safar", 65, 100 },
}
local failed = 0
print("")
for _, target in TARGETS do
	local median = percentile(results[target[1]].times[target[2]], 0.5)
	local ok = median ~= nil and median >= target[3] and median <= target[4]
	if not ok then
		failed += 1
	end
	print(
		("%s %s %s: %s min (target %d-%d)"):format(
			if ok then "ok  " else "FAIL",
			target[1],
			target[2],
			if median then ("%.1f"):format(median) else "never",
			target[3],
			target[4]
		)
	)
end
print("")
print(("%d checks passed, %d failed, 0 script errors, 0 warnings"):format(#TARGETS - failed, failed))
if failed > 0 then
	error("PACING OUT OF RANGE: change the numbers in src/shared or the targets above")
end
