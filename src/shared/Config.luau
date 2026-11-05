-- Every number you might want to tune while playtesting lives here.
-- The economy is tuned so a typical kid reaches their first Naya Safar in
-- about an hour (see README > Pacing).

local Config = {}

-- Money
Config.START_RUPEES = 1_000
Config.PRICE_MULTIPLIER = 2 -- every brainrot costs this many times its price in the design doc
Config.SELL_RATE = 0.5 -- sell for half the price

-- Haveli levels: each level costs rupees, adds plots and sometimes a feature.
-- Plots 1-10 are on the ground floor, 11-20 on the second floor.
Config.HAVELI_LEVELS = {
	{ plots = 4, cost = 0, name = "Chhota Ghar" },
	{ plots = 6, cost = 4_000, name = "Pakka Ghar" },
	{ plots = 8, cost = 12_000, name = "Laser Darwaza", unlock = "Laser Darwaza: your Taala blocks the door" },
	{ plots = 10, cost = 30_000, name = "Bagh Wala Ghar", unlock = "A garden full of decorations" },
	{ plots = 12, cost = 80_000, name = "Do Manzila", unlock = "The second floor" },
	{ plots = 14, cost = 180_000, name = "Chowkidar Wali", unlock = "A Chowkidar who catches thieves" },
	{ plots = 16, cost = 350_000, name = "Bari Haveli" },
	{ plots = 18, cost = 550_000, name = "Chhat Wali Haveli", unlock = "A rooftop with chhatris and kites" },
	{ plots = 20, cost = 800_000, name = "Shahi Haveli", unlock = "The fanciest haveli in the bazaar" },
}
Config.LASER_LEVEL = 3
Config.GARDEN_LEVEL = 4
Config.UPPER_FLOOR_LEVEL = 5
Config.GUARD_LEVEL = 6
Config.ROOFTOP_LEVEL = 8
Config.LOCKER_PLOTS = 2 -- plots 1 and 2 can never be stolen from

-- Bazaar Lane
Config.SPAWN_INTERVAL = 4 -- seconds between new brainrots
Config.LANE_WALK_TIME = 26 -- seconds to walk from the Spawn Gate to the Chowk
Config.WALK_HOME_SPEED = 22 -- studs per second when walking to a plot
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

-- Players
Config.WALK_SPEED = 20 -- a bit faster than Roblox's 16, the bazaar is big

-- Stealing
Config.STEAL_HOLD_TIME = 1.5
Config.STEAL_COOLDOWN = 15 -- a thief can steal once every 15 seconds
Config.SAME_HAVELI_COOLDOWN = 120 -- cannot rob the same haveli twice in a row within 2 minutes
Config.LOCK_TIME = 30 -- Taala lasts 30 seconds
Config.LOCK_COOLDOWN = 60 -- then needs 60 seconds before it can be used again
Config.NEW_PLAYER_PROTECTION = 180 -- 3 minutes of steal protection after joining
Config.STEAL_PRICE_CAP = 16_000 -- players who have not rebirthed can only steal brainrots worth up to this
Config.BONK_RANGE = 10
Config.BONK_COOLDOWN = 0.8
Config.CARRY_SPEED = { -- thieves walk this much slower while carrying a brainrot
	Common = 0.9,
	Uncommon = 0.85,
	Rare = 0.8,
	Epic = 0.72,
	Legendary = 0.65,
	Mythic = 0.58,
}
Config.CARRY_MUTATION_SPEED = 0.93 -- extra slowdown for a mutated brainrot
Config.GUARD_RANGE = 12 -- the Chowkidar spots thieves this close to him
Config.GUARD_SPOT_TIME = 1.2 -- seconds a thief must stay in range before he catches them
Config.GUARD_COOLDOWN = 40 -- then he takes a nap

-- Rebirth ("Naya Safar")
Config.REBIRTH_COST = 1_000_000
Config.REBIRTH_COST_GROWTH = 2.5 -- every Naya Safar costs this many times more than the last
Config.REBIRTH_BONUS = 0.5 -- +50% income for every rebirth

function Config.rebirthCost(rebirths: number): number
	return math.floor(Config.REBIRTH_COST * Config.REBIRTH_COST_GROWTH ^ rebirths)
end

-- Daily chai
Config.DAILY_MIN_RUPEES = 500
Config.DAILY_INCOME_SECONDS = 120 -- the rupee reward is worth this many seconds of your income
Config.DAILY_FREE_ROLLS = 1 -- free Kismat Rolls with every daily chai

-- Kismat Roll (RNG): spend rupees or a roll for a random brainrot
Config.ROLL_RUPEE_COST = 5_000
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

-- Events: every 15-20 minutes a 5 minute event starts in each server
Config.FIRST_EVENT_DELAY = 180
Config.EVENT_GAP_MIN = 900
Config.EVENT_GAP_MAX = 1200
Config.EVENT_DURATION = 300

-- Quests
Config.QUESTS_PER_DAY = 3
Config.QUEST_REWARD_SECONDS = 60 -- each quest pays this many seconds of your income...
Config.QUEST_MIN_REWARD = 1_500 -- ...but never less than this
Config.QUEST_BONUS_ROLLS = 2 -- Kismat Rolls for finishing all of today's quests

-- Collection Book rewards for discovering every brainrot of a rarity.
-- Rupees and rolls are given once; the special brainrot can be claimed again after every Naya Safar.
Config.COLLECTION_REWARDS = {
	Common = { rupees = 4_000, rolls = 1, special = "MithaiMamu" },
	Uncommon = { rupees = 16_000, rolls = 2, special = "LassiLightning" },
	Rare = { rupees = 60_000, rolls = 3, special = "ChowkidarChoocha" },
	Epic = { rupees = 240_000, rolls = 4, special = "RangeelaRaja" },
	Legendary = { rupees = 1_000_000, rolls = 5, special = "ShalimarSultan" },
	Mythic = { rupees = 4_000_000, rolls = 10, special = "TaaronWalaTonga" },
}

-- World
Config.DAY_LENGTH = 720 -- seconds for a full day and night (nights go by twice as fast)
Config.AUTOSAVE_INTERVAL = 120
Config.DATASTORE_NAME = "ChaiChaos_v1"

return Config
