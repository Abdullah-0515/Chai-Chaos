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
pa.data.rollTokens, pa.data.rollPity = 3, 7
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
check(pa.data.rollTokens == 3 and pa.data.rollPity == 7, "rebirth keeps Kismat Rolls and pity")
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
section("Kismat Roll (RNG)")
---------------------------------------------------------------------------
local Remotes = sharedModule("Remotes")
local Kismat = serverModule("Kismat")
local MPS = M.services.MarketplaceService
local Granted = M.Enum.ProductPurchaseDecision.PurchaseGranted
local NotYet = M.Enum.ProductPurchaseDecision.NotProcessedYet
local EPIC_PLUS = { Epic = true, Legendary = true, Mythic = true }

-- Developer Product ids, as the game owner would paste them into Config
local clientConfig = requireModule(shared:FindFirstChild("Config"), "client2")
for _, cfg in { Config, clientConfig } do
	cfg.ROLL_PRODUCTS[1].id, cfg.ROLL_PRODUCTS[2].id = 1001, 1010
	cfg.STEAL_PRODUCTS[1].id, cfg.STEAL_PRODUCTS[2].id = 2001, 2005
end
M.prices[1010] = 199

markLog()
local D = addPlayer("Dua", 4)
M.advance(0.5)
local pd = State.profiles[D]
check(pd.data.rollTokens == Config.DAILY_FREE_ROLLS, "daily chai gives a free Kismat Roll")
check(notified("Dua", "free Kismat Roll"), "daily chai mentions the free roll")
check(D:GetAttribute("PaidRollsAllowed") == true, "policy allows paid rolls")
local charD = spawnCharacter(D)
M.advance(0.3)
Havelis.clearBrainrots(pd)
Havelis.arrange(pd)

M.localPlayer = D
M.rawset(Players, "LocalPlayer", D)
runScripts(client, "client2")
M.advance(0.5)
local hudD = D.PlayerGui:FindFirstChild("ChaiChaosHud")
local kp = hudD.KismatPanel
local kc = kp.Content
check(kc.Common.Percent.Text == "50%" and kc.Common.OneIn.Text == "1 in 2", "common odds shown")
check(
	kc.Mythic.Percent.Text == "0.2%" and kc.Mythic.OneIn.Text == "1 in 500",
	"mythic odds shown: " .. kc.Mythic.Percent.Text .. " " .. kc.Mythic.OneIn.Text
)
check(kc.Legendary.Percent.Text == "1.8%" and kc.Legendary.OneIn.Text == "1 in 56", "legendary odds shown")
check(kc.BuyRolls1.Visible and kc.BuyRolls1.Text:find("R%$ 25") ~= nil, "1-roll pack priced: " .. kc.BuyRolls1.Text)
check(
	kc.BuyRolls2.Text:find("10 Kismat Rolls") and kc.BuyRolls2.Text:find("R%$ 199"),
	"10-roll pack priced: " .. kc.BuyRolls2.Text
)
check(kc.Pity.Text == "Epic or better guaranteed within 30 rolls", "pity shown: " .. kc.Pity.Text)

