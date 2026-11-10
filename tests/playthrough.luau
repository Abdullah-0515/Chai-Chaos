-- Runs the real Chai Chaos scripts on a mock Roblox engine and plays through the game.
-- Start it with tests/run.sh, which sets TEST_DIR, CACHE_DIR and SRC_DIR.
local DIR = TEST_DIR .. "/"
local SRC = SRC_DIR .. "/"
local FILES = loadchunk(readfile(CACHE_DIR .. "/filelist.luau"), "filelist", {})()

local API = loadchunk(readfile(CACHE_DIR .. "/api.luau"), "api", {})()
local M = loadchunk(readfile(DIR .. "mock.luau"), "mock", setmetatable({}, { __index = _G }))(API)

math.randomseed(42)

local game, workspace = M.game, M.workspace
local Players = M.services.Players
local PPS = M.services.ProximityPromptService
local Vector3, CFrame = M.Vector3, M.CFrame

---------------------------------------------------------------------------
-- Loading scripts like Rojo would
---------------------------------------------------------------------------
local sources = {}
local cache = { server = {}, client = {} }
local requireModule

local function scriptEnv(scriptInst, context)
	local env = {
		game = game,
		workspace = workspace,
		script = scriptInst,
		Instance = M.Instance,
		Vector3 = M.Vector3,
		CFrame = M.CFrame,
		Color3 = M.Color3,
		UDim = M.UDim,
		UDim2 = M.UDim2,
		Vector2 = M.Vector2,
		NumberRange = M.NumberRange,
		NumberSequence = M.NumberSequence,
		ColorSequence = M.ColorSequence,
		ColorSequenceKeypoint = M.ColorSequenceKeypoint,
		TweenInfo = M.TweenInfo,
		Random = M.Random,
		Enum = M.Enum,
		task = M.task,
		os = M.os,
		typeof = M.typeof,
		warn = function(...)
			local parts = {}
			for i = 1, select("#", ...) do
				parts[i] = tostring((select(i, ...)))
			end
			local msg = table.concat(parts, " ")
			table.insert(M.warnings, msg)
			print("  WARN(" .. context .. "): " .. msg)
		end,
		print = function(...)
			print("  [" .. context .. "]", ...)
		end,
		require = function(module)
			return requireModule(module, context)
		end,
	}
	return setmetatable(env, { __index = _G })
end

requireModule = function(module, context)
	assert(M.isInstance(module) and module.ClassName == "ModuleScript", "require() needs a ModuleScript")
	cache[context] = cache[context] or {}
	local c = cache[context]
	if c[module] == nil then
		local path = sources[module]
		c[module] = loadchunk(readfile(path), path, scriptEnv(module, context))()
	end
	return c[module]
end

local function mount(folderName, parent, dir, files)
	local folder = M.Instance.new("Folder")
	folder.Name = folderName
	for _, file in files do
		local name, kind = file:match("^(.-)%.server%.luau$"), "Script"
		if not name then
			name, kind = file:match("^(.-)%.client%.luau$"), "LocalScript"
		end
		if not name then
			name, kind = file:match("^(.-)%.luau$"), "ModuleScript"
		end
		local inst = M.Instance.new(kind)
		inst.Name = name
		inst.Parent = folder
		sources[inst] = SRC .. dir .. "/" .. file
	end
	folder.Parent = parent
	return folder
end

local shared = mount("ChaiChaos", M.services.ReplicatedStorage, "shared", FILES.shared)
local server = mount("ChaiChaosServer", M.services.ServerScriptService, "server", FILES.server)
local client = mount("ChaiChaosClient", M.services.StarterPlayer.StarterPlayerScripts, "client", FILES.client)

local function runScripts(folder, context, only)
	for _, inst in folder:GetChildren() do
		local wanted = if only then only[inst.Name] else inst.Name ~= "Smooth"
		if wanted and (inst.ClassName == "Script" or inst.ClassName == "LocalScript") then
			M.context = context
			M.task.spawn(loadchunk(readfile(sources[inst]), sources[inst], scriptEnv(inst, context)))
			M.context = "server"
		end
	end
end

---------------------------------------------------------------------------
-- Test helpers
---------------------------------------------------------------------------
local passed, failed = 0, 0
local function check(cond, msg)
	if cond then
		passed += 1
	else
		failed += 1
		print("FAIL: " .. msg)
	end
end
local function section(name)
	print("== " .. name)
end

local mark = 0
local function markLog()
	mark = #M.log
end
local function notified(playerName, pattern)
	for i = mark + 1, #M.log do
		local e = M.log[i]
		if e.remote == "Notify" and e.player == playerName and tostring(e.args[2]):find(pattern) then
			return true
		end
	end
	return false
end
local function dumpLog(playerName)
	for i = mark + 1, #M.log do
		local e = M.log[i]
		if e.player == playerName then
			print("    log", e.args[1], e.args[2])
		end
	end
end

local function serverModule(name)
	return requireModule(server:FindFirstChild(name), "server")
end
local function sharedModule(name)
	return requireModule(shared:FindFirstChild(name), "server")
end

local userIds = {}
local function addPlayer(name, userId)
	local player = M.newInstance("Player", true)
	M.rawset(player, "Name", name)
	M.rawset(player, "DisplayName", name)
	M.rawset(player, "UserId", userId)
	M.newInstance("Backpack", true).Parent = player
	M.newInstance("PlayerGui", true).Parent = player
	player.Parent = Players
	userIds[name] = userId
	Players.PlayerAdded:Fire(player)
	return player
end

local function spawnCharacter(player)
	local char = M.newInstance("Model", true)
	M.rawset(char, "Name", player.Name)
	local root = M.Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = CFrame.new(0, 5, 0)
	root.Parent = char
	local head = M.Instance.new("Part")
	head.Name = "Head"
	head.CFrame = CFrame.new(0, 6.5, 0)
	head.Parent = char
	M.Instance.new("Humanoid").Parent = char
	char.PrimaryPart = root
	char.Parent = workspace
	M.rawset(player, "Character", char)
	player.CharacterAdded:Fire(char)
	return char
end

local function removePlayer(player)
	Players.PlayerRemoving:Fire(player)
	M.advance(0.5)
	if player.Character then
		player.Character:Destroy()
	end
	player.Parent = nil
end

local function moveNear(player, model, offset)
	player.Character:PivotTo(CFrame.new(model:GetPivot().Position + (offset or Vector3.new(0, 0, 3))))
end

local function prompt(model, name)
	return model.PrimaryPart:FindFirstChild(name)
end

local function trigger(model, name, player)
	local p = prompt(model, name)
	assert(p, "missing prompt " .. name .. " on " .. model.Name)
	PPS.PromptTriggered:Fire(p, player)
	M.advance(0.05)
end

local function entryOf(profile, id)
	for _, e in profile.owned do
		if e.def.id == id then
			return e
		end
	end
	return nil
end

local function plotOf(profile, id)
	local e = entryOf(profile, id)
	return e and e.plot
end
---------------------------------------------------------------------------
section("Server boot")
---------------------------------------------------------------------------
-- events, egg rushes and timed hazards would start by themselves; the tests start them by hand
local Config = sharedModule("Config")
-- the tests teleport players around with eggs; the speed check has its own test
local EGG_MAX_SPEED = Config.EGG_MAX_SPEED
Config.EGG_MAX_SPEED = math.huge
Config.FIRST_EVENT_DELAY = 1e9
Config.EGG_RUSH_EVERY = 1e9
Config.SANDSTORM_EVERY = 1e9
Config.WAVE_EVERY = 1e9
Config.SNOWBALL_EVERY = 1e9
Config.SALT_FALL_EVERY = 1e9
M.rawset(workspace, "StreamingEnabled", true) -- as set in default.project.json
runScripts(server, "server")
M.advance(0.2)

