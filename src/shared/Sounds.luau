-- Every sound in the game, by name.
--
-- THE SOUND SHEET. Every sound effect, the ambience and three dhol and tumbi
-- music loops are made by tools/make_sounds.py and packed into ONE audio file,
-- assets/sounds/ChaiChaosSounds.ogg. Upload that file once (Creator Hub >
-- Creations > Audio > Upload, or Studio's Asset Manager > Import), copy its id
-- and paste it below as "rbxassetid://123456789". The game then plays just the
-- right part of the file for each sound (see SoundSheet.luau).
--
-- Until you do, each sound uses its `id` below: sounds that come with Roblox
-- (rbxasset://sounds/...). Engines and ambience stay quiet until the sheet is in.
--
-- YOUR OWN SOUNDS. To use your own sound for a name, paste its id as that
-- name's `id` and set `own = true` (the music slots use your id whenever it is
-- not empty).

local Sounds = {}

Sounds.SHEET = "" -- paste the uploaded ChaiChaosSounds.ogg id here: "rbxassetid://..."

export type Sound = {
	id: string,
	volume: number,
	pitch: number?,
	looped: boolean?,
	own: boolean?,
}

local PING = "rbxasset://sounds/electronicpingshort.wav"
local LAND = "rbxasset://sounds/action_jump_land.mp3"

Sounds.list = {
	-- buttons and money
	Click = { id = PING, volume = 0.25, pitch = 1.6 },
	Coin = { id = PING, volume = 0.5, pitch = 1.3 },
	Sell = { id = PING, volume = 0.6, pitch = 1.1 }, -- cha-ching at the BECHO stall
	Purchase = { id = PING, volume = 0.6, pitch = 0.9 },
	Error = { id = "rbxasset://sounds/action_get_up.mp3", volume = 0.5, pitch = 0.7 },

	-- eggs, treasure and catching
	EggPickup = { id = "rbxasset://sounds/action_jump.mp3", volume = 0.7, pitch = 1.3 },
	EggHome = { id = LAND, volume = 0.7, pitch = 1.2 },
	EggCrack = { id = "rbxasset://sounds/uuhhh.mp3", volume = 0.8 },
	EggHatch = { id = PING, volume = 0.8, pitch = 0.7 },
	Treasure = { id = PING, volume = 0.8, pitch = 1.1 },
	Catch = { id = PING, volume = 0.8, pitch = 0.8 }, -- a wild brainrot caught
	GateOpen = { id = PING, volume = 0.8, pitch = 0.75 }, -- a zone unlocked

	-- trouble
	Bonk = { id = LAND, volume = 1, pitch = 1.6 }, -- a chappal slap
	ChorAlert = { id = PING, volume = 1, pitch = 0.5 }, -- the chowkidar's whistle
	Splash = { id = "rbxasset://sounds/impact_water.mp3", volume = 0.9 },
	Wave = { id = "", volume = 0.6 }, -- a big wave rolling in at Sahil Beach
	Hit = { id = LAND, volume = 0.9, pitch = 0.8 },
	Snowball = { id = LAND, volume = 0.9, pitch = 1.1 },
	Rumble = { id = LAND, volume = 0.8, pitch = 0.5 }, -- a salt rock landing
	TrainHorn = { id = "", volume = 0.9 },
	CrossingBell = { id = "", volume = 0.6 },

	-- vehicles: every one has its own horn and engine
	HornBike = { id = PING, volume = 0.8, pitch = 0.75 },
	HornRickshaw = { id = PING, volume = 0.9, pitch = 0.58 },
	HornTaxi = { id = PING, volume = 0.9, pitch = 0.45 },
	HornTruck = { id = PING, volume = 1, pitch = 0.3 },
	EngineBike = { id = "", volume = 0.35, looped = true },
	EngineRickshaw = { id = "", volume = 0.4, looped = true },
	EngineTaxi = { id = "", volume = 0.35, looped = true },
	EngineTruck = { id = "", volume = 0.45, looped = true },
	Crash = { id = LAND, volume = 1, pitch = 0.6 },
	Fuel = { id = PING, volume = 0.6, pitch = 0.6 },

	-- big moments
	Upgrade = { id = PING, volume = 0.8, pitch = 1.2 },
	Rebirth = { id = PING, volume = 1, pitch = 0.6 },
	EventStart = { id = PING, volume = 0.9, pitch = 0.8 },
	RollSpin = { id = PING, volume = 0.2, pitch = 2 },
	RollReveal = { id = PING, volume = 0.8, pitch = 1 },

	-- all around you
	Wind = { id = "rbxasset://sounds/action_falling.mp3", volume = 0.5, looped = true },
	Fountain = { id = "", volume = 0.3, looped = true }, -- by the Chowk's fountain
	Birds = { id = "", volume = 0.35, looped = true }, -- in the green zones
	Sea = { id = "", volume = 0.45, looped = true }, -- on the beach and at the port

	-- music: dhol and tumbi from the sound sheet, or your own track's id
	MusicBazaar = { id = "", volume = 0.22, looped = true },
	MusicBiome = { id = "", volume = 0.2, looped = true },
	MusicEvent = { id = "", volume = 0.28, looped = true },
} :: { [string]: Sound }

return Sounds