hudD.Buttons.Kismat.Activated:Fire()
M.advance(0.1)
check(kp.Visible, "Kismat panel opens")
check(kc.RollToken.Visible and hudD.Buttons.Kismat.Text == "Kismat Roll (1)", "free roll button shows")
local rupeesBefore = pd.data.rupees
kc.RollToken.Activated:Fire()
M.advance(0.1)
check(pd.data.rollTokens == 0 and #pd.owned == 1, "roll with a token gives a brainrot")
check(pd.data.rupees == rupeesBefore, "token roll costs no rupees")
check(hudD.KismatReveal.Visible, "reveal pops up")
M.advance(2)
local rolled = pd.owned[1]
check(hudD.KismatReveal.BrainrotName.Text == rolled.def.name, "reveal lands on the rolled brainrot")
check(not kc.RollToken.Visible, "free roll button hides when used up")
M.advance(3)
check(not hudD.KismatReveal.Visible, "reveal hides again")
M.advance(8)
check(rolled.arrived, "rolled brainrot walked onto a plot")

pd.data.rupees = 100
State.syncStats(pd)
markLog()
kc.RollRupees.Activated:Fire()
M.advance(0.1)
check(notified("Dua", "costs Rs 2,500") and #pd.owned == 1, "rupee roll needs Rs 2,500")
M.advance(3)
pd.data.rupees = 10000
State.syncStats(pd)
kc.RollRupees.Activated:Fire()
M.advance(0.1)
check(pd.data.rupees == 7500 and #pd.owned == 2, "rupee roll costs Rs 2,500")
Remotes.Roll:FireServer("rupees") -- skipping the client's own cooldown
M.advance(0.1)
check(#pd.owned == 2 and pd.data.rupees == 7500, "server enforces the roll cooldown")
M.advance(3)
Remotes.Roll:FireServer("rupees")
M.advance(3)
check(#pd.owned == 3, "third roll fills the last plot")
markLog()
Remotes.Roll:FireServer("rupees")
M.advance(0.1)
check(notified("Dua", "No empty plot") and pd.data.rupees == 5000, "no roll (and no charge) without an empty plot")
Remotes.Roll:FireServer("free-mythic")
M.advance(3)
check(#pd.owned == 3 and pd.data.rupees == 5000, "unknown roll method ignored")

-- pity: the 30th roll without an Epic is always Epic or better
local pityOk = true
for _ = 1, 8 do
	Havelis.clearBrainrots(pd)
	pd.data.rollPity = Config.ROLL_PITY - 1
	pd.data.rollTokens = 1
	Remotes.Roll:FireServer("token")
	M.advance(Config.ROLL_COOLDOWN + 0.1)
	local got = pd.owned[1]
	pityOk = pityOk and got ~= nil and EPIC_PLUS[got.def.rarity] == true and pd.data.rollPity == 0
end
check(pityOk, "pity roll is always Epic or better and resets the counter")
check(hudD.KismatReveal.Rarity.Text ~= "", "pity reveal shows rarity")
Havelis.clearBrainrots(pd)
Havelis.arrange(pd)

-- the odds really are the odds shown
M.rawset(M.services.Lighting, "ClockTime", 12)
local rc = {}
for _ = 1, 100000 do
	local def = Kismat.pick(false)
	rc[def.rarity] = (rc[def.rarity] or 0) + 1
end
check(math.abs(rc.Common / 1e5 - 0.5) < 0.01, "roll common ~50%: " .. rc.Common / 1e5)
check(math.abs(rc.Legendary / 1e5 - 0.018) < 0.002, "roll legendary ~1.8%: " .. rc.Legendary / 1e5)
check(math.abs((rc.Mythic or 0) / 1e5 - 0.002) < 0.001, "roll mythic ~0.2%: " .. tostring(rc.Mythic))
local pityRare = true
for _ = 1, 5000 do
	pityRare = pityRare and EPIC_PLUS[Kismat.pick(true).rarity] == true
end
check(pityRare, "pity pick never gives below Epic")

---------------------------------------------------------------------------
section("Robux purchases")
---------------------------------------------------------------------------
local function receipt(userId, productId, purchaseId)
	local result
	M.task.spawn(function()
		result = MPS.ProcessReceipt({
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

table.clear(M.prompts)
kc.BuyRolls2.Activated:Fire()
M.advance(0.1)
check(
	#M.prompts == 1 and M.prompts[1].id == 1010 and M.prompts[1].player == "Dua",
	"10-roll button opens the Robux prompt"
)
pd.data.rollTokens = 0
check(receipt(4, 1010, "buy-1") == Granted and pd.data.rollTokens == 10, "10-roll pack granted")
check(M.store["player_4"] and M.store["player_4"].rollTokens == 10, "purchase saved straight away")
check(hudD.Buttons.Kismat.Text == "Kismat Roll (10)", "HUD shows the new rolls")
check(receipt(4, 1010, "buy-1") == Granted and pd.data.rollTokens == 10, "same purchase is never granted twice")
check(receipt(4, 9999, "buy-2") == NotYet, "unknown product is not granted")
check(receipt(99, 1001, "buy-3") == NotYet, "player not in the server: Roblox retries later")
M.failSavesFor["player_4"] = true
check(receipt(4, 1001, "buy-4") == NotYet and pd.data.rollTokens == 10, "failed save undoes the grant")
M.failSavesFor["player_4"] = nil
check(receipt(4, 1001, "buy-4") == Granted and pd.data.rollTokens == 11, "retry after a failed save works")
M.studio = false
check(receipt(3, 1001, "buy-5") == NotYet, "live server, data did not load: retry later")
M.studio = true
check(receipt(3, 1001, "buy-6") == Granted, "Studio test purchase works without DataStores")

-- players where Roblox restricts paid random items
M.restricted[5] = true
local E = addPlayer("Ehsan", 5)
M.advance(0.5)
check(E:GetAttribute("PaidRollsAllowed") == false, "restricted player flagged")
table.clear(M.prompts)
markLog()
M.localPlayer = E
Remotes.BuyProduct:FireServer("rolls", 1)
M.advance(0.1)
check(#M.prompts == 0 and notified("Ehsan", "not available"), "restricted players are never offered paid rolls")
Remotes.BuyProduct:FireServer("steals", 1)
M.advance(0.1)
check(#M.prompts == 1 and M.prompts[1].id == 2001, "Chor Passes are not random, so they are allowed")
Remotes.BuyProduct:FireServer("rolls", "lots")
Remotes.BuyProduct:FireServer("gems", 1)
M.advance(0.1)
check(#M.prompts == 1, "bad purchase requests ignored")
M.localPlayer = D
M.policyFail = true
local F = addPlayer("Faraz", 6)
M.advance(0.5)
M.policyFail = false
check(F:GetAttribute("PaidRollsAllowed") == false, "if PolicyService fails, paid rolls stay off")
D:SetAttribute("PaidRollsAllowed", false)
M.advance(0.1)
check(not kc.BuyRolls1.Visible and not kc.BuyRolls2.Visible, "Robux roll buttons hide when not allowed")
check(kc.RollRupees.Visible, "rupee rolls stay available")
D:SetAttribute("PaidRollsAllowed", true)

---------------------------------------------------------------------------
section("Chor Pass stealing")
---------------------------------------------------------------------------
local pe = State.profiles[E]
local charE = spawnCharacter(E)
M.advance(0.3)
Havelis.clearBrainrots(pe)
Havelis.arrange(pe)
pe.data.rupees = 1000
State.syncStats(pe)
buy(E, "ChanaChaatChacha")
buy(E, "SamosaSupremo")
buy(E, "GolGappaGhostu")
M.advance(10)
local ghost = entryOf(pe, "GolGappaGhostu")
check(ghost.plot == 3, "ghostu on Ehsan's plot 3")
check(prompt(ghost.model, "StealPrompt").ActionText == "Steal (1 Chor Pass)", "steal prompt shows the cost")
check(hudD.Buttons:FindFirstChild("ChorPass") ~= nil, "Chor Pass button on the HUD")
M.advance(Config.NEW_PLAYER_PROTECTION + 1)

pd.data.stealTokens = 0
State.syncTokens(pd)
table.clear(M.prompts)
markLog()
moveNear(D, ghost.model)
trigger(ghost.model, "StealPrompt", D)
check(ghost.carrier == nil and notified("Dua", "needs a Chor Pass"), "no Chor Pass, no steal")
check(#M.prompts == 1 and M.prompts[1].id == 2001, "Chor Pass purchase pops up")
check(receipt(4, 2005, "chor-1") == Granted and pd.data.stealTokens == 5, "5 Chor Passes granted")
check(hudD.ChorPanel.Content.Passes.Text == "Your Chor Passes: 5", "Chor panel shows passes")
check(hudD.ChorPanel.Content.BuyPasses2.Text:find("5 Chor Passes") ~= nil, "Chor pack button")

trigger(ghost.model, "StealPrompt", D)
check(ghost.carrier == D and pd.data.stealTokens == 4, "steal uses a Chor Pass")
charD:PivotTo(CFrame.new(10, 5, 0))
charE:PivotTo(CFrame.new(13, 5, 0))
markLog()
E.Backpack:FindFirstChild("Chappal").Activated:Fire()
M.advance(0.1)
check(ghost.carrier == nil and pd.data.stealTokens == 5, "bonked thief gets the Chor Pass back")
check(notified("Dua", "given back"), "refund message")
M.advance(Config.SAME_HAVELI_COOLDOWN + 1)
moveNear(D, ghost.model)
trigger(ghost.model, "StealPrompt", D)
check(ghost.carrier == D and pd.data.stealTokens == 4, "second steal uses a pass")
pd.haveli.door.Touched:Fire(charD.HumanoidRootPart)
M.advance(0.1)
check(entryOf(pd, "GolGappaGhostu") ~= nil and pd.data.stealTokens == 4, "successful steal keeps the pass spent")

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