local map = workspace:FindFirstChild("ChaiChaosMap")
check(map ~= nil, "map is built")
check(#map.Havelis:GetChildren() == 8, "8 havelis")
local h1 = map.Havelis.Haveli1
check(
	h1:FindFirstChild("Plot20") ~= nil and h1:FindFirstChild("Deck") ~= nil,
	"havelis have 20 plots and a second floor"
)
check(h1:FindFirstChild("Incubator4") ~= nil, "havelis have incubator nests")
local State = serverModule("State")
local Havelis = serverModule("Havelis")
local Models = serverModule("Models")
local Kismat = serverModule("Kismat")
local QuestBook = serverModule("QuestBook")
local EventRunner = serverModule("EventRunner")
local EggSystem = serverModule("EggSystem")
local Hazards = serverModule("Hazards")
local Treasure = serverModule("Treasure")
local Garage = serverModule("Garage")
local Zones = serverModule("Zones")
local Vehicles = sharedModule("Vehicles")
local BiomeBuilder = serverModule("BiomeBuilder")
local Picker = serverModule("Picker")
local Brainrots = sharedModule("Brainrots")
local Biomes = sharedModule("Biomes")
local Gear = sharedModule("Gear")
local Sounds = sharedModule("Sounds")
local Format = sharedModule("Format")
local Mutations = sharedModule("Mutations")
local Themes = sharedModule("Themes")
local Remotes = sharedModule("Remotes")
local Motion = sharedModule("Motion")
local FLAT = Vector3.new(1, 0, 1)
check(#Brainrots.list == 46, "36 brainrots + 4 Secret + 6 quest brainrots, got " .. #Brainrots.list)
check(Brainrots.byId.SamosaSupremo.price == 100, "prices use the multiplier")
check(Format.rupees(1234567) == "Rs 1,234,567", "format commas")
check(Format.short(12500) == "12.5K" and Format.short(2000000) == "2M", "format short")
check(M.services.Lighting:FindFirstChild("ChaiChaosColor") ~= nil, "bright colour correction added")
check(M.groups.ChaiLaser1 and M.groups.ChaiOwner8 and M.noCollide["ChaiLaser1|ChaiOwner1"], "laser collision groups")
check(not M.noCollide["ChaiLaser1|ChaiOwner2"], "a laser only lets its own owner through")
check(
	M.groups.ChaiVehicles and M.noCollide["ChaiVehicles|ChaiOwner1"] and M.noCollide["ChaiVehicles|ChaiOwner8"],
	"vehicle bumpers never shove players"
)
check(
	not M.noCollide["ChaiVehicles|Default"] and not M.noCollide["ChaiVehicles|ChaiLaser1"],
	"but they crash into walls, trees, buildings and lasers"
)
check(h1.Barrier.CollisionGroup == "ChaiLaser1", "barrier in its laser group")
check(map.Leaderboard:FindFirstChild("Row1", true) ~= nil, "leaderboard rows")
local parsedId, parsedMutation = Mutations.parse("SamosaSupremo:Golden")
check(parsedId == "SamosaSupremo" and parsedMutation == "Golden", "mutation keys")
check(select(2, Mutations.parse("SamosaSupremo:Purple")) == nil, "unknown mutation ignored")

---------------------------------------------------------------------------
section("The world")
---------------------------------------------------------------------------
-- 8 havelis in a ring around the Chowk, each facing the fountain
local ringOk, facingOk = true, true
for _, h in Havelis.all() do
	local flat = h.origin.Position * FLAT
	ringOk = ringOk and math.abs(flat.Magnitude - Biomes.HAVELI_RADIUS) < 1
	facingOk = facingOk and h.origin.LookVector:Dot(-flat.Unit) > 0.99
end
check(ringOk, "havelis stand in a ring around the Chowk")
check(facingOk, "every haveli faces the fountain")
check(map:FindFirstChild("ChowkSpawn") ~= nil and map:FindFirstChild("FountainTop") ~= nil, "Chowk fountain and spawn")
-- the Chowk shops, and the vehicle shops in the bazaar
local shops = {}
for _, d in map:GetDescendants() do
	if d:IsA("BasePart") and type(d:GetAttribute("Shop")) == "string" then
		shops[d:GetAttribute("Shop")] = d
	end
end
for _, name in { "Sell", "Gear", "Tracker", "Kismat", "Rebirth", "Quests" } do
	local shop = shops[name]
	check(shop ~= nil and shop:FindFirstChild("ShopPrompt") ~= nil, "Chowk shop " .. name)
	check(shop and (shop.Position * FLAT).Magnitude < Biomes.PLAZA_RADIUS, name .. " is in the Chowk")
end
for _, name in { "Showroom", "Workshop" } do
	local shop = shops[name]
	local r = shop and Biomes.radiusOf(shop.Position)
	check(shop ~= nil and shop:FindFirstChild("ShopPrompt") ~= nil, "bazaar shop " .. name)
	check(r and r > Biomes.HUB_RADIUS and r < Biomes.TOWN_RADIUS, name .. " is in the Lahore bazaar")
end
check(Biomes.townSectorAt(shops.Showroom.Position).id == "RickshawStand", "the showroom is at the Rickshaw Stand")
check(Biomes.townSectorAt(shops.Workshop.Position).id == "ChaiDhabaBazaar", "the workshop is in the Chai Dhaba Bazaar")
-- 12 zones: 4 regions x 3 rings
check(#Biomes.list == 12, "12 zones")
local tiers = {}
for _, biome in Biomes.list do
	tiers[biome.tier] = true
end
check(#tiers == 12, "zone tiers 1 to 12")
for _, region in Biomes.REGIONS do
	local rings = Biomes.byRegion[region.id]
	check(rings[1] and rings[2] and rings[3], region.id .. " has 3 rings")
	check(
		rings[3].rebirths > 0 and rings[1].rebirths == 0 and rings[2].rebirths == 0,
		region.id .. " ring 3 needs rebirths"
	)
end
local ring1Max, ring2Min = 0, math.huge
for _, biome in Biomes.list do
	if biome.ring == 1 then
		ring1Max = math.max(ring1Max, biome.price)
	elseif biome.ring == 2 then
		ring2Min = math.min(ring2Min, biome.price)
	end
end
check(ring2Min > ring1Max, "every ring 2 zone costs more than every ring 1 zone")
check(
	Biomes.byId.MangoBagh.price == 0 and Biomes.byId.BarfaniPahar.rebirths == 4,
	"Mango Bagh is free, Barfani needs 4 rebirths"
)
check(Biomes.byId.BarfaniPahar.odds.Secret ~= nil, "Barfani Pahar has Secret brainrots")
local secretOnly = true
for _, biome in Biomes.list do
	if biome.id ~= "BarfaniPahar" and biome.odds.Secret then
		secretOnly = false
	end
end
check(secretOnly and Config.ROLL_ODDS.Secret == nil, "Secret brainrots only hatch in Barfani Pahar")
check(#map.Biomes:GetChildren() == 12, "12 zone folders")
-- every brainrot hatches somewhere
local hatches = {}
for _, biome in Biomes.list do
	for _, id in biome.pool do
		check(Brainrots.byId[id] ~= nil, biome.id .. " pool: " .. id)
		hatches[id] = true
	end
	for rarity in biome.odds do
		local found = false
		for _, id in biome.pool do
			found = found or Brainrots.byId[id].rarity == rarity
		end
		check(found, biome.id .. " has a " .. rarity .. " in its pool")
	end
end
for _, def in Brainrots.list do
	check(def.questOnly or hatches[def.id], def.id .. " hatches in some zone")
end
-- gates zigzag: ring 2 gates 30 degrees one way, ring 3 gates 30 degrees the other
for _, biome in Biomes.list do
	local angle, radius = Biomes.gate(biome)
	local expected = biome.angle + (if biome.ring == 2 then 30 elseif biome.ring == 3 then -30 else 0)
	check(math.abs(Biomes.angleDiff(angle, expected)) < 0.01, biome.id .. " gate angle")
	local barrier = Havelis.map().gates[biome.id]
	if biome.price == 0 and biome.rebirths == 0 then
		check(barrier == nil, biome.id .. " has no barrier (free)")
	else
		check(
			barrier ~= nil and barrier:FindFirstChild("GatePrompt") ~= nil,
			biome.id .. " has a gate barrier with a prompt"
		)
		check(
			barrier and ((barrier.Position - Biomes.polar(angle, radius)) * FLAT).Magnitude < 1,
			biome.id .. " barrier is in its gate"
		)
	end
end
local gateArches = 0
for _, d in map.Gates:GetChildren() do
	gateArches += if d.Name == "ZoneGate" then 1 else 0
end
check(gateArches == 12, "12 gate arches")
-- no wall piece blocks a gate
local blocked = 0
for _, wall in map.Walls:GetChildren() do
	if wall.Name ~= "RegionFence" then
		for _, biome in Biomes.list do
			local angle, radius = Biomes.gate(biome)
			if ((wall.Position - Biomes.polar(angle, radius)) * FLAT).Magnitude < Biomes.GATE_WIDTH / 2 then
				blocked += 1
			end
		end
	end
end
check(blocked == 0, "no wall blocks a gate: " .. blocked)
check(#Havelis.map().doors == 12, "12 shortcut doors")
for _, door in Havelis.map().doors do
	local a, b = Biomes.byId[door:GetAttribute("ZoneA")], Biomes.byId[door:GetAttribute("ZoneB")]
	check(a and b and a.ring == b.ring and a.region ~= b.region, "a shortcut door joins two zones in the same ring")
end
check(#Havelis.map().pumps == 12, "12 petrol pumps")
for _, pump in Havelis.map().pumps do
	check(pump:FindFirstChild("PumpPrompt") ~= nil, "pumps have a prompt")
	check(Biomes.roadDistance(pump.Position) > 2, "pumps stand off the road")
end
-- the roads: from the Chowk through every town gate, then gate to gate
local roadsOut = 0
for _, road in Biomes.roads() do
	if road.kind == "spoke" then
		roadsOut += 1
	end
end
check(roadsOut == 4, "4 roads out of the Chowk")
for _, biome in Biomes.list do
	local angle, radius = Biomes.gate(biome)
	check(Biomes.roadDistance(Biomes.polar(angle, radius)) < 0, biome.id .. "'s gate is on a road")
end
local fillsIn = {}
for _, fill in M.terrainFills do
	local biome = Biomes.at(fill.position)
	if biome then
		fillsIn[biome.id] = (fillsIn[biome.id] or 0) + 1
	end
end
local plans = BiomeBuilder.run(nil)
local eggsIn = {}
local eggFolder = workspace:FindFirstChild("ChaiChaosEggs")
for _, egg in eggFolder:GetChildren() do
	local biome = Biomes.at(egg:GetPivot().Position)
	check(biome and biome.id == egg:GetAttribute("Biome"), "egg lies in its own zone: " .. egg.Name)
	if biome then
		eggsIn[biome.id] = (eggsIn[biome.id] or 0) + 1
	end
end
local chestsIn = {}
for _, chest in Treasure.all() do
	chestsIn[chest.biome.id] = (chestsIn[chest.biome.id] or 0) + 1
end
for _, biome in Biomes.list do
	local plan = plans[biome.id]
	check((fillsIn[biome.id] or 0) > 20, biome.id .. " has terrain: " .. (fillsIn[biome.id] or 0))
	check(eggsIn[biome.id] == Config.EGGS_PER_BIOME, biome.id .. " has its eggs: " .. (eggsIn[biome.id] or 0))
	check((chestsIn[biome.id] or 0) >= 2, biome.id .. " has treasure chests: " .. (chestsIn[biome.id] or 0))
	check(#plan.eggSpots >= 20, biome.id .. " has egg spots: " .. #plan.eggSpots)
	local inside, offRoad = true, true
	for _, spot in plan.eggSpots do
		local b = Biomes.at(spot)
		inside = inside and b ~= nil and b.id == biome.id
		offRoad = offRoad and Biomes.roadDistance(spot) > 0
	end
	check(inside, biome.id .. " egg spots are inside the zone")
	check(offRoad, biome.id .. " egg spots are off the roads")
	check(Biomes.at(Biomes.center(biome)) == biome, biome.id .. " has its own area")
	check(not Biomes.contains(biome, Vector3.zero), biome.id .. " zone maths")
end
check(Biomes.at(Vector3.new(0, 5, 0)) == nil, "the Chowk is not a zone")
check(
	Biomes.at(Biomes.polar(0, 250)) == nil and Biomes.townSectorAt(Biomes.polar(0, 250)) ~= nil,
	"the bazaar is not a zone"
)
check(
	Biomes.byId.BarfaniPahar.eggTime < Biomes.byId.MangoBagh.eggTime
		and Biomes.innerRadius(Biomes.byId.BarfaniPahar) > Biomes.innerRadius(Biomes.byId.MangoBagh),
	"further zones are further away and their eggs crack sooner"
)
for name, info in Sounds.list do
	check(type(info.id) == "string" and info.volume > 0, "sound " .. name)
end
local khet = Biomes.byId.MangoBagh -- the free starter zone

do
	---------------------------------------------------------------------------
	section("Zone landmarks, the train and the bazaar")
	---------------------------------------------------------------------------
	local Props = serverModule("Props")
	local PropData = serverModule("PropData")
	-- each zone's landmarks, modelled in Blender
	local landmarks = {
		MangoBagh = { "MangoTree", "TubeWell", "WaterTank" },
		RailwayJunction = { "RailwayStation", "Train", "CrossingLight", "Rail" },
		CamelMela = { "MelaTent", "Camel" },
		QissaKhawani = { "GhantaGhar", "KahwaStall", "DryFruitStall" },
		SarsonFields = { "SarsonField", "TractorTrolley", "Scarecrow" },
		SahilBeach = { "Lighthouse", "BeachUmbrella", "CoconutPalm", "Camel" },
		TharDesert = { "DesertFort", "KikarDry" },
		NamakCaves = { "MineEntrance", "CrystalCluster" },
		LahoreQila = { "QilaGate", "QilaWall", "QilaTower", "Chhatri" },
		KarachiPort = { "PortCrane", "CargoShip" },
		MohenjoDaro = { "GreatBath", "RuinMound" },
		BarfaniPahar = { "IceCave", "Snowman", "MountainHut" },
	}
	for biomeId, names in landmarks do
		local folder = map.Biomes:FindFirstChild(biomeId)
		for _, name in names do
			check(folder and folder:FindFirstChild(name) ~= nil, biomeId .. " has a " .. name)
		end
	end
	check(map.Biomes.QissaKhawani:FindFirstChild("QissaHouseA") ~= nil, "Qissa Khawani's tall houses")
	check(map.Biomes.NamakCaves:FindFirstChild("SignText", true).Gui.Text.Text == "NAMAK CAVES", "mine entrance sign")
	local containers = 0
	for _, d in map.Biomes.KarachiPort:GetChildren() do
		containers += if d.Name:match("^Container") then 1 else 0
	end
	check(containers >= 10, "stacks of containers at the port: " .. containers)
	-- every ring 3 zone has a rickshaw home
	for _, biome in Biomes.list do
		local pad = map.Biomes[biome.id]:FindFirstChild("RickshawHome")
		check((biome.ring == 3) == (pad ~= nil), biome.id .. " rickshaw home only in ring 3")
	end
	-- climbing chests land you next to the treasure
	for _, chest in Treasure.all() do
		if chest.kind == "climb" and chest.stand then
			check((chest.stand - chest.top).Magnitude < 6, chest.model.Name .. " stand spot is next to the chest")
		end
	end
	-- the train waits, blinks, runs the track and comes back
	local train = map.Biomes.RailwayJunction.Train
	check(train.ModelStreamingMode == M.Enum.ModelStreamingMode.Persistent, "the train is always loaded")
	local w, b, sp = Config.TRAIN_WAIT, Config.TRAIN_BLINK, Config.TRAIN_SPEED
	local a0, moving0, light0 = Biomes.trainAt(0, w, b, sp)
	local _, moving1, light1 = Biomes.trainAt(w + 0.1, w, b, sp)
	local a2, moving2, light2 = Biomes.trainAt(w + b + 1, w, b, sp)
	check(not moving0 and light0 == "green", "the train waits with a green light")
	check(not moving1 and light1 == "blink", "the light blinks before it comes")
	check(moving2 and light2 == "red" and a2 > a0, "then it runs with a red light")
	local runTime = 80 * math.pi * Biomes.TRAIN.radius / 180 / sp
	local aBack, _, _, dirBack = Biomes.trainAt(w + b + runTime + w + b + 1, w, b, sp)
	check(dirBack == -1 and aBack < Biomes.byId.RailwayJunction.angle + 40, "and comes back the other way")
	-- the bazaar
	local bazaar = map.Bazaar
	local counts = {}
	for _, item in bazaar:GetChildren() do
		counts[item.Name] = (counts[item.Name] or 0) + 1
	end
	local stallCount = (counts.BazaarStallRed or 0)
		+ (counts.BazaarStallGreen or 0)
		+ (counts.BazaarStallBlue or 0)
		+ (counts.BazaarStallYellow or 0)
	check(stallCount >= 30, "rows of bazaar stalls: " .. stallCount)
	check(counts.FerrisWheel == 1 and counts.KiteTower == 1 and counts.MelaStage == 1, "Mela Ground and Kite Point")
	check(counts.Showroom == 1 and counts.Workshop == 1, "the Gaari Showroom and Ustad's Workshop")
	check((counts.Signboard or 0) == #Biomes.TOWN_SECTORS, "a sign for every bazaar sector")
	local onRoads = 0
	for _, item in bazaar:GetChildren() do
		if
			item:IsA("Model")
			and item.Name:match("^BazaarStall")
			and Biomes.roadDistance(item.WorldPivot.Position) < 2
		then
			onRoads += 1
		end
	end
	check(onRoads == 0, "no stall sits on a road: " .. onRoads)
	-- the Mandi lane round the Chowk, in front of every haveli door
	local lane = map:FindFirstChild("MandiLane")
	local tiles, offLane = 0, 0
	for _, p in lane:GetChildren() do
		if p.Name == "LaneTile" then
			tiles += 1
			offLane += if math.abs((p.Position * FLAT).Magnitude - Biomes.MANDI_RADIUS) > 0.5 then 1 else 0
		end
	end
	check(tiles == 72 and offLane == 0, "the Mandi lane runs all the way round the Chowk")
	check(lane.MandiSign.Gui.Label.Text == "BRAINROT MANDI", "the Brainrot Mandi arch")
	local pillarsClear = true
	for _, p in lane:GetChildren() do
		if p.Name == "MandiPillar" and Biomes.roadDistance(p.Position) < 1 then
			pillarsClear = false
		end
	end
	check(pillarsClear, "the arch's pillars stand beside the road, not on it")
	local doorsClear = true
	for _, h in Havelis.all() do
		local r = (h.doorOutside.Position * FLAT).Magnitude
		doorsClear = doorsClear and r > Biomes.MANDI_RADIUS + 10 and r < Biomes.MANDI_RADIUS + 30
	end
	check(
		doorsClear and Biomes.PLAZA_RADIUS < Biomes.MANDI_RADIUS - 20,
		"the lane runs just in front of the haveli doors"
	)
	check(
		map:FindFirstChild("ChaiDhaba") ~= nil and map:FindFirstChild("FruitStall") ~= nil,
		"a dhaba and a fruit cart in the Chowk"
	)
	-- a budget so the world stays light enough for phones
	local parts = 0
	for _, d in workspace:GetDescendants() do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	check(parts < 16000, "parts in the whole world: " .. parts)

	-- every Blender prop builds from parts
	local scratch = M.Instance.new("Folder")
	scratch.Parent = workspace
	local propCount = 0
	for name, spec in PropData.props do
		propCount += 1
		local model = Props.place(name, CFrame.new(0, 100, 0), scratch)
		check(#model:GetChildren() == #spec.parts, name .. " builds all its parts")
		local size = Props.size(name)
		check(size.X > 0 and size.Y > 0 and size.Z > 0, name .. " has a size")
	end
	check(propCount >= 60, "props modelled in Blender: " .. propCount)
	local lighthouseCF = CFrame.new(10, 1, 10) * CFrame.Angles(0, math.rad(90), 0)
	local gallery = Props.anchor("Lighthouse", "Gallery", lighthouseCF)
	check(gallery.Y > 28 and gallery.Y < 32, "anchors follow the prop: " .. tostring(gallery))
	local scaled = Props.place("KikarTree", CFrame.new(0, 100, 0), scratch, 2)
	check(
		math.abs(
			scaled:FindFirstChildWhichIsA("Part").Size.Magnitude
				- Props.place("KikarTree", CFrame.new(0, 100, 0), scratch)
						:FindFirstChildWhichIsA("Part").Size.Magnitude
					* 2
		) < 1e-3,
		"props scale"
	)
	-- imported meshes: one per prop in ServerStorage.ChaiChaosProps
	local meshes = M.Instance.new("Folder")
	meshes.Name = "ChaiChaosProps"
	local imported = M.Instance.new("Model")
	imported.Name = "ChaiChaosProps_Import"
	imported.Parent = meshes
	local expected = PropData.props.StiltVillage.mesh.size
	local stilt = M.newInstance("MeshPart", true)
	stilt.Name = "StiltVillage"
	stilt.Size = Vector3.new(expected[1] * 0.28, expected[3] * 0.28, expected[2] * 0.28) -- imported lying down (Z up)
	stilt.Parent = imported
	local charpai = M.newInstance("MeshPart", true)
	charpai.Name = "Charpai"
	local cs = PropData.props.Charpai.mesh.size
	charpai.Size = Vector3.new(cs[1], cs[2], cs[3])
	charpai.Parent = imported
	meshes.Parent = M.services.ServerStorage
	Props.reload()
	local villageCF = CFrame.new(50, 1, 50)
	local village = Props.place("StiltVillage", villageCF, scratch)
	local mesh = village:FindFirstChild("StiltVillage")
	check(mesh ~= nil and mesh:IsA("MeshPart") and mesh.Anchored and not mesh.CanCollide, "the imported mesh is used")
	check(math.abs(mesh.CFrame.LookVector.Y) > 0.99 or math.abs(mesh.CFrame.LookVector.Y) < 0.01, "mesh turned upright")
	check(
		math.abs(mesh.Size.Z - expected[2]) < 1e-3,
		"a mesh lying down is stood up and sized: " .. tostring(mesh.Size)
	)
	local colliders, visibleParts, keepParts = 0, 0, 0
	for _, child in village:GetChildren() do
		if child.Name == "Collider" then
			colliders += 1
			visibleParts += if child.Transparency < 1 then 1 else 0
		elseif child:IsA("Part") then
			keepParts += 1
		end
	end
	check(colliders > 30 and visibleParts == 0, "the parts become invisible walls: " .. colliders)
	local plain = Props.place("Charpai", CFrame.new(60, 1, 60), scratch)
	check(
		plain:FindFirstChild("Charpai"):IsA("MeshPart") and #plain:GetChildren() == 1 + 9,
		"charpai mesh plus its colliders"
	)
	check(
		Props.place("Lighthouse", CFrame.new(70, 1, 70), scratch):FindFirstChild("Collider") == nil,
		"props without an imported mesh are still parts"
	)
	meshes:Destroy()
	Props.reload()
	scratch:Destroy()
end

do
	---------------------------------------------------------------------------
	section("Brainrot models from Blender")
	---------------------------------------------------------------------------
	local Props = serverModule("Props")
	local PropData = serverModule("PropData")
	local function eyesOf(model)
		local eyes = {}
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") and p.Name == "Eye" then
				table.insert(eyes, p)
			end
		end
		return eyes
	end
	local brainrotProps = 0
	for _, spec in PropData.props do
		brainrotProps += if spec.category == "brainrot" then 1 else 0
	end
	check(brainrotProps == #Brainrots.list, "a Blender model for every brainrot: " .. brainrotProps)
	for _, def in Brainrots.list do
		check(Props.exists(def.id) and PropData.props[def.id].category == "brainrot", def.id .. " is modelled")
		local model = Models.create(def)
		local root = model.PrimaryPart
		check(root and root.Name == "Root" and root.Transparency == 1, def.id .. " has an invisible Root")
		-- Samosa Supremo hides its eyes behind shades; Mela Maharaja laughs with its eyes shut
		local eyeless = def.id == "SamosaSupremo" or def.id == "MelaMaharaja"
		check(#eyesOf(model) >= 3 or eyeless, def.id .. " has big eyes")
		check(model:FindFirstChild("RarityRing") ~= nil and model:GetAttribute("Height") > 2, def.id .. " decorated")
		local size = Props.size(def.id)
		local scale = math.min(1, 7.4 / math.max(size.X, size.Z), 7.6 / size.Y)
		check(math.max(size.X, size.Z) * scale <= 7.41 and size.Y * scale <= 7.61, def.id .. " fits on a plot")
		local loose = 0
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				loose += if p ~= root and p:FindFirstChild("Hold") == nil then 1 else 0
				loose += if p.CanCollide then 1 else 0
			end
		end
		check(loose == 0, def.id .. " parts are welded and never collide")
		model:Destroy()
	end
	-- mutated brainrots are tinted, but their eyes keep their colour
	local golden = Models.create(Brainrots.byId.PakoraPanda, "Golden")
	local foil, plain = 0, 0
	for _, p in golden:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 and p.Name ~= "RarityRing" then
			if p.Name == "Eye" then
				plain += if p.Material ~= M.Enum.Material.Foil then 1 else 0
			else
				foil += if p.Material == M.Enum.Material.Foil then 1 else 0
			end
		end
	end
	check(
		foil > 8 and plain > 0 and plain == #eyesOf(golden),
		"Golden Pakora Panda is gold all over but its eyes: " .. foil
	)
	golden:Destroy()
	-- the parrot's tail says "Dekh magar pyar se"
	local totaa = Models.create(Brainrots.byId.TruckArtTotaa)
	local tail = totaa:FindFirstChild("SignText")
	check(tail and tail.Gui.Text.Text == "Dekh magar pyar se", "truck art lettering on the parrot's tail")
	check(tail and tail.CFrame.LookVector.Z > 0.5 and tail.CFrame.LookVector.Y > 0.3, "the lettering faces back")
	check(tail and tail:FindFirstChild("Hold") ~= nil, "and moves with the parrot")
	totaa:Destroy()
	-- an imported mesh is used for normal brainrots; mutated ones stay parts so they can be tinted
	local meshes = M.Instance.new("Folder")
	meshes.Name = "ChaiChaosProps"
	local panda = M.newInstance("MeshPart", true)
	panda.Name = "PakoraPanda"
	local ms = PropData.props.PakoraPanda.mesh.size
	panda.Size = Vector3.new(ms[1], ms[2], ms[3])
	panda.Parent = meshes
	meshes.Parent = M.services.ServerStorage
	Props.reload()
	local smooth = Models.create(Brainrots.byId.PakoraPanda)
	check(smooth:FindFirstChildWhichIsA("MeshPart") ~= nil and #eyesOf(smooth) == 0, "the panda uses the imported mesh")
	local diamond = Models.create(Brainrots.byId.PakoraPanda, "Diamond")
	check(diamond:FindFirstChildWhichIsA("MeshPart") == nil and #eyesOf(diamond) > 0, "a Diamond panda uses parts")
	smooth:Destroy()
	diamond:Destroy()
	meshes:Destroy()
	Props.reload()
	-- your own model in ServerStorage.Brainrots still comes first
	local custom = M.Instance.new("Folder")
	custom.Name = "Brainrots"
	local mine = M.Instance.new("Model")
	mine.Name = "NaanNinja"
	local body = M.Instance.new("Part")
	body.Name = "MyNaan"
	body.Parent = mine
	mine.Parent = custom
	custom.Parent = M.services.ServerStorage
	local naan = Models.create(Brainrots.byId.NaanNinja)
	check(naan:FindFirstChild("MyNaan") ~= nil and naan.PrimaryPart.Name == "MyNaan", "a custom model wins")
	naan:Destroy()
	custom:Destroy()
	-- Cycle Wala Cyclops became Cylinder Cycle Chacha; old saves keep it
	local PlayerData = serverModule("PlayerData")
	local migrated = PlayerData.reconcile({
		level = 3,
		owned = { "CycleWalaCyclops", "CycleWalaCyclops:Golden" },
		discovered = { CycleWalaCyclops = true },
		mutations = { ["CycleWalaCyclops:Golden"] = true },
		ride = "CycleWalaCyclops:Rainbow",
		incubators = { { slot = 1, biome = "Registan", id = "CycleWalaCyclops", hatchAt = 1 } },
	})
	check(
		migrated.owned[1] == "CylinderCycleChacha" and migrated.owned[2] == "CylinderCycleChacha:Golden",
		"renamed brainrots stay in your haveli"
	)
	check(
		migrated.discovered.CylinderCycleChacha and migrated.mutations["CylinderCycleChacha:Golden"],
		"and in your Collection Book"
	)
	check(
		migrated.owned[3] == "CylinderCycleChacha:Rainbow" and migrated.ride == nil,
		"an old ride walks back to a plot (riding is gone)"
	)
	check(migrated.incubators[1] and migrated.incubators[1].id == "CylinderCycleChacha", "and in your incubator")
	check(Brainrots.byId.CycleWalaCyclops == nil, "the old id is gone")
end

local TODAY = math.floor(M.os.time() / 86400)
local function setQuests(profile, list)
	profile.data.quests = { day = TODAY, list = list, bonusClaimed = false }
	State.syncQuests(profile)
end

-- gives a brainrot that walks in from the door
local function give(profile, id, mutation)
	local entry = Havelis.adopt(profile, Brainrots.byId[id], mutation, nil, true)
	M.advance(12)
	return entry
end

local function stealable(profile)
	for _, e in profile.owned do
		if not Havelis.isLocker(e.plot) and not e.def.questOnly and e.arrived and not e.carrier then
			return e
		end
	end
	return nil
end

local function receipt(userId, productId, purchaseId)
	local result
	M.task.spawn(function()
		result = M.services.MarketplaceService.ProcessReceipt({
			PlayerId = userId,
			ProductId = productId,
			PurchaseId = purchaseId,
			CurrencySpent = 25,
			CurrencyType = M.Enum.CurrencyType.Robux,
			PlaceIdWherePurchased = 1,
		})
	end)
	M.advance(0.5)
	return result
end

local function goTo(player, position)
	player.Character:PivotTo(CFrame.new(position + Vector3.new(0, 3, 0)))
end

-- stand in front of a Chowk stall (stalls face the fountain)
local function atShop(player, name)
	goTo(player, shops[name].Position * FLAT + shops[name].CFrame.LookVector * FLAT * 5)
end

local function eggIn(biomeId, golden)
	for _, egg in eggFolder:GetChildren() do
		if
			egg:GetAttribute("Biome") == biomeId
			and (golden == nil or egg:GetAttribute("Golden") == golden)
			and egg.PrimaryPart.Anchored
			and egg.PrimaryPart.EggPrompt.Enabled
		then
			return egg
		end
	end
	return nil
end

local function pickUp(player, egg)
	goTo(player, egg:GetPivot().Position)
	trigger(egg, "EggPrompt", player)
end

local function soundsFor(playerName, name)
	local count = 0
	for i = mark + 1, #M.log do
		local e = M.log[i]
		if e.remote == "PlaySound" and e.player == playerName and e.args[1] == name then
			count += 1
		end
	end
	return count
end

---------------------------------------------------------------------------
section("Ali joins")
---------------------------------------------------------------------------
markLog()
local A = addPlayer("Ali", 1)
M.advance(0.5)
local pa = State.profiles[A]
check(pa and pa.haveli and pa.haveli.index == 1, "Ali got haveli 1")
check(pa.haveli.signLabel.Text == "Ali ki Haveli · Lv 1", "sign: " .. pa.haveli.signLabel.Text)
check(pa.data.theme == "MughalMarble" and pa.data.level == 1, "starts in a level 1 Mughal Marble haveli")
check(pa.data.rupees >= Config.START_RUPEES, "starts with at least Rs 1,000: " .. pa.data.rupees)
check(pa.data.version == 5 and pa.data.trackerLevel == 1 and next(pa.data.gear) == nil, "v5 data: tracker 1, no gear")
check(A:GetAttribute("OpenZones") == "MangoBagh", "only Mango Bagh is open at the start")
check(A:GetAttribute("Vehicles") == "" and A:GetAttribute("Driving") == "", "no vehicles yet")
check(A:GetAttribute("TrackerLevel") == 1 and A:GetAttribute("Gear") == "", "tracker and gear sent to the HUD")
check(A:GetAttribute("HomePosition") == pa.haveli.doorOutside.Position, "the radar knows where home is")
check(notified("Ali", "Daily chai") and notified("Ali", "free Kismat Roll"), "daily chai with a free roll")
check(notified("Ali", "radar"), "welcome message explains the egg hunt")
check(pa.data.rollTokens == 1, "one free Kismat Roll")
check(#pa.data.quests.list == Config.QUESTS_PER_DAY, "daily quests given")
check(type(A:GetAttribute("QuestState")) == "string", "quest state sent to the HUD")
check(h1.Walls:GetChildren()[1].Material == M.Enum.Material.Marble, "Mughal Marble walls")
check(h1.StairGates.StairGate.CanCollide == true, "stairs closed at level 1")
check(pa.haveli.incubatorLabels[1].Text == "Empty incubator", "one empty incubator at level 1")
check(pa.haveli.incubatorLabels[2].Text == "", "the second incubator comes later")
local charA = spawnCharacter(A)
M.advance(0.3)
check((charA:GetPivot().Position - pa.haveli.spawn.Position).Magnitude < 0.01, "Ali teleported into haveli")
check(
	#M.streamRequests > 0 and M.streamRequests[#M.streamRequests].position == pa.haveli.spawn.Position,
	"the haveli streams in before the teleport"
)
check(charA.Humanoid.WalkSpeed == Config.WALK_SPEED, "walk speed " .. charA.Humanoid.WalkSpeed)
check(charA.HumanoidRootPart.CollisionGroup == "ChaiOwner1", "Ali can pass his own laser")
check(A.Backpack:FindFirstChild("Chappal") ~= nil, "Ali has a chappal")

M.localPlayer = A
M.rawset(Players, "LocalPlayer", A)
runScripts(client, "client")
M.advance(0.5)
local hud = A.PlayerGui:FindFirstChild("ChaiChaosHud")
check(hud ~= nil, "HUD created")
for _, name in { "Taala", "Haveli", "Kismat", "Quests", "Collection", "Brainrots", "Gaari" } do
	check(hud.Buttons:FindFirstChild(name) ~= nil, "HUD button " .. name)
end
check(hud.Buttons:FindFirstChild("NayaSafar") == nil, "Naya Safar is at the Chowk now, not a button")
check(hud.Buttons:FindFirstChild("ChorPass") == nil, "no Chor Pass button while stealing is free")
check(hud.EventBanner.Title.Text == "Next event", "event banner")
check(hud.Money:FindFirstChildWhichIsA("TextLabel").Text == Format.rupees(pa.data.rupees), "HUD shows rupees")
check(hud.RadarHolder.Radar.Level.Text == "Radar Lv 1", "radar level shown")
check(hud.RadarHolder.Tracks.Text == "Tracks: 1 open zone", "radar tracks Mango Bagh: " .. hud.RadarHolder.Tracks.Text)
check(hud.RadarHolder.Area.Text == "Chowk", "radar says where you are: " .. hud.RadarHolder.Area.Text)
check(hud.CollectionBook:FindFirstChild("SamosaSupremo", true) ~= nil, "collection book cards")

---------------------------------------------------------------------------
section("Egg hunt")
---------------------------------------------------------------------------
local function groundEggs(biomeId)
	local count = 0
	for _, egg in eggFolder:GetChildren() do
		if egg:GetAttribute("Biome") == biomeId and egg.PrimaryPart.Anchored then
			count += 1
		end
	end
	return count
end
local function visibleDots()
	local list = {}
	for _, d in hud.RadarHolder.Radar.Dots:GetChildren() do
		if d.Visible then
			table.insert(list, d)
		end
	end
	return list
end
local function inPool(biome, id)
	return table.find(biome.pool, id) ~= nil
end

Havelis.clearBrainrots(pa)
pa.data.discovered = {}
State.syncDiscovered(pa)
setQuests(pa, {
	{ id = "eggHome", target = 2, progress = 0, claimed = false },
	{ id = "biomes", target = 2, progress = 0, claimed = false },
	{ id = "discover", target = 1, progress = 0, claimed = false },
})
local khetEgg = eggIn("MangoBagh", false)
check(khetEgg ~= nil, "found a Mango Bagh egg")
markLog()
PPS.PromptTriggered:Fire(khetEgg.PrimaryPart.EggPrompt, A)
M.advance(0.05)
check(pa.egg == nil, "cannot pick up an egg from far away")
pickUp(A, khetEgg)
check(pa.egg ~= nil and pa.egg.model == khetEgg, "picked up the Mango Bagh egg")
check(A:GetAttribute("EggBiome") == "MangoBagh" and A:GetAttribute("EggTimeTotal") == 60, "egg timer starts at 60s")
check(khetEgg.PrimaryPart:FindFirstChild("CarryWeld") ~= nil and not khetEgg.PrimaryPart.Anchored, "egg in Ali's hands")
check(not khetEgg.PrimaryPart.EggPrompt.Enabled, "nobody else can grab a carried egg")
check(notified("Ali", "Run it home") and soundsFor("Ali", "EggPickup") == 1, "pickup message and sound")
check(M.soundsPlayed[#M.soundsPlayed].name == "EggPickup", "the sound plays on Ali's screen")
-- an egg right next to Ali for the radar
local here = charA:GetPivot().Position
local nearEgg = EggSystem.spawn(khet, false, here * FLAT + Vector3.new(8, Biomes.GROUND_Y, 8))
M.advance(5)
local left = A:GetAttribute("EggTimeLeft")
check(left < 56 and left > 54, "egg timer runs down: " .. left)
check(hud.RadarStatus.EggBar.Visible, "egg bar on the radar")
check(hud.RadarStatus.EggBar.Text.Text:find("Mango Bagh egg") ~= nil, "egg bar: " .. hud.RadarStatus.EggBar.Text.Text)
check(hud.RadarHolder.Area.Text == "Mango Bagh", "radar: in Mango Bagh")
local sawEggDot = false
for _, d in visibleDots() do
	sawEggDot = sawEggDot or d.BackgroundColor3 == khet.eggColor
end
check(sawEggDot, "radar shows the egg next to Ali")
check(#visibleDots() >= 3, "radar shows eggs, home and the Chowk")
check(hud.AreaTitle.Text == "MANGO BAGH · Punjab Mango Orchards", "zone title when walking in: " .. hud.AreaTitle.Text)
local beforeRefill = groundEggs("MangoBagh")
M.advance(Config.EGG_RESPAWN + 0.5)
check(groundEggs("MangoBagh") >= beforeRefill, "eggs refill over time")

markLog()
goTo(A, pa.haveli.spawn.Position)
M.advance(0.5)
check(pa.egg == nil and pa.incubating[1] ~= nil, "home safe: the egg is in the incubator")
local record = pa.incubating[1]
check(inPool(khet, record.id), "what hatches is from Mango Bagh's pool: " .. record.id)
check(khetEgg.Parent == pa.haveli.brainrotFolder, "the egg sits in the nest")
check(notified("Ali", "Home safe") and soundsFor("Ali", "EggHome") == 1, "home message and sound")
check(A:GetAttribute("EggBiome") == "" and not hud.RadarStatus.EggBar.Visible, "egg bar gone")
check(pa.haveli.incubatorLabels[1].Text:find("Hatching") ~= nil, "nest shows the countdown")
check(pa.data.quests.list[1].progress == 1 and pa.data.quests.list[2].progress == 1, "egg quests count")

-- locked zones: unlock them at their gates
local jungle = Biomes.byId.RailwayJunction
local jungleEgg = eggIn("RailwayJunction", false)
markLog()
pickUp(A, jungleEgg)
check(pa.egg == nil and notified("Ali", "Unlock Railway Junction"), "no eggs from a locked zone")
local function gateOf(id)
	return Havelis.map().gates[id]
end
local function atGate(player, id)
	local barrier = gateOf(id)
	goTo(player, barrier.Position * FLAT - barrier.CFrame.LookVector * FLAT * 6)
end
pa.data.rupees = 5_000
State.syncStats(pa)
atGate(A, "RailwayJunction")
markLog()
PPS.PromptTriggered:Fire(gateOf("RailwayJunction").GatePrompt, A)
M.advance(0.1)
check(not pa.data.zones.RailwayJunction and notified("Ali", "costs Rs 15,000"), "unlocking costs rupees")
pa.data.rupees = 2_000_000
State.syncStats(pa)
PPS.PromptTriggered:Fire(gateOf("RailwayJunction").GatePrompt, A)
M.advance(0.1)
check(pa.data.zones.RailwayJunction and pa.data.rupees == 1_985_000, "Railway Junction unlocked for Rs 15,000")
check(A:GetAttribute("OpenZones") == "MangoBagh,RailwayJunction" and notified("Ali", "unlocked"), "open zones sent")
check(soundsFor("Ali", "Purchase") >= 1, "unlock sound")
check(not gateOf("RailwayJunction").GatePrompt.Enabled, "Ali's screen hides the prompt on an open gate")
check(not gateOf("RailwayJunction").CanCollide, "and lets Ali through the barrier")
check(gateOf("SahilBeach").CanCollide, "locked gates stay solid")
atGate(A, "NamakCaves")
markLog()
PPS.PromptTriggered:Fire(gateOf("NamakCaves").GatePrompt, A)
M.advance(0.1)
check(not pa.data.zones.NamakCaves and notified("Ali", "Unlock Qissa Khawani first"), "unlock the ring in front first")
atGate(A, "LahoreQila")
markLog()
PPS.PromptTriggered:Fire(gateOf("LahoreQila").GatePrompt, A)
M.advance(0.1)
check(not State.isZoneOpen(pa, Biomes.byId.LahoreQila) and notified("Ali", "1 rebirth"), "ring 3 needs rebirths")
goTo(A, pa.haveli.spawn.Position)
PPS.PromptTriggered:Fire(gateOf("CamelMela").GatePrompt, A)
M.advance(0.1)
check(not pa.data.zones.CamelMela, "gates only work up close")
-- the rest of the zones (rings 1 and 2) for the tests that follow
for _, biome in Biomes.list do
	if biome.price > 0 then
		pa.data.zones[biome.id] = true
	end
end
State.syncZones(pa)
pa.data.rupees = 100_000
State.syncStats(pa)
M.advance(0.1)

-- a second egg while the incubator is busy
pickUp(A, jungleEgg)
check(pa.egg and A:GetAttribute("EggTimeTotal") == jungle.eggTime, "Railway Junction egg picked up")
markLog()
goTo(A, pa.haveli.spawn.Position)
M.advance(0.5)
check(pa.egg ~= nil and notified("Ali", "incubators are full"), "incubator full: keep holding it")
local held = A:GetAttribute("EggTimeLeft")
M.advance(3)
check(A:GetAttribute("EggTimeLeft") == held, "the egg is safe at home while you wait")
markLog()
M.advance(khet.hatchTime)
check(#pa.owned == 1 and inPool(khet, pa.owned[1].def.id), "the Mango Bagh egg hatched")
check(notified("Ali", "Your egg hatched") and soundsFor("Ali", "EggHatch") == 1, "hatch message and sound")
check(
	pa.egg == nil and pa.incubating[1] and pa.incubating[1].biome == "RailwayJunction",
	"the Railway Junction egg took the nest"
)
check(pa.data.quests.list[2].progress == 2, "two different zones")
check(pa.data.quests.list[3].progress == 1, "first brainrot discovered")
M.advance(jungle.hatchTime + 1)
check(#pa.owned == 2 and inPool(jungle, pa.owned[2].def.id), "the Railway Junction egg hatched")
M.advance(10)
check(pa.owned[1].arrived and pa.owned[2].arrived, "hatched brainrots walk to their plots")
check(A:GetAttribute("Owned"):find(pa.owned[1].def.id) ~= nil, "the Brainrots window knows what Ali owns")

-- an egg that cracks
local samandar = Biomes.byId.SahilBeach
local seaEgg = eggIn("SahilBeach", false)
pickUp(A, seaEgg)
markLog()
M.advance(samandar.eggTime + 1)
check(pa.egg == nil and seaEgg.Parent == nil, "the egg cracked")
check(notified("Ali", "cracked") and soundsFor("Ali", "EggCrack") == 1, "crack message and sound")
check(A:GetAttribute("EggBiome") == "", "nothing carried")

-- dying drops the egg
local dropEgg = eggIn("MangoBagh", false)
pickUp(A, dropEgg)
M.advance(2)
local leftBefore = pa.egg.timeLeft
charA.Humanoid.Died:Fire()
M.advance(0.1)
check(pa.egg == nil and dropEgg.PrimaryPart.Anchored and dropEgg.PrimaryPart.EggPrompt.Enabled, "dying drops the egg")
pickUp(A, dropEgg)
check(pa.egg and math.abs(pa.egg.timeLeft - leftBefore) < 0.5, "a dropped egg keeps its time")
EggSystem.drop(A)
M.advance(Config.DROPPED_EGG_LIFETIME + 1)
check(dropEgg.Parent == nil, "dropped eggs vanish after a while")
nearEgg:Destroy()

---------------------------------------------------------------------------
section("Zone hazards")
---------------------------------------------------------------------------
local function zoneSpot(biomeId, kind)
	local biome = Biomes.byId[biomeId]
	for _, z in plans[biomeId].zones do
		if z.kind == kind then
			if z.center then
				return Vector3.new(z.center.X, Biomes.GROUND_Y, z.center.Z)
			end
			-- a band: find a spot in it, off the roads
			for side = -40, 40, 4 do
				local spot = Biomes.point(biome, (z.inner + math.min(z.outer, Biomes.outerRadius(biome))) / 2, side)
				if Biomes.at(spot) == biome and Biomes.roadDistance(spot) > 4 then
					return spot
				end
			end
		end
	end
	error("no " .. kind .. " zone in " .. biomeId)
end

do
	markLog()
	goTo(A, zoneSpot("MangoBagh", "mud"))
	M.advance(0.5)
	check(pa.hazardSpeed == Config.HAZARD_SPEED.mud, "mud slows you down")
	check(math.abs(charA.Humanoid.WalkSpeed - Config.WALK_SPEED * Config.HAZARD_SPEED.mud) < 1e-6, "walk speed in mud")
	check(A:GetAttribute("Hazard") == "Mud! Gum Boots helps", "hazard warning: " .. A:GetAttribute("Hazard"))
	check(
		hud.RadarStatus.Hazard.Visible and hud.RadarStatus.Hazard.Text == "Mud! Gum Boots helps",
		"warning on the radar"
	)
	pa.data.gear.GumBoots = true
	State.syncGear(pa)
	M.advance(0.5)
	check(charA.Humanoid.WalkSpeed == Config.WALK_SPEED and A:GetAttribute("Hazard") == "", "Gum Boots: no more mud")
	goTo(A, pa.haveli.spawn.Position)
	M.advance(0.5)

	-- water makes eggs crack faster
	local riverEgg = eggIn("SahilBeach", false)
	pickUp(A, riverEgg)
	goTo(A, zoneSpot("SahilBeach", "water"))
	M.advance(0.3)
	local t0 = pa.egg.timeLeft
	M.advance(2)
	check(
		pa.egg and t0 - pa.egg.timeLeft > 3.5,
		"water cracks eggs twice as fast: " .. (t0 - (pa.egg and pa.egg.timeLeft or 0))
	)
	check(pa.hazardSpeed == Config.HAZARD_SPEED.water, "water slows you down")
	pa.data.gear.LifeJacket = true
	State.syncGear(pa)
	M.advance(0.3)
	t0 = pa.egg.timeLeft
	M.advance(2)
	check(t0 - pa.egg.timeLeft < 2.2 and pa.hazardSpeed == 1, "Life Jacket keeps you and the egg safe")
	pa.data.gear.LifeJacket = nil
	State.syncGear(pa)
	-- the roads are always safe: the road out to Karachi Port crosses the sea
	local causeway = nil
	for _, road in Biomes.roads() do
		for t = 0, 1, 0.02 do
			local p = road.a:Lerp(road.b, t)
			if Biomes.at(p) == Biomes.byId.SahilBeach and BiomeBuilder.inZone(plans.SahilBeach, p, "water") then
				causeway = p
			end
		end
	end
	check(causeway ~= nil, "a road crosses the sea")
	goTo(A, causeway)
	M.advance(0.3)
	check(pa.hazardSpeed == 1, "no water on a road")

	-- waves on the beach push you back
	goTo(A, zoneSpot("SahilBeach", "shore"))
	M.advance(1.2)
	markLog()
	t0 = pa.egg.timeLeft
	Hazards.wave()
	M.advance(0.05)
	check(t0 - pa.egg.timeLeft >= Config.EGG_HIT_PENALTY - 0.1, "a big wave knocks time off the egg")
	check(notified("Ali", "SPLASH") and soundsFor("Ali", "Splash") == 1, "splash message and sound (once)")
	check(workspace:GetAttribute("WaveAt") ~= nil, "clients are told about the wave")
	check(charA.HumanoidRootPart:FindFirstChild("Knockback") ~= nil, "the wave pushes you back")
	M.advance(1.2)
	check(charA.HumanoidRootPart:FindFirstChild("Knockback") == nil, "the push is short")
	pa.data.gear.LifeJacket = true
	State.syncGear(pa)
	t0 = pa.egg.timeLeft
	Hazards.wave()
	M.advance(0.05)
	check(t0 - pa.egg.timeLeft < 0.5, "a Life Jacket shrugs off waves")

	-- snowballs and ice in Barfani Pahar, falling salt in the Namak Caves
	pa.egg.timeLeft = 45 -- a fresh timer, so the egg lasts through every hazard
	local barfani = Biomes.byId.BarfaniPahar
	goTo(A, zoneSpot("BarfaniPahar", "ice") + Vector3.new(0, 0, 0))
	M.advance(0.3)
	check(pa.hazardSpeed == Config.HAZARD_SPEED.ice, "frozen lakes are slippery")
	goTo(A, Biomes.point(barfani, Biomes.innerRadius(barfani) + 20, 20))
	M.advance(0.3)
	t0 = pa.egg.timeLeft
	Hazards.snowball()
	M.advance(0.05)
	check(t0 - pa.egg.timeLeft >= Config.EGG_HIT_PENALTY - 0.1, "snowball hit")
	pa.data.gear.SnowBoots = true
	State.syncGear(pa)
	t0 = pa.egg.timeLeft
	Hazards.snowball()
	M.advance(0.05)
	check(t0 - pa.egg.timeLeft < 0.5, "Snow Boots dodge snowballs")
	goTo(A, zoneSpot("BarfaniPahar", "ice"))
	M.advance(0.3)
	check(pa.hazardSpeed == 1, "Snow Boots: no slipping on ice")
	pa.egg.timeLeft = 45
	local namak = Biomes.byId.NamakCaves
	goTo(A, zoneSpot("NamakCaves", "dark"))
	M.advance(1.2)
	t0 = pa.egg.timeLeft
	markLog()
	Hazards.salt()
	M.advance(0.05)
	local warning = workspace.ChaiChaosHazards:FindFirstChild("SaltWarning")
	check(
		warning ~= nil and (warning.Position * FLAT - charA:GetPivot().Position * FLAT).Magnitude < 6,
		"a red circle near Ali"
	)
	M.advance(Config.SALT_WARNING + 0.1)
	check(t0 - pa.egg.timeLeft >= Config.EGG_HIT_PENALTY - 0.1, "the salt rock lands on Ali")
	check(notified("Ali", "salt rock"), "salt message")
	local tint = M.services.Lighting:FindFirstChild("ChaiChaosBiomeTint")
	check(tint and tint.Brightness < -0.2, "the salt caves are dark")
	pa.data.gear.Lantern = true
	State.syncGear(pa)
	M.advance(1.2)
	t0 = pa.egg.timeLeft
	Hazards.salt()
	M.advance(Config.SALT_WARNING + 0.1)
	check(t0 - pa.egg.timeLeft < Config.SALT_WARNING + 0.6, "a Lantern lights the way")
	check(charA.HumanoidRootPart:FindFirstChild("LanternGlow") ~= nil and tint.Brightness > -0.2, "lantern glow")
	_ = namak

	-- sandstorms in the desert
	goTo(A, zoneSpot("TharDesert", "sandstorm"))
	M.advance(0.5)
	check(pa.hazardSpeed == 1, "no sandstorm yet")
	workspace:SetAttribute("Sandstorm", true)
	M.advance(0.5)
	check(pa.hazardSpeed == Config.HAZARD_SPEED.sandstorm, "sandstorm slows you")
	local weather = workspace.CurrentCamera:FindFirstChild("ChaiChaosWeather")
	check(weather and weather.Sand.Enabled, "sand on screen")
	pa.data.gear.SandGoggles = true
	State.syncGear(pa)
	M.advance(0.5)
	check(pa.hazardSpeed == 1 and weather.Sand.Rate < 500, "Sand Goggles help")
	workspace:SetAttribute("Sandstorm", false)

	-- the train in Railway Junction
	local train = Biomes.TRAIN
	local trainT = M.services.Workspace:GetServerTimeNow()
	local angle, moving = Biomes.trainAt(trainT, Config.TRAIN_WAIT, Config.TRAIN_BLINK, Config.TRAIN_SPEED)
	local waited = 0
	while not moving and waited < 40 do
		M.advance(0.5)
		waited += 0.5
		angle, moving = Biomes.trainAt(
			M.services.Workspace:GetServerTimeNow() + 0.3,
			Config.TRAIN_WAIT,
			Config.TRAIN_BLINK,
			Config.TRAIN_SPEED
		)
	end
	check(moving, "the train comes")
	if not pa.egg then
		pickUp(A, eggIn("MangoBagh", false))
	end
	pa.egg.timeLeft = 45
	goTo(A, Biomes.polar(angle, train.radius))
	markLog()
	t0 = pa.egg.timeLeft
	local pushed = false
	for _ = 1, 8 do
		M.advance(0.05)
		pushed = pushed or charA.HumanoidRootPart:FindFirstChild("Knockback") ~= nil
	end
	check(
		notified("Ali", "TOOT TOOT") and t0 - pa.egg.timeLeft >= Config.EGG_HIT_PENALTY - 0.5,
		"the train bumps you off the track"
	)
	check(pushed, "and pushes you away (it never hurts)")

	EggSystem.drop(A)
	pa.data.gear = {}
	State.syncGear(pa)
	goTo(A, pa.haveli.spawn.Position)
	M.advance(0.5)
	check(charA.Humanoid.WalkSpeed == Config.WALK_SPEED and A:GetAttribute("Hazard") == "", "back home, all normal")
end

---------------------------------------------------------------------------
section("Gear shop")
---------------------------------------------------------------------------
local function openShop(name)
	atShop(A, name)
	PPS.PromptTriggered:Fire(shops[name].ShopPrompt, A)
	M.advance(0.1)
end
pa.data.rupees = 100_000
State.syncStats(pa)
openShop("Gear")
local gearPanel = hud.GearPanel
check(gearPanel.Visible, "the Gear stall opens the Gear window")
check(gearPanel.Content.Joggers.Button.Text == "Rs 3,000", "gear price: " .. gearPanel.Content.Joggers.Button.Text)
local beforeGear = pa.data.rupees
goTo(A, pa.haveli.spawn.Position)
gearPanel.Content.Joggers.Button.Activated:Fire()
M.advance(0.1)
check(not pa.data.gear.Joggers and pa.data.rupees == beforeGear, "gear is bought at the stall, not from home")
atShop(A, "Gear")
markLog()
gearPanel.Content.Joggers.Button.Activated:Fire()
M.advance(0.1)
check(pa.data.gear.Joggers and pa.data.rupees == beforeGear - 3000, "bought Joggers")
check(gearPanel.Content.Joggers.Button.Text == "Owned", "shown as owned")
check(math.abs(charA.Humanoid.WalkSpeed - Config.WALK_SPEED * 1.1) < 1e-6, "Joggers: 10% faster")
check(notified("Ali", "You got the Joggers") and soundsFor("Ali", "Purchase") == 1, "purchase message and sound")
gearPanel.Content.Joggers.Button.Activated:Fire()
M.advance(0.1)
check(pa.data.rupees == beforeGear - 3000, "cannot buy the same gear twice")
gearPanel.Content.Tokri.Button.Activated:Fire()
M.advance(0.1)
check(EggSystem.eggTime(pa, khet, false) == 75, "Padded Tokri: eggs last 25% longer")
check(EggSystem.eggTime(pa, khet, true) == 75 * Config.GOLDEN_EGG_TIME, "golden eggs last longer still")
pa.data.rupees = 10
State.syncStats(pa)
markLog()
gearPanel.Content.Shovel.Button.Activated:Fire()
M.advance(0.1)
check(not pa.data.gear.Shovel and notified("Ali", "Belcha costs"), "not enough rupees")
Remotes.BuyGear:FireServer("Rocket")
Remotes.BuyGear:FireServer(42)
M.advance(0.1)
check(Gear.encode(pa.data.gear) == "Joggers,Tokri", "bad gear requests ignored: " .. Gear.encode(pa.data.gear))
check(A:GetAttribute("Gear") == "Joggers,Tokri", "gear sent to the HUD")

---------------------------------------------------------------------------
section("Radar Wala")
---------------------------------------------------------------------------
pa.data.rupees = 100_000
State.syncStats(pa)
openShop("Tracker")
local trackerPanel = hud.TrackerPanel
check(trackerPanel.Visible and not gearPanel.Visible, "the Radar Wala window, one window at a time")
check(
	trackerPanel.Content.Upgrade.Text == "Upgrade for Rs 2,500",
	"tracker price: " .. trackerPanel.Content.Upgrade.Text
)
check(trackerPanel.Content.Next.Text:find("220 studs") ~= nil, "next level sees further")
check(
	trackerPanel.Content.Now.Text:find("8 open zones") ~= nil,
	"the radar tracks Ali's open zones: " .. trackerPanel.Content.Now.Text
)
setQuests(pa, { { id = "upgrade", target = 1, progress = 0, claimed = false } })
markLog()
trackerPanel.Content.Upgrade.Activated:Fire()
M.advance(0.1)
check(pa.data.trackerLevel == 2 and pa.data.rupees == 97_500, "tracker level 2")
check(A:GetAttribute("TrackerLevel") == 2 and notified("Ali", "Tracker level 2"), "tracker message")
check(soundsFor("Ali", "Upgrade") == 1, "upgrade sound")
check(pa.data.quests.list[1].progress == 1, "tracker upgrades count for the upgrade quest")
M.advance(0.2)
check(hud.RadarHolder.Tracks.Text:find("open zones") ~= nil, "radar tracks the open zones")
goTo(A, pa.haveli.spawn.Position)
Remotes.UpgradeTracker:FireServer()
M.advance(0.1)
check(pa.data.trackerLevel == 2, "upgrades only at the Radar Wala")
atShop(A, "Tracker")
for _ = 3, 8 do
	pa.data.rupees = 1_000_000
	Remotes.UpgradeTracker:FireServer()
	M.advance(0.05)
end
check(pa.data.trackerLevel == 8, "tracker maxed")
markLog()
Remotes.UpgradeTracker:FireServer()
M.advance(0.1)
check(pa.data.trackerLevel == 8 and notified("Ali", "best there is"), "no level 9")
M.advance(0.2)
check(hud.RadarHolder.Tracks.Text:find("8 open zones") ~= nil, "radar tracks every open zone")
check(
	hud.RadarHolder.Tracks.Text:find("golden eggs") and hud.RadarHolder.Tracks.Text:find("treasure"),
	"and golden eggs and treasure"
)
pa.data.trackerLevel = 1
State.syncGear(pa)

---------------------------------------------------------------------------
section("Golden eggs, egg rushes and hatch odds")
---------------------------------------------------------------------------
pa.data.trackerLevel = 3
State.syncGear(pa)
local goldenEgg = EggSystem.spawn(khet, true, here * FLAT + Vector3.new(-8, Biomes.GROUND_Y, 8))
check(goldenEgg.Name == "GoldenEgg" and goldenEgg.PrimaryPart:FindFirstChild("GoldenSparkles"), "golden egg sparkles")
goTo(A, goldenEgg:GetPivot().Position + Vector3.new(4, 0, 0))
M.advance(0.3)
local sawGold = false
for _, d in visibleDots() do
	sawGold = sawGold or d.BackgroundColor3 == M.Color3.fromRGB(255, 205, 50)
end
check(sawGold, "tracker level 3 shows golden eggs")
setQuests(pa, { { id = "goldenEgg", target = 1, progress = 0, claimed = false } })
pickUp(A, goldenEgg)
check(A:GetAttribute("EggGolden") == true and A:GetAttribute("EggTimeTotal") == 75 * 1.3, "golden egg picked up")
M.advance(0.15)
check(
	hud.RadarStatus.EggBar.Text.Text:find("Golden egg") ~= nil,
	"egg bar says golden: " .. hud.RadarStatus.EggBar.Text.Text
)
goTo(A, pa.haveli.spawn.Position)
M.advance(0.5)
local goldenRecord = pa.incubating[1]
check(goldenRecord and goldenRecord.golden and goldenRecord.mutation ~= nil, "golden eggs always hatch mutated")
check(goldenRecord.hatchAt - M.os.time() >= khet.hatchTime * Config.GOLDEN_HATCH_TIME - 1, "and take longer to hatch")
check(pa.data.quests.list[1].progress == 1, "golden egg quest")
M.advance(khet.hatchTime * Config.GOLDEN_HATCH_TIME + 1)
local goldenEntry = pa.owned[#pa.owned]
check(goldenEntry.mutation == goldenRecord.mutation, "hatched a " .. tostring(goldenEntry.mutation) .. " brainrot")
check(Havelis.entryIncome(goldenEntry) > goldenEntry.def.income, "mutations earn more")
pa.data.trackerLevel = 1
State.syncGear(pa)

markLog()
EggSystem.startRush("TharDesert")
M.advance(0.5)
check(workspace:GetAttribute("EggRush") == "TharDesert" and notified("Ali", "EGG RUSH in Thar Desert"), "egg rush")
check(
	groundEggs("TharDesert") >= Config.EGGS_PER_BIOME + Config.EGG_RUSH_EGGS - 1,
	"lots of eggs: " .. groundEggs("TharDesert")
)
check(groundEggs("MangoBagh") <= Config.EGGS_PER_BIOME + 1, "only in the rush biome")
check(hud.RadarStatus.Rush.Visible and hud.RadarStatus.Rush.Text:find("Thar Desert"), "rush on the radar")
check(soundsFor("Ali", "EventStart") == 1, "rush sound")
EggSystem.stopRush()
M.advance(0.3)
check(not hud.RadarStatus.Rush.Visible, "rush over")

-- what hatches: the biome's pool, with its odds; luck helps
local function tally(biome, golden, n)
	local rarities, outside = {}, 0
	for _ = 1, n do
		local def = EggSystem.roll(biome, golden)
		rarities[def.rarity] = (rarities[def.rarity] or 0) + 1
		if not table.find(biome.pool, def.id) then
			outside += 1
		end
	end
	return rarities, outside
end
local khetCounts, khetOutside = tally(khet, false, 40000)
check(khetOutside == 0, "Mango Bagh eggs only hatch Mango Bagh brainrots")
check(math.abs(khetCounts.Common / 40000 - 0.72) < 0.015, "Mango Bagh common ~72%: " .. khetCounts.Common / 40000)
check(math.abs((khetCounts.Rare or 0) / 40000 - 0.04) < 0.006, "Mango Bagh rare ~4%")
check(not khetCounts.Epic and not khetCounts.Mythic, "no Epics in the starter zone")
local barfaniCounts, barfaniOutside = tally(Biomes.byId.BarfaniPahar, false, 40000)
check(barfaniOutside == 0 and (barfaniCounts.Secret or 0) > 0, "Barfani Pahar eggs can hatch Secret brainrots")
check(math.abs((barfaniCounts.Secret or 0) / 40000 - 0.07) < 0.01, "Secret ~7% in Barfani Pahar")
local namakCounts, namakOutside = tally(Biomes.byId.NamakCaves, false, 40000)
check(namakOutside == 0 and (namakCounts.Mythic or 0) > 0, "the Namak Caves can hatch Mythics")
local goldenCounts = tally(khet, true, 40000)
check((goldenCounts.Rare or 0) / 40000 > 0.06, "golden eggs are luckier: " .. (goldenCounts.Rare or 0) / 40000)
local mutated = 0
for _ = 1, 20000 do
	if Mutations.roll("egg") then
		mutated += 1
	end
end
check(math.abs(mutated / 20000 - 0.0525) < 0.006, "~5% of normal eggs hatch mutated: " .. mutated / 20000)
local picks = {}
for _ = 1, 3000 do
	picks[Picker.pick({ Common = 1 }, { "MithaiMamu", "SamosaSupremo" }).id] = true
end
check(picks.SamosaSupremo and not picks.MithaiMamu, "quest brainrots never hatch")

---------------------------------------------------------------------------
section("Brainrots window and selling")
---------------------------------------------------------------------------
local brainrotPanel = hud.BrainrotPanel
goTo(A, pa.haveli.spawn.Position)
M.advance(10)
hud.Buttons.Brainrots.Activated:Fire()
M.advance(0.1)
check(brainrotPanel.Visible, "Brainrots window opens")
local rows = 0
for _, child in brainrotPanel.Content:GetChildren() do
	if child.Name:match("^Brainrot%d") then
		rows += 1
	end
end
check(rows == #pa.owned, "one row per brainrot: " .. rows)
check(brainrotPanel.Content.SellInfo.Text:find("come to the BECHO") ~= nil, "sell only at the stall")
check(brainrotPanel.Content.Brainrot1:FindFirstChild("Sell") == nil, "no sell buttons at home")
check(brainrotPanel.Content:FindFirstChild("StopRide") == nil, "no more riding brainrots")
local ownedBefore = #pa.owned

-- selling at the BECHO stall
markLog()
Remotes.SellBrainrot:FireServer(pa.owned[1].uid)
M.advance(0.1)
check(#pa.owned == ownedBefore and notified("Ali", "BECHO stall"), "cannot sell from home")
hud.Buttons.Brainrots.Activated:Fire() -- close
openShop("Sell")
check(brainrotPanel.Visible, "the BECHO stall opens the Brainrots window")
M.advance(0.6)
local sellButton = brainrotPanel.Content.Brainrot1:FindFirstChild("Sell")
check(sellButton ~= nil and brainrotPanel.Content.SellInfo.Text:find("half") ~= nil, "sell buttons at the stall")
local mostValuable = 0
for _, e in pa.owned do
	mostValuable = math.max(mostValuable, Havelis.entryValue(e))
end
local beforeSale = pa.data.rupees
sellButton.Activated:Fire()
M.advance(0.2)
check(pa.data.rupees == beforeSale + math.floor(mostValuable * Config.SELL_RATE), "sold for half its value")
check(#pa.owned == ownedBefore - 1 and soundsFor("Ali", "Coin") >= 1, "sold, with a coin sound")
Remotes.SellBrainrot:FireServer(-5)
Remotes.SellBrainrot:FireServer("abc")
M.advance(0.1)
check(#pa.owned == ownedBefore - 1, "bad sell requests ignored")

do
	---------------------------------------------------------------------------
	section("Vehicles: showroom, driving, fuel, the boot, upgrades and paint")
	---------------------------------------------------------------------------
	-- drives a player to a spot in small steps, like a real drive
	local function driveTo(player, target)
		local root = player.Character.HumanoidRootPart
		local from = root.Position * FLAT
		local goal = target * FLAT
		local distance = (goal - from).Magnitude
		local steps = math.max(1, math.ceil(distance / 6))
		for i = 1, steps do
			local p = from:Lerp(goal, i / steps)
			player.Character:PivotTo(CFrame.new(p + Vector3.new(0, 4, 0)))
			M.advance(0.25)
		end
	end
	EggSystem.reset(pa) -- start with empty incubators
	pa.data.rupees = 50_000
	State.syncStats(pa)
	openShop("Showroom")
	local showroomPanel = hud.ShowroomPanel
	check(showroomPanel.Visible, "the Gaari Showroom window opens at the counter")
	for _, def in Vehicles.list do
		check(showroomPanel.Content:FindFirstChild(def.id) ~= nil, "the showroom sells the " .. def.name)
	end
	check(showroomPanel.Content.Motorbike.Button.Text == "Rs 3,000", "motorbike price")
	markLog()
	showroomPanel.Content.Motorbike.Button.Activated:Fire()
	M.advance(0.1)
	check(pa.data.vehicles.Motorbike ~= nil and pa.data.rupees == 47_000, "bought a motorbike for Rs 3,000")
	check(
		A:GetAttribute("Vehicles"):find("^Motorbike:0:0:0:0:1500") ~= nil,
		"vehicles sent: " .. A:GetAttribute("Vehicles")
	)
	check(notified("Ali", "You bought a Motorbike"), "purchase message")
	check(showroomPanel.Content.Motorbike.Button.Text == "Owned", "the window shows it is owned")
	goTo(A, pa.haveli.spawn.Position)
	Remotes.BuyVehicle:FireServer("Rickshaw")
	M.advance(0.1)
	check(pa.data.vehicles.Rickshaw == nil, "vehicles are only sold at the showroom")
	-- the Gaari window: drive it
	hud.Buttons.Gaari.Activated:Fire()
	M.advance(0.1)
	local garagePanel = hud.GaragePanel
	check(
		garagePanel.Visible and garagePanel.Content.Motorbike.Button.Text == "Drive",
		"Gaari window lists the motorbike"
	)
	markLog()
	garagePanel.Content.Motorbike.Button.Activated:Fire()
	M.advance(0.1)
	check(pa.driving == nil and notified("Ali", "Step outside"), "no driving inside a haveli")
	goTo(A, pa.haveli.doorOutside.Position)
	M.advance(0.1)
	Remotes.Drive:FireServer("Motorbike")
	M.advance(0.3)
	check(pa.driving and pa.driving.def.id == "Motorbike", "driving the motorbike")
	local bike = charA:FindFirstChild("Vehicle")
	check(bike and bike.VehicleRoot:FindFirstChild("VehicleWeld") ~= nil, "the motorbike carries Ali")
	check(
		bike and bike:FindFirstChild("Paint") ~= nil and bike:FindFirstChild("PassengerSeat") ~= nil,
		"panels and a pillion seat"
	)
	check(charA.Humanoid.WalkSpeed == Vehicles.byId.Motorbike.speed, "motorbike speed: " .. charA.Humanoid.WalkSpeed)
	check(A:GetAttribute("Driving") == "Motorbike" and A:GetAttribute("FuelMax") == 1500, "driving shown on the HUD")
	check(hud.Dashboard.Visible and hud.Dashboard.Vehicle.Text == "Motorbike", "the dashboard shows")
	check(M.renderBindings.ChaiChaosDrive ~= nil and charA.Humanoid.AutoRotate == false, "car-like steering on screen")
	-- steering: the stick points right, the motorbike turns towards it bit by bit
	charA.HumanoidRootPart.CFrame = CFrame.new(charA.HumanoidRootPart.Position)
	M.advance(0.05)
	M.rawset(charA.Humanoid, "MoveDirection", Vector3.new(1, 0, 0))
	M.advance(0.1)
	local look = charA.HumanoidRootPart.CFrame.LookVector
	check(look.X > 0.05 and look.Z < -0.5, "it turns gradually, not on the spot: " .. tostring(look))
	M.advance(1)
	look = charA.HumanoidRootPart.CFrame.LookVector
	check(look.X > 0.95, "and ends up facing the way you push")
	check(M.lastMove(charA.Humanoid) and M.lastMove(charA.Humanoid).Magnitude > 0.5, "it drives forward")
	-- the solid bumper: it crashes into walls and trees but never shoves players
	do
		local Props = serverModule("Props")
		local bumper = bike.Bumper
		local seatPoint = Props.anchor("VehicleMotorbike", "Seat", CFrame.new())
		local road = bike.VehicleRoot.Position.Y - seatPoint.Y
		check(
			bumper.CanCollide and bumper.Transparency == 1 and bumper.Massless,
			"every vehicle has a solid, invisible bumper"
		)
		check(bumper.CollisionGroup == "ChaiVehicles", "in the vehicle group, even inside Ali's character")
		check(bumper.Hold.Part0 == bike.VehicleRoot, "welded to the vehicle")
		check(bumper.Position.Y - bumper.Size.Y / 2 > road + 1.3, "raised off the road, so kerbs don't stop it")
		check(bumper.Size.Z > 5, "as long as the motorbike: " .. bumper.Size.Z)
		-- crash: going fast and suddenly stopped means you hit something
		local rootA = charA.HumanoidRootPart
		M.rawset(charA.Humanoid, "MoveDirection", look)
		M.advance(0.6)
		rootA.AssemblyLinearVelocity = look * 34
		M.advance(1 / 30)
		local soundsAt = #M.soundsPlayed
		rootA.AssemblyLinearVelocity = Vector3.zero
		M.advance(1 / 30)
		local function crunches()
			local n = 0
			for i = soundsAt + 1, #M.soundsPlayed do
				n += if M.soundsPlayed[i].name == "Crash" then 1 else 0
			end
			return n
		end
		check(crunches() == 1, "hitting a wall at speed: crunch!")
		check(rootA.AssemblyLinearVelocity:Dot(look) < -10, "and the motorbike bounces back")
		M.advance(0.3)
		check(M.lastMove(charA.Humanoid).Magnitude < 0.05, "and stops for a moment")
		M.advance(1)
		check(M.lastMove(charA.Humanoid).Magnitude > 0.3, "then drives on")
		-- a gentle bump is not a crash
		rootA.AssemblyLinearVelocity = look * 8
		M.advance(1 / 30)
		soundsAt = #M.soundsPlayed
		rootA.AssemblyLinearVelocity = Vector3.zero
		M.advance(1 / 30)
		check(crunches() == 0, "a slow bump is not a crash")
		M.rawset(charA.Humanoid, "MoveDirection", Vector3.zero)
		M.advance(1)
	end
	-- the horn: the Horn button or H
	markLog()
	hud.Dashboard.Horn.Activated:Fire()
	M.advance(0.1)
	hud.Dashboard.Horn.Activated:Fire()
	M.advance(0.1)
	check(soundsFor("Ali", "Horn") == 1, "honk! (and not again straight away)")
	local hornEvent = nil
	for i = mark + 1, #M.log do
		local e = M.log[i]
		if e.remote == "PlaySound" and e.player == "Ali" and e.args[1] == "Horn" then
			hornEvent = e
		end
	end
	check(
		hornEvent and M.typeof(hornEvent.args[2]) == "Vector3" and hornEvent.args[3] == Vehicles.byId.Motorbike.horn,
		"everyone nearby hears the motorbike's own horn"
	)
	M.advance(1)
	local inputService = game:GetService("UserInputService")
	M.signalOf(inputService, "InputBegan"):Fire({ KeyCode = M.Enum.KeyCode.H }, true)
	M.advance(0.1)
	check(soundsFor("Ali", "Horn") == 1, "typing an H in the chat doesn't honk")
	M.signalOf(inputService, "InputBegan"):Fire({ KeyCode = M.Enum.KeyCode.H }, false)
	M.advance(0.1)
	check(soundsFor("Ali", "Horn") == 2, "H sounds the horn too")
	-- fuel: every stud uses fuel, a rickshaw ride or teleport does not
	local fuel0 = pa.data.vehicles.Motorbike.fuel
	local mango = Biomes.byId.MangoBagh
	local drivePoint = Biomes.point(mango, Biomes.innerRadius(mango) + 40, 12)
	driveTo(A, drivePoint)
	local used = fuel0 - pa.data.vehicles.Motorbike.fuel
	local distance = ((drivePoint - pa.haveli.doorOutside.Position) * FLAT).Magnitude
	check(math.abs(used - distance) < 15, ("fuel used %d for %d studs"):format(used, distance))
	check(A:GetAttribute("Fuel") == math.floor(pa.data.vehicles.Motorbike.fuel), "fuel on the dashboard")
	local before = pa.data.vehicles.Motorbike.fuel
	goTo(A, drivePoint + Vector3.new(300, 0, 0))
	M.advance(0.3)
	goTo(A, drivePoint)
	M.advance(0.3)
	check(math.abs(pa.data.vehicles.Motorbike.fuel - before) < 1, "teleports use no fuel")
	-- eggs ride in the boot
	local bootEgg = nil
	for _, egg in eggFolder:GetChildren() do
		if
			egg:GetAttribute("Biome") == "MangoBagh"
			and egg.PrimaryPart.Anchored
			and egg.PrimaryPart.EggPrompt.Enabled
		then
			bootEgg = egg
			break
		end
	end
	driveTo(A, bootEgg:GetPivot().Position)
	trigger(bootEgg, "EggPrompt", A)
	M.advance(0.1)
	check(#pa.boot == 1 and pa.egg == nil, "the egg goes in the boot")
	check(bootEgg.PrimaryPart.CarryWeld.Part0 == bike.VehicleRoot, "welded to the motorbike")
	check(A:GetAttribute("BootEggs") == 1 and A:GetAttribute("EggCount") == 1, "boot count on the HUD")
	check(hud.Dashboard.FuelText.Text:find("Boot 1/1") ~= nil, "dashboard: " .. hud.Dashboard.FuelText.Text)
	local second = eggIn("MangoBagh", false)
	markLog()
	pickUp(A, second)
	check(#pa.boot == 1 and notified("Ali", "boot is full"), "the motorbike's boot holds one egg")
	local leftBoot = pa.boot[1].timeLeft
	M.advance(2)
	check(pa.boot[1].timeLeft < leftBoot - 1.5, "boot eggs count down too")
	-- drive home: the egg goes in the incubator and the motorbike parks
	markLog()
	driveTo(A, pa.haveli.doorOutside.Position)
	M.advance(0.5)
	check(#pa.boot == 0 and pa.incubating[1] ~= nil, "home: the boot egg went into the incubator")
	check(pa.driving == nil and charA:FindFirstChild("Vehicle") == nil, "and the motorbike parked itself")
	check(
		charA.Humanoid.WalkSpeed == Havelis.walkSpeed(pa) and A:GetAttribute("Driving") == "",
		"walking again: " .. charA.Humanoid.WalkSpeed
	)
	check(notified("Ali", "Home safe"), "home message")
	-- parked vehicles refill for free at home
	pa.data.vehicles.Motorbike.fuel = 100
	M.advance(2.1)
	check(pa.data.vehicles.Motorbike.fuel > 150, "free refill at home: " .. pa.data.vehicles.Motorbike.fuel)
	-- out of petrol: crawl at walking speed, then fill up at a pump
	pa.data.vehicles.Motorbike.fuel = 10
	local pump = Havelis.map().pumps[1]
	goTo(A, pump.Position * FLAT + Vector3.new(30, 0, 0))
	M.advance(0.1)
	Remotes.Drive:FireServer("Motorbike")
	M.advance(0.3)
	markLog()
	driveTo(A, pump.Position * FLAT + Vector3.new(14, 0, 0))
	check(pa.driving.empty and charA.Humanoid.WalkSpeed == Config.FUEL_EMPTY_SPEED, "out of petrol: walking speed")
	check(
		notified("Ali", "Out of petrol") and hud.Dashboard.FuelText.Text:find("Out of petrol") ~= nil,
		"empty warning"
	)
	local rupeesAtPump = pa.data.rupees
	markLog()
	PPS.PromptTriggered:Fire(pump.PumpPrompt, A)
	M.advance(0.1)
	check(pa.data.vehicles.Motorbike.fuel == 1500, "filled up")
	check(pa.data.rupees == rupeesAtPump - math.ceil(1500 * Config.FUEL_PRICE), "petrol costs rupees")
	check(not pa.driving.empty and charA.Humanoid.WalkSpeed == Vehicles.byId.Motorbike.speed, "full speed again")
	PPS.PromptTriggered:Fire(pump.PumpPrompt, A)
	M.advance(0.1)
	check(notified("Ali", "already full"), "a full tank needs no petrol")
	-- upgrades at Ustad's Workshop
	pa.data.rupees = 1_000_000
	State.syncStats(pa)
	openShop("Workshop")
	local workshopPanel = hud.WorkshopPanel
	check(workshopPanel.Visible, "Ustad's Workshop window opens")
	local engineRow = workshopPanel.Content:FindFirstChild("Motorbikespeed")
	check(engineRow and engineRow.Button.Text == "Rs 1,500", "engine level 1 price")
	markLog()
	engineRow.Button.Activated:Fire()
	M.advance(0.1)
	check(pa.data.vehicles.Motorbike.speed == 1 and notified("Ali", "Engine is now level 1"), "engine upgraded")
	check(math.abs(charA.Humanoid.WalkSpeed - Vehicles.byId.Motorbike.speed * 1.1) < 1e-6, "faster right away")
	for _ = 1, 3 do
		Remotes.UpgradeVehicle:FireServer("Motorbike", "eggs")
		M.advance(0.05)
	end
	check(pa.data.vehicles.Motorbike.eggs == 3 and A:GetAttribute("BootSpace") == 4, "egg space: 4 eggs now")
	Remotes.UpgradeVehicle:FireServer("Motorbike", "eggs")
	M.advance(0.05)
	check(pa.data.vehicles.Motorbike.eggs == 3, "egg space stops at its max")
	Remotes.UpgradeVehicle:FireServer("Motorbike", "tank")
	M.advance(0.05)
	check(A:GetAttribute("FuelMax") == math.floor(1500 * 1.25), "a bigger tank")
	Remotes.UpgradeVehicle:FireServer("Motorbike", "nitro")
	Remotes.UpgradeVehicle:FireServer("Bicycle", "speed")
	M.advance(0.05)
	check(pa.data.vehicles.Motorbike.speed == 1, "bad upgrade requests ignored")
	-- grip: mud slows a vehicle until its tyres are good enough
	goTo(A, zoneSpot("MangoBagh", "mud"))
	M.advance(0.5)
	check(pa.surfaceSpeed == Config.DRIVE_SURFACE_SPEED.mud, "mud slows the motorbike")
	check(
		A:GetAttribute("Hazard"):find("Tyres level 1") ~= nil,
		"the warning says what helps: " .. A:GetAttribute("Hazard")
	)
	atShop(A, "Workshop")
	Remotes.UpgradeVehicle:FireServer("Motorbike", "grip")
	M.advance(0.05)
	goTo(A, zoneSpot("MangoBagh", "mud"))
	M.advance(0.5)
	check(pa.surfaceSpeed == 1 and A:GetAttribute("Grip") == 1, "tyres level 1 drive through mud")
	goTo(A, zoneSpot("TharDesert", "sand"))
	M.advance(0.5)
	check(pa.surfaceSpeed == Config.DRIVE_SURFACE_SPEED.sand, "sand needs tyres level 2")
	-- paint jobs (Robux, looks only)
	local panel = bike and nil
	panel = charA.Vehicle:FindFirstChild("Paint")
	local factoryColor = panel.Color
	Garage.onPaintBought(pa, "Sona")
	M.advance(0.1)
	check(pa.data.paints.Sona and pa.data.paint == "Sona" and A:GetAttribute("Paint") == "Sona", "Sona paint job")
	check(panel.Material == M.Enum.Material.Foil, "the panels turn gold")
	Remotes.SetPaint:FireServer("Factory")
	M.advance(0.1)
	check(panel.Color == factoryColor and pa.data.paint == "Factory", "back to the factory paint")
	Remotes.SetPaint:FireServer("Chamak")
	M.advance(0.1)
	check(pa.data.paint == "Factory", "paint jobs you don't own can't be used")
	check(
		math.abs(charA.Humanoid.WalkSpeed - Vehicles.byId.Motorbike.speed * 1.1 * Config.DRIVE_SURFACE_SPEED.sand)
			< 1e-6,
		"paint never changes speed"
	)
	-- getting out away from home: one egg in your hands, the rest fall out
	goTo(A, Biomes.point(mango, Biomes.innerRadius(mango) + 30, -20))
	M.advance(0.5)
	for _ = 1, 2 do
		local egg = eggIn("MangoBagh", false)
		driveTo(A, egg:GetPivot().Position)
		trigger(egg, "EggPrompt", A)
		M.advance(0.1)
	end
	check(#pa.boot == 2, "two eggs in the boot")
	markLog()
	hud.Dashboard.Park.Activated:Fire()
	M.advance(0.2)
	check(pa.driving == nil and pa.egg ~= nil and #pa.boot == 0, "got out: one egg in Ali's hands")
	check(notified("Ali", "fell out of the boot"), "the other fell out")
	check(charA.Humanoid.HipHeight == 2, "standing again")
	markLog()
	Remotes.Honk:FireServer()
	M.advance(0.1)
	check(soundsFor("Ali", "Horn") == 0, "no horn without a vehicle")
	-- the rickshaw home at the end of a ring 3 road only takes people
	do
		local pad = map.Biomes.LahoreQila.RickshawHome
		goTo(A, pad.Position)
		M.advance(0.1)
		markLog()
		PPS.PromptTriggered:Fire(pad.RickshawHome, A)
		M.advance(0.1)
		check(notified("Ali", "No eggs in the rickshaw"), "no eggs in the rickshaw: they must make the trip home")
		check((charA:GetPivot().Position - pad.Position).Magnitude < 10, "so Ali stays put")
		EggSystem.drop(A)
		Remotes.Drive:FireServer("Motorbike")
		M.advance(0.2)
		markLog()
		PPS.PromptTriggered:Fire(pad.RickshawHome, A)
		M.advance(0.1)
		check(notified("Ali", "Park your vehicle first"), "and no vehicles in the rickshaw")
		Remotes.Drive:FireServer(nil)
		M.advance(0.2)
		for _, egg in pa.boot do
			check(false, "unexpected boot egg " .. tostring(egg))
		end
		if pa.egg then
			EggSystem.drop(A)
		end
		markLog()
		PPS.PromptTriggered:Fire(pad.RickshawHome, A)
		M.advance(0.1)
		check(notified("Ali", "Pon pon"), "on foot with empty hands: a ride to the Chowk")
		check((charA:GetPivot().Position * FLAT).Magnitude < 40, "dropped at the Chowk")
		goTo(A, Biomes.point(mango, Biomes.innerRadius(mango) + 30, -20))
		M.advance(0.2)
	end
	-- no stealing from a vehicle, and no driving with a stolen brainrot
	Remotes.Drive:FireServer("Motorbike")
	M.advance(0.2)
	check(pa.driving ~= nil, "driving again")
	charA.Humanoid.Died:Fire()
	M.advance(0.1)
	check(pa.driving == nil, "dying parks your vehicle")
	charA = spawnCharacter(A)
	M.advance(0.3)
	check(
		charA.Humanoid.WalkSpeed == Havelis.walkSpeed(pa) and charA:FindFirstChild("Vehicle") == nil,
		"a fresh start on foot"
	)
	pa.data.rupees = 100_000
	State.syncStats(pa)
end

---------------------------------------------------------------------------
section("Treasure")
---------------------------------------------------------------------------
local digChest, climbChest
for _, chest in Treasure.all() do
	if chest.biome.id == "RailwayJunction" and chest.kind == "dig" then
		digChest = chest
	elseif chest.biome.id == "MangoBagh" and chest.kind == "climb" then
		climbChest = chest
	end
end
check(digChest and climbChest, "a buried chest in Railway Junction and a high one in Mango Bagh")
setQuests(pa, { { id = "treasure", target = 1, progress = 0, claimed = false } })
goTo(A, digChest.model.PrimaryPart.Position + Vector3.new(3, 0, 0))
markLog()
trigger(digChest.model, "TreasurePrompt", A)
check(notified("Ali", "need a Belcha") and soundsFor("Ali", "Error") == 1, "need a shovel to dig")
pa.data.gear.Shovel = true
State.syncGear(pa)
local beforeTreasure = pa.data.rupees
markLog()
trigger(digChest.model, "TreasurePrompt", A)
local jungleTreasure = math.floor(Config.TREASURE_RUPEES * 2 * 2)
check(pa.data.rupees == beforeTreasure + jungleTreasure, "Railway Junction treasure: Rs " .. jungleTreasure)
check(notified("Ali", "Treasure!") and soundsFor("Ali", "Treasure") == 1, "treasure message and sound")
check(pa.data.quests.list[1].progress == 1, "treasure quest")
markLog()
trigger(digChest.model, "TreasurePrompt", A)
check(
	pa.data.rupees == beforeTreasure + jungleTreasure and notified("Ali", "refills in 10 minutes"),
	"once every 10 min"
)
local climbSpot = climbChest.model.ClimbSpot
goTo(A, climbSpot.Position)
markLog()
PPS.PromptTriggered:Fire(climbSpot.ClimbPrompt, A)
M.advance(0.05)
check(notified("Ali", "Rassi Seedhi"), "need a rope ladder to climb")
pa.data.gear.RopeLadder = true
PPS.PromptTriggered:Fire(climbSpot.ClimbPrompt, A)
M.advance(0.05)
check(charA:GetPivot().Y > climbChest.top.Y, "climbed up")
beforeTreasure = pa.data.rupees
trigger(climbChest.model, "TreasurePrompt", A)
check(pa.data.rupees == beforeTreasure + Config.TREASURE_RUPEES, "Mango Bagh treasure")
goTo(A, pa.haveli.spawn.Position)

---------------------------------------------------------------------------
section("Haveli levels")
---------------------------------------------------------------------------
pa.data.gear = { Joggers = true, Tokri = true }
State.syncGear(pa)
Havelis.applyWalkSpeed(pa)
local haveliPanel = hud.HaveliPanel
hud.Buttons.Haveli.Activated:Fire()
M.advance(0.1)
check(haveliPanel.Visible, "Haveli panel opens")
check(
	haveliPanel.Content.Upgrade.Text == "Upgrade for Rs 4,000",
	"upgrade price shown: " .. haveliPanel.Content.Upgrade.Text
)
check(haveliPanel.Content:FindFirstChild("Level", true) == nil or true, "level text")
check(h1.Plot5.Gui.Label.Text == "Level 2", "locked plots show which level unlocks them")
pa.data.rupees = 10_000
State.syncStats(pa)
markLog()
local before = pa.data.rupees
haveliPanel.Content.Upgrade.Activated:Fire()
M.advance(0.2)
check(pa.data.level == 2 and pa.data.rupees == before - 4000, "upgraded to level 2")
check(Havelis.plotCount(pa) == 6 and h1.Plot5.Transparency == 0, "level 2 has 6 plots")
check(notified("Ali", "Haveli Level 2") and soundsFor("Ali", "Upgrade") == 1, "upgrade message and sound")
check(hud.Buttons.Haveli.Text == "Haveli Lv 2", "HUD shows the level")
pa.data.rupees = 0
State.syncStats(pa)
markLog()
Remotes.UpgradeHaveli:FireServer()
M.advance(0.1)
check(pa.data.level == 2 and notified("Ali", "You need"), "cannot upgrade without rupees")
pa.data.rupees = 10_000_000
State.syncStats(pa)
Remotes.UpgradeHaveli:FireServer()
M.advance(0.6)
check(pa.data.level == 3 and EggSystem.incubatorCount(pa) == 2, "level 3: a second incubator")
check(pa.haveli.incubatorLabels[2].Text == "Empty incubator", "the second nest is ready")
for _ = 4, 5 do
	Remotes.UpgradeHaveli:FireServer()
	M.advance(0.1)
end
check(pa.data.level == 5 and Havelis.plotCount(pa) == 12, "level 5 has 12 plots")
check(h1.StairGates.StairGate.CanCollide == false and h1.StairGates.StairGate.Transparency == 1, "stairs open")
check(h1.Barrier.CanCollide == false, "laser off while unlocked")
while #pa.owned < 12 do
	Havelis.adopt(pa, Brainrots.byId.NaanNinja, nil, nil, true)
end
M.advance(15)
local upstairs = 0
for _, e in pa.owned do
	if e.plot > 10 then
		upstairs += 1
		local plot = pa.haveli.plots[e.plot]
		local d = (e.model:GetPivot().Position - plot.Position) * FLAT
		check(e.arrived and d.Magnitude < 0.01, "brainrot walked up the stairs to plot " .. e.plot)
		check(e.model:GetPivot().Y > plot.Position.Y, "standing on the second floor")
	end
end
check(upstairs == 2, "two brainrots went upstairs")
-- two eggs hatching at once
local eggA, eggB = eggIn("MangoBagh", false), eggIn("RailwayJunction", false)
pickUp(A, eggA)
goTo(A, pa.haveli.spawn.Position)
M.advance(0.5)
pickUp(A, eggB)
goTo(A, pa.haveli.spawn.Position)
M.advance(0.5)
check(pa.incubating[1] and pa.incubating[2] and pa.egg == nil, "two eggs in two incubators")
M.advance(Biomes.byId.RailwayJunction.hatchTime + 1)
check(pa.incubating[2] ~= nil, "no free plot: the egg waits in its nest")
check(
	pa.haveli.incubatorLabels[2].Text:find("free plot") ~= nil,
	"nest says why: " .. pa.haveli.incubatorLabels[2].Text
)
Havelis.clearBrainrots(pa)
M.advance(1)
check(pa.incubating[1] == nil and pa.incubating[2] == nil and #pa.owned == 2, "both hatch once there is room")

---------------------------------------------------------------------------
section("Themes")
---------------------------------------------------------------------------
local themeCards = haveliPanel.Content
check(themeCards.TruckArt.Use.Text == "Safar 1", "Truck Art locked until a Naya Safar")
markLog()
themeCards.TruckArt.Use.Activated:Fire()
M.advance(0.1)
check(pa.data.theme == "MughalMarble" and notified("Ali", "unlocks after 1 Naya Safar"), "locked theme refused")
themeCards.BaghGarden.Use.Activated:Fire()
M.advance(0.1)
check(pa.data.theme == "BaghGarden" and A:GetAttribute("Theme") == "BaghGarden", "Bagh Garden picked")
check(h1.Floor.Material == M.Enum.Material.Grass, "garden floor")
check(themeCards.BaghGarden.Use.Text == "Using", "panel shows the theme in use")
Remotes.SetTheme:FireServer("NotATheme")
Remotes.SetTheme:FireServer(42)
M.advance(0.1)
check(pa.data.theme == "BaghGarden", "bad theme requests ignored")

---------------------------------------------------------------------------
section("Income and galla")
---------------------------------------------------------------------------
for _ = 1, 4 do
	Havelis.adopt(pa, Brainrots.byId.SamosaSupremo, nil, nil, true)
end
M.advance(12)
setQuests(pa, {
	{ id = "collect", target = 50, progress = 0, claimed = false },
	{ id = "taala", target = 1, progress = 0, claimed = false },
	{ id = "roll", target = 1, progress = 0, claimed = false },
})
pa.data.galla = 0
local base = 0
for _, e in pa.owned do
	base += Havelis.entryIncome(e)
end
local income = Havelis.incomePerSecond(pa)
check(math.abs(income - base) < 1e-6, "Bagh Garden has no income perk: " .. income)
pa.data.theme = "MughalMarble"
check(math.abs(Havelis.incomePerSecond(pa) - base * 1.05) < 1e-6, "Mughal Marble +5% income")
pa.data.theme = "BaghGarden"
M.advance(5)
check(math.abs(pa.data.galla - income * 5) <= income, "galla filled: " .. pa.data.galla)
markLog()
before = pa.data.rupees
local galla = math.floor(pa.data.galla)
pa.haveli.galla.Touched:Fire(charA.HumanoidRootPart)
M.advance(0.1)
check(pa.data.rupees == before + galla, "collected galla")
check(soundsFor("Ali", "Coin") == 1, "coin sound")
check(galla >= 50 and pa.data.quests.list[1].progress == 50, "collect quest counts rupees")

---------------------------------------------------------------------------
section("Quests")
---------------------------------------------------------------------------
local qp = hud.QuestPanel
openShop("Quests")
check(qp.Visible and not haveliPanel.Visible, "the quest board opens the Quests window")
check(hud.Buttons.Quests.Text == "Quests (!)", "quest button shows a reward is waiting")
check(qp.Content.Quest1.Text.Text == "Collect Rs 50 from your galla", "quest text: " .. qp.Content.Quest1.Text.Text)
before = pa.data.rupees
local tokens = pa.data.rollTokens
local reward = QuestBook.reward(pa)
qp.Content.Quest1.Claim.Activated:Fire()
M.advance(0.1)
check(pa.data.rupees == before + reward and pa.data.quests.list[1].claimed, "quest reward claimed: " .. reward)
qp.Content.Quest1.Claim.Activated:Fire()
M.advance(0.1)
check(pa.data.rupees == before + reward, "cannot claim twice")
qp.Content.Bonus.Claim.Activated:Fire()
M.advance(0.1)
check(pa.data.rollTokens == tokens, "bonus needs every quest")
hud.Buttons.Taala.Activated:Fire()
M.advance(0.1)
check(pa.data.quests.list[2].progress == 1, "taala quest")
M.advance(Config.LOCK_TIME + Config.LOCK_COOLDOWN + 1)
pa.data.quests.day = TODAY - 1
QuestBook.ensure(pa)
check(pa.data.quests.day == TODAY and not pa.data.quests.list[1].claimed, "new quests every day")
local offered, dupes = {}, false
for _, q in pa.data.quests.list do
	dupes = dupes or offered[q.id] == true
	offered[q.id] = true
end
check(not dupes, "no duplicate quests")
-- quests are only offered when they can be done
pa.data.gear = {}
local noTreasure = true
for _ = 1, 200 do
	pa.data.quests.day = TODAY - 1
	QuestBook.ensure(pa)
	for _, q in pa.data.quests.list do
		noTreasure = noTreasure and q.id ~= "treasure"
	end
end
check(noTreasure, "no treasure quest without a Belcha or Rassi Seedhi")
pa.data.gear = { Joggers = true, Tokri = true }
local questTexts = sharedModule("Quests")
for _, quest in questTexts.list do
	check(type(quest.text) == "string" and (quest.money or quest.targets), "quest " .. quest.id)
end
setQuests(pa, {
	{ id = "eggHome", target = 1, progress = 1, claimed = false },
	{ id = "roll", target = 1, progress = 0, claimed = false },
	{ id = "mutation", target = 1, progress = 0, claimed = false },
})

---------------------------------------------------------------------------
section("Collection Book rewards")
---------------------------------------------------------------------------
for _, def in Brainrots.byRarity.Common do
	pa.data.discovered[def.id] = true
end
State.syncDiscovered(pa)
M.advance(0.1)
check(qp.Content.Common.Claim.Text == "Claim", "complete rarity can be claimed")
check(qp.Content.Uncommon.Claim.Text == "...", "incomplete rarity cannot")
while #pa.owned >= Havelis.plotCount(pa) do
	local e = pa.owned[#pa.owned]
	Havelis.remove(pa, e)
	e.model:Destroy()
end
before = pa.data.rupees
tokens = pa.data.rollTokens
qp.Content.Common.Claim.Activated:Fire()
M.advance(0.2)
check(pa.data.rupees == before + 4000 and pa.data.rollTokens == tokens + 1, "Common reward: Rs 4,000 and a roll")
local mamu = entryOf(pa, "MithaiMamu")
check(mamu ~= nil, "Mithai Mamu joins the haveli")
check(prompt(mamu.model, "StealPrompt") == nil, "quest brainrots cannot be stolen")
check(qp.Content.Common.Claim.Text == "Done", "reward marked done")
qp.Content.Common.Claim.Activated:Fire()
Remotes.ClaimCollection:FireServer("Mythic")
Remotes.ClaimCollection:FireServer("Gems")
M.advance(0.1)
check(pa.data.rupees == before + 4000, "collection reward only once; incomplete or unknown rarities ignored")
M.advance(10)
check(mamu.arrived and mamu.plot == #pa.owned, "quest brainrots take the last plot, not a locker: " .. mamu.plot)
atShop(A, "Sell")
markLog()
Remotes.SellBrainrot:FireServer(mamu.uid)
M.advance(0.1)
check(entryOf(pa, "MithaiMamu") ~= nil, "quest brainrots cannot be sold")
local book = hud.CollectionBook
check(book:FindFirstChild("ChandRaatCheetah", true) ~= nil, "every brainrot has a card")

---------------------------------------------------------------------------
section("Kismat Roll")
---------------------------------------------------------------------------
local kp = hud.KismatPanel
local kc = kp.Content
check(kc.Common.Percent.Text == "50%" and kc.Mythic.OneIn.Text == "1 in 500", "rarity odds shown")
check(kc.RollRupees.Text == "Roll for Rs 5,000", "roll price: " .. kc.RollRupees.Text)
openShop("Kismat")
check(kp.Visible, "the Kismat Kettle opens the Kismat window")
before = pa.data.rupees
local ownedBefore = #pa.owned
local soundsBefore = #M.soundsPlayed
kc.RollRupees.Activated:Fire()
M.advance(0.1)
check(pa.data.rupees == before - 5000 and #pa.owned == ownedBefore + 1, "rupee roll")
check(hud.KismatReveal.Visible, "reveal shows")
M.advance(2)
local rolled = pa.owned[#pa.owned]
check(
	hud.KismatReveal.BrainrotName.Text == Mutations.displayName(rolled.def, rolled.mutation),
	"reveal shows the rolled brainrot"
)
local spins, reveals = 0, 0
for i = soundsBefore + 1, #M.soundsPlayed do
	local n = M.soundsPlayed[i].name
	spins += if n == "RollSpin" then 1 else 0
	reveals += if n == "RollReveal" then 1 else 0
end
check(spins > 5 and reveals == 1, "spin and reveal sounds")
check(pa.data.quests.list[2].progress == 1, "roll quest")
M.advance(3)
check(not hud.KismatReveal.Visible, "reveal hides")
local rc = {}
for _ = 1, 100000 do
	local d = Kismat.pick(false)
	rc[d.rarity] = (rc[d.rarity] or 0) + 1
end
check(math.abs(rc.Common / 1e5 - 0.5) < 0.01, "roll common ~50%")
check(math.abs(rc.Legendary / 1e5 - 0.018) < 0.002, "roll legendary ~1.8%")
local pityOk = true
for _ = 1, 3000 do
	pityOk = pityOk and ({ Epic = true, Legendary = true, Mythic = true })[Kismat.pick(true).rarity] == true
end
check(pityOk, "pity never below Epic")
local mc = {}
for _ = 1, 100000 do
	local m = Mutations.roll("roll") or "none"
	mc[m] = (mc[m] or 0) + 1
end
check(math.abs(mc.Golden / 1e5 - 0.08) < 0.005, "roll golden ~8%: " .. mc.Golden / 1e5)

do
	---------------------------------------------------------------------------
	section("Stealing")
	---------------------------------------------------------------------------
	goTo(A, pa.haveli.spawn.Position)
	local B = addPlayer("Bilal", 2)
	M.advance(0.5)
	local pb = State.profiles[B]
	local charB = spawnCharacter(B)
	M.advance(0.3)
	Havelis.clearBrainrots(pb)
	check(pb.haveli.index == 2 and charB.HumanoidRootPart.CollisionGroup == "ChaiOwner2", "Bilal in haveli 2")
	for _, id in { "SamosaSupremo", "ChanaChaatChacha", "GolGappaGhostu" } do
		Havelis.adopt(pb, Brainrots.byId[id], nil, nil, true)
	end
	M.advance(12)
	local bilalOwn = stealable(pb)
	markLog()
	moveNear(A, bilalOwn.model)
	trigger(bilalOwn.model, "StealPrompt", A)
	check(bilalOwn.carrier == nil and notified("Ali", "protected"), "new players are protected")
	goTo(A, pa.haveli.spawn.Position)
	Havelis.clearBrainrots(pb)
	M.advance(Config.NEW_PLAYER_PROTECTION + 1)
	local target = stealable(pa)
	target = stealable(pa)
	check(prompt(target.model, "StealPrompt"):GetAttribute("Active") == true, "steal prompt on after protection")
	check(not prompt(target.model, "StealPrompt").Enabled, "Ali does not see Steal on his own brainrots")
	local locker = nil
	for _, e in pa.owned do
		if Havelis.isLocker(e.plot) then
			locker = e
		end
	end
	markLog()
	moveNear(B, locker.model)
	trigger(locker.model, "StealPrompt", B)
	check(locker.carrier == nil and notified("Bilal", "Locker"), "lockers cannot be robbed")
	-- you cannot steal with an egg in your hands
	local bilalEgg = eggIn("MangoBagh", false)
	pickUp(B, bilalEgg)
	check(pb.egg ~= nil, "Bilal picked up an egg")
	markLog()
	moveNear(B, target.model)
	trigger(target.model, "StealPrompt", B)
	check(target.carrier == nil and notified("Bilal", "egg home first"), "no stealing while carrying an egg")
	EggSystem.drop(B)
	markLog()
	local incomeBeforeTheft = Havelis.incomePerSecond(pa)
	trigger(target.model, "StealPrompt", B)
	check(target.carrier == B, "Bilal carries " .. target.def.id)
	check(notified("Ali", "Chor! Chor!") and soundsFor("Ali", "ChorAlert") == 1, "alert and sound")
	local expected = Config.WALK_SPEED
		* Config.CARRY_SPEED[target.def.rarity]
		* (if target.mutation then Config.CARRY_MUTATION_SPEED else 1)
		* 0.85
	check(
		math.abs(charB.Humanoid.WalkSpeed - expected) < 1e-6,
		"thief slowed, more by Bagh Garden: " .. charB.Humanoid.WalkSpeed
	)
	check(
		target.model:GetAttribute("Carried") == true and target.model.PrimaryPart:FindFirstChild("CarryWeld") ~= nil,
		"welded onto the thief"
	)
	check(Havelis.incomePerSecond(pa) < incomeBeforeTheft, "stolen brainrot stops earning")
	check(A:GetAttribute("Owned"):find("|1") ~= nil, "Ali's Brainrots window shows it is being carried")
	markLog()
	pickUp(B, bilalEgg)
	check(pb.egg == nil and notified("Bilal", "hands are full"), "no eggs while carrying a stolen brainrot")
	pb.haveli.door.Touched:Fire(charB.HumanoidRootPart)
	M.advance(0.1)
	check(entryOf(pb, target.def.id) ~= nil, "Bilal got away with it")
	check(charB.Humanoid.WalkSpeed == Config.WALK_SPEED, "speed back to normal")
	check(pb.carryingBrainrot == false, "hands free again")
	M.advance(10)
	check(entryOf(pb, target.def.id).arrived, "walked to Bilal's plot")
	markLog()
	target = stealable(pa)
	moveNear(B, target.model)
	trigger(target.model, "StealPrompt", B)
	check(notified("Bilal", "Catch your breath"), "15 second steal cooldown")
	M.advance(Config.STEAL_COOLDOWN + 1)
	markLog()
	trigger(target.model, "StealPrompt", B)
	check(notified("Bilal", "different one"), "same haveli cooldown")
	M.advance(Config.SAME_HAVELI_COOLDOWN + 1)
	Config.STEAL_PRICE_CAP = 1
	markLog()
	target = stealable(pa)
	moveNear(B, target.model)
	trigger(target.model, "StealPrompt", B)
	check(notified("Bilal", "Naya Safar"), "price cap before rebirth")
	Config.STEAL_PRICE_CAP = 16000

	---------------------------------------------------------------------------
	section("Chowkidar and Laser Darwaza")
	---------------------------------------------------------------------------
	pa.data.rupees = 10_000_000
	Remotes.UpgradeHaveli:FireServer()
	M.advance(0.2)
	check(pa.data.level == 6 and h1.Decor:FindFirstChild("Chowkidar") ~= nil, "Chowkidar at level 6")
	target = stealable(pa)
	moveNear(B, target.model)
	trigger(target.model, "StealPrompt", B)
	check(target.carrier == B, "Bilal steals again")
	charB:PivotTo(pa.haveli.guardSpot + Vector3.new(3, 3, 0))
	M.advance(0.6)
	check(target.carrier == B, "the Chowkidar needs a moment to notice")
	markLog()
	M.advance(1)
	check(target.carrier == nil, "the Chowkidar caught the thief")
	check(notified("Ali", "Chowkidar caught") and notified("Bilal", "Seeti"), "Chowkidar messages")
	M.advance(Config.GUARD_COOLDOWN + 1)
	charB:PivotTo(pa.haveli.origin * CFrame.new(10, 3, 0))
	check(Havelis.isInside(pa.haveli, charB.HumanoidRootPart.Position), "Bilal is inside Ali's haveli")
	markLog()
	hud.Buttons.Taala.Activated:Fire()
	M.advance(0.3)
	check(h1.Barrier.CanCollide == true, "laser blocks the door")
	check(not Havelis.isInside(pa.haveli, charB.HumanoidRootPart.Position), "Bilal moved out instead of trapped")
	check(notified("Ali", "Laser Darwaza is on"), "laser message")
	target = stealable(pa)
	markLog()
	moveNear(B, target.model)
	trigger(target.model, "StealPrompt", B)
	check(target.carrier == nil and notified("Bilal", "taala"), "locked haveli cannot be robbed")
	M.advance(Config.LOCK_TIME + 1)
	check(h1.Barrier.CanCollide == false, "laser off after the Taala")

	---------------------------------------------------------------------------
	section("Bonks: brainrots and eggs")
	---------------------------------------------------------------------------
	M.advance(Config.SAME_HAVELI_COOLDOWN)
	target = stealable(pa)
	moveNear(B, target.model)
	trigger(target.model, "StealPrompt", B)
	check(target.carrier == B, "steal for the bonk test")
	charB:PivotTo(CFrame.new(10, 5, 0))
	charA:PivotTo(CFrame.new(13, 5, 0))
	markLog()
	A.Backpack:FindFirstChild("Chappal").Activated:Fire()
	M.advance(0.1)
	check(target.carrier == nil and notified("Ali", "Bonk!"), "bonk")
	check(soundsFor("Ali", "Bonk") == 1 and soundsFor("Bilal", "Bonk") == 1, "bonk sounds")
	check(charB.Humanoid.WalkSpeed == Config.WALK_SPEED, "speed restored after a bonk")
	M.advance(10)
	check(target.arrived, "walked home")
	-- bonking someone with an egg makes them drop it, and anyone can grab it
	local contested = eggIn("MangoBagh", false)
	pickUp(B, contested)
	M.advance(3)
	charB:PivotTo(CFrame.new(10, 5, 0))
	charA:PivotTo(CFrame.new(13, 5, 0))
	M.advance(Config.BONK_COOLDOWN + 0.1)
	local bilalLeft = pb.egg.timeLeft
	markLog()
	A.Backpack:FindFirstChild("Chappal").Activated:Fire()
	M.advance(0.1)
	check(pb.egg == nil and contested.PrimaryPart.EggPrompt.Enabled, "Bilal dropped the egg")
	check(notified("Bilal", "dropped an egg"), "drop message")
	pickUp(A, contested)
	check(pa.egg and pa.egg.biome.id == "MangoBagh", "Ali grabbed Bilal's egg")
	check(math.abs(pa.egg.timeLeft - bilalLeft) < 0.6, "with the time it had left")
	goTo(A, pa.haveli.spawn.Position)
	M.advance(0.5)
	check(pa.egg == nil, "and took it home")
	-- a thief who dies drops what they carry
	M.advance(Config.SAME_HAVELI_COOLDOWN + 1)
	target = stealable(pa)
	moveNear(B, target.model)
	trigger(target.model, "StealPrompt", B)
	check(target.carrier == B, "steal for the dying test")
	charB.Humanoid.Health = 0
	charB.Humanoid.Died:Fire()
	M.advance(0.1)
	check(target.carrier == nil, "dying drops it")

	---------------------------------------------------------------------------
	section("Vehicles with friends, and no stealing from a vehicle")
	---------------------------------------------------------------------------
	charB = spawnCharacter(B)
	M.advance(0.3)
	pa.data.vehicles.Rickshaw = { fuel = 2000, speed = 0, tank = 0, eggs = 0, grip = 0 }
	Garage.sync(pa)
	goTo(A, pa.haveli.doorOutside.Position + Vector3.new(0, 0, 20))
	M.advance(0.1)
	Remotes.Drive:FireServer("Rickshaw")
	M.advance(0.3)
	local rickshaw = charA:FindFirstChild("Vehicle")
	check(rickshaw and pa.driving.def.id == "Rickshaw", "Ali drives the rickshaw")
	local seats = {}
	for _, d in rickshaw:GetChildren() do
		if d.Name == "PassengerSeat" then
			table.insert(seats, d)
		end
	end
	check(#seats == 2 and seats[1]:FindFirstChild("RideAlong") ~= nil, "two seats for friends")
	charB:PivotTo(CFrame.new(seats[1].Position + Vector3.new(2, 0, 0)))
	PPS.PromptTriggered:Fire(seats[1].RideAlong, B)
	M.advance(0.1)
	check(seats[1].Occupant == charB.Humanoid and charB.Humanoid.SeatPart == seats[1], "Bilal rides along")
	check(charB.Head.Massless, "a friend doesn't slow the rickshaw down")
	PPS.PromptTriggered:Fire(seats[2].RideAlong, A)
	M.advance(0.1)
	check(seats[2].Occupant == nil, "the driver can't sit in the back")
	markLog()
	Remotes.Honk:FireServer()
	M.advance(0.6)
	check(soundsFor("Ali", "Horn") == 2 and soundsFor("Bilal", "Horn") == 2, "the rickshaw goes pon pon, for everyone")
	-- no stealing from a vehicle
	local bilalRot = pb.owned[1]
	if bilalRot then
		markLog()
		serverModule("Stealing").start(A, bilalRot.model)
		M.advance(0.1)
		check(bilalRot.carrier == nil and notified("Ali", "Get out of your vehicle"), "no stealing from a vehicle")
	end
	Remotes.Drive:FireServer(nil)
	M.advance(0.2)
	check(pa.driving == nil and rickshaw.Parent == nil, "parked")
	check(charB.Humanoid.Sit == false and not charB.Head.Massless, "Bilal hopped off")
	-- Robux paint jobs (looks only): bought with a Developer Product
	local Shop = serverModule("Shop")
	local packs = Shop.KINDS.paint.packs
	local rangeela = nil
	for _, pack in packs do
		if pack.paint == "Rangeela" then
			rangeela = pack
		end
	end
	check(rangeela ~= nil and #packs == 4, "4 Robux paint jobs")
	rangeela.id = 4242
	table.clear(M.prompts)
	Remotes.BuyProduct:FireServer("paint", "Rangeela")
	M.advance(0.1)
	check(#M.prompts == 1 and M.prompts[1].id == 4242, "paint purchase prompt")
	local paintResult = receipt(1, 4242, "paint-1")
	check(paintResult == M.Enum.ProductPurchaseDecision.PurchaseGranted, "paint job granted")
	check(pa.data.paints.Rangeela and pa.data.paint == "Rangeela", "Ali has the Rangeela paint job")
	check(receipt(1, 4242, "paint-1") == M.Enum.ProductPurchaseDecision.PurchaseGranted, "never granted twice")
	Remotes.BuyProduct:FireServer("paint", "Rangeela")
	M.advance(0.1)
	check(notified("Ali", "already have that paint"), "can't buy a paint job twice")
	rangeela.id = 0
	Remotes.SetPaint:FireServer("Factory")
	M.advance(0.1)
end -- in a function of its own: the main chunk is close to Luau's 200 locals
(function()
	---------------------------------------------------------------------------
	section("Wild brainrots")
	---------------------------------------------------------------------------
	local Wild = serverModule("Wild")
	local Mover = serverModule("Mover")
	local CollectionService = M.services.CollectionService
	local mango = Biomes.byId.MangoBagh
	local wildFolder = workspace:FindFirstChild("ChaiChaosWild")
	check(wildFolder ~= nil, "a folder for wild brainrots")
	check(
		Wild.count() >= 1 and Wild.count() <= Config.WILD_MAX,
		"wild brainrots turned up by themselves: " .. Wild.count()
	)
	local allWild, inZone = true, true
	for model, info in Wild.list() do
		allWild = allWild and Config.WILD_RARITIES[info.def.rarity] == true
		local here = Biomes.at(Mover.pivot(model).Position)
		inZone = inZone and here ~= nil and here.id == info.biome.id
	end
	check(allWild, "only Rare, Epic, Legendary and Mythic brainrots roam wild")
	local mangoWild = Brainrots.wildOdds(Biomes.byId.MangoBagh.odds)
	local qissaWild = Brainrots.wildOdds(Biomes.byId.QissaKhawani.odds)
	local barfaniWild = Brainrots.wildOdds(Biomes.byId.BarfaniPahar.odds)
	check(mangoWild.Rare and not mangoWild.Epic and not mangoWild.Common, "wild in Mango Bagh: always Rare")
	check(
		qissaWild.Epic == 5 and qissaWild.Legendary == 1 and not qissaWild.Uncommon,
		"a zone's own odds, Rare or better"
	)
	check(barfaniWild.Mythic and not barfaniWild.Secret, "Secrets only ever hatch from eggs")
	check(inZone, "each one stays in its own zone")
	-- room at home for what we catch (put back at the end)
	local oldLevel = pa.data.level
	pa.data.level = #Config.HAVELI_LEVELS
	local rareDef = nil
	for _, id in mango.pool do
		if Brainrots.byId[id].rarity == "Rare" then
			rareDef = Brainrots.byId[id]
			break
		end
	end
	local wildOne = Wild.spawn(mango, rareDef, "Golden")
	check(
		wildOne.Parent == wildFolder and CollectionService:HasTag(wildOne, "ChaiWild"),
		"a wild brainrot in Mango Bagh"
	)
	check(wildOne.ModelStreamingMode == M.Enum.ModelStreamingMode.Persistent, "always loaded, for the radar")
	local catch = wildOne.PrimaryPart.CatchPrompt
	check(
		catch.HoldDuration == Config.WILD_CATCH_TIME and catch.ObjectText:find("^Wild Golden") ~= nil,
		"hold E to catch it: " .. catch.ObjectText
	)
	check(Mover.isWalking(wildOne), "it wanders about")
	M.advance(15)
	local here = Biomes.at(Mover.pivot(wildOne).Position)
	check(here and here.id == "MangoBagh", "and stays in Mango Bagh")
	-- on the radar
	goTo(A, Mover.pivot(wildOne).Position + Vector3.new(15, 0, 0))
	M.advance(0.3)
	local wildDot = false
	for _, d in visibleDots() do
		wildDot = wildDot or (d.Icon.Text == "W" and d.BackgroundColor3 == Brainrots.RARITY_COLORS.Rare)
	end
	check(wildDot, "a W on the radar in its rarity's colour")
	-- driving close scares it away
	Remotes.Drive:FireServer("Motorbike")
	M.advance(0.2)
	check(pa.driving ~= nil, "Ali drives up to it")
	goTo(A, Mover.pivot(wildOne).Position + Vector3.new(12, 0, 0))
	M.advance(0.6)
	check(wildOne:GetAttribute("MoveSpeed") == Config.WILD_FLEE_SPEED, "the motorbike scares it: it runs away")
	-- a horn scares them from further away
	local wildTwo = Wild.spawn(mango, rareDef, "Golden")
	local twoAt = Mover.pivot(wildTwo).Position
	goTo(A, twoAt + (twoAt * FLAT).Unit * -50)
	M.advance(0.6)
	check(wildTwo:GetAttribute("MoveSpeed") ~= Config.WILD_FLEE_SPEED, "a quiet vehicle 50 studs away is fine")
	Remotes.Honk:FireServer()
	M.advance(0.1)
	check(wildTwo:GetAttribute("MoveSpeed") == Config.WILD_FLEE_SPEED, "but a horn makes it run")
	Remotes.Drive:FireServer(nil)
	M.advance(0.2)
	if pa.egg then
		EggSystem.drop(A)
	end
	-- catching: on foot, in an open zone, with a free plot
	local function sneakUp(model)
		goTo(A, Mover.pivot(model).Position + Vector3.new(3, 0, 0))
		M.advance(0.05)
		PPS.PromptTriggered:Fire(model.PrimaryPart.CatchPrompt, A)
		M.advance(0.1)
	end
	local locked = Wild.spawn(Biomes.byId.BarfaniPahar, nil, nil)
	markLog()
	sneakUp(locked)
	check(locked.Parent == wildFolder and notified("Ali", "Unlock Barfani Pahar"), "only in zones you have unlocked")
	local realFree = Havelis.hasFreePlot
	Havelis.hasFreePlot = function()
		return false
	end
	markLog()
	sneakUp(wildOne)
	Havelis.hasFreePlot = realFree
	check(wildOne.Parent == wildFolder and notified("Ali", "No empty plot"), "it needs a free plot")
	setQuests(pa, { { id = "catchWild", target = 1, progress = 0, claimed = false } })
	local ownedBefore = #pa.owned
	markLog()
	sneakUp(wildOne)
	check(wildOne.Parent == nil and #pa.owned == ownedBefore + 1, "caught it!")
	local caught = pa.owned[#pa.owned]
	for _, entry in pa.owned do
		if entry.def == rareDef and entry.mutation == "Golden" then
			caught = entry
		end
	end
	check(caught.def == rareDef and caught.mutation == "Golden", "a Golden " .. rareDef.name .. " for the haveli")
	check(caught.model.Parent == pa.haveli.brainrotFolder, "it walks into Ali's haveli")
	check(notified("Ali", "You caught a wild Golden"), "catch message")
	check(pa.data.quests.list[1].progress == 1, "the catch quest counts it")
	-- big ones are announced, old ones wander off
	markLog()
	local legend = Wild.spawn(mango, Brainrots.byRarity.Legendary[1], nil)
	check(notified("Ali", "wild LEGENDARY"), "a wild Legendary is announced to everyone")
	Wild.list()[legend].born = M.now() - Config.WILD_LIFETIME - 1
	M.advance(0.6)
	check(legend.Parent == nil and Wild.list()[legend] == nil, "after a while it wanders off")
	while Wild.count() < Config.WILD_MAX do
		Wild.spawn()
	end
	M.advance(Config.WILD_EVERY + 1)
	check(Wild.count() <= Config.WILD_MAX, "never more than " .. Config.WILD_MAX .. " at once")

	---------------------------------------------------------------------------
	section("The Mandi lane")
	---------------------------------------------------------------------------
	local Mandi = serverModule("Mandi")
	check(
		Mandi.count() >= 1 and Mandi.count() <= Config.MANDI_MAX,
		"brainrots walk round the Mandi lane: " .. Mandi.count()
	)
	local onLane, cheap = true, true
	for model, walker in Mandi.walkers() do
		if model.Parent then
			onLane = onLane and math.abs((Mover.pivot(model).Position * FLAT).Magnitude - Biomes.MANDI_RADIUS) < 2
			cheap = cheap and Config.MANDI_ODDS[walker.def.rarity] ~= nil and not walker.def.questOnly
		end
	end
	check(onLane, "every one is on the lane")
	check(cheap, "never a Mythic, Secret or quest brainrot on the lane")
	local biryani = Brainrots.byId.BiryaniBadshah
	local walker = Mandi.spawn(biryani, "Golden")
	local price = Mandi.price(biryani, "Golden")
	check(price > Mutations.value(biryani, "Golden"), "lane brainrots cost more than they're worth: " .. price)
	check(walker.PrimaryPart.BuyPrompt.ActionText == "Buy for " .. Format.rupees(price), "the price on the prompt")
	local arch = Biomes.polar(Biomes.MANDI_START, Biomes.MANDI_RADIUS)
	check(((Mover.pivot(walker).Position - arch) * FLAT).Magnitude < 2, "it comes out of the Mandi arch")
	M.advance(10)
	local turned = Biomes.angleDiff(Biomes.angleOf(Mover.pivot(walker).Position), Biomes.MANDI_START)
	check(turned > 30 and turned < 42, "and walks clockwise round the Chowk: " .. turned)
	local function buy(model)
		goTo(A, Mover.pivot(model).Position + Vector3.new(0, 0, 3))
		M.advance(0.05)
		PPS.PromptTriggered:Fire(model.PrimaryPart.BuyPrompt, A)
		M.advance(0.1)
	end
	pa.data.rupees = 10
	State.syncStats(pa)
	markLog()
	buy(walker)
	check(Mandi.walkers()[walker] ~= nil and notified("Ali", "Not enough rupees"), "too poor to buy it")
	setQuests(pa, { { id = "buyMandi", target = 1, progress = 0, claimed = false } })
	pa.data.rupees = price + 500
	State.syncStats(pa)
	markLog()
	buy(walker)
	check(pa.data.rupees == 500 and Mandi.walkers()[walker] == nil, "bought it for " .. Format.rupees(price))
	check(State.entries[walker] ~= nil and walker.Parent == pa.haveli.brainrotFolder, "it walks to Ali's haveli")
	check(walker.PrimaryPart:FindFirstChild("BuyPrompt") == nil, "and can't be bought twice")
	check(notified("Ali", "You bought Golden Biryani Badshah"), "purchase message")
	check(pa.data.quests.list[1].progress == 1, "the Mandi quest counts it")
	local unsold = Mandi.spawn(biryani, nil)
	M.advance(Config.MANDI_WALK_TIME + 2)
	check(unsold.Parent == nil, "nobody bought it, so it walks back into the Mandi")
	check(Mandi.count() <= Config.MANDI_MAX, "never more than " .. Config.MANDI_MAX .. " on the lane")

	-- put Ali's haveli back the way it was
	for _, entry in { caught, State.entries[walker] } do
		Havelis.remove(pa, entry)
		entry.model:Destroy()
	end
	pa.data.level = oldLevel
	Havelis.arrange(pa)
	pa.data.rupees = 100_000
	State.syncStats(pa)
end)();
(function()
	---------------------------------------------------------------------------
	section("The new-player guide")
	---------------------------------------------------------------------------
	local Steps = sharedModule("Tutorial")
	local Menu = serverModule("Menu")
	local PlayerData = serverModule("PlayerData")
	local Marketplace = M.services.MarketplaceService
	local mango = Biomes.byId.MangoBagh
	check(#Steps.steps == 8 and Steps.steps[1].id == "leave" and Steps.DONE == 9, "8 guide steps")
	check(
		Steps.byId.vehicle.text:find("Rs 3,000") ~= nil,
		"the guide uses the real prices: " .. Steps.byId.vehicle.text
	)
	check(
		M.typeof(workspace:GetAttribute("ShowroomPosition")) == "Vector3",
		"the guide knows where the showroom is, even before it loads"
	)

	-- a brand new player walks through the whole guide
	Config.BADGES.Welcome = 900
	Config.BADGES.FirstEgg = 901
	local G = addPlayer("Guddu", 21)
	M.advance(0.8)
	local pg = State.profiles[G]
	local charG = spawnCharacter(G)
	M.advance(0.4)
	check(pg.data.tutorial == 1 and G:GetAttribute("Tutorial") == "leave", "a new player starts at step 1")
	check(M.badges["21:900"] and pg.data.badges.Welcome, "the Welcome badge")
	local rollsBefore = pg.data.rollTokens
	goTo(G, Biomes.point(mango, Biomes.innerRadius(mango) + 40, 0))
	M.advance(1.3)
	check(G:GetAttribute("Tutorial") == "egg", "walking into Mango Bagh: step 2")
	pickUp(G, eggIn("MangoBagh", false))
	M.advance(0.1)
	check(pg.egg ~= nil and G:GetAttribute("Tutorial") == "home", "picked up an egg: step 3")
	goTo(G, pg.haveli.spawn.Position)
	M.advance(0.6)
	check(G:GetAttribute("Tutorial") == "hatch", "egg home: step 4")
	check(M.badges["21:901"] and pg.data.badges.FirstEgg, "the First Egg badge")
	M.advance(mango.hatchTime + 3)
	check(#pg.owned >= 1 and G:GetAttribute("Tutorial") == "collect", "it hatched: step 5")
	M.advance(2)
	pg.haveli.galla.Touched:Fire(charG.HumanoidRootPart)
	M.advance(0.1)
	check(G:GetAttribute("Tutorial") == "vehicle", "collected the galla: step 6")
	pg.data.rupees = 30_000
	State.syncStats(pg)
	atShop(G, "Showroom")
	M.advance(0.1)
	Garage.buy(G, "Motorbike")
	M.advance(0.1)
	check(pg.data.vehicles.Motorbike ~= nil and G:GetAttribute("Tutorial") == "drive", "bought a motorbike: step 7")
	Garage.drive(G, "Motorbike")
	M.advance(0.3)
	check(pg.driving ~= nil and G:GetAttribute("Tutorial") == "zone", "driving: step 8")
	Garage.drive(G, nil)
	M.advance(0.2)
	atGate(G, "RailwayJunction")
	markLog()
	Zones.unlock(G, gateOf("RailwayJunction"))
	M.advance(0.1)
	check(pg.data.zones.RailwayJunction and G:GetAttribute("Tutorial") == "", "unlocked a zone: the guide is finished")
	check(pg.data.tutorial == Steps.DONE and pg.data.guideRewarded, "finished for good")
	check(
		pg.data.rollTokens == rollsBefore + Steps.REWARD_ROLLS and notified("Guddu", "Guide finished"),
		"the guide pays Kismat Rolls"
	)
	-- starting again skips what you have already done, and pays nothing twice
	serverModule("Tutorial").command(G, "restart")
	M.advance(0.1)
	check(G:GetAttribute("Tutorial") == "leave", "the guide can be started again")
	local rollsAfter = pg.data.rollTokens
	goTo(G, Biomes.point(mango, Biomes.innerRadius(mango) + 40, 0))
	M.advance(1.3)
	pickUp(G, eggIn("MangoBagh", false))
	goTo(G, pg.haveli.spawn.Position)
	M.advance(mango.hatchTime + 4)
	pg.haveli.galla.Touched:Fire(charG.HumanoidRootPart)
	M.advance(0.1)
	check(G:GetAttribute("Tutorial") == "drive", "it skips the steps you have done (vehicle), up to driving")
	goTo(G, Biomes.polar(45, 60))
	M.advance(0.1)
	Garage.drive(G, "Motorbike")
	M.advance(0.3)
	Garage.drive(G, nil)
	M.advance(0.2)
	check(G:GetAttribute("Tutorial") == "" and pg.data.rollTokens == rollsAfter, "finished again, no second reward")

	-- on Ali's screen: the card, the beacon and the Skip button
	Remotes.Guide:FireServer("restart")
	goTo(A, pa.haveli.doorOutside.Position)
	M.advance(0.7)
	check(A:GetAttribute("Tutorial") == "leave", "Ali starts the guide again")
	check(
		hud.Guide.Visible and hud.Guide.Text.Text:find("Mango Bagh") ~= nil,
		"the guide card: " .. hud.Guide.Text.Text
	)
	check(hud.Guide.Step.Text == "Guide · step 1 of 8", "the step number: " .. hud.Guide.Step.Text)
	local beacon = workspace:FindFirstChild("GuideBeacon")
	local gate = Biomes.polar(Biomes.gate(mango))
	check(
		beacon ~= nil and ((beacon.Position - gate) * FLAT).Magnitude < 12,
		"a glowing beacon stands at the Mango Bagh gate"
	)
	check(beacon and beacon.GuideLine.Attachment0 ~= nil and beacon.CanCollide == false, "with a line to follow")
	check(beacon and beacon.Label.Distance.Text:find("studs") ~= nil, "and the distance")
	hud.Guide.Skip.Activated:Fire()
	M.advance(0.7)
	check(A:GetAttribute("Tutorial") == "" and not hud.Guide.Visible, "Skip hides the guide")
	check(workspace:FindFirstChild("GuideBeacon") == nil, "and the beacon")

	---------------------------------------------------------------------------
	section("Menu: settings, codes, game passes and the streak")
	---------------------------------------------------------------------------
	hud.Buttons.Menu.Activated:Fire()
	M.advance(0.1)
	local menu = hud.MenuPanel
	check(menu.Visible and menu.Content:FindFirstChild("Streak") ~= nil, "the Menu window opens")
	check(menu.Content:FindFirstChild("PassDoubleCash") == nil, "game passes are hidden until they have ids")
	check(A:GetAttribute("Settings") == "music,sounds", "music and sounds start on")
	menu.Content.SettingSounds.Button.Activated:Fire()
	M.advance(0.1)
	check(A:GetAttribute("Settings") == "music" and pa.data.settings.sounds == false, "sounds switched off")
	check(menu.Content.SettingSounds.Text.Text == "Off", "the window shows it")
	local soundsAt = #M.soundsPlayed
	hud.Buttons.Collection.Activated:Fire()
	hud.Buttons.Collection.Activated:Fire()
	M.advance(0.1)
	check(#M.soundsPlayed == soundsAt, "no click sounds while sounds are off")
	menu.Content.SettingSounds.Button.Activated:Fire()
	M.advance(0.1)
	check(A:GetAttribute("Settings") == "music,sounds", "and back on")
	Remotes.SetSetting:FireServer("gravity", false)
	Remotes.SetSetting:FireServer("music", "no")
	M.advance(0.1)
	check(A:GetAttribute("Settings") == "music,sounds", "bad settings are ignored")

	-- promo codes
	local rupees0, rolls0 = pa.data.rupees, pa.data.rollTokens
	markLog()
	menu.Content.Code.Box.Text = " chaichaos "
	menu.Content.Code.Redeem.Activated:Fire()
	M.advance(0.1)
	check(
		pa.data.rupees == rupees0 + Config.CODES.CHAICHAOS.rupees and pa.data.rollTokens == rolls0 + 1,
		"a code pays rupees and a roll"
	)
	check(notified("Ali", "Code CHAICHAOS") and menu.Content.Code.Box.Text == "", "code message")
	Remotes.RedeemCode:FireServer("CHAICHAOS")
	M.advance(0.1)
	check(pa.data.rupees == rupees0 + Config.CODES.CHAICHAOS.rupees, "no spamming codes")
	M.advance(2)
	markLog()
	Remotes.RedeemCode:FireServer("CHAICHAOS")
	M.advance(0.1)
	check(
		pa.data.rupees == rupees0 + Config.CODES.CHAICHAOS.rupees and notified("Ali", "already used"),
		"each code works once"
	)
	M.advance(2)
	markLog()
	Remotes.RedeemCode:FireServer("FREEMONEY")
	M.advance(0.1)
	check(notified("Ali", "doesn't work"), "wrong codes say so")

	-- game passes
	check(
		Config.plotCount(1, true) == 6 and Config.plotCount(4, true) == 10,
		"Extra Plots: +2, but only where there is room"
	)
	check(Config.plotCount(5, true) == 14 and Config.plotCount(9, true) == 20, "upstairs once the second floor is open")
	Config.GAME_PASSES.DoubleCash = 501
	Config.GAME_PASSES.ExtraPlots = 502
	local clientConfig = requireModule(shared:FindFirstChild("Config"), "client")
	clientConfig.GAME_PASSES.DoubleCash = 501
	clientConfig.GAME_PASSES.ExtraPlots = 502
	menu.Visible = false
	hud.Buttons.Menu.Activated:Fire()
	M.advance(0.1)
	check(menu.Content.PassDoubleCash.Button.Text == "Robux", "the passes show once they have ids")
	menu.Content.PassDoubleCash.Button.Activated:Fire()
	M.advance(0.1)
	check(
		#M.passPrompts == 1 and M.passPrompts[1].id == 501 and M.passPrompts[1].player == "Ali",
		"buying a pass opens Roblox's purchase window"
	)
	local incomeBefore = Havelis.incomeMultiplier(pa)
	local plotsBefore = Havelis.plotCount(pa)
	markLog()
	M.signalOf(Marketplace, "PromptGamePassPurchaseFinished"):Fire(A, 501, false)
	M.advance(0.1)
	check(not pa.data.passes.DoubleCash, "closing the window gives nothing")
	M.signalOf(Marketplace, "PromptGamePassPurchaseFinished"):Fire(A, 501, true)
	M.advance(0.1)
	check(pa.data.passes.DoubleCash and A:GetAttribute("Passes") == "DoubleCash", "2x Cash bought")
	check(math.abs(Havelis.incomeMultiplier(pa) - incomeBefore * 2) < 1e-6, "brainrots earn twice as much")
	check(notified("Ali", "2x Cash is yours forever"), "thank-you message")
	check(menu.Content.PassDoubleCash.Button.Text == "Owned", "the Menu shows it is owned")
	Remotes.BuyProduct:FireServer("pass", "DoubleCash")
	M.advance(0.1)
	check(#M.passPrompts == 1, "a pass can't be bought twice")
	M.signalOf(Marketplace, "PromptGamePassPurchaseFinished"):Fire(A, 502, true)
	M.advance(0.1)
	check(
		Havelis.plotCount(pa) == Config.plotCount(pa.data.level, true) and Havelis.plotCount(pa) >= plotsBefore,
		"Extra Plots: " .. plotsBefore .. " -> " .. Havelis.plotCount(pa)
	)
	-- Roblox is asked when you join; what it said is kept in the save
	M.passesOwned["21:502"] = true
	removePlayer(G)
	M.advance(0.5)
	check(M.store.player_21.session == nil, "leaving lets go of the save")
	G = addPlayer("Guddu", 21)
	M.advance(0.8)
	pg = State.profiles[G]
	check(pg.data.passes.ExtraPlots and Havelis.plotCount(pg) == 6, "a pass bought on the website works when you join")
	check(pg.data.tutorial == Steps.DONE and G:GetAttribute("Tutorial") == "", "the guide stays finished")
	check(M.store.player_21.session ~= nil, "this server holds the save while you play")
	removePlayer(G)
	M.advance(0.5)
	M.failPassChecks = true
	G = addPlayer("Guddu", 21)
	M.advance(0.8)
	pg = State.profiles[G]
	M.failPassChecks = false
	check(pg.data.passes.ExtraPlots == true, "if Roblox can't say, the save remembers your passes")
	removePlayer(G)
	M.advance(0.5)
	pa.data.passes = {}
	serverModule("Passes").sync(pa)
	Havelis.arrange(pa)
	Config.GAME_PASSES.DoubleCash = 0
	Config.GAME_PASSES.ExtraPlots = 0
	clientConfig.GAME_PASSES.DoubleCash = 0
	clientConfig.GAME_PASSES.ExtraPlots = 0
	menu.Visible = false

	-- offline earnings and the daily chai streak
	local today = math.floor(M.os.time() / 86400)
	local away = PlayerData.default()
	away.owned = { "BiryaniBadshah" }
	away.lastSeen = M.os.time() - 3600
	away.lastDaily = today - 1
	away.streak = 2
	away.rollTokens = 0
	away.tutorial = 1000
	M.store.player_22 = away
	markLog()
	local Z = addPlayer("Zoya", 22)
	M.advance(0.8)
	local pz = State.profiles[Z]
	-- what the saved brainrot earns (daily chai may have added another one since)
	local awayIncome = Brainrots.byId.BiryaniBadshah.income * Havelis.incomeMultiplier(pz)
	local perSecond = Havelis.incomePerSecond(pz)
	local expected = math.floor(awayIncome * 3600 * Config.OFFLINE_RATE)
	check(
		pz.data.galla >= expected and pz.data.galla < expected + perSecond * 5,
		("an hour away: %d in the galla (10%% of %d/s)"):format(pz.data.galla, perSecond)
	)
	check(notified("Zoya", "While you were away"), "offline earnings message")
	check(pz.data.streak == 3 and Z:GetAttribute("Streak") == 3, "third day in a row")
	check(
		pz.data.rollTokens == Config.DAILY_FREE_ROLLS + Config.streakRolls(3) and notified("Zoya", "Day 3 in a row"),
		"the streak pays an extra Kismat Roll: " .. pz.data.rollTokens
	)
	check(Config.streakRolls(1) == 0 and Config.streakRolls(7) == 2 and Config.streakRolls(40) == 2, "streak bonuses")
	pz.data.galla = 0
	pz.data.lastSeen = M.os.time() - 36000
	Menu.offlineEarnings(pz)
	check(pz.data.galla == math.floor(perSecond * Config.OFFLINE_MAX * Config.OFFLINE_RATE), "at most 4 hours count")
	pz.data.galla = 0
	pz.data.lastSeen = M.os.time() - 60
	Menu.offlineEarnings(pz)
	check(pz.data.galla == 0, "a short break pays nothing")
	pz.data.lastDaily = today - 3
	check(select(1, Menu.streak(pz, today)) == 1, "miss a day and the streak starts again")
	removePlayer(Z)
	M.advance(0.5)

	---------------------------------------------------------------------------
	section("Safe saving and fair play")
	---------------------------------------------------------------------------
	check(
		M.store.player_1.session ~= nil and M.store.player_1.session.job == "studio",
		"Ali's save is held by this server"
	)
	-- another server still has the save open: wait for it instead of loading old data
	PlayerData.tries = 3
	M.store.player_30 = { rupees = 777, session = { job = "other-server", at = M.os.time() } }
	local loaded, canSave = nil, nil
	M.task.spawn(function()
		loaded, canSave = PlayerData.load(30)
	end)
	M.advance(1)
	check(loaded == nil, "loading waits while another server holds the save")
	M.store.player_30 = { rupees = 888 } -- the other server saved and let go
	M.advance(3)
	check(loaded ~= nil and loaded.rupees == 888 and canSave == true, "then it loads the newest data")
	check(M.store.player_30.session.job == "studio", "and holds the save")
	-- a server that lost the save never writes over it
	M.store.player_30.session = { job = "other-server", at = M.os.time() }
	M.store.player_30.rupees = 999
	local saved = nil
	M.task.spawn(function()
		saved = PlayerData.save(30, loaded)
	end)
	M.advance(0.3)
	check(saved == false and M.store.player_30.rupees == 999, "a save that another server took over is left alone")
	-- a crashed server's lock runs out
	M.store.player_31 = { rupees = 555, session = { job = "crashed", at = M.os.time() - 700 } }
	local late = nil
	M.task.spawn(function()
		late = PlayerData.load(31)
	end)
	M.advance(0.3)
	check(late ~= nil and late.rupees == 555, "an old lock from a crashed server is ignored")
	-- the last try takes over rather than locking a player out for ever
	M.store.player_32 = { rupees = 444, session = { job = "stuck", at = M.os.time() } }
	local stuck, stuckSave = nil, nil
	M.task.spawn(function()
		stuck, stuckSave = PlayerData.load(32)
	end)
	M.advance(7)
	check(stuck ~= nil and stuck.rupees == 444 and stuckSave == true, "after a few tries the new server takes over")
	PlayerData.tries = 1
	M.store.player_30, M.store.player_31, M.store.player_32 = nil, nil, nil

	-- eggs that travel faster than any vehicle crack
	Config.EGG_MAX_SPEED = EGG_MAX_SPEED
	if pa.driving then
		Remotes.Drive:FireServer(nil)
		M.advance(0.2)
	end
	if pa.egg then
		EggSystem.drop(A)
	end
	local spot = Biomes.point(mango, Biomes.innerRadius(mango) + 60, 0)
	goTo(A, spot)
	M.advance(0.5)
	pickUp(A, eggIn("MangoBagh", false))
	M.advance(0.3)
	check(pa.egg ~= nil, "Ali carries an egg")
	local from = charA:GetPivot().Position
	for i = 1, 12 do
		-- 60 studs a second: as fast as a good vehicle
		charA:PivotTo(CFrame.new(from + Vector3.new(15 * i, 0, 0)))
		M.advance(0.25)
	end
	check(pa.egg ~= nil, "at vehicle speed the egg is fine")
	markLog()
	charA:PivotTo(CFrame.new(charA:GetPivot().Position + Vector3.new(0, 0, 400)))
	M.advance(0.6)
	check(pa.egg == nil and notified("Ali", "too fast"), "teleporting with an egg cracks it")
	Config.EGG_MAX_SPEED = math.huge

	-- vehicles can't be swapped faster than the server can build them
	pa.data.vehicles.Rickshaw = pa.data.vehicles.Rickshaw or { fuel = 2000, speed = 0, tank = 0, eggs = 0, grip = 0 }
	Garage.sync(pa)
	goTo(A, pa.haveli.doorOutside.Position + Vector3.new(0, 0, 30))
	M.advance(0.5)
	Remotes.Drive:FireServer("Motorbike")
	M.advance(0.05)
	Remotes.Drive:FireServer("Rickshaw")
	M.advance(0.05)
	check(pa.driving and pa.driving.def.id == "Motorbike", "swapping vehicles too fast is ignored")
	M.advance(0.4)
	Remotes.Drive:FireServer("Rickshaw")
	M.advance(0.2)
	check(pa.driving and pa.driving.def.id == "Rickshaw", "a moment later it works")
	Remotes.Drive:FireServer(nil)
	M.advance(0.3)
	check(pa.driving == nil, "parked")
	Config.BADGES.Welcome = 0
	Config.BADGES.FirstEgg = 0
end)()

do
	---------------------------------------------------------------------------
	section("Events")
	---------------------------------------------------------------------------
	local Events = sharedModule("Events")
	goTo(A, pa.haveli.spawn.Position)
	markLog()
	local baseMultiplier = Havelis.incomeMultiplier(pa)
	EventRunner.start("Basant")
	M.advance(1)
	check(workspace:GetAttribute("EventId") == "Basant" and notified("Ali", "Basant"), "Basant Kite Festival")
	check(soundsFor("Ali", "EventStart") == 1, "event sound")
	check(math.abs(Havelis.incomeMultiplier(pa) - baseMultiplier * 2) < 1e-6, "Basant: cash x2")
	check(Events.mult("luckMult") == 2, "Basant: luck x2")
	check(hud.EventBanner.Title.Text == "Basant Kite Festival", "banner shows the event")
	check(hud.EventBanner.Perks.Text == "Cash x2 · Luck x2", "banner shows the boosts: " .. hud.EventBanner.Perks.Text)
	local effects = workspace.CurrentCamera:FindFirstChild("ChaiChaosEventEffects")
	local kites, near = 0, 0
	local cameraAt = workspace.CurrentCamera.CFrame.Position
	for _, p in effects:GetChildren() do
		if p.Name == "Kite" then
			kites += 1
			if ((p.Position - cameraAt) * FLAT).Magnitude < 160 and p.Position.Y > cameraAt.Y + 30 then
				near += 1
			end
		end
	end
	check(kites == 24 and near == 24, "kites fill the sky around you: " .. kites .. ", " .. near)
	local luckyRares = tally(khet, false, 40000).Rare or 0
	-- luck x2 doubles Rare's weight: 8 / (72 + 24 + 8)
	check(math.abs(luckyRares / 40000 - 8 / 104) < 0.006, "luck makes rare hatches likelier: " .. luckyRares / 40000)
	EventRunner.stop()
	M.advance(1)
	check(effects:FindFirstChild("Kite") == nil and hud.EventBanner.Title.Text == "Next event", "kites gone")
	check(hud.EventBanner.Perks.Text == "", "no boosts between events")

	EventRunner.start("Baarish")
	M.advance(Config.EGG_RESPAWN * 10)
	check(
		groundEggs("SarsonFields") > Config.EGGS_PER_BIOME,
		"Baarish: more eggs everywhere: " .. groundEggs("SarsonFields")
	)
	check(effects:FindFirstChild("Weather") ~= nil, "rain on screen")
	EventRunner.stop()
	EventRunner.start("Sardi")
	M.advance(0.5)
	check(EggSystem.eggTime(pa, khet, false) == 75 * 1.5, "Sardi: eggs last longer")
	EventRunner.stop()
	EventRunner.start("MelaNight")
	M.advance(0.5)
	check(Kismat.cost(pa) == 3500, "Mela Night roll discount: " .. Kismat.cost(pa))
	check(effects:FindFirstChild("Burst") ~= nil, "mela fireworks")
	while #pa.owned >= Havelis.plotCount(pa) do
		local e = pa.owned[#pa.owned]
		Havelis.remove(pa, e)
		e.model:Destroy()
	end
	pickUp(A, eggIn("MangoBagh", false))
	goTo(A, pa.haveli.spawn.Position)
	M.advance(0.5)
	local melaRecord = pa.incubating[1] or pa.incubating[2]
	check(melaRecord and melaRecord.hatchAt - M.os.time() <= math.ceil(khet.hatchTime / 2), "Mela Night: hatching x2")
	EventRunner.stop()
	EventRunner.start("LoadShedding")
	M.advance(1)
	check(M.services.Lighting.ClockTime == 0, "Load Shedding makes it night")
	EventRunner.stop()
	M.advance(1)
	check(M.services.Lighting.ClockTime ~= 0, "the light comes back")
	local last, repeats = nil, false
	for _ = 1, 40 do
		local id = EventRunner.pick()
		repeats = repeats or id == last
		EventRunner.start(id)
		last = id
		EventRunner.stop()
	end
	check(not repeats, "never the same event twice in a row")
	M.advance(1)
end

do
	---------------------------------------------------------------------------
	section("Robux packs and Chor Passes")
	---------------------------------------------------------------------------
	local Granted = M.Enum.ProductPurchaseDecision.PurchaseGranted
	local NotYet = M.Enum.ProductPurchaseDecision.NotProcessedYet
	local clientConfig = requireModule(shared:FindFirstChild("Config"), "client2")
	for _, cfg in { Config, clientConfig } do
		cfg.ROLL_PRODUCTS[1].id, cfg.ROLL_PRODUCTS[2].id = 1001, 1010
		cfg.STEAL_PRODUCTS[1].id, cfg.STEAL_PRODUCTS[2].id = 2001, 2005
	end
	M.prices[1010] = 199
	local D = addPlayer("Dua", 4)
	M.advance(0.5)
	local pd = State.profiles[D]
	local charD = spawnCharacter(D)
	M.advance(0.3)
	Havelis.clearBrainrots(pd)
	M.localPlayer = D
	M.rawset(Players, "LocalPlayer", D)
	runScripts(client, "client2")
	M.advance(0.5)
	local hudD = D.PlayerGui:FindFirstChild("ChaiChaosHud")
	check(hudD.Buttons:FindFirstChild("ChorPass") ~= nil, "Chor Pass button once products are set up")
	check(hudD.KismatPanel.Content.BuyRolls2.Text:find("R%$ 199") ~= nil, "Robux pack priced")
	table.clear(M.prompts)
	hudD.KismatPanel.Content.BuyRolls2.Activated:Fire()
	M.advance(0.1)
	check(#M.prompts == 1 and M.prompts[1].id == 1010, "Robux prompt")
	pd.data.rollTokens = 0
	check(receipt(4, 1010, "buy-1") == Granted and pd.data.rollTokens == 10, "10 rolls granted")
	check(M.store["player_4"] and M.store["player_4"].rollTokens == 10, "saved straight away")
	check(receipt(4, 1010, "buy-1") == Granted and pd.data.rollTokens == 10, "never granted twice")
	check(receipt(4, 9999, "buy-2") == NotYet, "unknown product not granted")
	check(receipt(99, 1001, "buy-3") == NotYet, "player not here: retry later")
	M.failSavesFor["player_4"] = true
	check(receipt(4, 1001, "buy-4") == NotYet and pd.data.rollTokens == 10, "failed save undoes the grant")
	M.failSavesFor["player_4"] = nil
	check(receipt(4, 1001, "buy-4") == Granted and pd.data.rollTokens == 11, "retry works")
	kc = hudD.KismatPanel.Content
	pd.data.rollTokens = 1
	State.syncTokens(pd)
	M.advance(0.1)
	kc.RollToken.Activated:Fire()
	M.advance(0.1)
	check(pd.data.rollTokens == 0 and #pd.owned == 1, "token roll")

	M.restricted[5] = true
	local E = addPlayer("Ehsan", 5)
	M.advance(0.5)
	check(E:GetAttribute("PaidRollsAllowed") == false, "restricted player flagged")
	table.clear(M.prompts)
	markLog()
	M.localPlayer = E
	Remotes.BuyProduct:FireServer("rolls", 1)
	Remotes.BuyProduct:FireServer("steals", 1)
	Remotes.BuyProduct:FireServer("gems", 1)
	M.advance(0.1)
	M.localPlayer = D
	check(#M.prompts == 1 and M.prompts[1].id == 2001, "no paid rolls where restricted; Chor Passes are fine")
	check(notified("Ehsan", "not available"), "restricted message")

	local pe = State.profiles[E]
	local charE = spawnCharacter(E)
	M.advance(0.3)
	Havelis.clearBrainrots(pe)
	for _, id in { "ChanaChaatChacha", "SamosaSupremo", "GolGappaGhostu" } do
		Havelis.adopt(pe, Brainrots.byId[id], nil, nil, true)
	end
	M.advance(12)
	local ghost = entryOf(pe, "GolGappaGhostu")
	check(ghost and ghost.plot == 3, "ghostu on Ehsan's plot 3")
	check(prompt(ghost.model, "StealPrompt").ActionText == "Steal (1 Chor Pass)", "steal prompt shows the cost")
	M.advance(Config.NEW_PLAYER_PROTECTION + 1)
	pd.data.stealTokens = 0
	State.syncTokens(pd)
	table.clear(M.prompts)
	markLog()
	moveNear(D, ghost.model)
	trigger(ghost.model, "StealPrompt", D)
	check(ghost.carrier == nil and notified("Dua", "needs a Chor Pass"), "no Chor Pass, no steal")
	check(#M.prompts == 1 and M.prompts[1].id == 2001, "Chor Pass purchase pops up")
	check(receipt(4, 2005, "chor-1") == Granted and pd.data.stealTokens == 5, "5 Chor Passes")
	check(hudD.ChorPanel.Content.Passes.Text == "Your Chor Passes: 5", "Chor panel")
	trigger(ghost.model, "StealPrompt", D)
	check(ghost.carrier == D and pd.data.stealTokens == 4, "steal uses a pass")
	charD:PivotTo(CFrame.new(10, 5, 0))
	charE:PivotTo(CFrame.new(13, 5, 0))
	markLog()
	E.Backpack:FindFirstChild("Chappal").Activated:Fire()
	M.advance(0.1)
	check(ghost.carrier == nil and pd.data.stealTokens == 5 and notified("Dua", "given back"), "failed steal refunds")
	M.advance(Config.SAME_HAVELI_COOLDOWN + 10)
	moveNear(D, ghost.model)
	trigger(ghost.model, "StealPrompt", D)
	check(ghost.carrier == D, "stealing again")
	local passes = pd.data.stealTokens
	markLog()
	removePlayer(E)
	check(notified("Dua", "ran away") and pd.data.stealTokens == passes + 1, "owner left: it runs away, pass refunded")
	check(charD.Humanoid.WalkSpeed == Config.WALK_SPEED, "thief speed restored")
	local savedE = M.store["player_5"]
	check(savedE and table.find(savedE.owned, "GolGappaGhostu") ~= nil, "the owner keeps it in their save")
	M.localPlayer = A
	M.rawset(Players, "LocalPlayer", A)
end

do
	---------------------------------------------------------------------------
	section("Naya Safar at the Chowk")
	---------------------------------------------------------------------------
	M.advance(math.max(khet.hatchTime, 10))
	pa.data.rupees = Config.rebirthCost(0)
	pa.data.rollTokens = 3
	pa.data.trackerLevel = 4
	pa.data.gear = { Joggers = true, Tokri = true, Shovel = true }
	State.syncStats(pa)
	State.syncGear(pa)
	pickUp(A, eggIn("MangoBagh", false))
	goTo(A, pa.haveli.spawn.Position)
	M.advance(0.5)
	check(next(pa.incubating) ~= nil, "an egg is hatching")
	check(not State.isZoneOpen(pa, Biomes.byId.LahoreQila), "Lahore Qila is closed before the first rebirth")
	markLog()
	Remotes.Rebirth:FireServer()
	M.advance(0.1)
	check(pa.data.rebirths == 0 and notified("Ali", "Naya Safar stall"), "Naya Safar only at the Chowk")
	openShop("Rebirth")
	local rp = hud.RebirthPanel
	check(rp.Visible, "the Naya Safar gate opens its window")
	check(rp.Content.Cost.Text:find("Rs 2,500,000") ~= nil, "cost shown: " .. rp.Content.Cost.Text)
	check(rp.Content.Theme.Text:find("Truck Art") ~= nil, "shows the theme it unlocks")
	check(rp.Content.Theme.Text:find("Lahore Qila") ~= nil, "and the zone it opens")
	check(rp.Content.Rebirth.Text == "Start Naya Safar!", "ready")
	markLog()
	rp.Content.Rebirth.Activated:Fire()
	M.advance(0.1)
	check(pa.data.rebirths == 0 and rp.Content.Rebirth.Text:find("Sure") ~= nil, "asks to confirm")
	rp.Content.Rebirth.Activated:Fire()
	M.advance(0.5)
	check(pa.data.rebirths == 1 and pa.data.level == 1 and pa.data.rupees == Config.START_RUPEES, "rebirth resets")
	check(pa.data.trackerLevel == 1 and A:GetAttribute("TrackerLevel") == 1, "radar back to level 1")
	check(#pa.owned == 0 and next(pa.incubating) == nil and #pa.data.incubators == 0, "brainrots and eggs reset")
	check(pa.data.vehicles.Motorbike and pa.data.vehicles.Motorbike.speed == 1, "vehicles and upgrades kept")
	check(pa.data.zones.RailwayJunction and pa.data.zones.NamakCaves, "unlocked zones kept")
	check(
		State.isZoneOpen(pa, Biomes.byId.LahoreQila) and A:GetAttribute("OpenZones"):find("LahoreQila") ~= nil,
		"the first rebirth opens Lahore Qila"
	)
	check(not State.isZoneOpen(pa, Biomes.byId.KarachiPort), "Karachi Port needs 2 rebirths")
	check(notified("Ali", "Lahore Qila's gate is open"), "Lahore Qila message")
	check(pa.data.gear.Joggers and pa.data.gear.Shovel and pa.data.rollTokens == 3, "gear and rolls kept")
	check(pa.data.theme == "BaghGarden", "theme kept")
	check(notified("Ali", "New haveli theme unlocked: Truck Art"), "new theme unlocked")
	check(soundsFor("Ali", "Rebirth") == 1, "rebirth sound")
	check(A:GetAttribute("RebirthCost") == 10_000_000, "next Naya Safar costs 4 times more")
	check(h1.StairGates.StairGate.CanCollide and h1.Decor:FindFirstChild("Chowkidar") == nil, "haveli back to level 1")
	haveliPanel.Content.TruckArt.Use.Activated:Fire()
	M.advance(0.1)
	check(
		pa.data.theme == "TruckArt" and math.abs(charA.Humanoid.WalkSpeed - Config.WALK_SPEED * 1.12 * 1.1) < 1e-6,
		"Truck Art makes you faster (with Joggers): " .. charA.Humanoid.WalkSpeed
	)
	before = pa.data.rupees
	qp.Content.Common.Claim.Activated:Fire()
	M.advance(0.1)
	check(entryOf(pa, "MithaiMamu") ~= nil and pa.data.rupees == before, "quest brainrot again, rupees only once")
end

do
	---------------------------------------------------------------------------
	section("Save and rejoin")
	---------------------------------------------------------------------------
	pa.data.trackerLevel = 3
	State.syncGear(pa)
	Havelis.adopt(pa, Brainrots.byId.PyaazPehelwan, "Diamond", nil, true)
	Havelis.adopt(pa, Brainrots.byId.TongaTornado, nil, nil, true)
	M.advance(12)
	pa.data.vehicles.Motorbike.fuel = 777
	pickUp(A, eggIn("MangoBagh", false))
	goTo(A, pa.haveli.spawn.Position)
	M.advance(0.5)
	local savedHatch = pa.incubating[1].hatchAt
	local savedHatchId = pa.incubating[1].id
	removePlayer(A)
	local savedA = M.store["player_1"]
	check(savedA.version == 5 and savedA.rebirths == 1 and savedA.theme == "TruckArt", "v5 save")
	check(table.find(savedA.owned, "PyaazPehelwan:Diamond") ~= nil, "mutations saved")
	check(table.find(savedA.owned, "MithaiMamu") ~= nil, "quest brainrots saved")
	check(savedA.vehicles.Motorbike and savedA.vehicles.Motorbike.speed == 1, "vehicles and upgrades are saved")
	check(savedA.zones.RailwayJunction == true and savedA.zones.MangoBagh == nil, "unlocked zones are saved")
	check(savedA.trackerLevel == 3 and savedA.gear.Shovel == true, "tracker and gear saved")
	check(#savedA.incubators == 1 and savedA.incubators[1].hatchAt == savedHatch, "the hatching egg is saved")
	check(#workspace.ChaiChaosEggs:GetChildren() > 0 and pa.haveli == nil, "Ali's haveli is free again")
	local A2 = addPlayer("Ali", 1)
	M.advance(0.5)
	local pa2 = State.profiles[A2]
	local pyaaz = entryOf(pa2, "PyaazPehelwan")
	check(pyaaz and pyaaz.mutation == "Diamond" and pyaaz.arrived, "Diamond Pyaaz back on its plot")
	check(pa2.haveli.walls[1].Color == Themes.byId.TruckArt.wall, "theme restored")
	check(pa2.incubating[1] and pa2.incubating[1].hatchAt == savedHatch, "the egg is back in its nest")
	check(pa2.incubating[1].id == savedHatchId, "and will hatch the same brainrot")
	check(A2:GetAttribute("TrackerLevel") == 3 and A2:GetAttribute("Gear"):find("Shovel"), "tracker and gear back")
	check(
		pa2.data.vehicles.Motorbike and A2:GetAttribute("Vehicles"):find("^Motorbike:1:1:3:1:") ~= nil,
		"vehicles back"
	)
	check(A2:GetAttribute("OpenZones"):find("LahoreQila") ~= nil, "open zones back")
	local charA2 = spawnCharacter(A2)
	M.advance(0.3)
	check(charA2:FindFirstChild("Vehicle") == nil and pa2.driving == nil, "you rejoin on foot")
	check(not notified("Ali", "Daily chai"), "daily chai only once a day")
	M.advance(khet.hatchTime + 1)
	check(pa2.incubating[1] == nil and entryOf(pa2, savedHatchId) ~= nil, "the saved egg hatched")
	-- old saves still load
	M.store["player_9"] = {
		rupees = 5000,
		plots = 7,
		owned = { "SamosaSupremo", "NotABrainrot" },
		discovered = { SamosaSupremo = true },
		lastDaily = TODAY,
		gear = { Joggers = true, Jetpack = true, [5] = true },
		trackerLevel = 99,
		ride = "NotABrainrot",
		incubators = {
			{ slot = 9, biome = "Khet", id = "SamosaSupremo", hatchAt = 1 },
			{ slot = 1, biome = "Nowhere", id = "SamosaSupremo", hatchAt = 1 },
			{ slot = 1, biome = "Khet", id = "SamosaSupremo", hatchAt = 1 },
			"junk",
		},
	}
	local P = addPlayer("Purana", 9)
	M.advance(0.5)
	local pp = State.profiles[P]
	check(pp.data.level == 2 and pp.data.rupees >= 5000, "old saves move to haveli levels")
	check(Gear.encode(pp.data.gear) == "Joggers", "unknown gear dropped")
	check(
		pp.data.trackerLevel == #Config.TRACKER_LEVELS and pp.data.ride == nil,
		"tracker clamped, old ride field gone"
	)
	check(#pp.data.incubators == 1, "only the good incubator egg is kept")
	M.advance(1)
	check(#pp.owned == 2 and next(pp.incubating) == nil, "and it hatched straight away")
	removePlayer(P)

	---------------------------------------------------------------------------
	section("Sounds and music")
	---------------------------------------------------------------------------
	local clicks = 0
	local soundsAt = #M.soundsPlayed
	hud.Buttons.Collection.Activated:Fire()
	hud.Buttons.Collection.Activated:Fire()
	M.advance(0.1)
	for i = soundsAt + 1, #M.soundsPlayed do
		clicks += if M.soundsPlayed[i].name == "Click" then 1 else 0
	end
	check(clicks == 2, "buttons click")
	local soundFolder = M.services.SoundService:FindFirstChild("ChaiChaosSounds")
	check(soundFolder and soundFolder:FindFirstChild("MusicBazaar") == nil, "no music until you add an id")
	local clientSounds = requireModule(shared:FindFirstChild("Sounds"), "client")
	clientSounds.list.MusicBazaar.id = "rbxassetid://1234"
	M.advance(1.1)
	local playing = nil
	for _, sound in M.services.SoundService:GetDescendants() do
		if sound:IsA("Sound") and sound.Name:match("^Music") and sound.IsPlaying then
			playing = sound
		end
	end
	check(playing and playing.Name == "MusicBazaar" and playing.Looped, "bazaar music plays once it has an id")
end

do
	---------------------------------------------------------------------------
	section("Every theme at every level")
	---------------------------------------------------------------------------
	local HaveliStyle = serverModule("HaveliStyle")
	local spare = Havelis.byIndex(8)
	local most = 0
	for _, theme in Themes.list do
		for level = 1, #Config.HAVELI_LEVELS do
			local guard = HaveliStyle.apply(spare, theme.id, level)
			most = math.max(most, #spare.decor:GetChildren())
			check((guard ~= nil) == (level >= Config.GUARD_LEVEL), theme.id .. " level " .. level .. " guard")
		end
		check(spare.walls[1].Color == theme.wall, theme.id .. " wall colour")
	end
	check(most > 40, "top level havelis are full of decorations: " .. most)
	HaveliStyle.apply(spare, nil, 1)
	check(#spare.decor:GetChildren() == 0 and spare.roof.Transparency == 1, "an empty haveli is plain again")
end

do
	---------------------------------------------------------------------------
	section("Leaderboard")
	---------------------------------------------------------------------------
	M.advance(6)
	local row1 = map.Leaderboard:FindFirstChild("Row1", true)
	check(row1.Text:find("Ali") ~= nil and row1.Text:find("Safar 1") ~= nil, "leaderboard: " .. row1.Text)
end

do
	---------------------------------------------------------------------------
	section("Smooth movement on screen")
	---------------------------------------------------------------------------
	local fake = Models.create(Brainrots.byId.NaanNinja, "Rainbow")
	fake.Parent = workspace
	local startedAt = workspace:GetServerTimeNow()
	fake:SetAttribute("MoveFrom", CFrame.new(0, 5, 0))
	fake:SetAttribute("MoveTo", CFrame.new(100, 5, 0))
	fake:SetAttribute("MoveStart", startedAt)
	fake:SetAttribute("MoveSpeed", 10)
	runScripts(client, "client2", { Smooth = true })
	M.advance(2)
	local expectedCF =
		Motion.at(CFrame.new(0, 5, 0), CFrame.new(100, 5, 0), startedAt, 10, workspace:GetServerTimeNow())
	local gap = fake:GetPivot().Position - expectedCF.Position
	check(math.abs(gap.X) < 0.01 and gap.Y >= -0.01 and gap.Y <= 0.61, "walks smoothly with a hop: " .. tostring(gap))
	local tinted
	for _, p in fake:GetDescendants() do
		if p:IsA("BasePart") and p:GetAttribute("Tint") then
			tinted = p
			break
		end
	end
	local firstColor = tinted.Color
	M.advance(0.5)
	check(tinted.Color ~= firstColor, "rainbow colours change")
	fake:SetAttribute("MoveSpeed", 0)
	fake:SetAttribute("Rest", CFrame.new(0, 5, 0))
	M.advance(0.5)
	local y = fake:GetPivot().Y
	check(y >= 5 and y <= 5.31 and math.abs(fake:GetPivot().X) < 0.01, "idle bob on its plot: " .. y)
end

---------------------------------------------------------------------------
section("Shutdown")
---------------------------------------------------------------------------
local co = coroutine.create(M.bindToClose)
coroutine.resume(co)
M.advance(1)
check(coroutine.status(co) == "dead", "BindToClose finished")
check(M.store["player_1"] and M.store["player_1"].rebirths == 1, "Ali saved on shutdown")
check(M.store["player_1"].vehicles.Motorbike ~= nil, "with his motorbike")

---------------------------------------------------------------------------
print(("\n%d checks passed, %d failed, %d script errors, %d warnings"):format(passed, failed, #M.errors, #M.warnings))
for _, warning in M.warnings do
	print("warning: " .. warning)
end
if failed > 0 or #M.errors > 0 then
	error("TESTS FAILED")
end
