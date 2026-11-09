-- Zone hazards. They slow you down, knock you back and knock time off your
-- eggs, but they never hurt you. Gear from the Chowk's Gear shop protects
-- you on foot; a vehicle's tyres (Grip) protect it.
--
--   train     (Railway Junction: watch the crossing light!)     : nothing, just dodge it
--   water     (Sahil Beach and Karachi Port sea, Lahore's moat) : Life Jacket
--   waves     (Sahil Beach, every so often)                     : Life Jacket
--   mud       (Mango Bagh puddles, Sarson Fields paths)         : Gum Boots (Grip 1 in a vehicle)
--   sandstorm (Thar Desert and Mohenjo-daro, every so often)    : Sand Goggles (Grip 2)
--   salt      (Namak Caves: rocks fall on the red circles)      : Lantern
--   ice       (Barfani Pahar's frozen lakes)                    : Snow Boots (Grip 3)
--   snowballs (Barfani Pahar, every so often)                   : Snow Boots
--
-- Sand (Sahil Beach, Thar Desert, Mohenjo-daro) slows vehicles without Grip 2.
-- The roads are always safe: no water, mud or ice on a road.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Biomes = require(Shared.Biomes)
local Gear = require(Shared.Gear)
local Vehicles = require(Shared.Vehicles)

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
local pushedAt: { [Player]: number } = {}
local rockFolder: Folder = nil

local function now(): number
	return workspace:GetServerTimeNow()
end

local function sandstorm(): boolean
	return workspace:GetAttribute("Sandstorm") == true
end

local function has(biome, hazard: string): boolean
	return table.find(biome.hazards, hazard) ~= nil
end

-- What is under a position in a zone: water, ice, mud, sandstorm, sand or nil.
function Hazards.surfaceAt(position: Vector3): string?
	local biome = Biomes.at(position)
	if not biome then
		return nil
	end
	local plan = map.biomes[biome.id]
	local onRoad = Biomes.roadDistance(position) < 0
	if not onRoad then
		if position.Y < Biomes.GROUND_Y + 4 and BiomeBuilder.inZone(plan, position, "water") then
			return "water"
		elseif BiomeBuilder.inZone(plan, position, "ice") then
			return "ice"
		elseif BiomeBuilder.inZone(plan, position, "mud") then
			return "mud"
		end
	end
	if sandstorm() and BiomeBuilder.inZone(plan, position, "sandstorm") then
		return "sandstorm"
	end
	if not onRoad and (BiomeBuilder.inZone(plan, position, "sand") or BiomeBuilder.inZone(plan, position, "shore")) then
		return "sand"
	end
	return nil
end

-- The hazard a player on foot is standing in right now that their gear does
-- not protect them from, if any.
function Hazards.standingIn(profile, position: Vector3): string?
	local surface = Hazards.surfaceAt(position)
	if surface == nil or surface == "sand" then
		return nil
	end
	if Gear.protects(profile.data.gear, surface) then
		return nil
	end
	return surface
end

function Hazards.tick()
	for player, profile in State.profiles do
		local root = State.rootPart(player)
		local drive = profile.driving
		local text = ""
		if drive then
			-- in a vehicle: good tyres get you through mud, sand and ice
			local surface = if root then Hazards.surfaceAt(root.Position) else nil
			local slow = surface ~= nil and not Vehicles.handles(drive.grip, surface)
			local speed = if slow then Config.DRIVE_SURFACE_SPEED[surface :: string] or 1 else 1
			if profile.surfaceSpeed ~= speed then
				profile.surfaceSpeed = speed
				Havelis.applyWalkSpeed(profile)
			end
			profile.eggDrain = if surface == "water" or surface == "sandstorm"
				then Config.HAZARD_EGG_DRAIN[surface] or 1
				else 1
			if slow then
				local needed = Vehicles.GRIP_NEEDED[surface :: string]
				text = if needed
					then ("%s! Tyres level %d drive right through"):format(
						(surface :: string):sub(1, 1):upper() .. (surface :: string):sub(2),
						needed
					)
					else "Deep water! Vehicles go slowly here"
			end
			if profile.hazardSpeed ~= 1 then
				profile.hazardSpeed = 1
			end
		else
			local hazard = if root then Hazards.standingIn(profile, root.Position) else nil
			local speed = if hazard then Config.HAZARD_SPEED[hazard] or 1 else 1
			if profile.hazardSpeed ~= speed then
				profile.hazardSpeed = speed
				Havelis.applyWalkSpeed(profile)
			end
			profile.eggDrain = if hazard then Config.HAZARD_EGG_DRAIN[hazard] or 1 else 1
			if hazard then
				text = ("%s! %s helps"):format(hazard:sub(1, 1):upper() .. hazard:sub(2), GEAR_FOR[hazard])
			end
		end
		if player:GetAttribute("Hazard") ~= text then
			player:SetAttribute("Hazard", text)
		end
	end
end

-- Pushes a player away from `from` (never hurts). Works in vehicles too.
function Hazards.push(player: Player, from: Vector3, power: number?)
	local root = State.rootPart(player)
	if not root then
		return
	end
	local t = now()
	if t - (pushedAt[player] or 0) < 1 then
		return
	end
	pushedAt[player] = t
	local away = (root.Position - from) * Vector3.new(1, 0, 1)
	if away.Magnitude < 0.1 then
		away = Vector3.new(0, 0, 1)
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "KnockAttachment"
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "Knockback"
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = away.Unit * (power or Config.KNOCKBACK) + Vector3.new(0, 40, 0)
	velocity.Parent = root
	Debris:AddItem(attachment, 0.25)
	Debris:AddItem(velocity, 0.25)
end

-- Hits every unprotected player in a zone (waves, snowballs), or only in some
-- of its hazard areas. Each player is hit at most once.
local function strike(biomeId: string, zoneKinds: { string }?, protectedBy: string, sound: string, message: string)
	local plan = map.biomes[biomeId]
	for player, profile in State.profiles do
		local root = State.rootPart(player)
		if root then
			local biome = Biomes.at(root.Position)
			local inArea = zoneKinds == nil
			for _, kind in zoneKinds or {} do
				inArea = inArea or BiomeBuilder.inZone(plan, root.Position, kind)
			end
			if biome and biome.id == biomeId and inArea then
				State.sound(player, sound, root.Position)
				if not Gear.protects(profile.data.gear, protectedBy) then
					EggSystem.hit(player, Config.EGG_HIT_PENALTY, message)
					if sound == "Splash" then
						-- the wave pushes you back towards the land
						Hazards.push(player, root.Position * 1.2, Config.KNOCKBACK * 0.8)
					end
				end
			end
		end
	end
end

local function zoneWith(hazard: string): { string }
	local list = {}
	for _, biome in Biomes.list do
		if has(biome, hazard) then
			table.insert(list, biome.id)
		end
	end
	return list
end

function Hazards.wave()
	workspace:SetAttribute("WaveAt", now())
	for _, id in zoneWith("waves") do
		strike(id, { "shore", "water" }, "water", "Splash", "SPLASH! A big wave got you!")
	end
end

function Hazards.snowball()
	for _, id in zoneWith("snowballs") do
		strike(id, nil, "ice", "Hit", "THWACK! A snowball hit you!")
	end
end

-- Namak Caves: a red circle appears near every player there, then a salt rock
-- lands on it. Step out of the circle! A Lantern lets you see them coming.
function Hazards.salt()
	for player in State.profiles do
		local root = State.rootPart(player)
		local biome = root and Biomes.at(root.Position)
		if root and biome and has(biome, "salt") then
			local a = math.random() * math.pi * 2
			local spot = Vector3.new(
				root.Position.X + math.cos(a) * math.random() * 5,
				Biomes.GROUND_Y,
				root.Position.Z + math.sin(a) * math.random() * 5
			)
			local mark = Instance.new("Part")
			mark.Name = "SaltWarning"
			mark.Shape = Enum.PartType.Cylinder
			mark.Size = Vector3.new(0.3, Config.SALT_RADIUS * 2, Config.SALT_RADIUS * 2)
			mark.CFrame = CFrame.new(spot + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
			mark.Anchored = true
			mark.CanCollide = false
			mark.CanQuery = false
			mark.Material = Enum.Material.Neon
			mark.Color = Color3.fromRGB(255, 60, 60)
			mark.Transparency = 0.3
			mark.Parent = rockFolder
			Debris:AddItem(mark, Config.SALT_WARNING + 0.5)
			task.delay(Config.SALT_WARNING, function()
				local rock = Instance.new("Part")
				rock.Name = "SaltRock"
				rock.Shape = Enum.PartType.Ball
				rock.Size = Vector3.one * 6
				rock.Color = Color3.fromRGB(245, 170, 185)
				rock.Material = Enum.Material.Glass
				rock.Anchored = true
				rock.CanCollide = false
				rock.CFrame = CFrame.new(spot + Vector3.new(0, 3, 0))
				rock.Parent = rockFolder
				Debris:AddItem(rock, 1.5)
				for other, profile in State.profiles do
					local r = State.rootPart(other)
					if r and ((r.Position - spot) * Vector3.new(1, 0, 1)).Magnitude < Config.SALT_RADIUS then
						State.sound(other, "Hit", spot)
						if not Gear.protects(profile.data.gear, "dark") then
							EggSystem.hit(other, Config.EGG_HIT_PENALTY, "Ouch! A salt rock fell on you!")
							Hazards.push(other, spot)
						end
					end
				end
			end)
		end
	end
end

-- Railway Junction: the train runs the curved track (see Biomes.trainAt).
function Hazards.trainTick()
	local train = Biomes.TRAIN
	local angle, moving = Biomes.trainAt(now(), Config.TRAIN_WAIT, Config.TRAIN_BLINK, Config.TRAIN_SPEED)
	if not moving then
		return
	end
	local halfAngle = math.deg(train.length / 2 / train.radius)
	for player in State.profiles do
		local root = State.rootPart(player)
		if root then
			local r = Biomes.radiusOf(root.Position)
			local off = math.abs(Biomes.angleDiff(Biomes.angleOf(root.Position), angle))
			if
				math.abs(r - train.radius) < Config.TRAIN_HIT_RADIUS - 3
				and off < halfAngle
				and root.Position.Y < 20
			then
				local trackPoint = Biomes.polar(Biomes.angleOf(root.Position), train.radius)
				State.sound(player, "Hit", root.Position)
				EggSystem.hit(player, Config.EGG_HIT_PENALTY, "TOOT TOOT! The train bumped you off the track!")
				Hazards.push(player, trackPoint, Config.KNOCKBACK * 1.2)
			end
		end
	end
end

function Hazards.init(gameMap)
	map = gameMap
	rockFolder = Instance.new("Folder")
	rockFolder.Name = "ChaiChaosHazards"
	rockFolder.Parent = workspace
	workspace:SetAttribute("Sandstorm", false)
	task.spawn(function()
		while true do
			task.wait(0.25)
			Hazards.tick()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			Hazards.trainTick()
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
