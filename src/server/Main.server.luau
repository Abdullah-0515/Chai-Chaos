-- Chai Chaos server entry point. Wires the world (the Chowk, the ring of
-- havelis and the eight biomes), players, income, eggs, hazards, treasure, the
-- Chowk shops, riding, the Taala lock, the chappal, daily chai, quests, events,
-- Kismat Rolls, Robux purchases and Naya Safar (rebirth) together.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Brainrots = require(Shared.Brainrots)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)
local Themes = require(Shared.Themes)

local State = require(script.Parent.State)
local PlayerData = require(script.Parent.PlayerData)
local MapBuilder = require(script.Parent.MapBuilder)
local Models = require(script.Parent.Models)
local Havelis = require(script.Parent.Havelis)
local Stealing = require(script.Parent.Stealing)
local Shop = require(script.Parent.Shop)
local Kismat = require(script.Parent.Kismat)
local World = require(script.Parent.World)
local Defenses = require(script.Parent.Defenses)
local EventRunner = require(script.Parent.EventRunner)
local QuestBook = require(script.Parent.QuestBook)
local Leaderboard = require(script.Parent.Leaderboard)
local EggSystem = require(script.Parent.EggSystem)
local Hazards = require(script.Parent.Hazards)
local Treasure = require(script.Parent.Treasure)
local Upgrades = require(script.Parent.Upgrades)
local Garage = require(script.Parent.Garage)
local Zones = require(script.Parent.Zones)
local Wild = require(script.Parent.Wild)
local Mandi = require(script.Parent.Mandi)

World.init()
local map = MapBuilder.ensure()
Havelis.init(map)
Defenses.init(map)
Stealing.init(map)
EggSystem.init(map)
Hazards.init(map)
Treasure.init(map)
Upgrades.init(map)
Garage.init(map)
Garage.onHonk = Wild.scare
Wild.init(map)
Mandi.init()
Shop.init()
Shop.paintHook = Garage.onPaintBought
Kismat.init()
QuestBook.init()
EventRunner.init()
Leaderboard.init(map)

---------------------------------------------------------------------------
-- The chappal tool: bonk a thief to make them drop your brainrot
---------------------------------------------------------------------------
local chappalTemplate = Instance.new("Tool")
chappalTemplate.Name = "Chappal"
chappalTemplate.ToolTip = "Bonk a chor to get your brainrot back"
chappalTemplate.CanBeDropped = false
do
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 0.2, 1.8)
	handle.Color = Color3.fromRGB(60, 110, 210)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = chappalTemplate
	local strap = Instance.new("Part")
	strap.Name = "Strap"
	strap.Size = Vector3.new(0.6, 0.25, 0.35)
	strap.Color = Color3.fromRGB(25, 25, 30)
	strap.CanCollide = false
	strap.Massless = true
	strap.CFrame = handle.CFrame * CFrame.new(0, 0.2, -0.3)
	strap.Parent = chappalTemplate
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = strap
	weld.Parent = handle
end

