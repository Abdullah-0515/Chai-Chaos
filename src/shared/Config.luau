-- Every number you might want to tune while playtesting lives here.
-- The economy is tuned so a typical kid reaches their first Naya Safar in
-- about an hour (see README > Pacing).

local Config = {}

-- Money
Config.START_RUPEES = 1_000
Config.PRICE_MULTIPLIER = 2 -- brainrots are worth this many times their price in the design doc
Config.SELL_RATE = 0.5 -- sell for half the value
Config.SELL_DISTANCE = 22 -- how close to the Sell stall you must be to sell

-- Haveli levels: each level costs rupees, adds plots and sometimes a feature.
-- Plots 1-10 are on the ground floor, 11-20 on the second floor.
-- `incubators` is how many eggs can hatch at the same time.
Config.HAVELI_LEVELS = {
	{ plots = 4, incubators = 1, cost = 0, name = "Chhota Ghar" },
	{ plots = 6, incubators = 1, cost = 4_000, name = "Pakka Ghar" },
	{
		plots = 8,
		incubators = 2,
		cost = 12_000,
		name = "Laser Darwaza",
		unlock = "A second incubator, and the Laser Darwaza: your Taala blocks the door",
	},
	{ plots = 10, incubators = 2, cost = 30_000, name = "Bagh Wala Ghar", unlock = "A garden full of decorations" },
	{
		plots = 12,
		incubators = 3,
		cost = 80_000,
		name = "Do Manzila",
		unlock = "The second floor and a third incubator",
	},
	{ plots = 14, incubators = 3, cost = 180_000, name = "Chowkidar Wali", unlock = "A Chowkidar who catches thieves" },
	{ plots = 16, incubators = 4, cost = 350_000, name = "Bari Haveli", unlock = "A fourth incubator" },
	{
		plots = 18,
		incubators = 4,
		cost = 550_000,
		name = "Chhat Wali Haveli",
		unlock = "A rooftop with chhatris and kites",
	},
	{ plots = 20, incubators = 4, cost = 800_000, name = "Shahi Haveli", unlock = "The fanciest haveli in the bazaar" },
}
Config.LASER_LEVEL = 3
Config.GARDEN_LEVEL = 4
Config.UPPER_FLOOR_LEVEL = 5
Config.GUARD_LEVEL = 6
Config.ROOFTOP_LEVEL = 8
Config.LOCKER_PLOTS = 2 -- plots 1 and 2 can never be stolen from
Config.MAX_INCUBATORS = 4

-- Tracker (radar): shows eggs in every zone you have unlocked. Each level
-- sees further; level 3 finds golden eggs and level 5 treasure chests.
Config.TRACKER_LEVELS = {
	{ cost = 0, range = 180 },
	{ cost = 2_500, range = 220 },
	{ cost = 8_000, range = 260, golden = true },
	{ cost = 25_000, range = 300, golden = true },
	{ cost = 70_000, range = 340, golden = true, treasure = true },
	{ cost = 160_000, range = 390, golden = true, treasure = true },
	{ cost = 320_000, range = 440, golden = true, treasure = true },
	{ cost = 600_000, range = 520, golden = true, treasure = true },
}

-- Eggs
Config.EGGS_PER_BIOME = 8 -- eggs lying around in each zone at once
Config.EGG_RESPAWN = 6 -- seconds between new eggs in a biome that is short of eggs
Config.GOLDEN_EGG_CHANCE = 0.03 -- golden eggs always hatch a mutated brainrot and are luckier
Config.GOLDEN_EGG_LUCK = 2
Config.GOLDEN_EGG_TIME = 1.3 -- golden eggs last a bit longer...
Config.GOLDEN_HATCH_TIME = 1.5 -- ...and take longer to hatch
Config.EGG_HIT_PENALTY = 8 -- seconds a hazard knocks off a carried egg
Config.DROPPED_EGG_LIFETIME = 60 -- a dropped egg disappears after this long
Config.EGG_RUSH_EVERY = 240 -- an egg rush in a random zone every 4 minutes
Config.EGG_RUSH_DURATION = 60
Config.EGG_RUSH_EGGS = 14
Config.PICKUP_DISTANCE = 12

