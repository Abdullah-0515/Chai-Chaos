-- Saving and loading with DataStoreService.
--
-- * A save belongs to one server at a time (a "session lock"). If you hop to
--   another server before the old one has saved, the new server waits for it,
--   so the last minutes of your progress are never overwritten by old data.
-- * If loading fails, the player plays without saving, so a hiccup can never
--   wipe their progress. Saves are tried again when they fail.
--
-- In Studio, saving only works when the place is published and
-- Game Settings > Security > "Enable Studio Access to API Services" is on.
-- Without it the game still runs, it just starts fresh every time.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Brainrots = require(Shared.Brainrots)
local Mutations = require(Shared.Mutations)
local Themes = require(Shared.Themes)
local Gear = require(Shared.Gear)
local Biomes = require(Shared.Biomes)
local Vehicles = require(Shared.Vehicles)

local PlayerData = {}

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DATASTORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[ChaiChaos] DataStore is not available, progress will not be saved:", result)
	end
end

local function storeKey(userId: number): string
	return "player_" .. userId
end

-- This server's name on the saves it has open.
local JOB = if game.JobId ~= nil and game.JobId ~= "" then tostring(game.JobId) else "studio"
local LOCK_EXPIRES = 600 -- a server that crashed keeps its lock no longer than this
PlayerData.tries = if RunService:IsStudio() then 1 else 4 -- how often loading and saving are tried

local function lockedElsewhere(old: any): boolean
	local session = type(old) == "table" and old.session
	return type(session) == "table"
		and session.job ~= JOB
		and type(session.at) == "number"
		and os.time() - session.at < LOCK_EXPIRES
end

function PlayerData.default()
	return {
		version = 5,
		rupees = Config.START_RUPEES,
		galla = 0,
		rebirths = 0,
		level = 1, -- haveli level (see Config.HAVELI_LEVELS)
		theme = Themes.DEFAULT,
		owned = {}, -- brainrot keys: "SamosaSupremo" or "SamosaSupremo:Golden"
		discovered = {}, -- [id] = true
		mutations = {}, -- ["SamosaSupremo:Golden"] = true, for the Collection Book
		lastDaily = 0, -- day number of the last daily chai
		rollTokens = 0, -- Kismat Rolls from daily chai, quests and Robux packs
		rollPity = 0, -- rolls since the last Epic or better
		stealTokens = 0, -- Chor Passes, one is used for every steal
		receipts = {}, -- recent Robux purchase ids, so a purchase is never granted twice
		quests = { day = 0, list = {}, bonusClaimed = false },
		collection = {}, -- [rarity] = { rewarded = true, specialRebirth = n }
		trackerLevel = 1, -- egg tracker level (see Config.TRACKER_LEVELS)
		gear = {}, -- [gear id] = true
		incubators = {}, -- { slot, biome, golden, id, mutation, hatchAt } eggs waiting to hatch
		zones = {}, -- [zone id] = true for zones bought at their gate (ring 3 opens with rebirths)
		vehicles = {}, -- [vehicle id] = { fuel, speed, tank, eggs, grip } (upgrade levels)
		vehicle = nil, -- the vehicle you drove last
		paints = {}, -- [paint id] = true for Robux paint jobs
		paint = "Factory", -- the paint job on your vehicles
		lastSeen = 0, -- os.time() of the last save, for offline earnings
		streak = 0, -- days in a row you came for your daily chai
		tutorial = 1, -- the guide's step (see Tutorial.luau); past the last step = finished
		codes = {}, -- [code] = true for promo codes you have used
		settings = { music = true, sounds = true }, -- the Settings window
		badges = {}, -- [badge name] = true once Roblox has awarded it
		guideRewarded = false, -- the guide's reward is only given once
		passes = {}, -- [pass id] = true for game passes Roblox says you own
	}
end

-- Version 3 had 8 biomes; eggs waiting in an incubator keep hatching as one of the new zones.
local OLD_BIOMES = {
	Khet = "MangoBagh",
	Jungle = "CamelMela",
	Samandar = "SahilBeach",
	Jheel = "SarsonFields",
	Registan = "TharDesert",
	Delta = "QissaKhawani",
	Pahar = "BarfaniPahar",
	NamakKaan = "NamakCaves",
}

-- Brainrots that were renamed, so old saves keep them under their new id.
local RENAMED = {
	CycleWalaCyclops = "CylinderCycleChacha",
}
PlayerData.RENAMED = RENAMED

-- A saved brainrot key ("Id" or "Id:Mutation") as its current id and mutation.
local function parseKey(key: string): (string, string?)
	local id, mutation = Mutations.parse(key)
	return RENAMED[id] or id, mutation
end

local function whole(value: any, minimum: number): number?
	if type(value) == "number" and value == value then
		return math.max(minimum, math.floor(value))
	end
	return nil
end

