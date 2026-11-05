-- Biome hazards. Gear from the Chowk's Gear shop protects against each one.
--
--   water     (Jungle river, Samandar sea, Jheel lake, Delta pools) : Life Jacket
--   mud       (Khet paddies, all of Delta)                           : Gum Boots
--   ice       (Pahar frozen lake and glaciers)                       : Snow Boots
--   sandstorm (Registan, every so often)                             : Sand Goggles
--   waves     (Samandar beach, every so often)                       : Life Jacket
--   snowballs (Pahar, every so often)                                : Snow Boots
--   salt      (Namak Kaan, falling salt; it is also dark there)      : Lantern
--
-- Standing in water, mud, ice or a sandstorm slows you down (and water, ice and
-- sandstorms make a carried egg crack faster). Waves, snowballs and falling
-- salt knock time off a carried egg.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Biomes = require(Shared.Biomes)
local Gear = require(Shared.Gear)

local State = require(script.Parent.State)
local Havelis = require(script.Parent.Havelis)
local BiomeBuilder = require(script.Parent.BiomeBuilder)
local EggSystem = require(script.Parent.EggSystem)

local Hazards = {}

local GEAR_FOR = {
	water = "Life Jacket",
	mud = "Gum Boots",
	ice = "Snow Boots",
	sandstorm = "Sand Goggles",
	waves = "Life Jacket",
	snowballs = "Snow Boots",
	salt = "Lantern",
}

local map = nil

local function now(): number
	return workspace:GetServerTimeNow()
end

local function sandstorm(): boolean
	return workspace:GetAttribute("Sandstorm") == true
end

-- The hazard a player is standing in right now that their gear does not
-- protect them from, if any.
function Hazards.standingIn(profile, position: Vector3): string?
	local biome = Biomes.at(position)
	if not biome then
		return nil
	end
	local plan = map.biomes[biome.id]
	local owned = profile.data.gear
	local function hits(kind: string): boolean
		return BiomeBuilder.inZone(plan, position, kind) and not Gear.protects(owned, kind)
	end
	if position.Y < Biomes.GROUND_Y + 4 and hits("water") then
		return "water"
	elseif hits("ice") then
		return "ice"
	elseif hits("mud") then
		return "mud"
	elseif sandstorm() and hits("sandstorm") then
		return "sandstorm"
	end
	return nil
end

function Hazards.tick()
	for player, profile in State.profiles do
		local root = State.rootPart(player)
		local hazard = if root then Hazards.standingIn(profile, root.Position) else nil
		local speed = if hazard then Config.HAZARD_SPEED[hazard] or 1 else 1
		local drain = if hazard then Config.HAZARD_EGG_DRAIN[hazard] or 1 else 1
		if profile.hazardSpeed ~= speed then
			profile.hazardSpeed = speed
			Havelis.applyWalkSpeed(profile)
		end
		profile.eggDrain = drain
		local text = if hazard
			then ("%s! %s helps"):format(hazard:sub(1, 1):upper() .. hazard:sub(2), GEAR_FOR[hazard])
			else ""
		if player:GetAttribute("Hazard") ~= text then
			player:SetAttribute("Hazard", text)
		end
	end
end

-- Hits every unprotected player in a biome (waves, snowballs, salt), or only
-- in some of its zones. Each player is hit at most once.
local function strike(biomeId: string, zoneKinds: { string }?, hazard: string, sound: string, message: string)
	local plan = map.biomes[biomeId]
	for player, profile in State.profiles do
		local root = State.rootPart(player)
		if root then
			local biome = Biomes.at(root.Position)
			local inZone = zoneKinds == nil
			for _, kind in zoneKinds or {} do
				inZone = inZone or BiomeBuilder.inZone(plan, root.Position, kind)
			end
			local hitZone = biome and biome.id == biomeId and inZone
			if hitZone then
				local protected = Gear.protects(
					profile.data.gear,
					if hazard == "waves" then "water" elseif hazard == "snowballs" then "ice" else "dark"
				)
				State.sound(player, sound, root.Position)
				if not protected then
					EggSystem.hit(player, Config.EGG_HIT_PENALTY, message)
				end
			end
		end
	end
end

function Hazards.wave()
	workspace:SetAttribute("WaveAt", now())
	strike("Samandar", { "shore", "water" }, "waves", "Splash", "SPLASH! A big wave got you!")
end

function Hazards.snowball()
	strike("Pahar", nil, "snowballs", "Hit", "THWACK! A snowball hit you!")
end

function Hazards.salt()
	strike("NamakKaan", nil, "salt", "Hit", "Ouch! Falling salt!")
end

function Hazards.init(gameMap)
	map = gameMap
	workspace:SetAttribute("Sandstorm", false)
	task.spawn(function()
		while true do
			task.wait(0.25)
			Hazards.tick()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.SANDSTORM_EVERY)
			workspace:SetAttribute("Sandstorm", true)
			task.wait(Config.SANDSTORM_DURATION)
			workspace:SetAttribute("Sandstorm", false)
		end
	end)
	for _, timer in
		{
			{ Config.WAVE_EVERY, Hazards.wave },
			{ Config.SNOWBALL_EVERY, Hazards.snowball },
			{ Config.SALT_FALL_EVERY, Hazards.salt },
		}
	do
		task.spawn(function()
			while true do
				task.wait(timer[1])
				timer[2]()
			end
		end)
	end
end

return Hazards