local function giveChappal(player: Player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack or backpack:FindFirstChild("Chappal") then
		return
	end
	if player.Character and player.Character:FindFirstChild("Chappal") then
		return
	end
	local tool = chappalTemplate:Clone()
	tool.Activated:Connect(function()
		-- plays the default sword-slash animation
		local anim = Instance.new("StringValue")
		anim.Name = "toolanim"
		anim.Value = "Slash"
		anim.Parent = tool
		Debris:AddItem(anim, 1)
		Stealing.bonk(player)
	end)
	tool.Parent = backpack
end

---------------------------------------------------------------------------
-- Players joining and leaving
---------------------------------------------------------------------------
local function makeLeaderstats(player: Player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local rupees = Instance.new("IntValue")
	rupees.Name = "Rupees"
	rupees.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = stats
	stats.Parent = player
end

local function today(): number
	return math.floor(os.time() / 86400)
end

local function plural(count: number, one: string, many: string): string
	return ("%d %s"):format(count, if count == 1 then one else many)
end

local function dailyChai(profile)
	local data = profile.data
	if data.lastDaily >= today() then
		return
	end
	data.lastDaily = today()

	local extras = {}
	if Config.DAILY_FREE_ROLLS > 0 then
		data.rollTokens += Config.DAILY_FREE_ROLLS
		table.insert(extras, plural(Config.DAILY_FREE_ROLLS, "free Kismat Roll", "free Kismat Rolls"))
	end
	if Config.DAILY_FREE_STEALS > 0 then
		data.stealTokens += Config.DAILY_FREE_STEALS
		table.insert(extras, plural(Config.DAILY_FREE_STEALS, "free Chor Pass", "free Chor Passes"))
	end
	State.syncTokens(profile)
	local bonus = if #extras > 0 then " Plus " .. table.concat(extras, " and ") .. "!" else ""

	if math.random() < 0.5 and Havelis.hasFreePlot(profile) then
		local pool = {}
		for _, rarity in { "Common", "Uncommon" } do
			for _, def in Brainrots.byRarity[rarity] do
				table.insert(pool, def)
			end
		end
		local def = pool[math.random(#pool)]
		Havelis.adopt(profile, def)
		State.notify(
			profile.player,
			"good",
			("Daily chai! A free %s is walking into your haveli.%s"):format(def.name, bonus)
		)
	else
		local amount = math.max(
			Config.DAILY_MIN_RUPEES,
			math.floor(Havelis.incomePerSecond(profile) * Config.DAILY_INCOME_SECONDS)
		)
		State.addRupees(profile, amount)
		State.notify(
			profile.player,
			"good",
			("Daily chai! Here is %s to start your day.%s"):format(Format.rupees(amount), bonus)
		)
	end
end

local function startProtection(profile)
	profile.protectedUntil = workspace:GetServerTimeNow() + Config.NEW_PLAYER_PROTECTION
	profile.player:SetAttribute("ProtectedUntil", profile.protectedUntil)
	task.delay(Config.NEW_PLAYER_PROTECTION + 0.1, function()
		if State.profiles[profile.player] == profile then
			Havelis.refreshPrompts(profile)
		end
	end)
end

local function onCharacterAdded(profile, character: Model)
	character:WaitForChild("HumanoidRootPart", 10)
	task.wait()
	if State.profiles[profile.player] == profile then
		profile.carrySpeed = nil
		Garage.reset(profile)
		Havelis.teleportHome(profile)
		Havelis.applyWalkSpeed(profile)
		Defenses.applyCharacter(profile)
	end
end

local function onPlayerAdded(player: Player)
	makeLeaderstats(player)
	player.CharacterAdded:Connect(function()
		giveChappal(player)
	end)
	if player.Character then
		task.spawn(giveChappal, player)
	end

	local data, canSave = PlayerData.load(player.UserId)
	if not player.Parent then
		return -- left while loading
	end

	local profile = State.newProfile(player, data, canSave)
	State.profiles[player] = profile
	State.syncStats(profile)
	State.syncDiscovered(profile)
	player:SetAttribute("Income", 0)
	player:SetAttribute("LockedUntil", 0)
	player:SetAttribute("LockReadyAt", 0)

	State.syncGear(profile)
	State.syncZones(profile)
	Garage.sync(profile)
	if Havelis.claim(profile) then
		player:SetAttribute("HaveliIndex", profile.haveli.index)
		player:SetAttribute("HomePosition", profile.haveli.doorOutside.Position)
		EggSystem.restore(profile)
	else
		State.notify(
			player,
			"bad",
			"Every haveli is taken, so there is no haveli for you right now. Try another server!"
		)
	end

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(profile, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, profile, player.Character)
	end

	startProtection(profile)
	Havelis.refreshPrompts(profile)
	State.syncTokens(profile)
	task.spawn(Shop.setup, profile)
	QuestBook.ensure(profile)
	State.syncQuests(profile)
	dailyChai(profile)
	State.notify(
		player,
		"info",
		"Welcome to Chai Chaos! Follow your radar out through the town gate to Mango Bagh, find eggs and carry them home to hatch. Buy a vehicle at the Gaari Showroom to go further!"
	)
	if next(data.discovered) == nil then
		State.notify(player, "info", "Open the Haveli menu to pick your haveli's theme!")
	end
	if not canSave then
		State.notify(player, "bad", "Saving is off right now, so your progress will not be kept.")
		if RunService:IsStudio() then
			warn(
				"[ChaiChaos] To test saving in Studio: publish the place, then turn on "
					.. "Game Settings > Security > Enable Studio Access to API Services."
			)
		end
	end
end

local function saveProfile(profile)
	if profile.canSave then
		Havelis.syncData(profile)
		EggSystem.syncData(profile)
		PlayerData.save(profile.player.UserId, profile.data)
	end
end

local function onPlayerRemoving(player: Player)
	local profile = State.profiles[player]
	Stealing.forget(player)
	Kismat.forget(player)
	if not profile then
		return
	end
	Stealing.releasePlayer(profile)
	Garage.park(profile)
	Havelis.syncData(profile)
	EggSystem.syncData(profile)
	EggSystem.release(profile)
	Havelis.release(profile)
	State.profiles[player] = nil
	saveProfile(profile)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	local pending = 0
	for _, profile in State.profiles do
		pending += 1
		task.spawn(function()
			saveProfile(profile)
			pending -= 1
		end)
	end
	local started = os.clock()
	while pending > 0 and os.clock() - started < 25 do
		task.wait(0.1)
	end
end)

task.spawn(function()
	while true do
		task.wait(Config.AUTOSAVE_INTERVAL)
		for _, profile in State.profiles do
			task.spawn(saveProfile, profile)
		end
	end
end)

---------------------------------------------------------------------------
-- Income: every brainrot drops rupees into its owner's galla each second
---------------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)
		for player, profile in State.profiles do
			local income = Havelis.incomePerSecond(profile)
			profile.data.galla += income
			player:SetAttribute("Income", income)
			Havelis.updateGalla(profile)
		end
	end
end)

---------------------------------------------------------------------------
-- Every ProximityPrompt in the game is handled here
---------------------------------------------------------------------------
-- (ShopPrompts at the Chowk only open a window on the player's screen.)
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	local name = prompt.Name
	if name == "EggPrompt" then
		EggSystem.pickUp(player, prompt:FindFirstAncestorOfClass("Model"))
	elseif name == "TreasurePrompt" then
		Treasure.open(player, prompt:FindFirstAncestorOfClass("Model"))
	elseif name == "ClimbPrompt" then
		Treasure.climb(player, prompt:FindFirstAncestorOfClass("Model"))
	elseif name == "StealPrompt" then
		local model = Models.ownerModel(prompt)
		if model then
			Stealing.start(player, model)
		end
	elseif name == "GatePrompt" then
		Zones.unlock(player, prompt.Parent)
	elseif name == "PumpPrompt" then
		Garage.refuel(player, prompt.Parent)
	elseif name == "RideAlong" then
		Garage.rideAlong(player, prompt.Parent)
	elseif name == "RickshawHome" then
		Zones.rideHome(player, prompt.Parent)
	elseif name == "CatchPrompt" then
		Wild.catch(player, prompt:FindFirstAncestorOfClass("Model"))
	elseif name == "BuyPrompt" then
		Mandi.buy(player, prompt:FindFirstAncestorOfClass("Model"))
	end
end)

---------------------------------------------------------------------------
-- Haveli buttons: Taala lock, upgrades and themes
---------------------------------------------------------------------------
Remotes.LockHaveli.OnServerEvent:Connect(Havelis.lock)
Remotes.UpgradeHaveli.OnServerEvent:Connect(Havelis.upgrade)
Remotes.SetTheme.OnServerEvent:Connect(Havelis.setTheme)

---------------------------------------------------------------------------
-- Naya Safar (rebirth) at the Chowk: costs more every time, unlocks a new
-- theme. You keep your gear, vehicles, unlocked zones, Kismat Rolls, Chor
-- Passes and Collection Book. Each rebirth opens more ring 3 zones.
---------------------------------------------------------------------------
Remotes.Rebirth.OnServerEvent:Connect(function(player: Player)
	local profile = State.profiles[player]
	if not profile or not profile.haveli then
		return
	end
	if not Upgrades.atShop(player, "Rebirth") then
		State.notify(player, "bad", "Go to the Naya Safar stall in the Chowk to rebirth.")
		return
	end
	local data = profile.data
	local cost = Config.rebirthCost(data.rebirths)
	if data.rupees < cost then
		State.notify(player, "bad", ("You need %s for a Naya Safar."):format(Format.rupees(cost)))
		return
	end
	Stealing.releasePlayer(profile)
	Garage.park(profile)
	EggSystem.reset(profile)
	Havelis.clearBrainrots(profile)
	data.rebirths += 1
	data.rupees = Config.START_RUPEES
	data.level = 1
	data.trackerLevel = 1
	data.galla = 0
	data.owned = {}
	State.syncStats(profile)
	State.syncGear(profile)
	Zones.refresh(profile)
	State.sound(player, "Rebirth")
	State.syncQuests(profile)
	Havelis.restyle(profile)
	State.notifyAll(
		"rare",
		("%s started a Naya Safar! Rebirth %d, now earning +%d%% forever."):format(
			player.DisplayName,
			data.rebirths,
			math.floor(Config.REBIRTH_BONUS * data.rebirths * 100)
		)
	)
	for _, theme in Themes.list do
		if theme.rebirths == data.rebirths then
			State.notify(player, "rare", ("New haveli theme unlocked: %s! %s"):format(theme.name, theme.perkText))
		end
	end
	for _, biome in require(Shared.Biomes).list do
		if biome.rebirths == data.rebirths then
			State.notify(player, "rare", ("%s's gate is open for you now! %s"):format(biome.name, biome.blurb))
		end
	end
	task.spawn(saveProfile, profile)
end)

print(
	("[ChaiChaos] Ready with %d brainrots, %d havelis and %d zones."):format(
		#Brainrots.list,
		#map.havelis,
		#require(Shared.Biomes).list
	)
)
