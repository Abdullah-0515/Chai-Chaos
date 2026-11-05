-- Saving and loading with DataStoreService.
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

function PlayerData.default()
	return {
		version = 2,
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
	}
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

	if type(saved.receipts) == "table" then
		for _, id in saved.receipts do
			if type(id) == "string" then
				table.insert(data.receipts, id)
			end
		end
	end
	if type(saved.discovered) == "table" then
		for id, value in saved.discovered do
			if value == true and Brainrots.byId[id] then
				data.discovered[id] = true
			end
		end
	end
	if type(saved.mutations) == "table" then
		for key, value in saved.mutations do
			local id, mutation = Mutations.parse(key)
			if value == true and Brainrots.byId[id] and mutation then
				data.mutations[key] = true
			end
		end
	end
	local plots = Config.HAVELI_LEVELS[data.level].plots
	if type(saved.owned) == "table" then
		for _, key in saved.owned do
			if type(key) == "string" then
				local id, mutation = Mutations.parse(key)
				if Brainrots.byId[id] and #data.owned < plots then
					table.insert(data.owned, Mutations.key(id, mutation))
					data.discovered[id] = true
				end
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
	local attempts = if RunService:IsStudio() then 1 else 3
	for attempt = 1, attempts do
		local ok, result = pcall(function()
			return store:GetAsync(storeKey(userId))
		end)
		if ok then
			return reconcile(result), true
		end
		warn(("[ChaiChaos] Could not load data for %d (try %d): %s"):format(userId, attempt, tostring(result)))
		if attempt < attempts then
			task.wait(attempt * 2)
		end
	end
	return PlayerData.default(), false
end

function PlayerData.save(userId: number, data: any): boolean
	if not store then
		return false
	end
	local ok, err = pcall(function()
		store:UpdateAsync(storeKey(userId), function()
			return data
		end)
	end)
	if not ok then
		warn(("[ChaiChaos] Could not save data for %d: %s"):format(userId, tostring(err)))
	end
	return ok
end

return PlayerData