-- Treasure chests (need a Rope Ladder for cliff tops, a Shovel for buried ones)
Config.TREASURE_COOLDOWN = 600 -- each player can open each chest once every 10 minutes
Config.TREASURE_RUPEES = 1_200 -- times the zone's tier squared
Config.TREASURE_ROLL_CHANCE = 0.35 -- chance of a free Kismat Roll too

-- Vehicles (see Vehicles.luau for each vehicle's speed, tank and egg space)
Config.FUEL_PRICE = 0.25 -- rupees for every stud of fuel at a petrol pump
Config.FUEL_HOME_REFILL = 40 -- studs of fuel per second, free, while you are at your haveli
Config.PARK_DISTANCE = 14 -- driving this close to your own door parks your vehicle
Config.PUMP_DISTANCE = 16 -- how close to a petrol pump you must be to fill up
Config.DRIVE_SURFACE_SPEED = { mud = 0.6, sand = 0.75, sandstorm = 0.7, ice = 0.8, water = 0.45 }
-- Robux paint jobs (looks only): Developer Product ids. A paint with id = 0 is hidden.
Config.PAINT_PRODUCTS = {
	PhoolPatti = 0,
	Sona = 0,
	Rangeela = 0,
	Chamak = 0,
}

-- Blender props (see the README). If the imported meshes all face backwards,
-- set this to 180.
Config.PROP_MESH_TURN = 0

-- Players
Config.WALK_SPEED = 20 -- a bit faster than Roblox's 16, the world is big
Config.FUEL_EMPTY_SPEED = Config.WALK_SPEED -- a vehicle with an empty tank only goes this fast
Config.PROMPT_DISTANCE = 12 -- how close you must be to press E
Config.WALK_HOME_SPEED = 22 -- studs per second when a brainrot walks to its plot

-- Hazards (see Biomes.luau for which zone has which)
Config.HAZARD_SPEED = { water = 0.6, mud = 0.55, ice = 0.7, sandstorm = 0.65 }
Config.HAZARD_EGG_DRAIN = { water = 2, ice = 1.5, sandstorm = 2 } -- eggs crack this many times faster
Config.SANDSTORM_EVERY = 50
Config.SANDSTORM_DURATION = 15
Config.WAVE_EVERY = 35
Config.SNOWBALL_EVERY = 20
Config.SALT_FALL_EVERY = 6 -- a salt rock falls near someone in the Namak Caves this often
Config.SALT_WARNING = 1.5 -- seconds the red circle shows before the rock lands
Config.SALT_RADIUS = 7
-- The train in Railway Junction: it waits, the crossing light blinks, then it runs the track
Config.TRAIN_WAIT = 9
Config.TRAIN_BLINK = 3.2
Config.TRAIN_SPEED = 40
Config.TRAIN_HIT_RADIUS = 9
Config.KNOCKBACK = 70 -- how hard the train, waves and salt rocks push you (they never hurt)

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
	Secret = 0.5,
}
Config.CARRY_MUTATION_SPEED = 0.93 -- extra slowdown for a mutated brainrot
Config.GUARD_RANGE = 12 -- the Chowkidar spots thieves this close to him
Config.GUARD_SPOT_TIME = 1.2 -- seconds a thief must stay in range before he catches them
Config.GUARD_COOLDOWN = 40 -- then he takes a nap

-- Rebirth ("Naya Safar"). Resets rupees, haveli, tracker and brainrots; keeps gear,
-- themes, the Collection Book and Kismat Rolls.
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
	Secret = { rupees = 20_000_000, rolls = 20 },
}

-- World
Config.DAY_LENGTH = 720 -- seconds for a full day and night (nights go by twice as fast)
Config.AUTOSAVE_INTERVAL = 120
Config.DATASTORE_NAME = "ChaiChaos_v1"

return Config
