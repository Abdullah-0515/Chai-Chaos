-- The guide for new players: one small step at a time, with an arrow to
-- follow. The server keeps your step (Tutorial.luau in the server folder) and
-- your screen shows it (Tutorial.client.luau).
--
-- target : where the arrow points
--          "zone:<id>" a zone's gate, "egg" the nearest egg in an open zone,
--          "home" your haveli door, "showroom" the Gaari Showroom, nil no arrow
-- done   : what you have to do (the same names quests use, see State.track)

local Config = require(script.Parent.Config)
local Biomes = require(script.Parent.Biomes)
local Format = require(script.Parent.Format)
local Vehicles = require(script.Parent.Vehicles)

local Tutorial = {}

export type Step = { id: string, text: string, target: string?, done: string }

local firstVehicle = Vehicles.list[1]
local firstZone = Biomes.byId.RailwayJunction

Tutorial.steps = {
	{
		id = "leave",
		text = "Follow the arrow out of the town gate to Mango Bagh",
		target = "zone:MangoBagh",
		done = "enterZone",
	},
	{
		id = "egg",
		text = "Find an egg (the dots on your radar) and hold E to pick it up",
		target = "egg",
		done = "eggPickup",
	},
	{ id = "home", text = "Carry the egg home before its timer runs out!", target = "home", done = "eggHome" },
	{ id = "hatch", text = "Your egg is hatching. Wait for your brainrot!", target = "home", done = "hatch" },
	{
		id = "collect",
		text = "Brainrots earn rupees every second. Walk into your galla to collect them",
		target = "home",
		done = "collect",
	},
	{
		id = "vehicle",
		text = ("Keep hunting eggs. With %s, buy a %s at the Gaari Showroom"):format(
			Format.rupees(firstVehicle.cost),
			firstVehicle.name
		),
		target = "showroom",
		done = "vehicle",
	},
	{ id = "drive", text = "Step outside, press Gaari, then Drive. Press H to honk!", target = nil, done = "drive" },
	{
		id = "zone",
		text = ("Save %s and unlock %s at its gate for rarer brainrots"):format(
			Format.rupees(firstZone.price),
			firstZone.name
		),
		target = "zone:" .. firstZone.id,
		done = "zone",
	},
} :: { Step }

Tutorial.byId = {} :: { [string]: Step }
for _, step in Tutorial.steps do
	Tutorial.byId[step.id] = step
end

Tutorial.REWARD_ROLLS = 2 -- Kismat Rolls for finishing the guide (once)
Tutorial.DONE = #Tutorial.steps + 1

local _ = Config
return Tutorial
