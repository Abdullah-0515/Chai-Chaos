-- Eggs: they appear in the zones, players carry them home, and they hatch
-- into brainrots in the haveli's incubators.
--
-- * Each zone keeps a few eggs lying around; golden eggs are rare and luckier.
--   You can only pick up eggs in zones you have unlocked.
-- * Picking an egg up starts a countdown. Further zones have shorter ones.
--   Hazards knock time off. If it runs out, the egg cracks and is gone.
-- * On foot you carry one egg in your hands. In a vehicle, eggs go in the boot
--   (as many as its Egg Space).
-- * At your own haveli the countdown stops and the egg goes into a free
--   incubator. What hatches is rolled then, from the zone's pool and odds.
-- * A bonk with a chappal makes you drop an egg, and anyone can grab it.
-- * Every few minutes an egg rush fills one zone with extra eggs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Brainrots = require(Shared.Brainrots)
local Biomes = require(Shared.Biomes)
local Events = require(Shared.Events)
local Gear = require(Shared.Gear)
local Mutations = require(Shared.Mutations)

local State = require(script.Parent.State)
local Models = require(script.Parent.Models)
local Havelis = require(script.Parent.Havelis)
local Picker = require(script.Parent.Picker)

local EggSystem = {}

local RARE_OR_BETTER = { Rare = true, Epic = true, Legendary = true, Mythic = true, Secret = true }
local GOLD = Color3.fromRGB(255, 205, 50)
local CARRY_OFFSET = CFrame.new(0, 0.4, 1.6)

local map = nil
local folder: Folder = nil
local eggs: { [Model]: any } = {} -- eggs lying on the ground
local live: { [string]: number } = {} -- natural eggs per biome

local function now(): number
	return workspace:GetServerTimeNow()
end

---------------------------------------------------------------------------
-- Egg models
---------------------------------------------------------------------------
local function eggModel(biome, golden: boolean): Model
	local model = Instance.new("Model")
	model.Name = if golden then "GoldenEgg" else biome.id .. "Egg"
	local shell = Instance.new("Part")
	shell.Name = "Shell"
	shell.Size = Vector3.new(2.6, 3.4, 2.6)
	shell.Color = if golden then GOLD else biome.eggColor
	shell.Material = if golden then Enum.Material.Foil else Enum.Material.SmoothPlastic
	shell.Anchored = true
	shell.CanCollide = false
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = shell
	shell.Parent = model
	model.PrimaryPart = shell
	for i = 1, 5 do
		local a = i * 1.3
		local h = -0.8 + (i % 3) * 0.7
		local rx = 1.3 * math.sqrt(math.max(0, 1 - (h / 1.7) ^ 2))
		local spot = Instance.new("Part")
		spot.Name = "Spot"
		spot.Shape = Enum.PartType.Ball
		spot.Size = Vector3.one * 0.7
		spot.Color = if golden then Color3.new(1, 1, 1) else biome.spotColor
		spot.Anchored = true
		spot.CanCollide = false
		spot.CFrame = CFrame.new(math.cos(a) * rx, h, math.sin(a) * rx)
		spot.Parent = model
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = shell
		weld.Part1 = spot
		weld.Parent = spot
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "EggGui"
	gui.Size = UDim2.fromScale(7, 1.6)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = if golden then GOLD else biome.eggColor
	label.Text = if golden then "GOLDEN EGG" else biome.name .. " Egg"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = shell

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EggPrompt"
	prompt.ActionText = "Pick up"
	prompt.ObjectText = if golden then "Golden " .. biome.name .. " Egg" else biome.name .. " Egg"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = Config.PICKUP_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = shell

	if golden then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "GoldenSparkles"
		sparkles.Rate = 10
		sparkles.Lifetime = NumberRange.new(0.8, 1.4)
		sparkles.Speed = NumberRange.new(1, 3)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new(0.5, 0)
		sparkles.LightEmission = 1
		sparkles.Color = ColorSequence.new(GOLD)
		sparkles.Parent = shell
		local glow = Instance.new("PointLight")
		glow.Color = GOLD
		glow.Range = 12
		glow.Brightness = 2
		glow.Parent = shell
	end
	model:SetAttribute("Biome", biome.id)
	model:SetAttribute("Golden", golden)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	return model
end

local function setAnchored(model: Model, anchored: boolean)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = anchored
			p.Massless = true
		end
	end
end

local function promptOf(model: Model): ProximityPrompt?
	local shell = model.PrimaryPart
	return shell and shell:FindFirstChild("EggPrompt") :: ProximityPrompt?