-- Fill in anything missing or broken so old saves keep working.
local function reconcile(saved: any)
	local data = PlayerData.default()
	if type(saved) ~= "table" then
		return data
	end
	data.rupees = whole(saved.rupees, 0) or data.rupees
	data.galla = if type(saved.galla) == "number" then math.max(0, saved.galla) else 0
	data.rebirths = whole(saved.rebirths, 0) or 0
	data.lastDaily = whole(saved.lastDaily, 0) or 0
	data.rollTokens = whole(saved.rollTokens, 0) or 0
	data.stealTokens = whole(saved.stealTokens, 0) or 0
	data.rollPity = whole(saved.rollPity, 0) or 0

	if type(saved.level) == "number" then
		data.level = math.clamp(math.floor(saved.level), 1, #Config.HAVELI_LEVELS)
	elseif type(saved.plots) == "number" then
		-- version 1 saved a plot count instead of a level
		for level, info in Config.HAVELI_LEVELS do
			if info.plots <= saved.plots then
				data.level = level
			end
		end
	end
	if type(saved.theme) == "string" and Themes.isUnlocked(saved.theme, data.rebirths) then
		data.theme = saved.theme
	end
	if type(saved.trackerLevel) == "number" then
		data.trackerLevel = math.clamp(math.floor(saved.trackerLevel), 1, #Config.TRACKER_LEVELS)
	end
	if type(saved.gear) == "table" then
		for id, value in saved.gear do
			if value == true and type(id) == "string" and Gear.byId[id] then
				data.gear[id] = true
			end
		end
	end

	if type(saved.receipts) == "table" then
		for _, id in saved.receipts do
			if type(id) == "string" then
				table.insert(data.receipts, id)
			end
		end
	end
	if type(saved.discovered) == "table" then
		for id, value in saved.discovered do
			id = RENAMED[id] or id
			if value == true and Brainrots.byId[id] then
				data.discovered[id] = true
			end
		end
	end
	if type(saved.mutations) == "table" then
		for key, value in saved.mutations do
			local id, mutation = parseKey(key)
			if value == true and Brainrots.byId[id] and mutation then
				data.mutations[Mutations.key(id, mutation)] = true
			end
		end
	end
	if type(saved.passes) == "table" then
		for id, value in saved.passes do
			if value == true and Config.GAME_PASSES[id] ~= nil then
				data.passes[id] = true
			end
		end
	end
	local plots = Config.plotCount(data.level, data.passes.ExtraPlots)
	if type(saved.zones) == "table" then
		for id, value in saved.zones do
			local biome = Biomes.byId[id]
			if value == true and biome and biome.price > 0 then
				data.zones[id] = true
			end
		end
	end
	if type(saved.vehicles) == "table" then
		for id, entry in saved.vehicles do
			local def = Vehicles.byId[id]
			if def and type(entry) == "table" then
				local levels = { fuel = 0 }
				for _, upgrade in Vehicles.UPGRADES do
					levels[upgrade.id] =
						math.clamp(whole(entry[upgrade.id], 0) or 0, 0, Vehicles.maxLevel(def, upgrade.id))
				end
				local tank = Vehicles.tank(def, Vehicles.levels(levels))
				levels.fuel = if type(entry.fuel) == "number" and entry.fuel == entry.fuel
					then math.clamp(entry.fuel, 0, tank)
					else tank
				data.vehicles[id] = levels
			end
		end
	end
	if type(saved.vehicle) == "string" and data.vehicles[saved.vehicle] then
		data.vehicle = saved.vehicle
	end
	if type(saved.paints) == "table" then
		for id, value in saved.paints do
			if value == true and Vehicles.paintById[id] and id ~= "Factory" then
				data.paints[id] = true
			end
		end
	end
	if type(saved.paint) == "string" and (saved.paint == "Factory" or data.paints[saved.paint]) then
		data.paint = saved.paint
	end
	if type(saved.incubators) == "table" then
		local used = {}
		for _, egg in saved.incubators do
			local eggId = type(egg) == "table" and type(egg.id) == "string" and (RENAMED[egg.id] or egg.id)
			local eggBiome = type(egg) == "table"
				and type(egg.biome) == "string"
				and (OLD_BIOMES[egg.biome] or egg.biome)
			local slot = type(egg) == "table" and whole(egg.slot, 1)
			if
				slot
				and not used[slot]
				and slot <= Config.HAVELI_LEVELS[data.level].incubators
				and eggBiome
				and Biomes.byId[eggBiome]
				and eggId
				and Brainrots.byId[eggId]
				and type(egg.hatchAt) == "number"
			then
				used[slot] = true
				table.insert(data.incubators, {
					slot = slot,
					biome = eggBiome,
					golden = egg.golden == true,
					id = eggId,
					mutation = if type(egg.mutation) == "string" and Mutations.byId[egg.mutation]
						then egg.mutation
						else nil,
					hatchAt = math.floor(egg.hatchAt),
				})
			end
		end
	end
	if type(saved.owned) == "table" then
		for _, key in saved.owned do
			if type(key) == "string" then
				local id, mutation = parseKey(key)
				if Brainrots.byId[id] and #data.owned < plots then
					table.insert(data.owned, Mutations.key(id, mutation))
					data.discovered[id] = true
				end
			end
		end
	end
	-- Version 3 let you ride a brainrot. Riding is gone, so it walks back to a
	-- plot; if every plot is full you get its full value in rupees instead.
	if type(saved.ride) == "string" then
		local id, mutation = parseKey(saved.ride)
		local def = Brainrots.byId[id]
		if def and not def.questOnly then
			data.discovered[id] = true
			if #data.owned < plots then
				table.insert(data.owned, Mutations.key(id, mutation))
			else
				data.rupees += Mutations.value(def, mutation)
			end
		end
	end
	if type(saved.quests) == "table" and type(saved.quests.list) == "table" then
		local quests =
			{ day = whole(saved.quests.day, 0) or 0, list = {}, bonusClaimed = saved.quests.bonusClaimed == true }
		for _, q in saved.quests.list do
			if type(q) == "table" and type(q.id) == "string" and type(q.target) == "number" then
				table.insert(quests.list, {
					id = q.id,
					target = q.target,
					progress = whole(q.progress, 0) or 0,
					claimed = q.claimed == true,
				})
			end
		end
		data.quests = quests
	end
	data.lastSeen = whole(saved.lastSeen, 0) or 0
	data.streak = whole(saved.streak, 0) or 0
	-- saves from before the guide: anyone who has found a brainrot has finished it
	data.tutorial = math.min(whole(saved.tutorial, 1) or (if next(data.discovered) ~= nil then 1000 else 1), 1000)
	if type(saved.codes) == "table" then
		for code, value in saved.codes do
			if value == true and type(code) == "string" then
				data.codes[code] = true
			end
		end
	end
	if type(saved.settings) == "table" then
		data.settings.music = saved.settings.music ~= false
		data.settings.sounds = saved.settings.sounds ~= false
	end
	if type(saved.badges) == "table" then
		for name, value in saved.badges do
			if value == true and type(name) == "string" then
				data.badges[name] = true
			end
		end
	end
	data.guideRewarded = saved.guideRewarded == true
	if type(saved.collection) == "table" then
		for rarity, entry in saved.collection do
			if Config.COLLECTION_REWARDS[rarity] and type(entry) == "table" then
				data.collection[rarity] = {
					rewarded = entry.rewarded == true,
					specialRebirth = whole(entry.specialRebirth, -1),
				}
			end
		end
	end
	return data
end
PlayerData.reconcile = reconcile

-- Returns the data and whether it is safe to save over it later.
-- If loading fails we never save, so a hiccup cannot wipe someone's progress.
function PlayerData.load(userId: number): (any, boolean)
	if not store then
		return PlayerData.default(), false
	end
	local tries = PlayerData.tries
	for attempt = 1, tries do
		local busy = false
		local loaded = nil
		local ok, err = pcall(function()
			store:UpdateAsync(storeKey(userId), function(old)
				-- another server still has this save open: wait for it (the
				-- last try takes over, in case that server crashed)
				busy = lockedElsewhere(old) and attempt < tries
				if busy then
					return nil
				end
				loaded = old
				local value = if type(old) == "table" then old else {}
				value.session = { job = JOB, at = os.time() }
				return value
			end)
		end)
		if ok and not busy then
			return reconcile(loaded), true
		end
		if not ok then
			warn(("[ChaiChaos] Could not load data for %d (try %d): %s"):format(userId, attempt, tostring(err)))
		end
		if attempt < tries then
			task.wait(attempt * 2)
		end
	end
	return PlayerData.default(), false
end

-- Saves the data. `final` (the player is leaving) lets go of the save so the
-- next server can open it straight away. Returns false if it could not be
-- saved, or if another server has taken the save over.
function PlayerData.save(userId: number, data: any, final: boolean?): boolean
	if not store then
		return false
	end
	local tries = PlayerData.tries
	for attempt = 1, tries do
		local taken = false
		local ok, err = pcall(function()
			store:UpdateAsync(storeKey(userId), function(old)
				local session = type(old) == "table" and old.session
				if type(session) == "table" and session.job ~= JOB then
					taken = true
					return nil
				end
				data.lastSeen = os.time()
				data.session = if final then nil else { job = JOB, at = os.time() }
				return data
			end)
		end)
		if ok then
			if taken then
				warn(("[ChaiChaos] Another server has the save for %d now, not saving over it."):format(userId))
			end
			return not taken
		end
		warn(("[ChaiChaos] Could not save data for %d (try %d): %s"):format(userId, attempt, tostring(err)))
		if attempt < tries then
			task.wait(attempt)
		end
	end
	return false
end

return PlayerData
