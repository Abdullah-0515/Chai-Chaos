-- Server events. Every 15-20 minutes one of these runs for 5 minutes.
--
-- boosts       : these brainrots spawn this many times more often on the lane
-- incomeMult   : everyone's income is multiplied
-- mutationMult : mutation chances are multiplied (lane and Kismat Rolls)
-- spawnRate    : the lane spawns this many times faster
-- rollDiscount : Kismat Rolls cost this much less (0.3 = 30% off)
-- night        : it is night during the event (night-only brainrots come out)
-- look         : which effects clients show (rain, kites, cricket, blackout, mela, snow)

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
	boosts: { [string]: number },
	incomeMult: number?,
	mutationMult: number?,
	spawnRate: number?,
	rollDiscount: number?,
	night: boolean?,
}

Events.list = {
	{
		id = "Baarish",
		name = "Baarish!",
		blurb = "It's raining! Pakora Panda is out and every brainrot earns +20%.",
		color = rgb(90, 160, 255),
		look = "rain",
		boosts = { PakoraPanda = 6, ChaiyooKettlesaurus = 3, DoodhPattiDolphin = 3 },
		incomeMult = 1.2,
	},
	{
		id = "Basant",
		name = "Basant Kite Night",
		blurb = "Kites everywhere! Flying brainrots spawn more and mutations are twice as likely.",
		color = rgb(255, 215, 40),
		look = "kites",
		boosts = { KiteKaptaan = 8, ParathaPilot = 3, GolGappaGhostu = 3, TruckArtTotaa = 3 },
		mutationMult = 2,
	},
	{
		id = "CricketMania",
		name = "Cricket Mania",
		blurb = "Sixer Sher spawns way more and everything earns +50%!",
		color = rgb(60, 200, 90),
		look = "cricket",
		boosts = { SixerSher = 10, CricketBatBhaijaan = 5 },
		incomeMult = 1.5,
	},
	{
		id = "LoadShedding",
		name = "Load Shedding!",
		blurb = "Light gayi! It's dark, night brainrots come out and Diamond and Rainbow glow 3x more often.",
		color = rgb(150, 110, 255),
		look = "blackout",
		boosts = { LoadSheddingLattoo = 8, GeneratorGainda = 8 },
		mutationMult = 3,
		night = true,
	},
	{
		id = "MelaNight",
		name = "Mela Night",
		blurb = "The mela is here! Kismat Rolls cost 30% less and Mela Maharaja spawns more.",
		color = rgb(255, 110, 200),
		look = "mela",
		boosts = { MelaMaharaja = 8, DholakDino = 4, JalebiJinn = 4 },
		rollDiscount = 0.3,
	},
	{
		id = "Sardi",
		name = "Sardi Aa Gayi",
		blurb = "Winter! Gajar Halwa Gorilla is out and the lane spawns twice as fast.",
		color = rgb(200, 235, 255),
		look = "snow",
		boosts = { GajarHalwaGorilla = 6, KulfiKangaroo = 3, ChaiyooKettlesaurus = 3 },
		spawnRate = 2,
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

return Events
