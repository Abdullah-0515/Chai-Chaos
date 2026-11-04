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

local function runScripts(folder, context)
	for _, inst in folder:GetChildren() do
		if inst.ClassName == "Script" or inst.ClassName == "LocalScript" then
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
runScripts(server, "server")
M.advance(0.2)

local map = workspace:FindFirstChild("ChaiChaosMap")
check(map ~= nil, "map is built")
check(#map.Havelis:GetChildren() == 8, "8 havelis")
local State = serverModule("State")
local Havelis = serverModule("Havelis")
local Spawner = serverModule("Spawner")
local Mover = serverModule("Mover")
local Brainrots = sharedModule("Brainrots")
local Config = sharedModule("Config")
local Format = sharedModule("Format")
check(#Brainrots.list == 36, "36 brainrots, got " .. #Brainrots.list)
check(Format.rupees(1234567) == "Rs 1,234,567", "format commas: " .. Format.rupees(1234567))
check(Format.rupees(25) == "Rs 25", "format small")
check(Format.short(12500) == "12.5K" and Format.short(2000000) == "2M", "format short")

---------------------------------------------------------------------------
section("Ali joins")
---------------------------------------------------------------------------
markLog()
local A = addPlayer("Ali", 1)
M.advance(0.5)
local pa = State.profiles[A]
check(pa ~= nil, "Ali has a profile")
check(pa.haveli and pa.haveli.index == 1, "Ali got haveli 1")
check(pa.haveli.signLabel.Text == "Ali ki Haveli", "sign: " .. tostring(pa.haveli.signLabel.Text))
check(pa.canSave, "Ali can save")
check(notified("Ali", "Daily chai"), "daily chai given")
local charA = spawnCharacter(A)
M.advance(0.3)
check((charA:GetPivot().Position - pa.haveli.spawn.Position).Magnitude < 0.01, "Ali teleported into haveli")
check(A.Backpack:FindFirstChild("Chappal") ~= nil, "Ali has a chappal")
check(A.leaderstats.Rupees.Value == pa.data.rupees, "leaderstats synced")

-- Client scripts for Ali
M.localPlayer = A
M.rawset(Players, "LocalPlayer", A)
runScripts(client, "client")
M.advance(0.5)
local hud = A.PlayerGui:FindFirstChild("ChaiChaosHud")
check(hud ~= nil, "HUD created")

---------------------------------------------------------------------------
section("Bazaar Lane")
---------------------------------------------------------------------------
M.advance(30)
local lane = map.LaneBrainrots
local walkers = lane:GetChildren()
check(#walkers >= 4, "walkers on the lane: " .. #walkers)
local w = walkers[#walkers]
local x0 = w:GetPivot().X
M.advance(1)
check(w.Parent ~= nil and w:GetPivot().X > x0, "walkers move down the lane")
check(prompt(w, "BuyPrompt") ~= nil, "walker has a buy prompt")
M.advance(30)
check(w.Parent == nil, "unbought walker vanished at the Chowk")

---------------------------------------------------------------------------
section("Buying")
---------------------------------------------------------------------------
-- clear whatever the daily chai gave so plot maths below is predictable
Havelis.clearBrainrots(pa)
Havelis.arrange(pa)
pa.data.rupees = 50000
State.syncStats(pa)

local function buy(player, id)
	local model = Spawner.spawn(Brainrots.byId[id])
	M.advance(0.1)
	moveNear(player, model)
	trigger(model, "BuyPrompt", player)
	return model
end

markLog()
local before = pa.data.rupees
local samosa = buy(A, "SamosaSupremo")
check(pa.data.rupees == before - 50, "paid Rs 50 for samosa")
check(samosa.Parent == pa.haveli.brainrotFolder, "samosa moved into Ali's haveli folder")
check(prompt(samosa, "BuyPrompt") == nil, "buy prompt removed")
check(notified("Ali", "You bought Samosa Supremo"), "buy message")
check(notified("Ali", "Collection Book"), "collection message")
buy(A, "ChaiyooKettlesaurus")
buy(A, "ChanaChaatChacha")
M.advance(10)
check(#pa.owned == 3, "3 brainrots owned")
check(plotOf(pa, "ChaiyooKettlesaurus") == 1, "most expensive in plot 1 (locker)")
check(plotOf(pa, "SamosaSupremo") == 2, "second in plot 2 (locker)")
check(plotOf(pa, "ChanaChaatChacha") == 3, "cheapest in plot 3")
for _, e in pa.owned do
	check(e.arrived, e.def.id .. " arrived")
	local plot = pa.haveli.plots[e.plot]
	local d = e.model:GetPivot().Position - plot.Position
	check(math.abs(d.X) < 0.01 and math.abs(d.Z) < 0.01, e.def.id .. " stands on its plot")
end

markLog()
local extra = buy(A, "GolGappaGhostu")
check(notified("Ali", "No empty plot"), "no empty plot message")
check(extra.Parent == lane, "brainrot stays on the lane when you cannot buy it")

-- unlock plot 4
markLog()
local plot4 = pa.haveli.plots[4]
check(plot4.UnlockPrompt:GetAttribute("Active") == true, "plot 4 unlock prompt active")
check(pa.haveli.plots[5].UnlockPrompt:GetAttribute("Active") == false, "plot 5 not yet")
charA:PivotTo(CFrame.new(plot4.Position + Vector3.new(0, 3, 0)))
before = pa.data.rupees
PPS.PromptTriggered:Fire(plot4.UnlockPrompt, A)
M.advance(0.1)
check(pa.data.plots == 4 and pa.data.rupees == before - 500, "plot 4 unlocked for Rs 500")
check(pa.haveli.plotLabels[5].Text == "Rs 2,000", "plot 5 shows its price: " .. pa.haveli.plotLabels[5].Text)
buy(A, "RickshawRaptor")
M.advance(10)
check(plotOf(pa, "RickshawRaptor") == 1, "raptor takes the top locker")
check(plotOf(pa, "ChaiyooKettlesaurus") == 2, "kettlesaurus shuffles to plot 2")
check(plotOf(pa, "SamosaSupremo") == 3 and plotOf(pa, "ChanaChaatChacha") == 4, "others shuffle down")

---------------------------------------------------------------------------
section("Income and galla")
---------------------------------------------------------------------------
pa.data.galla = 0
local income = Havelis.incomePerSecond(pa)
check(income == 18 + 4 + 2 + 2, "income per second " .. income)
M.advance(5)
check(math.abs(pa.data.galla - income * 5) <= income, "galla filled: " .. pa.data.galla)
check(A:GetAttribute("Income") == income, "income attribute")
markLog()
before = pa.data.rupees
local galla = math.floor(pa.data.galla)
pa.haveli.galla.Touched:Fire(charA.HumanoidRootPart)
M.advance(0.1)
check(pa.data.rupees == before + galla, "collected galla")
check(pa.data.galla < 1, "galla emptied")
check(notified("Ali", "from your galla"), "galla message")

---------------------------------------------------------------------------
section("Stealing")
---------------------------------------------------------------------------
local B = addPlayer("Bilal", 2)
M.advance(0.5)
local pb = State.profiles[B]
check(pb.haveli and pb.haveli.index == 2, "Bilal got haveli 2")
local charB = spawnCharacter(B)
M.advance(0.3)
Havelis.clearBrainrots(pb)
Havelis.arrange(pb)

local samosaEntry = entryOf(pa, "SamosaSupremo")
markLog()
moveNear(B, samosaEntry.model)
trigger(samosaEntry.model, "StealPrompt", B)
check(notified("Bilal", "protected"), "new players are protected")
check(prompt(samosaEntry.model, "StealPrompt"):GetAttribute("Active") == false, "steal prompt off while protected")
M.advance(Config.NEW_PLAYER_PROTECTION + 1)
check(prompt(samosaEntry.model, "StealPrompt"):GetAttribute("Active") == true, "steal prompt on after protection")
local raptor = entryOf(pa, "RickshawRaptor")
check(prompt(raptor.model, "StealPrompt"):GetAttribute("Active") == false, "locker brainrot cannot be stolen")

-- client side prompt visibility for Ali (the local player)
check(prompt(samosaEntry.model, "SellPrompt").Enabled == true, "Ali sees Sell on own brainrot")
check(prompt(samosaEntry.model, "StealPrompt").Enabled == false, "Ali does not see Steal on own brainrot")

markLog()
moveNear(B, raptor.model)
trigger(raptor.model, "StealPrompt", B)
check(raptor.carrier == nil and notified("Bilal", "Locker"), "server refuses locker steals")

markLog()
moveNear(B, samosaEntry.model)
local incomeBefore = Havelis.incomePerSecond(pa)
trigger(samosaEntry.model, "StealPrompt", B)
check(samosaEntry.carrier == B, "Bilal is carrying the samosa")
check(notified("Ali", "Chor! Chor! Bilal stole your Samosa Supremo"), "Chor! Chor! alert")
check(Havelis.incomePerSecond(pa) == incomeBefore - 2, "stolen brainrot stops earning")
check(charB:FindFirstChild("ChorMarker") ~= nil, "thief is highlighted")
charB:PivotTo(CFrame.new(40, 5, 0))
M.advance(0.5)
local carryGap = (samosaEntry.model:GetPivot().Position - charB:GetPivot().Position).Magnitude
check(
	carryGap < 5,
	"brainrot rides on the thief, gap "
		.. carryGap
		.. " model "
		.. tostring(samosaEntry.model:GetPivot().Position)
		.. " thief "
		.. tostring(charB:GetPivot().Position)
)
local phrase = samosaEntry.model.PrimaryPart.Popup.PhraseLabel.Text
check(phrase:find("AAAA") ~= nil, "brainrot panics: " .. phrase)

markLog()
pa.haveli.door.Touched:Fire(charB.HumanoidRootPart) -- the victim's door does nothing
M.advance(0.1)
check(samosaEntry.carrier == B, "touching someone else's door does not count")
pb.haveli.door.Touched:Fire(charB.HumanoidRootPart)
M.advance(0.1)
check(entryOf(pb, "SamosaSupremo") ~= nil, "samosa now belongs to Bilal")
check(entryOf(pa, "SamosaSupremo") == nil, "samosa gone from Ali")
check(State.entries[samosa].owner == pb, "entry owner updated")
check(notified("Bilal", "got away"), "thief success message")
check(charB:FindFirstChild("ChorMarker") == nil, "marker removed")
M.advance(8)
check(entryOf(pb, "SamosaSupremo").arrived, "samosa walked to Bilal's plot")
check(samosa:GetAttribute("OwnerId") == 2, "owner attribute updated")
check(
	prompt(samosa, "StealPrompt").Enabled == true or prompt(samosa, "StealPrompt"):GetAttribute("Active") == false,
	"steal prompt state sane"
)
check(prompt(samosa, "SellPrompt").Enabled == false, "Ali does not see Sell on Bilal's brainrot")
check(plotOf(pa, "ChanaChaatChacha") == 3, "Ali's brainrots re-sorted after the theft")

-- cooldowns
markLog()
local chana = entryOf(pa, "ChanaChaatChacha")
moveNear(B, chana.model)
trigger(chana.model, "StealPrompt", B)
check(notified("Bilal", "Catch your breath"), "15 second steal cooldown")
M.advance(Config.STEAL_COOLDOWN + 1)
markLog()
moveNear(B, chana.model)
trigger(chana.model, "StealPrompt", B)
check(notified("Bilal", "different one"), "same haveli cooldown")
M.advance(Config.SAME_HAVELI_COOLDOWN + 1)

-- price cap
Config.STEAL_PRICE_CAP = 30
markLog()
moveNear(B, chana.model)
trigger(chana.model, "StealPrompt", B)
check(notified("Bilal", "Naya Safar"), "price cap before rebirth")
Config.STEAL_PRICE_CAP = 8000

-- steal, then get bonked by Ali's chappal
markLog()
moveNear(B, chana.model)
trigger(chana.model, "StealPrompt", B)
check(chana.carrier == B, "Bilal carries the chana")
charB:PivotTo(CFrame.new(10, 5, 0))
charA:PivotTo(CFrame.new(13, 5, 0))
local chappal = A.Backpack:FindFirstChild("Chappal")
chappal.Activated:Fire()
M.advance(0.1)
check(chana.carrier == nil, "bonk makes the thief drop it")
check(notified("Ali", "Bonk!"), "bonk message")
check(notified("Bilal", "bonked you"), "thief told about bonk")
M.advance(10)
check(chana.arrived and entryOf(pa, "ChanaChaatChacha") == chana, "chana walked back home")
local plot = pa.haveli.plots[chana.plot]
local backGap = (chana.model:GetPivot().Position - plot.Position) * Vector3.new(1, 0, 1)
check(backGap.Magnitude < 0.01, "chana is back on a plot")

---------------------------------------------------------------------------
section("Taala lock and dying thief")
---------------------------------------------------------------------------
M.failLoadsFor["player_3"] = true
markLog()
local C = addPlayer("Chand", 3)
M.advance(0.5)
local pc = State.profiles[C]
check(not pc.canSave and notified("Chand", "Saving is off"), "failed load turns saving off")
local charC = spawnCharacter(C)
M.advance(0.3)
Havelis.clearBrainrots(pc)
Havelis.arrange(pc)

markLog()
hud.Buttons.Taala.Activated:Fire()
M.advance(0.3)
check(pa.lockedUntil > workspace:GetServerTimeNow(), "Ali's haveli is locked")
check(notified("Ali", "Taala laga diya"), "lock message")
check(pa.haveli.barrier.Transparency < 1, "lock barrier visible")
check(hud.Buttons.Taala.Text:find("Locked") ~= nil, "lock button shows countdown: " .. hud.Buttons.Taala.Text)
check(pa.haveli.signLabel.Text:find("LOCKED") ~= nil, "sign shows lock")
check(prompt(chana.model, "StealPrompt"):GetAttribute("Active") == false, "steal prompts off while locked")
markLog()
moveNear(C, chana.model)
trigger(chana.model, "StealPrompt", C)
check(notified("Chand", "taala"), "locked haveli cannot be robbed")
hud.Buttons.Taala.Activated:Fire()
M.advance(0.2)
check(notified("Ali", "not ready"), "cannot lock again right away")
M.advance(Config.LOCK_TIME + 1)
check(pa.haveli.barrier.Transparency == 1, "lock expires")
check(hud.Buttons.Taala.Text:find("Taala in") ~= nil, "lock cooldown shown: " .. hud.Buttons.Taala.Text)
markLog()
moveNear(C, chana.model)
trigger(chana.model, "StealPrompt", C)
check(chana.carrier == C, "Chand steals after the lock")
local humC = charC:FindFirstChildOfClass("Humanoid")
humC.Health = 0
humC.Died:Fire()
M.advance(0.1)
check(chana.carrier == nil, "thief died, brainrot goes back")
M.advance(10)
check(chana.arrived, "chana home again")

---------------------------------------------------------------------------
section("Owner leaves while being robbed")
---------------------------------------------------------------------------
pb.data.rupees = 1000
State.syncStats(pb)
buy(B, "ChanaChaatChacha")
buy(B, "GolGappaGhostu")
M.advance(10)
local ghostu = entryOf(pb, "GolGappaGhostu")
check(ghostu and ghostu.plot == 3, "ghostu in Bilal's plot 3")
charC = spawnCharacter(C)
M.advance(0.3)
M.advance(Config.STEAL_COOLDOWN + 1)
markLog()
moveNear(C, ghostu.model)
trigger(ghostu.model, "StealPrompt", C)
check(ghostu.carrier == C, "Chand carries Bilal's ghostu")
removePlayer(B)
check(State.profiles[B] == nil, "Bilal's profile removed")
check(notified("Chand", "ran away"), "thief told the brainrot ran away")
local saved = M.store["player_2"]
check(saved ~= nil, "Bilal saved on leave")
check(saved and table.find(saved.owned, "GolGappaGhostu") ~= nil, "stolen-in-progress brainrot stays with its owner")
check(saved and table.find(saved.owned, "SamosaSupremo") ~= nil, "stolen samosa saved for Bilal")
check(pb.haveli == nil and map.Havelis.Haveli2.Sign.Gui.Label.Text == "Khaali Haveli", "haveli freed")
local ghostCount = 0
for _, x in map.Havelis.Haveli2.Brainrots:GetChildren() do
	ghostCount += 1
end
check(ghostCount == 0, "Bilal's brainrots removed from the map")

---------------------------------------------------------------------------
section("Selling")
---------------------------------------------------------------------------
markLog()
local kettle = entryOf(pa, "ChaiyooKettlesaurus")
moveNear(A, kettle.model)
before = pa.data.rupees
trigger(kettle.model, "SellPrompt", A)
check(pa.data.rupees == before + 50 and entryOf(pa, "ChaiyooKettlesaurus") == nil, "sold for half price")
check(kettle.model.Parent == nil, "sold model destroyed")

---------------------------------------------------------------------------
section("Naya Safar (rebirth)")
---------------------------------------------------------------------------
pa.data.rupees = Config.REBIRTH_COST
State.syncStats(pa)
M.advance(0.5)
local rebirthButton = hud.Buttons.NayaSafar
check(rebirthButton.Visible, "rebirth button appears at Rs 1,000,000")
markLog()
rebirthButton.Activated:Fire()
M.advance(0.1)
check(pa.data.rebirths == 0 and rebirthButton.Text:find("Sure") ~= nil, "rebirth asks to confirm")
rebirthButton.Activated:Fire()
M.advance(0.5)
check(pa.data.rebirths == 1, "rebirthed")
check(pa.data.rupees == Config.START_RUPEES and pa.data.plots == Config.START_PLOTS, "rupees and plots reset")
check(#pa.owned == 0, "brainrots reset")
check(map.Havelis.Haveli1.Walls:GetChildren()[1].Color == Config.HAVELI_COLORS[2], "haveli got a new colour")
check(A.leaderstats.Rebirths.Value == 1, "rebirth leaderstat")
buy(A, "SamosaSupremo")
M.advance(5)
check(Havelis.incomePerSecond(pa) == 2 * 1.5, "rebirth multiplier applies: " .. Havelis.incomePerSecond(pa))

---------------------------------------------------------------------------
section("HUD")
---------------------------------------------------------------------------
M.advance(1.5)
check(hud.Money:FindFirstChildWhichIsA("TextLabel").Text == Format.rupees(pa.data.rupees), "HUD shows rupees")
local discovered = 0
for _ in pa.data.discovered do
	discovered += 1
end
check(
	hud.CollectionBook:FindFirstChildWhichIsA("TextLabel").Text == ("Collection Book  %d/36"):format(discovered),
	"collection count"
)
hud.Buttons.Collection.Activated:Fire()
M.advance(0.1)
check(hud.CollectionBook.Visible, "collection book opens")
local toastCount = #hud.Toasts:GetChildren()
check(toastCount >= 2, "toasts are showing: " .. toastCount)

---------------------------------------------------------------------------
section("Save and rejoin")
---------------------------------------------------------------------------
removePlayer(A)
local savedA = M.store["player_1"]
check(savedA and savedA.rebirths == 1 and savedA.owned[1] == "SamosaSupremo", "Ali saved")
M.localPlayer = nil
local A2 = addPlayer("Ali", 1)
M.advance(0.5)
local pa2 = State.profiles[A2]
check(pa2 and #pa2.owned == 1 and pa2.owned[1].arrived and pa2.owned[1].plot == 1, "saved brainrot back on plot 1")
check(pa2.data.rebirths == 1, "rebirth kept")
check(not notified("Ali", "Daily chai"), "daily chai only once a day")

---------------------------------------------------------------------------
section("Spawn odds and the night")
---------------------------------------------------------------------------
local Lighting = M.services.Lighting
local function sample(n)
	local counts, ids = {}, {}
	for _ = 1, n do
		local def = Spawner.pick()
		counts[def.rarity] = (counts[def.rarity] or 0) + 1
		ids[def.id] = true
	end
	return counts, ids
end
M.rawset(Lighting, "ClockTime", 12)
local counts, ids = sample(50000)
check(not ids.ChandRaatCheetah, "no cheetah in the day")
check(math.abs(counts.Common / 50000 - 0.6) < 0.02, "common ~60%: " .. counts.Common / 50000)
check(math.abs(counts.Uncommon / 50000 - 0.25) < 0.02, "uncommon ~25%")
check(math.abs((counts.Mythic or 0) / 50000 - 0.001) < 0.001, "mythic ~0.1%: " .. tostring(counts.Mythic))
M.rawset(Lighting, "ClockTime", 21)
counts, ids = sample(200000)
check(ids.ChandRaatCheetah == true, "cheetah at night")

---------------------------------------------------------------------------
section("Ammi ki Udti Chappal freezes everyone")
---------------------------------------------------------------------------
M.rawset(Lighting, "ClockTime", 12)
local plain = Spawner.spawn(Brainrots.byId.NaanNinja)
M.advance(1)
markLog()
local chappalModel = Spawner.spawn(Brainrots.byId.AmmiKiUdtiChappal)
local px, cx = plain:GetPivot().X, chappalModel:GetPivot().X
M.advance(2)
check(math.abs(plain:GetPivot().X - px) < 0.01, "other brainrots freeze")
check(chappalModel:GetPivot().X > cx, "the chappal keeps flying")
check(notified("Chand", "WHOOSH"), "chappal announcement")
M.advance(4)
check(plain:GetPivot().X > px + 1, "others move again after the freeze")

---------------------------------------------------------------------------
section("Shutdown")
---------------------------------------------------------------------------
M.store["player_3"] = nil
local co = coroutine.create(M.bindToClose)
coroutine.resume(co)
M.advance(1)
check(coroutine.status(co) == "dead", "BindToClose finished")
check(M.store["player_3"] == nil, "player whose load failed is never saved")
check(M.store["player_1"].owned[1] == "SamosaSupremo", "Ali saved on shutdown")

---------------------------------------------------------------------------
print(("\n%d checks passed, %d failed, %d script errors, %d warnings"):format(passed, failed, #M.errors, #M.warnings))
for _, w in M.warnings do
	print("warning: " .. w)
end
if failed > 0 or #M.errors > 0 then
	error("TESTS FAILED")
end
