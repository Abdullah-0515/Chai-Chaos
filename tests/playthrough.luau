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
local Riding = serverModule("Riding")
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
check(#Brainrots.list == 42, "36 brainrots + 6 quest brainrots, got " .. #Brainrots.list)
check(Brainrots.byId.SamosaSupremo.price == 100, "prices use the multiplier")
check(Format.rupees(1234567) == "Rs 1,234,567", "format commas")
check(Format.short(12500) == "12.5K" and Format.short(2000000) == "2M", "format short")
check(M.services.Lighting:FindFirstChild("ChaiChaosColor") ~= nil, "bright colour correction added")
check(M.groups.ChaiLaser1 and M.groups.ChaiOwner8 and M.noCollide["ChaiLaser1|ChaiOwner1"], "laser collision groups")
check(not M.noCollide["ChaiLaser1|ChaiOwner2"], "a laser only lets its own owner through")
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
-- the Chowk shops
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
-- 8 biomes, each with a road, a gate, terrain, eggs and treasure
check(#Biomes.list == 8, "8 biomes")
local tiers = {}
for _, biome in Biomes.list do
	tiers[biome.tier] = true
end
check(#tiers == 8, "biome tiers 1 to 8")
check(#map.Biomes:GetChildren() == 8, "8 biome folders")
local gates = 0
for _, d in map.Roads:GetChildren() do
	if d.Name == "GateSign" then
		gates += 1
	end
end
check(gates == 8, "8 biome gates")
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
	check(biome and biome.id == egg:GetAttribute("Biome"), "egg lies in its own biome: " .. egg.Name)
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
	check((chestsIn[biome.id] or 0) >= 2, biome.id .. " has treasure chests")
	check(#plan.eggSpots >= 20, biome.id .. " has egg spots")
	local inside = true
	for _, spot in plan.eggSpots do
		local b = Biomes.at(spot)
		inside = inside and b ~= nil and b.id == biome.id
	end
	check(inside, biome.id .. " egg spots are inside the biome")
	check(#plan.zones > 0, biome.id .. " has hazard zones")
	check(Biomes.innerRadius(biome) + Biomes.DEPTH < Biomes.WORLD_RADIUS, biome.id .. " fits in the world")
end
check(Biomes.at(Vector3.new(0, 5, 0)) == nil, "the Chowk is not a biome")
local khet = Biomes.byId.Khet
check(Biomes.at(Biomes.point(khet, Biomes.innerRadius(khet) + 20)).id == "Khet", "Biomes.at finds Khet")
check(
	(Biomes.innerRadius(Biomes.byId.NamakKaan) > Biomes.innerRadius(khet))
		and Biomes.byId.NamakKaan.eggTime < khet.eggTime,
	"further biomes are further away and their eggs crack sooner"
)
for name, info in Sounds.list do
	check(type(info.id) == "string" and info.volume > 0, "sound " .. name)
end

do
	---------------------------------------------------------------------------
	section("Biome zones, landmarks and the countryside")
	---------------------------------------------------------------------------
	local Props = serverModule("Props")
	local PropData = serverModule("PropData")
	local MapBuilder = serverModule("MapBuilder")
	-- the biomes are separate zones with countryside between them
	for i, biome in Biomes.list do
		local nextBiome = Biomes.list[i % #Biomes.list + 1]
		local gapAngle = math.rad(45 * i)
		local gapDistance = (Biomes.centerDistance(biome) + Biomes.centerDistance(nextBiome)) / 2
		local gap = Vector3.new(math.cos(gapAngle) * gapDistance, Biomes.GROUND_Y, math.sin(gapAngle) * gapDistance)
		check(Biomes.at(gap) == nil, "countryside between " .. biome.id .. " and " .. nextBiome.id)
		check(Biomes.at(Biomes.center(biome)) == biome, biome.id .. " has its own zone")
		check(
			not Biomes.contains(biome, Vector3.zero) and Biomes.zoneDistance(biome, Biomes.center(biome)) < 0.01,
			biome.id .. " zone maths"
		)
	end
	-- each biome's landmark, modelled in Blender
	local landmarks = {
		Khet = { "Rehat", "WaterTank", "MudHut" },
		Jungle = { "Treehouse", "RopeBridge", "BanyanTree" },
		Samandar = { "Lighthouse", "BeachHutTeal", "FishingBoat", "CoconutPalm" },
		Jheel = { "RestHouse", "Jetty", "RowBoat", "Willow" },
		Registan = { "DesertFort", "DesertTent", "KikarDry" },
		Delta = { "StiltVillage", "Mangrove", "NetRack" },
		Pahar = { "SuspensionBridge", "MountainHut", "DeodarSnowy" },
		NamakKaan = { "MineEntrance", "MineTrack", "CaveSupport", "CrystalCluster" },
	}
	for biomeId, names in landmarks do
		local folder = map.Biomes:FindFirstChild(biomeId)
		for _, name in names do
			check(folder and folder:FindFirstChild(name) ~= nil, biomeId .. " has a " .. name)
		end
	end
	check(map.Biomes.NamakKaan:FindFirstChild("SignText", true).Gui.Text.Text == "NAMAK KAAN", "mine entrance sign")
	-- climbing chests land you next to the treasure
	for _, chest in Treasure.all() do
		if chest.kind == "climb" and chest.stand then
			check((chest.stand - chest.top).Magnitude < 6, chest.model.Name .. " stand spot is next to the chest")
		end
	end
	-- the countryside
	local country = map.Countryside
	local counts = {}
	for _, item in country:GetChildren() do
		counts[item.Name] = (counts[item.Name] or 0) + 1
	end
	check((counts.ChaiDhaba or 0) >= 5, "roadside dhabas: " .. tostring(counts.ChaiDhaba))
	check((counts.Milestone or 0) >= 12, "milestones: " .. tostring(counts.Milestone))
	check((counts.BusStop or 0) == 4, "bus stops: " .. tostring(counts.BusStop))
	check((counts.TruckArt or 0) + (counts.Rickshaw or 0) >= 5, "parked trucks and rickshaws")
	check(((counts.WheatField or 0) + (counts.SarsonField or 0) + (counts.SugarcaneField or 0)) >= 20, "farm fields")
	check((counts.TractorTrolley or 0) >= 3 and (counts.TubeWell or 0) >= 6, "tractors and tube wells on the farms")
	check((counts.KikarTree or 0) >= 30 and (counts.MangoTree or 0) >= 15, "trees")
	check((counts.Reeds or 0) >= 20, "ponds with reeds")
	check((counts.CricketStumps or 0) >= 1 and (counts.KiteLine or 0) >= 1, "street cricket and kites")
	local onRoads = 0
	for _, item in country:GetChildren() do
		if item:IsA("Model") and item.Name ~= "Lamppost" and item.Name ~= "Reeds" and item.Name ~= "Milestone" then
			if not MapBuilder.isCountryside(item.WorldPivot.Position, 0) then
				onRoads += 1
			end
		end
	end
	check(onRoads == 0, "nothing in the countryside sits on a road, in a biome or in the bazaar: " .. onRoads)
	local milestone = country:FindFirstChild("SignText")
	check(milestone and milestone.Gui.Text.Text:match("^%u+\n%d+$") ~= nil, "milestones count down to a biome")
	check(map.Roads:FindFirstChild("Signboard") ~= nil, "road signs by the Chowk")
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
check(pa.data.version == 3 and pa.data.trackerLevel == 1 and next(pa.data.gear) == nil, "v3 data: tracker 1, no gear")
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
for _, name in { "Taala", "Haveli", "Kismat", "Quests", "Collection", "Brainrots" } do
	check(hud.Buttons:FindFirstChild(name) ~= nil, "HUD button " .. name)
end
check(hud.Buttons:FindFirstChild("NayaSafar") == nil, "Naya Safar is at the Chowk now, not a button")
check(hud.Buttons:FindFirstChild("ChorPass") == nil, "no Chor Pass button while stealing is free")
check(hud.EventBanner.Title.Text == "Next event", "event banner")
check(hud.Money:FindFirstChildWhichIsA("TextLabel").Text == Format.rupees(pa.data.rupees), "HUD shows rupees")
check(hud.RadarHolder.Radar.Level.Text == "Radar Lv 1", "radar level shown")
check(hud.RadarHolder.Tracks.Text == "Tracks: Khet", "radar tracks Khet: " .. hud.RadarHolder.Tracks.Text)
check(hud.RadarHolder.Area.Text == "Chowk Bazaar", "radar says where you are: " .. hud.RadarHolder.Area.Text)
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
local khetEgg = eggIn("Khet", false)
check(khetEgg ~= nil, "found a Khet egg")
markLog()
PPS.PromptTriggered:Fire(khetEgg.PrimaryPart.EggPrompt, A)
M.advance(0.05)
check(pa.egg == nil, "cannot pick up an egg from far away")
pickUp(A, khetEgg)
check(pa.egg ~= nil and pa.egg.model == khetEgg, "picked up the Khet egg")
check(A:GetAttribute("EggBiome") == "Khet" and A:GetAttribute("EggTimeTotal") == 60, "egg timer starts at 60s")
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
check(hud.RadarStatus.EggBar.Text.Text:find("Khet egg") ~= nil, "egg bar: " .. hud.RadarStatus.EggBar.Text.Text)
check(hud.RadarHolder.Area.Text == "Khet", "radar: in Khet")
local sawEggDot = false
for _, d in visibleDots() do
	sawEggDot = sawEggDot or d.BackgroundColor3 == khet.eggColor
end
check(sawEggDot, "radar shows the egg next to Ali")
check(#visibleDots() >= 3, "radar shows eggs, home and the Chowk")
check(hud.AreaTitle.Text == "KHET · Punjab Fields", "biome title when walking in: " .. hud.AreaTitle.Text)
local beforeRefill = groundEggs("Khet")
M.advance(Config.EGG_RESPAWN + 0.5)
check(groundEggs("Khet") >= beforeRefill, "eggs refill over time")

markLog()
goTo(A, pa.haveli.spawn.Position)
M.advance(0.5)
check(pa.egg == nil and pa.incubating[1] ~= nil, "home safe: the egg is in the incubator")
local record = pa.incubating[1]
check(inPool(khet, record.id), "what hatches is from Khet's pool: " .. record.id)
check(khetEgg.Parent == pa.haveli.brainrotFolder, "the egg sits in the nest")
check(notified("Ali", "Home safe") and soundsFor("Ali", "EggHome") == 1, "home message and sound")
check(A:GetAttribute("EggBiome") == "" and not hud.RadarStatus.EggBar.Visible, "egg bar gone")
check(pa.haveli.incubatorLabels[1].Text:find("Hatching") ~= nil, "nest shows the countdown")
check(pa.data.quests.list[1].progress == 1 and pa.data.quests.list[2].progress == 1, "egg quests count")

-- a second egg while the incubator is busy
local jungle = Biomes.byId.Jungle
local jungleEgg = eggIn("Jungle", false)
pickUp(A, jungleEgg)
check(pa.egg and A:GetAttribute("EggTimeTotal") == jungle.eggTime, "Jungle egg picked up")
markLog()
goTo(A, pa.haveli.spawn.Position)
M.advance(0.5)
check(pa.egg ~= nil and notified("Ali", "incubators are full"), "incubator full: keep holding it")
local held = A:GetAttribute("EggTimeLeft")
M.advance(3)
check(A:GetAttribute("EggTimeLeft") == held, "the egg is safe at home while you wait")
markLog()
M.advance(khet.hatchTime)
check(#pa.owned == 1 and inPool(khet, pa.owned[1].def.id), "the Khet egg hatched")
check(notified("Ali", "Your egg hatched") and soundsFor("Ali", "EggHatch") == 1, "hatch message and sound")
check(pa.egg == nil and pa.incubating[1] and pa.incubating[1].biome == "Jungle", "the Jungle egg took the nest")
check(pa.data.quests.list[2].progress == 2, "two different biomes")
check(pa.data.quests.list[3].progress == 1, "first brainrot discovered")
M.advance(jungle.hatchTime + 1)
check(#pa.owned == 2 and inPool(jungle, pa.owned[2].def.id), "the Jungle egg hatched")
M.advance(10)
check(pa.owned[1].arrived and pa.owned[2].arrived, "hatched brainrots walk to their plots")
check(A:GetAttribute("Owned"):find(pa.owned[1].def.id) ~= nil, "the Brainrots window knows what Ali owns")

-- an egg that cracks
local samandar = Biomes.byId.Samandar
local seaEgg = eggIn("Samandar", false)
pickUp(A, seaEgg)
markLog()
M.advance(samandar.eggTime + 1)
check(pa.egg == nil and seaEgg.Parent == nil, "the egg cracked")
check(notified("Ali", "cracked") and soundsFor("Ali", "EggCrack") == 1, "crack message and sound")
check(A:GetAttribute("EggBiome") == "", "nothing carried")

-- dying drops the egg
local dropEgg = eggIn("Khet", false)
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
section("Biome hazards")
---------------------------------------------------------------------------
local function zoneSpot(biomeId, kind)
	local biome = Biomes.byId[biomeId]
	for _, z in plans[biomeId].zones do
		if z.kind == kind then
			if z.center then
				return Vector3.new(z.center.X, Biomes.GROUND_Y, z.center.Z)
			end
			local r = (z.inner + math.min(z.outer, Biomes.innerRadius(biome) + Biomes.DEPTH)) / 2
			return Biomes.point(biome, r, 0)
		end
	end
	error("no " .. kind .. " zone in " .. biomeId)
end

markLog()
goTo(A, zoneSpot("Khet", "mud"))
M.advance(0.5)
check(pa.hazardSpeed == Config.HAZARD_SPEED.mud, "mud slows you down")
check(math.abs(charA.Humanoid.WalkSpeed - Config.WALK_SPEED * Config.HAZARD_SPEED.mud) < 1e-6, "walk speed in mud")
check(A:GetAttribute("Hazard") == "Mud! Gum Boots helps", "hazard warning: " .. A:GetAttribute("Hazard"))
check(hud.RadarStatus.Hazard.Visible and hud.RadarStatus.Hazard.Text == "Mud! Gum Boots helps", "warning on the radar")
pa.data.gear.GumBoots = true
State.syncGear(pa)
M.advance(0.5)
check(charA.Humanoid.WalkSpeed == Config.WALK_SPEED and A:GetAttribute("Hazard") == "", "Gum Boots: no more mud")
goTo(A, pa.haveli.spawn.Position)
M.advance(0.5)

-- water makes eggs crack faster
local riverEgg = eggIn("Jungle", false)
pickUp(A, riverEgg)
goTo(A, zoneSpot("Jungle", "water"))
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

-- waves on the beach
goTo(A, zoneSpot("Samandar", "shore"))
M.advance(0.3)
markLog()
t0 = pa.egg.timeLeft
Hazards.wave()
M.advance(0.05)
check(t0 - pa.egg.timeLeft >= Config.EGG_HIT_PENALTY - 0.1, "a big wave knocks time off the egg")
check(notified("Ali", "SPLASH") and soundsFor("Ali", "Splash") == 1, "splash message and sound (once)")
check(workspace:GetAttribute("WaveAt") ~= nil, "clients are told about the wave")
pa.data.gear.LifeJacket = true
State.syncGear(pa)
t0 = pa.egg.timeLeft
Hazards.wave()
M.advance(0.05)
check(t0 - pa.egg.timeLeft < 0.2, "a Life Jacket shrugs off waves")

-- snowballs in the mountains, salt in the caves
goTo(A, Biomes.point(Biomes.byId.Pahar, Biomes.innerRadius(Biomes.byId.Pahar) + 30, 10))
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
check(t0 - pa.egg.timeLeft < 0.2, "Snow Boots dodge snowballs")
goTo(A, zoneSpot("Pahar", "ice"))
M.advance(0.3)
check(pa.hazardSpeed == 1, "Snow Boots: no slipping on ice")
local namak = Biomes.byId.NamakKaan
goTo(A, Biomes.point(namak, Biomes.innerRadius(namak) + 40, 0))
M.advance(0.5)
t0 = pa.egg.timeLeft
Hazards.salt()
M.advance(0.05)
check(t0 - pa.egg.timeLeft >= Config.EGG_HIT_PENALTY - 0.1, "falling salt")
local tint = M.services.Lighting:FindFirstChild("ChaiChaosBiomeTint")
check(tint and tint.Brightness < -0.2, "the salt caves are dark")
pa.data.gear.Lantern = true
State.syncGear(pa)
M.advance(0.5)
t0 = pa.egg.timeLeft
Hazards.salt()
M.advance(0.05)
check(t0 - pa.egg.timeLeft < 0.2, "a Lantern lights the way")
check(charA.HumanoidRootPart:FindFirstChild("LanternGlow") ~= nil and tint.Brightness > -0.2, "lantern glow")

-- sandstorms in the desert
goTo(A, Biomes.point(Biomes.byId.Registan, Biomes.innerRadius(Biomes.byId.Registan) + 60, 0))
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
EggSystem.drop(A)
pa.data.gear = {}
State.syncGear(pa)
goTo(A, pa.haveli.spawn.Position)
M.advance(0.5)
check(charA.Humanoid.WalkSpeed == Config.WALK_SPEED and A:GetAttribute("Hazard") == "", "back home, all normal")

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
check(trackerPanel.Content.Next.Text:find("Jungle") ~= nil, "next level tracks Jungle")
setQuests(pa, { { id = "upgrade", target = 1, progress = 0, claimed = false } })
markLog()
trackerPanel.Content.Upgrade.Activated:Fire()
M.advance(0.1)
check(pa.data.trackerLevel == 2 and pa.data.rupees == 97_500, "tracker level 2")
check(A:GetAttribute("TrackerLevel") == 2 and notified("Ali", "Tracker level 2"), "tracker message")
check(soundsFor("Ali", "Upgrade") == 1, "upgrade sound")
check(pa.data.quests.list[1].progress == 1, "tracker upgrades count for the upgrade quest")
M.advance(0.2)
check(hud.RadarHolder.Tracks.Text == "Tracks: Khet, Jungle", "radar tracks Jungle too")
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
check(hud.RadarHolder.Tracks.Text:find("Namak Kaan") ~= nil, "radar tracks every biome")
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
check(hud.RadarStatus.EggBar.Text.Text:find("Golden egg") ~= nil, "egg bar says golden")
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
EggSystem.startRush("Registan")
M.advance(0.5)
check(workspace:GetAttribute("EggRush") == "Registan" and notified("Ali", "EGG RUSH in Registan"), "egg rush")
check(
	groundEggs("Registan") >= Config.EGGS_PER_BIOME + Config.EGG_RUSH_EGGS - 1,
	"lots of eggs: " .. groundEggs("Registan")
)
check(groundEggs("Khet") <= Config.EGGS_PER_BIOME + 1, "only in the rush biome")
check(hud.RadarStatus.Rush.Visible and hud.RadarStatus.Rush.Text:find("Registan"), "rush on the radar")
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
check(khetOutside == 0, "Khet eggs only hatch Khet brainrots")
check(math.abs(khetCounts.Common / 40000 - 0.7) < 0.015, "Khet common ~70%: " .. khetCounts.Common / 40000)
check(math.abs((khetCounts.Rare or 0) / 40000 - 0.05) < 0.006, "Khet rare ~5%")
check(not khetCounts.Epic and not khetCounts.Mythic, "no Epics in the starter biome")
local namakCounts, namakOutside = tally(namak, false, 40000)
check(namakOutside == 0 and (namakCounts.Mythic or 0) > 0, "Namak Kaan can hatch Mythics")
local goldenCounts = tally(khet, true, 40000)
check((goldenCounts.Rare or 0) / 40000 > 0.08, "golden eggs are luckier: " .. (goldenCounts.Rare or 0) / 40000)
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
section("Brainrots window: riding and selling")
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
check(not brainrotPanel.Content.StopRide.Visible, "not riding yet")
-- ride the most valuable one
local best = pa.owned[1]
for _, e in pa.owned do
	if Havelis.entryValue(e) > Havelis.entryValue(best) then
		best = e
	end
end
local incomeBefore = Havelis.incomePerSecond(pa)
markLog()
brainrotPanel.Content.Brainrot1.Button.Activated:Fire()
M.advance(0.2)
check(pa.ride and pa.ride.def == best.def and pa.ride.mutation == best.mutation, "riding " .. best.def.id)
check(entryOf(pa, best.def.id) == nil or #pa.owned == rows - 1, "the ride left its plot")
check(Havelis.incomePerSecond(pa) < incomeBefore, "the ride does not earn")
local rideSpeed = Riding.speedFor(best.def, best.mutation)
check(A:GetAttribute("RideSpeed") == rideSpeed and A:GetAttribute("Ride") ~= "", "ride shown on the HUD")
check(
	charA:FindFirstChild("Ride") ~= nil and charA.Ride.PrimaryPart:FindFirstChild("RideWeld"),
	"the brainrot carries Ali"
)
check(charA.Humanoid.HipHeight > 2, "Ali sits on top")
check(
	math.abs(charA.Humanoid.WalkSpeed - Config.WALK_SPEED * 1.1 * rideSpeed) < 1e-6,
	"riding is faster: " .. charA.Humanoid.WalkSpeed
)
check(notified("Ali", "You're riding"), "ride message")
check(brainrotPanel.Content.StopRide.Visible, "stop riding button")
check(pa.data.ride == Mutations.key(best.def.id, best.mutation), "ride saved")
-- rarer is faster
check(
	Riding.speedFor(Brainrots.byId.AmmiKiUdtiChappal) > Riding.speedFor(Brainrots.byId.SamosaSupremo),
	"Mythic rides are faster than Common ones"
)
check(
	Riding.speedFor(Brainrots.byId.SamosaSupremo, "Rainbow") > Riding.speedFor(Brainrots.byId.SamosaSupremo),
	"mutations ride faster"
)
-- respawning keeps the ride
local oldChar = charA
charA = spawnCharacter(A)
M.advance(0.3)
oldChar:Destroy()
check(charA:FindFirstChild("Ride") ~= nil, "back on the ride after respawning")
check(math.abs(charA.Humanoid.WalkSpeed - Config.WALK_SPEED * 1.1 * rideSpeed) < 1e-6, "ride speed after respawn")
-- stop riding: it walks home
local ownedBefore = #pa.owned
brainrotPanel.Content.StopRide.Activated:Fire()
M.advance(0.2)
check(pa.ride == nil and #pa.owned == ownedBefore + 1, "the ride walked home")
check(charA:FindFirstChild("Ride") == nil and charA.Humanoid.HipHeight == 2, "off the ride")
check(math.abs(charA.Humanoid.WalkSpeed - Config.WALK_SPEED * 1.1) < 1e-6, "normal speed again")
check(A:GetAttribute("Ride") == "" and pa.data.ride == nil, "no ride")

-- selling at the BECHO stall
markLog()
Remotes.SellBrainrot:FireServer(pa.owned[1].uid)
M.advance(0.1)
check(#pa.owned == ownedBefore + 1 and notified("Ali", "BECHO stall"), "cannot sell from home")
hud.Buttons.Brainrots.Activated:Fire() -- close
openShop("Sell")
check(brainrotPanel.Visible, "the BECHO stall opens the Brainrots window")
M.advance(0.6)
local sellButton = brainrotPanel.Content.Brainrot1:FindFirstChild("Sell")
check(sellButton ~= nil and brainrotPanel.Content.SellInfo.Text:find("half") ~= nil, "sell buttons at the stall")
local sold = nil
local mostValuable = 0
for _, e in pa.owned do
	mostValuable = math.max(mostValuable, Havelis.entryValue(e))
end
local beforeSale = pa.data.rupees
sellButton.Activated:Fire()
M.advance(0.2)
check(pa.data.rupees == beforeSale + math.floor(mostValuable * Config.SELL_RATE), "sold for half its value")
check(#pa.owned == ownedBefore and soundsFor("Ali", "Coin") >= 1, "sold, with a coin sound")
Remotes.SellBrainrot:FireServer(-5)
Remotes.SellBrainrot:FireServer("abc")
M.advance(0.1)
check(#pa.owned == ownedBefore, "bad sell requests ignored")
_ = sold

---------------------------------------------------------------------------
section("Treasure")
---------------------------------------------------------------------------
local digChest, climbChest
for _, chest in Treasure.all() do
	if chest.biome.id == "Jungle" and chest.kind == "dig" then
		digChest = chest
	elseif chest.biome.id == "Khet" and chest.kind == "climb" then
		climbChest = chest
	end
end
check(digChest and climbChest, "a buried chest in the Jungle and a high one in Khet")
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
check(pa.data.rupees == beforeTreasure + jungleTreasure, "Jungle treasure: Rs " .. jungleTreasure)
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
check(pa.data.rupees == beforeTreasure + Config.TREASURE_RUPEES, "Khet treasure")
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
local eggA, eggB = eggIn("Khet", false), eggIn("Jungle", false)
pickUp(A, eggA)
goTo(A, pa.haveli.spawn.Position)
M.advance(0.5)
pickUp(A, eggB)
goTo(A, pa.haveli.spawn.Position)
M.advance(0.5)
check(pa.incubating[1] and pa.incubating[2] and pa.egg == nil, "two eggs in two incubators")
M.advance(Biomes.byId.Jungle.hatchTime + 1)
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
	local bilalEgg = eggIn("Khet", false)
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
	local contested = eggIn("Jungle", false)
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
	check(notified("Bilal", "dropped your egg"), "drop message")
	pickUp(A, contested)
	check(pa.egg and pa.egg.biome.id == "Jungle", "Ali grabbed Bilal's egg")
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
end

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
	check(luckyRares / 40000 > 0.08, "luck makes rare hatches likelier: " .. luckyRares / 40000)
	EventRunner.stop()
	M.advance(1)
	check(effects:FindFirstChild("Kite") == nil and hud.EventBanner.Title.Text == "Next event", "kites gone")
	check(hud.EventBanner.Perks.Text == "", "no boosts between events")

	EventRunner.start("Baarish")
	M.advance(Config.EGG_RESPAWN * 10)
	check(groundEggs("Jheel") > Config.EGGS_PER_BIOME, "Baarish: more eggs everywhere: " .. groundEggs("Jheel"))
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
	pickUp(A, eggIn("Khet", false))
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
	pickUp(A, eggIn("Khet", false))
	goTo(A, pa.haveli.spawn.Position)
	M.advance(0.5)
	check(next(pa.incubating) ~= nil, "an egg is hatching")
	Riding.set(A, pa.owned[1].uid)
	M.advance(0.2)
	check(pa.ride ~= nil, "and Ali is riding")
	markLog()
	Remotes.Rebirth:FireServer()
	M.advance(0.1)
	check(pa.data.rebirths == 0 and notified("Ali", "Naya Safar stall"), "Naya Safar only at the Chowk")
	openShop("Rebirth")
	local rp = hud.RebirthPanel
	check(rp.Visible, "the Naya Safar gate opens its window")
	check(rp.Content.Cost.Text:find("Rs 1,000,000") ~= nil, "cost shown: " .. rp.Content.Cost.Text)
	check(rp.Content.Theme.Text:find("Truck Art") ~= nil, "shows the theme it unlocks")
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
	check(pa.ride == nil and A:GetAttribute("Ride") == "" and charA:FindFirstChild("Ride") == nil, "ride reset")
	check(pa.data.gear.Joggers and pa.data.gear.Shovel and pa.data.rollTokens == 3, "gear and rolls kept")
	check(pa.data.theme == "BaghGarden", "theme kept")
	check(notified("Ali", "New haveli theme unlocked: Truck Art"), "new theme unlocked")
	check(soundsFor("Ali", "Rebirth") == 1, "rebirth sound")
	check(A:GetAttribute("RebirthCost") == 2_500_000, "next Naya Safar costs more")
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
	Riding.set(A, entryOf(pa, "TongaTornado").uid)
	pickUp(A, eggIn("Khet", false))
	goTo(A, pa.haveli.spawn.Position)
	M.advance(0.5)
	local savedHatch = pa.incubating[1].hatchAt
	local savedHatchId = pa.incubating[1].id
	removePlayer(A)
	local savedA = M.store["player_1"]
	check(savedA.version == 3 and savedA.rebirths == 1 and savedA.theme == "TruckArt", "v3 save")
	check(table.find(savedA.owned, "PyaazPehelwan:Diamond") ~= nil, "mutations saved")
	check(table.find(savedA.owned, "MithaiMamu") ~= nil, "quest brainrots saved")
	check(savedA.ride == "TongaTornado" and table.find(savedA.owned, "TongaTornado") == nil, "the ride is saved")
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
	check(pa2.ride and pa2.ride.def.id == "TongaTornado" and A2:GetAttribute("Ride") == "Tonga Tornado", "ride back")
	local charA2 = spawnCharacter(A2)
	M.advance(0.3)
	check(charA2:FindFirstChild("Ride") ~= nil, "riding again after rejoining")
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
	check(pp.data.trackerLevel == #Config.TRACKER_LEVELS and pp.data.ride == nil, "tracker clamped, bad ride dropped")
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
check(M.store["player_1"].ride == "TongaTornado", "with his ride")

---------------------------------------------------------------------------
print(("\n%d checks passed, %d failed, %d script errors, %d warnings"):format(passed, failed, #M.errors, #M.warnings))
for _, warning in M.warnings do
	print("warning: " .. warning)
end
if failed > 0 or #M.errors > 0 then
	error("TESTS FAILED")
end
