-- Sounds on this player's screen:
-- * sounds the server asks for (eggs, coins, bonks, treasure...)
-- * a click for every button in the HUD
-- * music for where you are (dhol and tumbi from the sound sheet, or your own)
-- * all around you: the fountain in the Chowk, birds in the green zones, the sea
--   at the beach and the port, wind up in the mountains and in sandstorms
-- * your vehicle's engine, revving with your speed
-- * the crossing bell and the train's horn at Railway Junction, and the whoosh
--   of a big wave at Sahil Beach

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Biomes = require(Shared:WaitForChild("Biomes"))
local Config = require(Shared:WaitForChild("Config"))
local Events = require(Shared:WaitForChild("Events"))
local Vehicles = require(Shared:WaitForChild("Vehicles"))
local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChaiChaosHud")

local BIRDS = { MangoBagh = true, SarsonFields = true, LahoreQila = true, QissaKhawani = true, RailwayJunction = true }
local SEA = { KarachiPort = true }
local FOUNTAIN_RANGE = Biomes.PLAZA_RADIUS + 20

Remotes.PlaySound.OnClientEvent:Connect(function(name: any, position: any, pitch: any)
	if type(name) == "string" then
		SoundPlayer.play(
			name,
			if typeof(position) == "Vector3" then position else nil,
			if type(pitch) == "number" then pitch else nil
		)
	end
end)

-- a click for every HUD button, including ones made later
local function hook(instance: Instance)
	if instance:IsA("GuiButton") then
		instance.Activated:Connect(function()
			SoundPlayer.play("Click")
		end)
	end
end
gui.DescendantAdded:Connect(hook)
for _, descendant in gui:GetDescendants() do
	hook(descendant)
end

local function rootPart(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function has(biome, hazard: string): boolean
	return biome ~= nil and table.find(biome.hazards, hazard) ~= nil
end

-- music and the sounds all around you, once a second
local function update()
	local root = rootPart()
	local biome = if root then Biomes.at(root.Position) else nil
	local music = if Events.current() then "MusicEvent" elseif biome then "MusicBiome" else "MusicBazaar"
	for _, name in { "MusicBazaar", "MusicBiome", "MusicEvent" } do
		SoundPlayer.loop(name, name == music)
	end
	-- windy in the snowy mountains, and in the desert during a sandstorm
	local windy = has(biome, "snowballs") or (has(biome, "sandstorm") and workspace:GetAttribute("Sandstorm") == true)
	SoundPlayer.loop("Wind", windy)
	local nearFountain = root ~= nil and (root.Position * Vector3.new(1, 0, 1)).Magnitude < FOUNTAIN_RANGE
	SoundPlayer.loop("Fountain", nearFountain)
	SoundPlayer.loop("Birds", biome ~= nil and BIRDS[biome.id] == true)
	SoundPlayer.loop("Sea", has(biome, "waves") or (biome ~= nil and SEA[biome.id] == true))
end

-- your engine, revving with your speed
local engineOn: string? = nil
local function updateEngine()
	local def = Vehicles.byId[player:GetAttribute("Driving") or ""]
	local root = rootPart()
	local name = if def and root then "Engine" .. def.sound else nil
	if engineOn and engineOn ~= name then
		SoundPlayer.loop(engineOn, false)
	end
	engineOn = name
	if name and def and root then
		SoundPlayer.loop(name, true)
		local v = root.AssemblyLinearVelocity
		local speed = if typeof(v) == "Vector3" then Vector3.new(v.X, 0, v.Z).Magnitude else 0
		SoundPlayer.setPitch(name, 0.75 + 0.6 * math.clamp(speed / def.speed, 0, 1))
	end
end

-- Railway Junction: the crossing bell rings, then the train sounds its horn
local light = "green"
local function updateTrain()
	local root = rootPart()
	local biome = if root then Biomes.at(root.Position) else nil
	local _, _, now =
		Biomes.trainAt(workspace:GetServerTimeNow(), Config.TRAIN_WAIT, Config.TRAIN_BLINK, Config.TRAIN_SPEED)
	if now ~= light and biome and biome.id == Biomes.TRAIN.zone then
		-- heard all over the zone (the track is long)
		if now == "blink" then
			SoundPlayer.play("CrossingBell")
		elseif now == "red" then
			SoundPlayer.play("TrainHorn")
		end
	end
	light = now
end

-- Sahil Beach: the whoosh of a big wave coming in
workspace:GetAttributeChangedSignal("WaveAt"):Connect(function()
	local root = rootPart()
	if root and has(Biomes.at(root.Position), "waves") then
		SoundPlayer.play("Wave")
	end
end)

task.spawn(function()
	local tick = 0
	while gui.Parent do
		updateEngine()
		updateTrain()
		if tick % 4 == 0 then
			update()
		end
		tick += 1
		task.wait(0.25)
	end
end)
