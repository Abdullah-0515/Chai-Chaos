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
-- events would start by themselves after a few minutes; the tests start them by hand
local Config = sharedModule("Config")
Config.FIRST_EVENT_DELAY = 1e9
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
local State = serverModule("State")
local Havelis = serverModule("Havelis")
local Spawner = serverModule("Spawner")
local Mover = serverModule("Mover")
local Models = serverModule("Models")
local Kismat = serverModule("Kismat")
local QuestBook = serverModule("QuestBook")
local EventRunner = serverModule("EventRunner")
local Brainrots = sharedModule("Brainrots")
local Format = sharedModule("Format")
local Mutations = sharedModule("Mutations")
local Themes = sharedModule("Themes")
local Remotes = sharedModule("Remotes")
local Motion = sharedModule("Motion")
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

local TODAY = math.floor(M.os.time() / 86400)
local function setQuests(profile, list)
	profile.data.quests = { day = TODAY, list = list, bonusClaimed = false }
	State.syncQuests(profile)
end

local function buy(player, id, mutation)
	local model = Spawner.spawn(Brainrots.byId[id], mutation)
	M.advance(0.1)
	moveNear(player, model)
	trigger(model, "BuyPrompt", player)
	return model
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
check(notified("Ali", "Daily chai") and notified("Ali", "free Kismat Roll"), "daily chai with a free roll")
check(pa.data.rollTokens == 1, "one free Kismat Roll")
check(notified("Ali", "Haveli menu"), "new players are told to pick a theme")
check(#pa.data.quests.list == Config.QUESTS_PER_DAY, "daily quests given")
check(type(A:GetAttribute("QuestState")) == "string", "quest state sent to the HUD")
check(h1.Walls:GetChildren()[1].Material == M.Enum.Material.Marble, "Mughal Marble walls")
check(#h1.Decor:GetChildren() > 0, "level 1 decorations")
check(h1.StairGates.StairGate.CanCollide == true, "stairs closed at level 1")
local charA = spawnCharacter(A)
M.advance(0.3)
check((charA:GetPivot().Position - pa.haveli.spawn.Position).Magnitude < 0.01, "Ali teleported into haveli")
check(charA.Humanoid.WalkSpeed == Config.WALK_SPEED, "walk speed " .. charA.Humanoid.WalkSpeed)
check(charA.HumanoidRootPart.CollisionGroup == "ChaiOwner1", "Ali can pass his own laser")
check(A.Backpack:FindFirstChild("Chappal") ~= nil, "Ali has a chappal")

M.localPlayer = A
M.rawset(Players, "LocalPlayer", A)
runScripts(client, "client")
M.advance(0.5)
local hud = A.PlayerGui:FindFirstChild("ChaiChaosHud")
check(hud ~= nil, "HUD created")
for _, name in { "Taala", "Haveli", "Kismat", "Quests", "Collection", "NayaSafar" } do
	check(hud.Buttons:FindFirstChild(name) ~= nil, "HUD button " .. name)
end
check(hud.Buttons:FindFirstChild("ChorPass") == nil, "no Chor Pass button while stealing is free")
check(hud.EventBanner.Title.Text == "Next event", "event banner")
check(hud.Money:FindFirstChildWhichIsA("TextLabel").Text == Format.rupees(pa.data.rupees), "HUD shows rupees")

---------------------------------------------------------------------------
section("Bazaar Lane")
---------------------------------------------------------------------------
M.advance(30)
local lane = map.LaneBrainrots
local walkers = lane:GetChildren()
check(#walkers >= 4, "walkers on the lane: " .. #walkers)
local w = walkers[#walkers]
check((w:GetAttribute("MoveSpeed") or 0) > 0 and w:GetAttribute("MoveTo") ~= nil, "walkers tell clients how they move")
local x0 = w:GetPivot().X
M.advance(1)
check(w.Parent ~= nil and w:GetPivot().X > x0, "server position keeps up")
check(math.abs(Mover.pivot(w).X - w:GetPivot().X) < 3, "server position within a few studs of the walk")
M.advance(30)
check(w.Parent == nil, "unbought walker vanished at the Chowk")

---------------------------------------------------------------------------
section("Buying")
---------------------------------------------------------------------------
Havelis.clearBrainrots(pa)
pa.data.rupees = 50000
State.syncStats(pa)
setQuests(pa, {
	{ id = "buyLane", target = 3, progress = 0, claimed = false },
	{ id = "mutation", target = 1, progress = 0, claimed = false },
	{ id = "collect", target = 100, progress = 0, claimed = false },
})

markLog()
local before = pa.data.rupees
local samosa = buy(A, "SamosaSupremo")
check(pa.data.rupees == before - 100, "paid Rs 100 for samosa")
check(samosa.Parent == pa.haveli.brainrotFolder, "samosa moved into Ali's haveli folder")
check(prompt(samosa, "BuyPrompt") == nil, "buy prompt removed")
check(notified("Ali", "You bought Samosa Supremo"), "buy message")
buy(A, "ChaiyooKettlesaurus")
buy(A, "ChanaChaatChacha")
local golden = buy(A, "GolGappaGhostu", "Golden")
check(pa.data.rupees == before - 100 - 200 - 80 - 75, "golden brainrot costs 1.5x: " .. (before - pa.data.rupees))
M.advance(12)
check(#pa.owned == 4, "4 brainrots on 4 plots")
check(plotOf(pa, "ChaiyooKettlesaurus") == 1 and plotOf(pa, "SamosaSupremo") == 2, "most valuable in the lockers")
for _, e in pa.owned do
	local plot = pa.haveli.plots[e.plot]
	local d = (e.model:GetPivot().Position - plot.Position) * Vector3.new(1, 0, 1)
	check(e.arrived and d.Magnitude < 0.01, e.def.id .. " stands on its plot")
	check(e.model:GetAttribute("MoveSpeed") == 0 and e.model:GetAttribute("Rest") ~= nil, e.def.id .. " resting")
end
local goldenEntry = entryOf(pa, "GolGappaGhostu")
check(goldenEntry.mutation == "Golden" and Havelis.entryIncome(goldenEntry) == 2, "golden earns 2x")
check(golden.PrimaryPart.Popup.NameLabel.Text == "Golden Gol Gappa Ghostu", "golden name tag")
check(pa.data.mutations["GolGappaGhostu:Golden"] == true, "mutation recorded for the Collection Book")
check(A:GetAttribute("Discovered"):find("GolGappaGhostu:Golden") ~= nil, "mutation badge sent to the HUD")
check(pa.data.quests.list[1].progress == 3 and pa.data.quests.list[2].progress == 1, "quests track buys and mutations")

markLog()
local extra = buy(A, "NaanNinja")
check(notified("Ali", "No empty plot") and extra.Parent == lane, "no empty plot")

---------------------------------------------------------------------------
section("Haveli levels")
---------------------------------------------------------------------------
local haveliPanel = hud.HaveliPanel
hud.Buttons.Haveli.Activated:Fire()
M.advance(0.1)
check(haveliPanel.Visible, "Haveli panel opens")
check(
	haveliPanel.Content.Upgrade.Text == "Upgrade for Rs 4,000",
	"upgrade price shown: " .. haveliPanel.Content.Upgrade.Text
)
check(h1.Plot5.Gui.Label.Text == "Level 2", "locked plots show which level unlocks them")
markLog()
before = pa.data.rupees
haveliPanel.Content.Upgrade.Activated:Fire()
M.advance(0.2)
check(pa.data.level == 2 and pa.data.rupees == before - 4000, "upgraded to level 2")
check(Havelis.plotCount(pa) == 6 and h1.Plot5.Transparency == 0, "level 2 has 6 plots")
check(notified("Ali", "Haveli Level 2"), "upgrade message")
check(hud.Buttons.Haveli.Text == "Haveli Lv 2", "HUD shows the level")
pa.data.rupees = 0
State.syncStats(pa)
markLog()
Remotes.UpgradeHaveli:FireServer()
M.advance(0.1)
check(pa.data.level == 2 and notified("Ali", "You need"), "cannot upgrade without rupees")

pa.data.rupees = 10_000_000
State.syncStats(pa)
for _ = 3, 5 do
	Remotes.UpgradeHaveli:FireServer()
	M.advance(0.1)
end
check(pa.data.level == 5 and Havelis.plotCount(pa) == 12, "level 5 has 12 plots")
check(h1.StairGates.StairGate.CanCollide == false and h1.StairGates.StairGate.Transparency == 1, "stairs open")
check(h1.Barrier.CanCollide == false, "laser off while unlocked")
for _ = 1, 8 do
	buy(A, "NaanNinja")
end
M.advance(15)
check(#pa.owned == 12, "12 brainrots")
local upstairs = 0
for _, e in pa.owned do
	if e.plot > 10 then
		upstairs += 1
		local plot = pa.haveli.plots[e.plot]
		local d = (e.model:GetPivot().Position - plot.Position) * Vector3.new(1, 0, 1)
		check(e.arrived and d.Magnitude < 0.01, "brainrot walked up the stairs to plot " .. e.plot)
		check(e.model:GetPivot().Y > plot.Position.Y, "standing on the second floor")
	end
end
check(upstairs == 2, "the two cheapest went upstairs")

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
check(h1.Decor:FindFirstChild("Leaves", true) ~= nil, "garden decorations")
Remotes.SetTheme:FireServer("NotATheme")
Remotes.SetTheme:FireServer(42)
M.advance(0.1)
check(pa.data.theme == "BaghGarden", "bad theme requests ignored")

---------------------------------------------------------------------------
section("Income and galla")
---------------------------------------------------------------------------
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
check(pa.data.quests.list[3].progress == 100, "collect quest counts rupees")

---------------------------------------------------------------------------
section("Quests")
---------------------------------------------------------------------------
local qp = hud.QuestPanel
hud.Buttons.Quests.Activated:Fire()
M.advance(0.1)
check(qp.Visible and not haveliPanel.Visible, "only one window open at a time")
check(hud.Buttons.Quests.Text == "Quests (!)", "quest button shows a reward is waiting")
check(qp.Content.Quest1.Text.Text == "Buy 3 brainrots on Bazaar Lane", "quest text: " .. qp.Content.Quest1.Text.Text)
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
qp.Content.Quest2.Claim.Activated:Fire()
qp.Content.Quest3.Claim.Activated:Fire()
M.advance(0.1)
check(pa.data.rollTokens == tokens + 1, "mutation quest gives a Kismat Roll")
qp.Content.Bonus.Claim.Activated:Fire()
M.advance(0.1)
check(pa.data.rollTokens == tokens + 1 + Config.QUEST_BONUS_ROLLS and pa.data.quests.bonusClaimed, "bonus rolls")
check(hud.Buttons.Quests.Text == "Quests", "nothing left to claim")
pa.data.quests.day = TODAY - 1
QuestBook.ensure(pa)
check(pa.data.quests.day == TODAY and not pa.data.quests.list[1].claimed, "new quests every day")
local offered = {}
local dupes = false
for _, q in pa.data.quests.list do
	dupes = dupes or offered[q.id] == true
	offered[q.id] = true
end
check(not dupes, "no duplicate quests")

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
local naan = entryOf(pa, "NaanNinja")
moveNear(A, naan.model)
trigger(naan.model, "SellPrompt", A)
before = pa.data.rupees
tokens = pa.data.rollTokens
qp.Content.Common.Claim.Activated:Fire()
M.advance(0.2)
check(pa.data.rupees == before + 4000 and pa.data.rollTokens == tokens + 1, "Common reward: Rs 4,000 and a roll")
local mamu = entryOf(pa, "MithaiMamu")
check(mamu ~= nil, "Mithai Mamu joins the haveli")
check(
	prompt(mamu.model, "StealPrompt") == nil and prompt(mamu.model, "SellPrompt") == nil,
	"quest brainrots cannot be stolen or sold"
)
check(qp.Content.Common.Claim.Text == "Done", "reward marked done")
qp.Content.Common.Claim.Activated:Fire()
Remotes.ClaimCollection:FireServer("Mythic")
Remotes.ClaimCollection:FireServer("Gems")
M.advance(0.1)
check(pa.data.rupees == before + 4000, "collection reward only once; incomplete or unknown rarities ignored")
M.advance(10)
check(mamu.arrived and mamu.plot == #pa.owned, "quest brainrots take the last plot, not a locker: " .. mamu.plot)

---------------------------------------------------------------------------
section("Kismat Roll")
---------------------------------------------------------------------------
local kp = hud.KismatPanel
local kc = kp.Content
check(kc.Common.Percent.Text == "50%" and kc.Mythic.OneIn.Text == "1 in 500", "rarity odds shown")
check(kc.Golden.Chance.Text == "8%  ·  1 in 13", "golden odds shown: " .. kc.Golden.Chance.Text)
check(kc.Rainbow.Chance.Text == "0.5%  ·  1 in 200", "rainbow odds shown: " .. kc.Rainbow.Chance.Text)
check(kc.RollRupees.Text == "Roll for Rs 5,000", "roll price: " .. kc.RollRupees.Text)
for _ = 1, 3 do
	local n = entryOf(pa, "NaanNinja")
	moveNear(A, n.model)
	trigger(n.model, "SellPrompt", A)
end
hud.Buttons.Kismat.Activated:Fire()
M.advance(0.1)
before = pa.data.rupees
local ownedBefore = #pa.owned
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
M.advance(3)
check(not hud.KismatReveal.Visible, "reveal hides")
pa.data.theme = "BasantRooftop" -- test only: normally unlocked by the 4th Naya Safar
A:SetAttribute("Theme", "BasantRooftop")
M.advance(0.1)
check(kc.MutationTitle.Text:find("x2") ~= nil, "theme mutation boost shown")
check(kc.Golden.Chance.Text == "16%  ·  1 in 6", "boosted golden odds shown: " .. kc.Golden.Chance.Text)
check(Kismat.mutationBoost(pa) == 2, "server uses the same boost")
pa.data.theme = "ChaiDhaba"
A:SetAttribute("Theme", "ChaiDhaba")
M.advance(0.1)
check(Kismat.cost(pa) == 4250 and kc.RollRupees.Text == "Roll for Rs 4,250 (sale!)", "Chai Dhaba discount")
pa.data.theme = "BaghGarden"
State.syncStats(pa)
local mc = {}
for _ = 1, 100000 do
	local m = Mutations.roll("roll") or "none"
	mc[m] = (mc[m] or 0) + 1
end
check(math.abs(mc.Golden / 1e5 - 0.08) < 0.005, "roll golden ~8%: " .. mc.Golden / 1e5)
check(math.abs(mc.Diamond / 1e5 - 0.02) < 0.003, "roll diamond ~2%")
check(math.abs(mc.Rainbow / 1e5 - 0.005) < 0.0015, "roll rainbow ~0.5%")
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

---------------------------------------------------------------------------
section("Stealing")
---------------------------------------------------------------------------
local B = addPlayer("Bilal", 2)
M.advance(0.5)
local pb = State.profiles[B]
local charB = spawnCharacter(B)
M.advance(0.3)
Havelis.clearBrainrots(pb)
check(charB.HumanoidRootPart.CollisionGroup == "ChaiOwner2", "Bilal in his own laser group")
local target = stealable(pa)
markLog()
moveNear(B, target.model)
trigger(target.model, "StealPrompt", B)
check(notified("Bilal", "protected"), "new players are protected")
M.advance(Config.NEW_PLAYER_PROTECTION + 1)
target = stealable(pa)
check(prompt(target.model, "StealPrompt"):GetAttribute("Active") == true, "steal prompt on after protection")
check(
	prompt(target.model, "SellPrompt").Enabled and not prompt(target.model, "StealPrompt").Enabled,
	"Ali sees Sell, not Steal"
)
local locker = entryOf(pa, "ChaiyooKettlesaurus")
markLog()
moveNear(B, locker.model)
trigger(locker.model, "StealPrompt", B)
check(locker.carrier == nil and notified("Bilal", "Locker"), "lockers cannot be robbed")
moveNear(B, mamu.model)
check(prompt(mamu.model, "StealPrompt") == nil, "quest brainrots have no steal prompt")
markLog()
local incomeBeforeTheft = Havelis.incomePerSecond(pa)
moveNear(B, target.model)
trigger(target.model, "StealPrompt", B)
check(target.carrier == B, "Bilal carries " .. target.def.id)
check(notified("Ali", "Chor! Chor!"), "alert")
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
check(not target.model.PrimaryPart.Anchored and target.model.PrimaryPart.Massless, "carried parts unanchored, massless")
check(Havelis.incomePerSecond(pa) < incomeBeforeTheft, "stolen brainrot stops earning")
pb.haveli.door.Touched:Fire(charB.HumanoidRootPart)
M.advance(0.1)
check(entryOf(pb, target.def.id) ~= nil, "Bilal got away with it")
check(charB.Humanoid.WalkSpeed == Config.WALK_SPEED, "speed back to normal")
check(target.model.PrimaryPart.Anchored and target.model:GetAttribute("Carried") == false, "detached")
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
check(h1.Decor.Chowkidar:FindFirstChild("Label", true).Text == "Zzz...", "Chowkidar naps after a catch")
M.advance(Config.GUARD_COOLDOWN + 1)
check(h1.Decor.Chowkidar:FindFirstChild("Label", true).Text == "Jaagte Raho!", "and wakes up again")

charB:PivotTo(pa.haveli.origin * CFrame.new(10, 3, 0))
check(Havelis.isInside(pa.haveli, charB.HumanoidRootPart.Position), "Bilal is inside Ali's haveli")
markLog()
hud.Buttons.Taala.Activated:Fire()
M.advance(0.3)
check(h1.Barrier.CanCollide == true, "laser blocks the door")
check(not Havelis.isInside(pa.haveli, charB.HumanoidRootPart.Position), "Bilal moved out instead of trapped")
check(notified("Ali", "Laser Darwaza is on"), "laser message")
check(hud.Buttons.Taala.Text:find("Locked") ~= nil, "lock countdown")
target = stealable(pa)
markLog()
moveNear(B, target.model)
trigger(target.model, "StealPrompt", B)
check(target.carrier == nil and notified("Bilal", "taala"), "locked haveli cannot be robbed")
M.advance(Config.LOCK_TIME + 1)
check(h1.Barrier.CanCollide == false, "laser off after the Taala")

---------------------------------------------------------------------------
section("Bonk and dying thief")
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
check(charB.Humanoid.WalkSpeed == Config.WALK_SPEED, "speed restored after a bonk")
M.advance(10)
check(target.arrived, "walked home")
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
section("Selling")
---------------------------------------------------------------------------
if not Havelis.hasFreePlot(pa) then
	local n = entryOf(pa, "NaanNinja") or entryOf(pa, "SamosaSupremo")
	moveNear(A, n.model)
	trigger(n.model, "SellPrompt", A)
end
local diamond = buy(A, "PyaazPehelwan", "Diamond")
M.advance(10)
before = pa.data.rupees
moveNear(A, diamond)
trigger(diamond, "SellPrompt", A)
check(pa.data.rupees == before + 225, "Diamond Pyaaz sells for half its Rs 450 value")

---------------------------------------------------------------------------
section("Naya Safar")
---------------------------------------------------------------------------
pa.data.rupees = Config.rebirthCost(0)
pa.data.rollTokens = 3
State.syncStats(pa)
M.advance(0.5)
local rb = hud.Buttons.NayaSafar
check(rb.Visible, "rebirth button at Rs 1,000,000")
markLog()
rb.Activated:Fire()
M.advance(0.1)
check(pa.data.rebirths == 0 and rb.Text:find("Sure") ~= nil, "rebirth asks to confirm")
rb.Activated:Fire()
M.advance(0.5)
check(pa.data.rebirths == 1 and pa.data.level == 1 and pa.data.rupees == Config.START_RUPEES, "rebirth resets")
check(#pa.owned == 0 and pa.data.rollTokens == 3, "brainrots reset, rolls kept")
check(pa.data.theme == "BaghGarden", "theme kept")
check(notified("Ali", "New haveli theme unlocked: Truck Art"), "new theme unlocked")
check(A:GetAttribute("RebirthCost") == 2_500_000, "next Naya Safar costs more")
check(h1.StairGates.StairGate.CanCollide and h1.Decor:FindFirstChild("Chowkidar") == nil, "haveli back to level 1")
haveliPanel.Content.TruckArt.Use.Activated:Fire()
M.advance(0.1)
check(
	pa.data.theme == "TruckArt" and math.abs(charA.Humanoid.WalkSpeed - Config.WALK_SPEED * 1.12) < 1e-6,
	"Truck Art makes you faster"
)
before = pa.data.rupees
qp.Content.Common.Claim.Activated:Fire()
M.advance(0.1)
check(entryOf(pa, "MithaiMamu") ~= nil and pa.data.rupees == before, "quest brainrot again, rupees only once")

---------------------------------------------------------------------------
section("Events")
---------------------------------------------------------------------------
markLog()
EventRunner.start("Baarish")
M.advance(1)
check(workspace:GetAttribute("EventId") == "Baarish" and notified("Ali", "Baarish"), "event running")
check(hud.EventBanner.Title.Text == "Baarish!", "banner shows the event")
local effects = workspace.CurrentCamera:FindFirstChild("ChaiChaosEventEffects")
check(effects and effects:FindFirstChild("Weather"), "rain on screen")
check(
	math.abs(Havelis.incomeMultiplier(pa) - 1.5 * 1.2) < 1e-6,
	"Baarish +20% income: " .. Havelis.incomeMultiplier(pa)
)
local sawPanda = false
for _ = 1, 3000 do
	sawPanda = sawPanda or Spawner.pick().id == "PakoraPanda"
end
check(sawPanda, "Pakora Panda comes out in the rain")
EventRunner.stop()
M.advance(1)
check(effects:FindFirstChild("Weather") == nil and hud.EventBanner.Title.Text == "Next event", "rain stops")
local noPanda = true
for _ = 1, 5000 do
	noPanda = noPanda and Spawner.pick().id ~= "PakoraPanda"
end
check(noPanda, "no Pakora Panda without rain")
EventRunner.start("LoadShedding")
M.advance(1)
check(M.services.Lighting.ClockTime == 0 and Spawner.isNight(), "Load Shedding makes it night")
local sawCheetah = false
for _ = 1, 200000 do
	if Spawner.pick().id == "ChandRaatCheetah" then
		sawCheetah = true
		break
	end
end
check(sawCheetah, "night brainrots come out")
EventRunner.stop()
M.advance(1)
check(M.services.Lighting.ClockTime ~= 0, "the light comes back")
EventRunner.start("MelaNight")
M.advance(0.5)
check(Kismat.cost(pa) == 3500, "Mela Night roll discount: " .. Kismat.cost(pa))
check(effects:FindFirstChild("Burst") ~= nil, "mela fireworks")
EventRunner.stop()
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
M.failLoadsFor["player_5"] = nil
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
pe.data.rupees = 1000
State.syncStats(pe)
buy(E, "ChanaChaatChacha")
buy(E, "SamosaSupremo")
buy(E, "GolGappaGhostu")
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

---------------------------------------------------------------------------
section("Save and rejoin")
---------------------------------------------------------------------------
buy(A, "PyaazPehelwan", "Diamond")
M.advance(8)
removePlayer(A)
local savedA = M.store["player_1"]
check(savedA.version == 2 and savedA.level == 1 and savedA.theme == "TruckArt" and savedA.rebirths == 1, "v2 save")
check(table.find(savedA.owned, "PyaazPehelwan:Diamond") ~= nil, "mutations saved")
check(table.find(savedA.owned, "MithaiMamu") ~= nil, "quest brainrots saved")
check(savedA.collection.Common.rewarded and savedA.collection.Common.specialRebirth == 1, "collection claims saved")
local A2 = addPlayer("Ali", 1)
M.advance(0.5)
local pa2 = State.profiles[A2]
local pyaaz = entryOf(pa2, "PyaazPehelwan")
check(pyaaz and pyaaz.mutation == "Diamond" and pyaaz.arrived, "Diamond Pyaaz back on its plot")
check(pa2.haveli.walls[1].Color == Themes.byId.TruckArt.wall, "theme restored")
check(not notified("Ali", "Daily chai"), "daily chai only once a day")
M.store["player_9"] = {
	rupees = 5000,
	plots = 7,
	owned = { "SamosaSupremo", "NotABrainrot" },
	discovered = { SamosaSupremo = true },
	lastDaily = TODAY,
}
local P = addPlayer("Purana", 9)
M.advance(0.5)
local pp = State.profiles[P]
check(pp.data.level == 2 and #pp.owned == 1 and pp.data.rupees >= 5000, "old saves move to haveli levels")
removePlayer(P)

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

---------------------------------------------------------------------------
section("Spawn odds")
---------------------------------------------------------------------------
M.rawset(M.services.Lighting, "ClockTime", 12)
local counts, ids = {}, {}
for _ = 1, 50000 do
	local d = Spawner.pick()
	counts[d.rarity] = (counts[d.rarity] or 0) + 1
	ids[d.id] = true
end
check(not ids.ChandRaatCheetah and not ids.PakoraPanda and not ids.MithaiMamu, "no night, event or quest brainrots")
check(math.abs(counts.Common / 50000 - 0.6) < 0.02, "lane common ~60%: " .. counts.Common / 50000)
check(math.abs(counts.Uncommon / 50000 - 0.25) < 0.02, "lane uncommon ~25%")
local lm = {}
for _ = 1, 100000 do
	local m = Mutations.roll("lane") or "none"
	lm[m] = (lm[m] or 0) + 1
end
check(math.abs(lm.Golden / 1e5 - 0.04) < 0.004, "lane golden ~4%: " .. lm.Golden / 1e5)

---------------------------------------------------------------------------
section("Ammi ki Udti Chappal")
---------------------------------------------------------------------------
local plain = Spawner.spawn(Brainrots.byId.NaanNinja)
M.advance(1)
markLog()
local chappalModel = Spawner.spawn(Brainrots.byId.AmmiKiUdtiChappal)
M.advance(0.2)
check(plain:GetAttribute("MoveSpeed") == 0, "frozen brainrots stop on screen too")
local px, cx = plain:GetPivot().X, chappalModel:GetPivot().X
M.advance(2)
check(math.abs(plain:GetPivot().X - px) < 0.01 and chappalModel:GetPivot().X > cx, "frozen while the chappal flies")
check(notified("Dua", "WHOOSH"), "chappal announcement")
M.advance(4)
check(plain:GetPivot().X > px + 1 and plain:GetAttribute("MoveSpeed") > 0, "walking again after the freeze")

---------------------------------------------------------------------------
section("Leaderboard")
---------------------------------------------------------------------------
M.advance(6)
local row1 = map.Leaderboard:FindFirstChild("Row1", true)
check(row1.Text:find("Ali") ~= nil and row1.Text:find("Safar 1") ~= nil, "leaderboard: " .. row1.Text)

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
local expectedCF = Motion.at(CFrame.new(0, 5, 0), CFrame.new(100, 5, 0), startedAt, 10, workspace:GetServerTimeNow())
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

---------------------------------------------------------------------------
section("Shutdown")
---------------------------------------------------------------------------
local co = coroutine.create(M.bindToClose)
coroutine.resume(co)
M.advance(1)
check(coroutine.status(co) == "dead", "BindToClose finished")
check(M.store["player_1"] and M.store["player_1"].rebirths == 1, "Ali saved on shutdown")

---------------------------------------------------------------------------
print(("\n%d checks passed, %d failed, %d script errors, %d warnings"):format(passed, failed, #M.errors, #M.warnings))
for _, warning in M.warnings do
	print("warning: " .. warning)
end
if failed > 0 or #M.errors > 0 then
	error("TESTS FAILED")
end