end

---------------------------------------------------------------------------
-- Spawning
---------------------------------------------------------------------------
local function freeSpot(plan): Vector3?
	for _ = 1, 12 do
		local spot = plan.eggSpots[math.random(#plan.eggSpots)]
		local taken = false
		for model in eggs do
			if model.PrimaryPart and (model.PrimaryPart.Position - spot).Magnitude < 6 then
				taken = true
				break
			end
		end
		if not taken then
			return spot
		end
	end
	return nil
end

function EggSystem.spawn(biome, golden: boolean?, position: Vector3?)
	local plan = map.biomes[biome.id]
	local spot = position or freeSpot(plan)
	if not spot then
		return nil
	end
	local isGolden = if golden == nil then math.random() < Config.GOLDEN_EGG_CHANCE else golden
	local model = eggModel(biome, isGolden)
	model:PivotTo(CFrame.new(spot + Vector3.new(0, 1.7, 0)))
	model.Parent = folder
	eggs[model] = { biome = biome, golden = isGolden, natural = true }
	live[biome.id] = (live[biome.id] or 0) + 1
	return model
end

local function target(biome): number
	local count = math.floor(Config.EGGS_PER_BIOME * Events.mult("eggMult"))
	if workspace:GetAttribute("EggRush") == biome.id then
		count += Config.EGG_RUSH_EGGS
	end
	return count
end

function EggSystem.refill(perBiome: number?)
	for _, biome in Biomes.list do
		for _ = 1, perBiome or 1 do
			if (live[biome.id] or 0) < target(biome) then
				EggSystem.spawn(biome)
			end
		end
	end
end

function EggSystem.startRush(biomeId: string?)
	local biome = Biomes.byId[biomeId or ""] or Biomes.list[math.random(#Biomes.list)]
	workspace:SetAttribute("EggRush", biome.id)
	workspace:SetAttribute("EggRushEndsAt", now() + Config.EGG_RUSH_DURATION)
	State.notifyAll(
		"rare",
		("EGG RUSH in %s! Lots of eggs for %d seconds!"):format(biome.name, Config.EGG_RUSH_DURATION)
	)
	State.soundAll("EventStart")
	EggSystem.refill(Config.EGG_RUSH_EGGS)
end

function EggSystem.stopRush()
	workspace:SetAttribute("EggRush", "")
end

---------------------------------------------------------------------------
-- Carrying
---------------------------------------------------------------------------
-- The HUD shows the egg that will crack first (in your hands or in the boot).
local function lead(profile)
	local best = profile.egg
	for _, egg in profile.boot do
		if not best or egg.timeLeft < best.timeLeft then
			best = egg
		end
	end
	return best
end

local function syncAttributes(profile)
	local player = profile.player
	local egg = lead(profile)
	player:SetAttribute("EggBiome", if egg then egg.biome.id else "")
	player:SetAttribute("EggGolden", if egg then egg.golden else false)
	player:SetAttribute("EggTimeLeft", if egg then math.max(0, math.floor(egg.timeLeft * 10) / 10) else 0)
	player:SetAttribute("EggTimeTotal", if egg then egg.total else 0)
	player:SetAttribute("EggCount", #profile.boot + (if profile.egg then 1 else 0))
	player:SetAttribute("BootEggs", #profile.boot)
end
EggSystem.syncAttributes = syncAttributes

local function endCarry(profile)
	local carry = profile.egg
	if not carry then
		return nil
	end
	profile.egg = nil
	for _, connection in carry.connections do
		connection:Disconnect()
	end
	local weld = carry.model.PrimaryPart and carry.model.PrimaryPart:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	syncAttributes(profile)
	return carry
end

-- Welds an egg into the vehicle's boot, in slot `slot`.
local function intoBoot(profile, record, slot: number)
	local drive = profile.driving
	local model = record.model
	local weld = model.PrimaryPart and model.PrimaryPart:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	setAnchored(model, false)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Massless = true
		end
	end
	model:PivotTo(drive.bootSpot(slot) * CFrame.new(0, 0, 0))
	local newWeld = Instance.new("WeldConstraint")
	newWeld.Name = "CarryWeld"
	newWeld.Part0 = drive.root
	newWeld.Part1 = model.PrimaryPart
	newWeld.Parent = model.PrimaryPart
	record.warned = false
end

local function takeFromBoot(profile, index: number)
	local record = table.remove(profile.boot, index)
	local weld = record.model.PrimaryPart and record.model.PrimaryPart:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	-- the rest shuffle up
	for slot, egg in profile.boot do
		intoBoot(profile, egg, slot)
	end
	syncAttributes(profile)
	return record
end

-- How long a fresh egg from this biome lasts for this player.
function EggSystem.eggTime(profile, biome, golden: boolean): number
	return biome.eggTime
		* Gear.best(profile.data.gear, "egg")
		* Events.mult("eggTimeMult")
		* (if golden then Config.GOLDEN_EGG_TIME else 1)
end

function EggSystem.isCarrying(player: Player): boolean
	local profile = State.profiles[player]
	return profile ~= nil and (profile.egg ~= nil or #profile.boot > 0)
end

function EggSystem.pickUp(player: Player, model: Model?)
	local profile = State.profiles[player]
	local egg = model and eggs[model]
	if not profile or not egg or not profile.haveli then
		return
	end
	if not State.isZoneOpen(profile, egg.biome) then
		State.notify(player, "bad", ("Unlock %s at its gate to collect its eggs!"):format(egg.biome.name))
		State.sound(player, "Error")
		return
	end
	local drive = profile.driving
	if drive and #profile.boot >= drive.space then
		State.notify(player, "bad", ("Your boot is full (%d eggs)! Take them home first."):format(drive.space))
		return
	end
	if not drive and profile.egg then
		State.notify(player, "bad", "You can only carry one egg at a time! A vehicle's boot holds more.")
		return
	end
	if profile.carryingBrainrot then
		State.notify(player, "bad", "Your hands are full with a stolen brainrot!")
		return
	end
	local root = State.rootPart(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if
		not root
		or not humanoid
		or not State.isNear(player, (model :: Model):GetPivot().Position, Config.PICKUP_DISTANCE + 4)
	then
		return
	end
	local m = model :: Model
	eggs[m] = nil
	if egg.natural then
		live[egg.biome.id] -= 1
	end
	local total = EggSystem.eggTime(profile, egg.biome, egg.golden)
	local timeLeft = egg.timeLeft or total

	local prompt = promptOf(m)
	if prompt then
		prompt.Enabled = false
	end
	if drive then
		local record = {
			model = m,
			biome = egg.biome,
			golden = egg.golden,
			timeLeft = timeLeft,
			total = total,
			warned = false,
		}
		table.insert(profile.boot, record)
		intoBoot(profile, record, #profile.boot)
		syncAttributes(profile)
		State.sound(player, "EggPickup")
		State.notify(
			player,
			"info",
			("Egg in the boot (%d/%d)! Drive it home before it cracks (%d seconds)."):format(
				#profile.boot,
				drive.space,
				math.floor(timeLeft)
			)
		)
		return
	end
	setAnchored(m, false)
	m:PivotTo(root.CFrame * CARRY_OFFSET)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = m.PrimaryPart
	weld.Parent = m.PrimaryPart

	profile.egg = {
		model = m,
		biome = egg.biome,
		golden = egg.golden,
		timeLeft = timeLeft,
		total = total,
		warned = false,
		connections = {
			humanoid.Died:Connect(function()
				EggSystem.drop(player)
			end),
			player.CharacterRemoving:Connect(function()
				EggSystem.drop(player)
			end),
		},
	}
	syncAttributes(profile)
	State.sound(player, "EggPickup")
	State.notify(
		player,
		"info",
		("Got a %s! Run it home before it cracks (%d seconds)."):format(
			if egg.golden then "golden egg" else egg.biome.name .. " egg",
			math.floor(timeLeft)
		)
	)
end

-- Puts an egg on the ground where the player is; anyone can pick it up.
local function putDown(player: Player, carry, offset: Vector3?)
	local model = carry.model
	local root = State.rootPart(player)
	local spot = (if root then root.Position - Vector3.new(0, 1.2, 0) else model:GetPivot().Position)
		+ (offset or Vector3.zero)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Massless = false
		end
	end
	setAnchored(model, true)
	model:PivotTo(CFrame.new(spot))
	local prompt = promptOf(model)
	if prompt then
		prompt.Enabled = true
	end
	eggs[model] =
		{ biome = carry.biome, golden = carry.golden, natural = false, timeLeft = carry.timeLeft, droppedAt = now() }
end

-- Drops the egg in your hands (or, in a vehicle, one from the boot).
function EggSystem.drop(player: Player, reason: string?)
	local profile = State.profiles[player]
	if not profile then
		return
	end
	local carry = endCarry(profile)
	if not carry and #profile.boot > 0 then
		carry = takeFromBoot(profile, #profile.boot)
	end
	if not carry then
		return
	end
	putDown(player, carry)
	if reason == "bonk" then
		State.notify(player, "bad", "Bonk! You dropped an egg. Grab it back quick!")
	end
end

-- Getting in a vehicle: the egg in your hands goes in the boot.
function EggSystem.toBoot(profile)
	local drive = profile.driving
	if not drive or not profile.egg or #profile.boot >= drive.space then
		return
	end
	local carry = endCarry(profile)
	table.insert(profile.boot, carry)
	intoBoot(profile, carry, #profile.boot)
	syncAttributes(profile)
end

-- A hazard hit: the carried egg loses some time.
function EggSystem.hit(player: Player, seconds: number, message: string): boolean
	local profile = State.profiles[player]
	if not profile or (not profile.egg and #profile.boot == 0) then
		return false
	end
	if profile.egg then
		profile.egg.timeLeft -= seconds
	end
	for _, egg in profile.boot do
		egg.timeLeft -= seconds
	end
	syncAttributes(profile)
	State.notify(player, "bad", ("%s Your egg lost %d seconds."):format(message, seconds))
	return true
end

-- The egg in your hands cracks, or (with `bootIndex`) one in the boot.
local function crack(profile, bootIndex: number?)
	local carry = if bootIndex then takeFromBoot(profile, bootIndex) else endCarry(profile)
	if not carry then
		return
	end
	local position = carry.model:GetPivot().Position
	carry.model:Destroy()
	State.sound(profile.player, "EggCrack", position)
	State.notify(
		profile.player,
		"bad",
		"Oh no, your egg cracked! Faster vehicles and egg gear (Tokri, Thermos) help with far zones."
	)
end

---------------------------------------------------------------------------
-- Incubators and hatching
---------------------------------------------------------------------------
function EggSystem.incubatorCount(profile): number
	return Config.HAVELI_LEVELS[profile.data.level].incubators
end

local function freeIncubator(profile): number?
	for slot = 1, EggSystem.incubatorCount(profile) do
		if not profile.incubating[slot] then
			return slot
		end
	end
	return nil
end

local function nestCFrame(h, slot: number): CFrame
	return CFrame.new(h.incubators[slot].Position + Vector3.new(0, 2.2, 0))
end

-- Puts an egg (new or saved) into an incubator.
local function incubate(profile, slot: number, record)
	local h = profile.haveli
	local biome = Biomes.byId[record.biome]
	local model = record.model or eggModel(biome, record.golden)
	setAnchored(model, true)
	model:PivotTo(nestCFrame(h, slot))
	local prompt = promptOf(model)
	if prompt then
		prompt.Enabled = false
	end
	model.Parent = h.brainrotFolder
	record.model = model
	profile.incubating[slot] = record
end

-- What hatches: rolled when the egg goes into the incubator.
function EggSystem.roll(biome, golden: boolean)
	local luck = Events.mult("luckMult")
	local def = Picker.pick(biome.odds, biome.pool, luck * (if golden then Config.GOLDEN_EGG_LUCK else 1))
	local mutation = Mutations.roll(if golden then "golden" else "egg", luck)
	return def, mutation
end

local function deposit(profile, slot: number, bootIndex: number?)
	local carry = if bootIndex then takeFromBoot(profile, bootIndex) else endCarry(profile)
	if not carry then
		return
	end
	for _, p in carry.model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Massless = false
		end
	end
	local biome = carry.biome
	local def, mutation = EggSystem.roll(biome, carry.golden)
	local seconds = biome.hatchTime * (if carry.golden then Config.GOLDEN_HATCH_TIME else 1) / Events.mult("hatchMult")
	incubate(profile, slot, {
		biome = biome.id,
		golden = carry.golden,
		id = def.id,
		mutation = mutation,
		hatchAt = os.time() + math.ceil(seconds),
		model = carry.model,
	})
	State.sound(profile.player, "EggHome")
	State.notify(profile.player, "good", ("Home safe! The egg hatches in %d seconds."):format(math.ceil(seconds)))
	State.track(profile, "eggHome")
	if carry.golden then
		State.track(profile, "goldenEgg")
	end
	if Events.current() then
		State.track(profile, "eventEgg")
	end
	State.trackBiome(profile, biome.id)
end

local function hatch(profile, slot: number)
	local record = profile.incubating[slot]
	profile.incubating[slot] = nil
	local h = profile.haveli
	local position = h.incubators[slot].Position
	if record.model then
		record.model:Destroy()
	end
	local def = Brainrots.byId[record.id]
	local model = Models.create(def, record.mutation)
	model:PivotTo(Models.stand(model, CFrame.new(position + Vector3.new(0, 0.6, 0))))
	local _, isNew = Havelis.adopt(profile, def, record.mutation, model, true)
	local name = Mutations.displayName(def, record.mutation)
	State.sound(profile.player, "EggHatch", position)
	State.notify(
		profile.player,
		if RARE_OR_BETTER[def.rarity] or record.mutation then "rare" else "good",
		("Your egg hatched: %s (%s)!%s"):format(name, def.rarity, if isNew then " NEW!" else "")
	)
	if RARE_OR_BETTER[def.rarity] then
		State.track(profile, "hatchRare")
	end
	if record.mutation then
		State.track(profile, "mutation")
	end
	if def.rarity == "Mythic" or def.rarity == "Secret" or record.mutation == "Rainbow" then
		State.notifyAll("rare", ("%s hatched a %s!"):format(profile.player.DisplayName, name))
	end
end

local function updateNests(profile)
	local h = profile.haveli
	if not h then
		return
	end
	local count = EggSystem.incubatorCount(profile)
	local t = os.time()
	for slot, label in h.incubatorLabels do
		local record = profile.incubating[slot]
		local text
		if slot > count then
			text = ""
		elseif not record then
			text = "Empty incubator"
		elseif t >= record.hatchAt then
			text = "Ready! Needs a free plot"
		else
			text = ("Hatching %ds"):format(record.hatchAt - t)
		end
		if label.Text ~= text then
			label.Text = text
		end
	end
end

-- Puts saved incubator eggs back after the player claims a haveli.
function EggSystem.restore(profile)
	profile.incubating = {}
	for _, saved in profile.data.incubators do
		local slot = saved.slot
		if
			Biomes.byId[saved.biome]
			and Brainrots.byId[saved.id]
			and slot <= EggSystem.incubatorCount(profile)
			and not profile.incubating[slot]
		then
			incubate(profile, slot, {
				biome = saved.biome,
				golden = saved.golden == true,
				id = saved.id,
				mutation = if Mutations.byId[saved.mutation or ""] then saved.mutation else nil,
				hatchAt = saved.hatchAt,
			})
		end
	end
	updateNests(profile)
end

function EggSystem.syncData(profile)
	if not profile.haveli then
		return
	end
	local list = {}
	for slot, record in profile.incubating do
		table.insert(list, {
			slot = slot,
			biome = record.biome,
			golden = record.golden,
			id = record.id,
			mutation = record.mutation,
			hatchAt = record.hatchAt,
		})
	end
	profile.data.incubators = list
end

-- Leaving: drop the carried egg; incubator eggs are already saved.
function EggSystem.release(profile)
	EggSystem.drop(profile.player)
	for _, record in profile.incubating do
		if record.model then
			record.model:Destroy()
		end
	end
	profile.incubating = {}
end

-- Naya Safar: carried and incubating eggs are gone.
function EggSystem.reset(profile)
	local carry = endCarry(profile)
	if carry then
		carry.model:Destroy()
	end
	while #profile.boot > 0 do
		takeFromBoot(profile, #profile.boot).model:Destroy()
	end
	for _, record in profile.incubating do
		if record.model then
			record.model:Destroy()
		end
	end
	profile.incubating = {}
	profile.data.incubators = {}
	updateNests(profile)
end

---------------------------------------------------------------------------
-- The boot
---------------------------------------------------------------------------
-- Driving home: eggs in the boot go into free incubators.
function EggSystem.deliverBoot(profile)
	while #profile.boot > 0 do
		local slot = freeIncubator(profile)
		if not slot then
			local first = profile.boot[1]
			if not first.warned then
				first.warned = true
				State.notify(profile.player, "bad", "Your incubators are full! The eggs wait in your boot.")
			end
			return
		end
		deposit(profile, slot, 1)
	end
end

-- Getting out: at home the eggs go in the incubators; anywhere else you take
-- one in your hands and the rest go on the ground (anyone can grab them).
function EggSystem.unloadBoot(profile, atHome: boolean)
	if #profile.boot == 0 then
		return
	end
	if atHome then
		EggSystem.deliverBoot(profile)
	end
	local player = profile.player
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local alive = humanoid ~= nil and humanoid.Health > 0
	local dropped = 0
	while #profile.boot > 0 do
		local record = takeFromBoot(profile, 1)
		local root = State.rootPart(player)
		if alive and not profile.egg and root and humanoid then
			setAnchored(record.model, false)
			record.model:PivotTo(root.CFrame * CARRY_OFFSET)
			local weld = Instance.new("WeldConstraint")
			weld.Name = "CarryWeld"
			weld.Part0 = root
			weld.Part1 = record.model.PrimaryPart
			weld.Parent = record.model.PrimaryPart
			record.connections = {
				humanoid.Died:Connect(function()
					EggSystem.drop(player)
				end),
				player.CharacterRemoving:Connect(function()
					EggSystem.drop(player)
				end),
			}
			profile.egg = record
		else
			dropped += 1
			putDown(player, record, Vector3.new(math.cos(dropped * 2) * 4, 0, math.sin(dropped * 2) * 4))
		end
	end
	syncAttributes(profile)
	if dropped > 0 and alive then
		State.notify(
			player,
			"bad",
			("You got out, so %d egg(s) fell out of the boot. Grab them quick!"):format(dropped)
		)
	end
end

local function nearHome(profile, position: Vector3): boolean
	local h = profile.haveli
	return h ~= nil
		and (
			Havelis.isInside(h, position)
			or ((position - h.doorOutside.Position) * Vector3.new(1, 0, 1)).Magnitude < Config.PARK_DISTANCE
		)
end

---------------------------------------------------------------------------
-- The loops
---------------------------------------------------------------------------
function EggSystem.tick(dt: number)
	for player, profile in State.profiles do
		local carry = profile.egg
		if carry then
			local root = State.rootPart(player)
			local h = profile.haveli
			if root and h and Havelis.isInside(h, root.Position) then
				local slot = freeIncubator(profile)
				if slot then
					deposit(profile, slot)
				elseif not carry.warned then
					carry.warned = true
					State.notify(player, "bad", "Your incubators are full! Wait for an egg to hatch.")
				end
			else
				carry.warned = false
				carry.timeLeft -= dt * (profile.eggDrain or 1)
				if carry.timeLeft <= 0 then
					crack(profile)
				end
			end
		end
		-- eggs in the boot count down too, except when you are home
		local root = State.rootPart(player)
		if #profile.boot > 0 and not (root and nearHome(profile, root.Position)) then
			for i = #profile.boot, 1, -1 do
				local egg = profile.boot[i]
				egg.timeLeft -= dt * (profile.eggDrain or 1)
				if egg.timeLeft <= 0 then
					crack(profile, i)
				end
			end
		end
		if profile.egg or #profile.boot > 0 then
			local egg = lead(profile)
			local shown = if egg then math.max(0, math.floor(egg.timeLeft * 10) / 10) else 0
			if player:GetAttribute("EggTimeLeft") ~= shown then
				syncAttributes(profile)
			end
		end
	end
	-- dropped eggs do not last forever
	local t = now()
	for model, egg in eggs do
		if egg.droppedAt and t - egg.droppedAt > Config.DROPPED_EGG_LIFETIME then
			eggs[model] = nil
			model:Destroy()
		end
	end
end

function EggSystem.hatchTick()
	local t = os.time()
	for _, profile in State.profiles do
		if profile.haveli then
			for slot = 1, Config.MAX_INCUBATORS do
				local record = profile.incubating[slot]
				if record and t >= record.hatchAt and Havelis.hasFreePlot(profile) then
					hatch(profile, slot)
				end
			end
			updateNests(profile)
		end
	end
end

function EggSystem.init(gameMap)
	map = gameMap
	folder = Instance.new("Folder")
	folder.Name = "ChaiChaosEggs"
	folder.Parent = workspace
	workspace:SetAttribute("EggRush", "")
	for _ = 1, Config.EGGS_PER_BIOME do
		EggSystem.refill(1)
	end
	task.spawn(function()
		while true do
			EggSystem.tick(task.wait(0.25))
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			EggSystem.hatchTick()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.EGG_RESPAWN)
			EggSystem.refill(if workspace:GetAttribute("EggRush") ~= "" then 3 else 1)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(Config.EGG_RUSH_EVERY)
			EggSystem.startRush()
			task.wait(Config.EGG_RUSH_DURATION)
			EggSystem.stopRush()
		end
	end)
end

-- For tests and other modules: the eggs lying around.
function EggSystem.groundEggs()
	return eggs
end

return EggSystem
