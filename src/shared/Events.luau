-- Multiplier events. Every 15-20 minutes one of these runs for 5 minutes.
--
-- cashMult     : everyone's income is multiplied
-- luckMult     : rarer brainrots and mutations are likelier in eggs
-- eggMult      : more eggs lie around in every biome
-- eggTimeMult  : eggs last longer before breaking
-- hatchMult    : eggs hatch faster
-- rollDiscount : Kismat Rolls cost this much less (0.3 = 30% off)
-- night        : it is night during the event
-- look         : which effects clients show (kites, rain, cricket, blackout, mela, snow)

local Events = {}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

export type Event = {
	id: string,
	name: string,
	blurb: string,
	color: Color3,
	look: string,
	cashMult: number?,
	luckMult: number?,
	eggMult: number?,
	eggTimeMult: number?,
	hatchMult: number?,
	rollDiscount: number?,
	night: boolean?,
}

Events.list = {
	{
		id = "Basant",
		name = "Basant Kite Festival",
		blurb = "Kites fill the sky! Cash x2 and Luck x2!",
		color = rgb(255, 215, 40),
		look = "kites",
		cashMult = 2,
		luckMult = 2,
	},
	{
		id = "Baarish",
		name = "Baarish!",
		blurb = "It's raining eggs! Twice as many eggs in every biome.",
		color = rgb(90, 160, 255),
		look = "rain",
		eggMult = 2,
		cashMult = 1.2,
	},
	{
		id = "CricketMania",
		name = "Cricket Mania",
		blurb = "Sixer! Cash x1.5 for everyone.",
		color = rgb(60, 200, 90),
		look = "cricket",
		cashMult = 1.5,
	},
	{
		id = "LoadShedding",
		name = "Load Shedding!",
		blurb = "Light gayi! In the dark, Luck x3 for glowing mutations.",
		color = rgb(150, 110, 255),
		look = "blackout",
		luckMult = 3,
		night = true,
	},
	{
		id = "MelaNight",
		name = "Mela Night",
		blurb = "Fireworks! Eggs hatch twice as fast and Kismat Rolls are 30% off.",
		color = rgb(255, 110, 200),
		look = "mela",
		hatchMult = 2,
		rollDiscount = 0.3,
	},
	{
		id = "Sardi",
		name = "Sardi Aa Gayi",
		blurb = "Winter! Cold keeps eggs fresh: eggs last 50% longer.",
		color = rgb(200, 235, 255),
		look = "snow",
		eggTimeMult = 1.5,
	},
} :: { Event }

Events.byId = {} :: { [string]: Event }
for _, event in Events.list do
	Events.byId[event.id] = event
end

-- The running event, read from workspace attributes (works on server and client).
function Events.current(): Event?
	local id = workspace:GetAttribute("EventId")
	return if type(id) == "string" then Events.byId[id] else nil
end

-- A multiplier from the running event, or 1.
function Events.mult(field: string): number
	local event = Events.current()
	return if event then (event :: any)[field] or 1 else 1
end

return Events
