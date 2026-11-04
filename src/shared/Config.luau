-- Every number you might want to tune while playtesting lives here.

local Config = {}

-- Money and plots
Config.START_RUPEES = 100
Config.START_PLOTS = 3
Config.MAX_PLOTS = 10
Config.LOCKER_PLOTS = 2 -- plots 1 and 2 can never be stolen from
Config.PLOT_COSTS = {
	[4] = 500,
	[5] = 2_000,
	[6] = 5_000,
	[7] = 12_000,
	[8] = 30_000,
	[9] = 75_000,
	[10] = 150_000,
}
Config.SELL_RATE = 0.5 -- sell for half the price

-- Bazaar Lane
Config.SPAWN_INTERVAL = 4 -- seconds between new brainrots
Config.LANE_WALK_TIME = 24 -- seconds to walk from the Spawn Gate to the Chowk
Config.WALK_HOME_SPEED = 20 -- studs per second when walking to a plot
Config.PROMPT_DISTANCE = 12 -- how close you must be to press E
Config.RARITY_ODDS = {
	Common = 60,
	Uncommon = 25,
	Rare = 10,
	Epic = 4,
	Legendary = 0.9,
	Mythic = 0.1,
}
Config.CHAPPAL_FREEZE_TIME = 4 -- everyone freezes when Ammi ki Udti Chappal appears

-- Stealing
Config.STEAL_HOLD_TIME = 1.5
Config.STEAL_COOLDOWN = 15 -- a thief can steal once every 15 seconds
Config.SAME_HAVELI_COOLDOWN = 120 -- cannot rob the same haveli twice in a row within 2 minutes
Config.LOCK_TIME = 30 -- Taala lasts 30 seconds
Config.LOCK_COOLDOWN = 60 -- then needs 60 seconds before it can be used again
Config.NEW_PLAYER_PROTECTION = 180 -- 3 minutes of steal protection after joining
Config.STEAL_PRICE_CAP = 8_000 -- players who have not rebirthed can only steal brainrots up to this price
Config.BONK_RANGE = 10
Config.BONK_COOLDOWN = 0.8

-- Rebirth ("Naya Safar")
Config.REBIRTH_COST = 1_000_000
Config.REBIRTH_BONUS = 0.5 -- +50% income for every rebirth

-- Daily chai
Config.DAILY_MIN_RUPEES = 250
Config.DAILY_INCOME_SECONDS = 120 -- the rupee reward is worth this many seconds of your income
Config.DAILY_FREE_ROLLS = 1 -- free Kismat Rolls with every daily chai

-- Kismat Roll (RNG): spend rupees or a roll for a random brainrot
Config.ROLL_RUPEE_COST = 2_500
Config.ROLL_ODDS = { -- shown to players in the Kismat panel, keep it honest
	Common = 50,
	Uncommon = 30,
	Rare = 13,
	Epic = 5,
	Legendary = 1.8,
	Mythic = 0.2,
}
Config.ROLL_PITY = 30 -- an Epic or better is guaranteed at least once every 30 rolls
Config.ROLL_COOLDOWN = 2.5 -- seconds between rolls (the reveal takes about 2 seconds)

-- Robux packs. Create Developer Products on the Creator Dashboard
-- (your experience > Monetization > Developer Products), set their prices
-- there, and paste their ids here. A pack with id = 0 is hidden.
Config.ROLL_PRODUCTS = { -- Kismat Rolls
	{ id = 0, amount = 1 },
	{ id = 0, amount = 10 },
}
Config.STEAL_PRODUCTS = { -- Chor Passes: every steal uses one
	{ id = 0, amount = 1 },
	{ id = 0, amount = 5 },
}
Config.STEAL_COSTS_ROBUX = true -- set to false to make stealing free
Config.STEAL_REFUND_ON_FAIL = true -- give the Chor Pass back if the thief gets bonked, dies or the owner leaves
Config.DAILY_FREE_STEALS = 0 -- free Chor Passes with every daily chai

-- Stealing only costs a Chor Pass once a Chor Pass product id is set, so the
-- game stays testable before the products exist.
function Config.stealsCostRobux(): boolean
	if not Config.STEAL_COSTS_ROBUX then
		return false
	end
	for _, pack in Config.STEAL_PRODUCTS do
		if pack.id ~= 0 then
			return true
		end
	end
	return false
end

-- World
Config.DAY_LENGTH = 600 -- seconds for a full day and night
Config.AUTOSAVE_INTERVAL = 120
Config.DATASTORE_NAME = "ChaiChaos_v1"

-- Haveli wall colour changes with every rebirth
Config.HAVELI_COLORS = {
	Color3.fromRGB(226, 196, 150), -- sandstone
	Color3.fromRGB(235, 160, 170), -- gulabi
	Color3.fromRGB(140, 195, 235), -- aasmani
	Color3.fromRGB(150, 220, 170), -- pista
	Color3.fromRGB(245, 175, 75), -- kesari
	Color3.fromRGB(195, 165, 235), -- jamni
	Color3.fromRGB(45, 175, 165), -- truck-art firozi
}

return Config
