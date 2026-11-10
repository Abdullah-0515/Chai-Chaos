-- Every sound in the game, by name.
--
-- The defaults are sounds that come with Roblox (rbxasset://sounds/...).
-- To use your own, find a sound in the Creator Store (Toolbox > Audio), copy
-- its id and paste it as "rbxassetid://123456789". An empty id plays nothing.
-- Music is empty until you add some: try searching the Creator Store for
-- "dhol", "tabla", "bazaar" or "desi".

local Sounds = {}

export type Sound = {
	id: string,
	volume: number,
	pitch: number?,
	looped: boolean?,
}

Sounds.list = {
	-- buttons and money
	Click = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.25, pitch = 1.6 },
	Coin = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.5, pitch = 1.3 },
	Purchase = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.6, pitch = 0.9 },
	Error = { id = "rbxasset://sounds/action_get_up.mp3", volume = 0.5, pitch = 0.7 },

	-- eggs
	EggPickup = { id = "rbxasset://sounds/action_jump.mp3", volume = 0.7, pitch = 1.3 },
	EggHome = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 0.7, pitch = 1.2 },
	EggCrack = { id = "rbxasset://sounds/uuhhh.mp3", volume = 0.8 },
	EggHatch = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.8, pitch = 0.7 },
	Treasure = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.8, pitch = 1.1 },

	-- trouble
	Bonk = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 1, pitch = 1.6 },
	ChorAlert = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 1, pitch = 0.5 },
	Splash = { id = "rbxasset://sounds/impact_water.mp3", volume = 0.9 },
	Hit = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 0.9, pitch = 0.8 },
	Wind = { id = "rbxasset://sounds/action_falling.mp3", volume = 0.5, looped = true },

	-- vehicles. The horn is a beep for now: find a real one in the Creator
	-- Store (search "car horn" or "rickshaw horn") and paste its id here.
	Horn = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.9, pitch = 0.5 },
	Crash = { id = "rbxasset://sounds/action_jump_land.mp3", volume = 1, pitch = 0.6 },

	-- big moments
	Upgrade = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.8, pitch = 1.2 },
	Rebirth = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 1, pitch = 0.6 },
	EventStart = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.9, pitch = 0.8 },
	RollSpin = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.2, pitch = 2 },
	RollReveal = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.8, pitch = 1 },

	-- music (add your own ids)
	MusicBazaar = { id = "", volume = 0.25, looped = true },
	MusicBiome = { id = "", volume = 0.25, looped = true },
	MusicEvent = { id = "", volume = 0.3, looped = true },
} :: { [string]: Sound }

return Sounds
