-- Treasure chests hidden in every zone.
--
-- "dig" chests are buried under an X: you need a Belcha (shovel) to dig them up.
-- "climb" chests sit on a clock tower, a fort gate, a crane or an ice cave:
-- you need a Rassi Seedhi (rope ladder) to climb up from the marked spot.
-- Each player can open each chest once every 10 minutes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Biomes = require(Shared.Biomes)

local State = require(script.Parent.State)
local Havelis = require(script.Parent.Havelis)

local Treasure = {}

local GOLD = Color3.fromRGB(255, 205, 50)

local chests = {} -- { model, biome, kind, opened = { [userId] = time } }

local function now(): number
	return workspace:GetServerTimeNow()
end

local function newPart(model: Instance, name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function prompt(parent: BasePart, name: string, action: string, object: string)
	local p = Instance.new("ProximityPrompt")
	p.Name = name
	p.ActionText = action
	p.ObjectText = object
	p.HoldDuration = 0.6
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function build(folder: Instance, biome, spot, index: number)
	local model = Instance.new("Model")
	model.Name = ("%sTreasure%d"):format(biome.id, index)
	local cf = CFrame.new(spot.position)
	if spot.kind == "dig" then
		local mound = newPart(
			model,
			"Mound",
			Vector3.new(6, 1, 6),
			cf * CFrame.new(0, 0.3, 0),
			biome.color:Lerp(Color3.new(0, 0, 0), 0.3)
		)
		mound.Material = Enum.Material.Ground
		for _, angle in { 45, -45 } do
			newPart(
				model,
				"X",
				Vector3.new(0.6, 0.2, 4.5),
				cf * CFrame.new(0, 0.85, 0) * CFrame.Angles(0, math.rad(angle), 0),
				Color3.fromRGB(200, 40, 40)
			)
		end
		model.PrimaryPart = mound
		prompt(mound, "TreasurePrompt", "Dig", "Buried Treasure (needs Belcha)")
	else
		local box =
			newPart(model, "Chest", Vector3.new(3.6, 2.4, 2.4), cf * CFrame.new(0, 1.2, 0), Color3.fromRGB(140, 85, 40))
		box.Material = Enum.Material.WoodPlanks
		newPart(model, "Lid", Vector3.new(3.8, 0.8, 2.6), cf * CFrame.new(0, 2.6, 0), Color3.fromRGB(120, 70, 35))
		local trim = newPart(model, "Trim", Vector3.new(3.9, 0.4, 2.7), cf * CFrame.new(0, 2.1, 0), GOLD)
		trim.Material = Enum.Material.Metal
		local glow = Instance.new("PointLight")
		glow.Color = GOLD
		glow.Range = 10
		glow.Parent = trim
		model.PrimaryPart = box
		prompt(box, "TreasurePrompt", "Open", "Treasure Chest")
		-- the place to climb up from
		local base = newPart(
			model,
			"ClimbSpot",
			Vector3.new(5, 0.4, 5),
			CFrame.new(spot.base + Vector3.new(0, 0.3, 0)),
			Color3.fromRGB(255, 220, 120)
		)
		base.Material = Enum.Material.Neon
		base.Transparency = 0.4
		base.CanCollide = false
		prompt(base, "ClimbPrompt", "Climb", "Rope up (needs Rassi Seedhi)")
	end
	model:SetAttribute("Biome", biome.id)
	model:SetAttribute("Kind", spot.kind)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	model.Parent = folder
	table.insert(
		chests,
		{ model = model, biome = biome, kind = spot.kind, top = spot.position, stand = spot.stand, opened = {} }
	)
end

local function find(model: Model?)
	for _, chest in chests do
		if chest.model == model then
			return chest
		end
	end
	return nil
end

function Treasure.climb(player: Player, model: Model?)
	local profile = State.profiles[player]
	local chest = find(model)
	if not profile or not chest then
		return
	end
	if not profile.data.gear.RopeLadder then
		State.notify(player, "bad", "You need a Rassi Seedhi (rope ladder) from the Gear shop to climb up!")
		State.sound(player, "Error")
		return
	end
	local character = player.Character
	if character then
		-- land next to the chest (on the gallery, the lid, the tower top...)
		character:PivotTo(
			CFrame.new(if chest.stand then chest.stand + Vector3.new(0, 3, 0) else chest.top + Vector3.new(3, 4, 0))
		)
	end
end

function Treasure.open(player: Player, model: Model?)
	local profile = State.profiles[player]
	local chest = find(model)
	if not profile or not chest or not chest.model.PrimaryPart then
		return
	end
	if not State.isNear(player, chest.model.PrimaryPart.Position, 16) then
		return
	end
	if not State.isZoneOpen(profile, chest.biome) then
		State.notify(player, "bad", ("Unlock %s to open its treasure!"):format(chest.biome.name))
		return
	end
	if chest.kind == "dig" and not profile.data.gear.Shovel then
		State.notify(player, "bad", "You need a Belcha (shovel) from the Gear shop to dig this up!")
		State.sound(player, "Error")
		return
	end
	local userId = player.UserId
	local remaining = Config.TREASURE_COOLDOWN - (now() - (chest.opened[userId] or -math.huge))
	if remaining > 0 then
		State.notify(
			player,
			"info",
			("This chest is empty. It refills in %d minutes."):format(math.ceil(remaining / 60))
		)
		return
	end
	chest.opened[userId] = now()
	local tier = chest.biome.tier
	local rupees = math.floor(Config.TREASURE_RUPEES * tier * tier * (1 + Config.REBIRTH_BONUS * profile.data.rebirths))
	State.addRupees(profile, rupees)
	local roll = math.random() < Config.TREASURE_ROLL_CHANCE
	if roll then
		profile.data.rollTokens += 1
		State.syncTokens(profile)
	end
	State.sound(player, "Treasure", chest.model.PrimaryPart.Position)
	State.notify(
		player,
		"rare",
		("Treasure! %s%s"):format(Format.rupees(rupees), if roll then " and a free Kismat Roll" else "")
	)
	State.track(profile, "treasure")
	Havelis.updateGalla(profile)
end

function Treasure.init(map)
	local folder = Instance.new("Folder")
	folder.Name = "ChaiChaosTreasure"
	folder.Parent = workspace
	for _, biome in Biomes.list do
		for index, spot in map.biomes[biome.id].chests do
			build(folder, biome, spot, index)
		end
	end
end

function Treasure.all()
	return chests
end

return Treasure
