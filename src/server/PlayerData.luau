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

local function key(userId: number): string
	return "player_" .. userId
end

function PlayerData.default()
	return {
		version = 1,
		rupees = Config.START_RUPEES,
		galla = 0,
		rebirths = 0,
		plots = Config.START_PLOTS,
		owned = {}, -- list of brainrot ids
		discovered = {}, -- [id] = true
		lastDaily = 0, -- day number of the last daily chai
		rollTokens = 0, -- Kismat Rolls from daily chai and Robux packs
		rollPity = 0, -- rolls since the last Epic or better
		stealTokens = 0, -- Chor Passes, one is used for every steal
		receipts = {}, -- recent Robux purchase ids, so a purchase is never granted twice
	}
end

-- Fill in anything missing or broken so old saves keep working.
local function reconcile(saved: any)
	local data = PlayerData.default()
	if type(saved) ~= "table" then
		return data
	end
	if type(saved.rupees) == "number" then
		data.rupees = math.max(0, math.floor(saved.rupees))
	end
	if type(saved.galla) == "number" then
		data.galla = math.max(0, saved.galla)
	end
	if type(saved.rebirths) == "number" then
		data.rebirths = math.max(0, math.floor(saved.rebirths))
	end
	if type(saved.plots) == "number" then
		data.plots = math.clamp(math.floor(saved.plots), Config.START_PLOTS, Config.MAX_PLOTS)
	end
	if type(saved.lastDaily) == "number" then
		data.lastDaily = saved.lastDaily
	end
	if type(saved.rollTokens) == "number" then
		data.rollTokens = math.max(0, math.floor(saved.rollTokens))
	end
	if type(saved.stealTokens) == "number" then
		data.stealTokens = math.max(0, math.floor(saved.stealTokens))
	end
	if type(saved.rollPity) == "number" then
		data.rollPity = math.max(0, math.floor(saved.rollPity))
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
	if type(saved.owned) == "table" then
		for _, id in saved.owned do
			if Brainrots.byId[id] and #data.owned < data.plots then
				table.insert(data.owned, id)
				data.discovered[id] = true
			end
		end
	end
	return data
end

-- Returns the data and whether it is safe to save over it later.
-- If loading fails we never save, so a hiccup cannot wipe someone's progress.
function PlayerData.load(userId: number): (any, boolean)
	if not store then
		return PlayerData.default(), false
	end
	local attempts = if RunService:IsStudio() then 1 else 3
	for attempt = 1, attempts do
		local ok, result = pcall(function()
			return store:GetAsync(key(userId))
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
		store:UpdateAsync(key(userId), function()
			return data
		end)
	end)
	if not ok then
		warn(("[ChaiChaos] Could not save data for %d: %s"):format(userId, tostring(err)))
	end
	return ok
end

return PlayerData
