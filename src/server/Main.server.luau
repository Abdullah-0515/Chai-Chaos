-- Chai Chaos server entry point. Wires the map, players, income, prompts,
-- haveli levels and themes, the Taala lock, the chappal, daily chai, quests,
-- events, Kismat Rolls, Robux purchases and Naya Safar (rebirth) together.

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
local Spawner = require(script.Parent.Spawner)
local Stealing = require(script.Parent.Stealing)
local Shop = require(script.Parent.Shop)
local Kismat = require(script.Parent.Kismat)
local World = require(script.Parent.World)
local Defenses = require(script.Parent.Defenses)
local EventRunner = require(script.Parent.EventRunner)
local QuestBook = require(script.Parent.QuestBook)
local Leaderboard = require(script.Parent.Leaderboard)

World.init()
local map = MapBuilder.ensure()
Havelis.init(map)
Defenses.init(map)
Stealing.init(map)
Spawner.init(map)
Shop.init()
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
				if not def.eventOnly then
					table.insert(pool, def)
				end
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

	if Havelis.claim(profile) then
		player:SetAttribute("HaveliIndex", profile.haveli.index)
	else
		State.notify(player, "bad", "The bazaar is full, so there is no haveli for you right now. Try another server!")
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
		"Welcome to Chai Chaos! Buy brainrots on Bazaar Lane and collect rupees from your galla."
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
	Havelis.syncData(profile)
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
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	local model = Models.ownerModel(prompt)
	if not model then
		return
	end
	local name = prompt.Name
	if name == "BuyPrompt" then
		Spawner.buy(player, model)
	elseif name == "SellPrompt" then
		Havelis.sell(player, model)
	elseif name == "StealPrompt" then
		Stealing.start(player, model)
	end
end)

---------------------------------------------------------------------------
-- Haveli buttons: Taala lock, upgrades and themes
---------------------------------------------------------------------------
Remotes.LockHaveli.OnServerEvent:Connect(Havelis.lock)
Remotes.UpgradeHaveli.OnServerEvent:Connect(Havelis.upgrade)
Remotes.SetTheme.OnServerEvent:Connect(Havelis.setTheme)

---------------------------------------------------------------------------
-- Naya Safar (rebirth): costs more every time, unlocks a new theme
---------------------------------------------------------------------------
Remotes.Rebirth.OnServerEvent:Connect(function(player: Player)
	local profile = State.profiles[player]
	if not profile or not profile.haveli then
		return
	end
	local data = profile.data
	local cost = Config.rebirthCost(data.rebirths)
	if data.rupees < cost then
		State.notify(player, "bad", ("You need %s for a Naya Safar."):format(Format.rupees(cost)))
		return
	end
	Stealing.releasePlayer(profile)
	Havelis.clearBrainrots(profile)
	data.rebirths += 1
	data.rupees = Config.START_RUPEES
	data.level = 1
	data.galla = 0
	data.owned = {}
	State.syncStats(profile)
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
	task.spawn(saveProfile, profile)
end)

print(("[ChaiChaos] Ready with %d brainrots and %d havelis."):format(#Brainrots.list, #map.havelis))
