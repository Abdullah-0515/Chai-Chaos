-- Vehicles: buy them at the Gaari Showroom, upgrade them at Ustad's Workshop,
-- drive them out to the zones, fill up at petrol pumps and paint them.
--
-- * Driving: your vehicle appears under you and you sit in it. It is faster
--   than walking (each vehicle has its own top speed) and your friends can
--   hop on and ride along.
-- * Fuel: every stud you drive uses a stud of fuel. With an empty tank the
--   vehicle crawls at walking speed. Petrol pumps fill you up for rupees, and
--   parked vehicles fill up slowly for free while you are at your haveli.
-- * The boot: eggs you pick up while driving go in the boot (Egg Space). When
--   you drive home they go straight into your incubators and the vehicle parks.
-- * Grip: mud, sand and ice slow vehicles down (and ice makes them slide)
--   unless their tyres are good enough (see Vehicles.luau and Hazards.luau).
-- * Paint jobs (Robux, looks only) recolour the painted panels.
--
-- Vehicles and their upgrades are kept forever, even after a Naya Safar.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)
local Vehicles = require(Shared.Vehicles)

local State = require(script.Parent.State)
local Havelis = require(script.Parent.Havelis)
local Props = require(script.Parent.Props)
local Upgrades = require(script.Parent.Upgrades)
local EggSystem = require(script.Parent.EggSystem)

local Garage = {}

local SEAT_LIFT = 1.1 -- a sitting character's middle is this far above the seat
local HOME_REFILL_RANGE = 40 -- parked vehicles refill while you are this close to your door
local PHOOL_PATTI = {
	Color3.fromRGB(230, 50, 60),
	Color3.fromRGB(250, 190, 40),
	Color3.fromRGB(40, 170, 90),
	Color3.fromRGB(50, 120, 230),
	Color3.fromRGB(235, 90, 180),
	Color3.fromRGB(250, 130, 30),
}
local CHAMAK = { Color3.fromRGB(80, 255, 200), Color3.fromRGB(255, 80, 220), Color3.fromRGB(120, 180, 255) }

local map = nil

local function modelName(def): string
	return "Vehicle" .. def.id
end

---------------------------------------------------------------------------
-- Syncing to the player's screen
---------------------------------------------------------------------------
-- "Motorbike:2:1:0:0:1450,...": each vehicle's upgrade levels (speed, tank,
-- eggs, grip) and its fuel, for the Garage, Showroom and Workshop windows.
function Garage.sync(profile)
	local data = profile.data
	local list = {}
	for _, def in Vehicles.list do
		local e = data.vehicles[def.id]
		if e then
			table.insert(
				list,
				("%s:%d:%d:%d:%d:%d"):format(def.id, e.speed, e.tank, e.eggs, e.grip, math.floor(e.fuel))
			)
		end
	end
	local paints = {}
	for id in data.paints do
		table.insert(paints, id)
	end
	table.sort(paints)
	local player = profile.player
	player:SetAttribute("Vehicles", table.concat(list, ","))
	player:SetAttribute("Paint", data.paint)
	player:SetAttribute("Paints", table.concat(paints, ","))
	Garage.syncDrive(profile)
end

-- The vehicle you are driving: its fuel, boot and grip, for the HUD.
function Garage.syncDrive(profile)
	local drive = profile.driving
	local player = profile.player
	player:SetAttribute("Driving", if drive then drive.def.id else "")
	if drive then
		player:SetAttribute("Fuel", math.floor(drive.entry.fuel))
		player:SetAttribute("FuelMax", drive.tank)
		player:SetAttribute("BootSpace", drive.space)
		player:SetAttribute("Grip", drive.grip)
	end
	player:SetAttribute("BootEggs", #profile.boot)
end

---------------------------------------------------------------------------
-- Paint jobs
---------------------------------------------------------------------------
function Garage.paint(model: Model, paintId: string)
	local panels = {}
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Name == "Paint" then
			table.insert(panels, p)
		end
	end
	for i, p in panels do
		if p:GetAttribute("FactoryColor") == nil then
			p:SetAttribute("FactoryColor", p.Color)
			p:SetAttribute("FactoryMaterial", p.Material.Name)
		end
		p:SetAttribute("Tint", nil)
		p.Color = p:GetAttribute("FactoryColor")
		p.Material = (Enum.Material :: any)[p:GetAttribute("FactoryMaterial")]
		if paintId == "PhoolPatti" then
			p.Color = PHOOL_PATTI[i % #PHOOL_PATTI + 1]
			p.Material = Enum.Material.SmoothPlastic
		elseif paintId == "Sona" then
			p.Color = Color3.fromRGB(255, 200, 60)
			p.Material = Enum.Material.Foil
		elseif paintId == "Rangeela" then
			p:SetAttribute("Tint", true) -- the colour changes on everyone's screen (Driving.client.luau)
			p.Material = Enum.Material.SmoothPlastic
		elseif paintId == "Chamak" then
			p.Color = CHAMAK[i % #CHAMAK + 1]
			p.Material = Enum.Material.Neon
		end
	end
	model:SetAttribute("Paint", paintId)
end

function Garage.setPaint(player: Player, paintId: any)
	local profile = State.profiles[player]
	if not profile or type(paintId) ~= "string" or not Vehicles.paintById[paintId] then
		return
	end
	if paintId ~= "Factory" and not profile.data.paints[paintId] then
		return
	end
	profile.data.paint = paintId
	if profile.driving then
		Garage.paint(profile.driving.model, paintId)
	end
	Garage.sync(profile)
end

-- Called by Shop.luau when a Robux paint job is bought.
function Garage.onPaintBought(profile, paintId: string)
	profile.data.paints[paintId] = true
	profile.data.paint = paintId
	if profile.driving then
		Garage.paint(profile.driving.model, paintId)
	end
	Garage.sync(profile)
end

---------------------------------------------------------------------------
-- Buying and upgrading
---------------------------------------------------------------------------
function Garage.buy(player: Player, id: any)
	local profile = State.profiles[player]
	local def = type(id) == "string" and Vehicles.byId[id]
	if not profile or not def or not Upgrades.atShop(player, "Showroom") then
		return
	end
	local data = profile.data
	if data.vehicles[def.id] then
		return
	end
	if data.rupees < def.cost then
		State.notify(player, "bad", ("The %s costs %s."):format(def.name, Format.rupees(def.cost)))
		State.sound(player, "Error")
		return
	end
	State.addRupees(profile, -def.cost)
	local entry = { fuel = def.tank, speed = 0, tank = 0, eggs = 0, grip = 0 }
	data.vehicles[def.id] = entry
	data.vehicle = def.id
	Garage.sync(profile)
	State.sound(player, "Purchase")
	State.track(profile, "vehicle")
	State.notify(player, "good", ("You bought a %s! Press Gaari to drive it."):format(def.name))
end

-- Works out a vehicle's stats from its upgrades (when you get in, or upgrade it).
local function refreshStats(profile)
	local drive = profile.driving
	if not drive then
		return
	end
	local levels = Vehicles.levels(drive.entry)
	drive.topSpeed = Vehicles.speed(drive.def, levels)
	drive.tank = Vehicles.tank(drive.def, levels)
	drive.space = Vehicles.eggs(drive.def, levels)
	drive.grip = Vehicles.grip(drive.def, levels)
	drive.empty = drive.entry.fuel <= 0
	drive.model:SetAttribute("Grip", drive.grip)
	Havelis.applyWalkSpeed(profile)
end

function Garage.upgrade(player: Player, id: any, upgradeId: any)
	local profile = State.profiles[player]
	local def = type(id) == "string" and Vehicles.byId[id]
	local upgrade = type(upgradeId) == "string" and Vehicles.upgradeById[upgradeId]
	if not profile or not def or not upgrade or not Upgrades.atShop(player, "Workshop") then
		return
	end
	local entry = profile.data.vehicles[def.id]
	if not entry then
		State.notify(player, "bad", ("Buy the %s at the Gaari Showroom first."):format(def.name))
		return
	end
	local level = entry[upgrade.id] + 1
	if level > Vehicles.maxLevel(def, upgrade.id) then
		State.notify(player, "info", ("Your %s's %s is as good as it gets!"):format(def.name, upgrade.name))
		return
	end
	local cost = Vehicles.upgradeCost(def, upgrade.id, level)
	if profile.data.rupees < cost then
		State.notify(player, "bad", ("That upgrade costs %s."):format(Format.rupees(cost)))
		State.sound(player, "Error")
		return
	end
	State.addRupees(profile, -cost)
	entry[upgrade.id] = level
	if profile.driving and profile.driving.def == def then
		refreshStats(profile)
	end
	Garage.sync(profile)
	State.sound(player, "Upgrade")
	State.notify(player, "good", ("%s %s is now level %d. %s!"):format(def.name, upgrade.name, level, upgrade.text))
end

---------------------------------------------------------------------------
-- Driving
---------------------------------------------------------------------------
local function setMassless(character: Model, massless: boolean)
	for _, p in character:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			p.Massless = massless
		end
	end
end

local function anchorOr(name: string, anchor: string): Vector3?
	local ok, point = pcall(Props.anchor, name, anchor, CFrame.new())
	return if ok then point else nil
end

-- Where egg number `slot` rides in the boot (in the vehicle's own space).
function Garage.bootSpot(drive, slot: number): CFrame
	local name = modelName(drive.def)
	local point = anchorOr(name, "Boot" .. slot)
	if not point then
		local last, count = Vector3.new(0, 3, 2), 0
		for k = 1, 12 do
			local p = anchorOr(name, "Boot" .. k)
			if p then
				last, count = p, k
			end
		end
		point = last + Vector3.new(0, 3 * (slot - count), 0)
	end
	return drive.root.CFrame * CFrame.new(point - drive.seat + Vector3.new(0, 1.7, 0))
end

local function inAnyHaveli(position: Vector3): boolean
	for _, h in map.havelis do
		if Havelis.isInside(h, position) then
			return true
		end
	end
	return false
end

function Garage.atHome(profile, position: Vector3): boolean
	local h = profile.haveli
	if not h then
		return false
	end
	return Havelis.isInside(h, position)
		or ((position - h.doorOutside.Position) * Vector3.new(1, 0, 1)).Magnitude < Config.PARK_DISTANCE
end

-- Get out: your friends hop off, eggs in the boot come out (into your
-- incubators if you are home), and the vehicle goes back to the garage.
function Garage.park(profile)
	local drive = profile.driving
	if not drive then
		return
	end
	local root = State.rootPart(profile.player)
	EggSystem.unloadBoot(profile, root ~= nil and Garage.atHome(profile, root.Position))
	for _, connection in drive.connections do
		connection:Disconnect()
	end
	for _, seat in drive.seats do
		local occupant = seat.Occupant
		if occupant then
			occupant.Sit = false
			local weld = seat:FindFirstChild("SeatWeld")
			if weld then
				weld:Destroy()
			end
			if occupant.Parent then
				setMassless(occupant.Parent :: Model, false)
			end
		end
	end
	drive.model:Destroy()
	profile.driving = nil
	profile.surfaceSpeed = nil
	local character = profile.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and profile.baseHipHeight then
		humanoid.HipHeight = profile.baseHipHeight
	end
	Havelis.applyWalkSpeed(profile)
	Garage.syncDrive(profile)
end

-- Get in and drive vehicle `id`, or park with nil.
function Garage.drive(player: Player, id: any)
	local profile = State.profiles[player]
	if not profile or not profile.haveli then
		return
	end
	if id == nil then
		Garage.park(profile)
		return
	end
	local def = type(id) == "string" and Vehicles.byId[id]
	local entry = def and profile.data.vehicles[def.id]
	if not def or not entry then
		State.notify(player, "bad", "Buy a vehicle at the Gaari Showroom in the bazaar first!")
		return
	end
	if profile.carryingBrainrot then
		State.notify(player, "bad", "You can't drive while carrying a brainrot!")
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = State.rootPart(player)
	if not character or not humanoid or humanoid.Health <= 0 or not root then
		return
	end
	if humanoid.SeatPart then
		State.notify(player, "bad", "Hop off first!")
		return
	end
	if inAnyHaveli(root.Position) then
		State.notify(player, "bad", "Step outside to get in your vehicle!")
		return
	end
	if profile.driving then
		if profile.driving.def == def then
			return
		end
		if #profile.boot > 0 then
			State.notify(player, "bad", "Take the eggs in your boot home before you swap vehicles!")
			return
		end
		Garage.park(profile)
	end

	-- build the vehicle (always from parts, so paint jobs work) around its seat
	local name = modelName(def)
	local model = Props.place(name, CFrame.new(), nil, 1, { parts = true, noColliders = true })
	model.Name = "Vehicle"
	local seat = Props.anchor(name, "Seat", CFrame.new())
	local vehicleRoot = Instance.new("Part")
	vehicleRoot.Name = "VehicleRoot"
	vehicleRoot.Size = Vector3.one
	vehicleRoot.Transparency = 1
	vehicleRoot.CFrame = CFrame.new(seat)
	vehicleRoot.Parent = model
	model.PrimaryPart = vehicleRoot
	local seats = {}
	for k = 1, def.seats do
		local point = anchorOr(name, "Seat" .. k)
		if point then
			local s = Instance.new("Seat")
			s.Name = "PassengerSeat"
			s.Size = Vector3.new(1.6, 0.4, 1.6)
			s.CFrame = CFrame.new(point + Vector3.new(0, 0.2, 0))
			s.Transparency = 1
			s.CanTouch = false -- nobody sits by bumping into it; they use the prompt
			s.Parent = model
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "RideAlong"
			prompt.ActionText = "Ride along"
			prompt.ObjectText = ("%s's %s"):format(player.DisplayName, def.name)
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt:SetAttribute("OwnerId", player.UserId)
			prompt.Parent = s
			table.insert(seats, s)
		end
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.CanTouch = false
			p.Massless = true
			if p ~= vehicleRoot then
				local weld = Instance.new("WeldConstraint")
				weld.Name = "Hold"
				weld.Part0 = vehicleRoot
				weld.Part1 = p
				weld.Parent = p
			end
		end
	end
	Garage.paint(model, profile.data.paint)

	-- sit the driver on the seat: raise them so the wheels touch the ground
	profile.baseHipHeight = profile.baseHipHeight or humanoid.HipHeight
	local rootHalf = root.Size.Y / 2
	local legs = if humanoid.RigType == Enum.HumanoidRigType.R15 then 0 else 2
	local standing = legs + profile.baseHipHeight + rootHalf
	humanoid.HipHeight = profile.baseHipHeight + (seat.Y + SEAT_LIFT - standing)
	model:PivotTo(root.CFrame * CFrame.new(0, -SEAT_LIFT, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Name = "VehicleWeld"
	weld.Part0 = root
	weld.Part1 = vehicleRoot
	weld.Parent = vehicleRoot
	model:SetAttribute("Owner", player.UserId)
	CollectionService:AddTag(model, "ChaiVehicle")
	model.Parent = character

	profile.driving = {
		def = def,
		entry = entry,
		model = model,
		root = vehicleRoot,
		seat = seat,
		seats = seats,
		lastPos = root.Position,
		leftHome = not Garage.atHome(profile, root.Position),
		connections = {
			humanoid.Died:Connect(function()
				Garage.park(profile)
			end),
		},
		topSpeed = 0,
		tank = 0,
		space = 0,
		grip = 0,
		empty = false,
	}
	local drive = profile.driving
	drive.bootSpot = function(slot: number): CFrame
		return Garage.bootSpot(drive, slot)
	end
	profile.data.vehicle = def.id
	refreshStats(profile)
	EggSystem.toBoot(profile)
	Garage.syncDrive(profile)
	State.sound(player, "Upgrade")
	if profile.driving.empty then
		State.notify(player, "bad", "Your tank is empty! Fill up at a petrol pump.")
	end
end

-- A friend hops on (the RideAlong prompt on a passenger seat).
function Garage.rideAlong(player: Player, seat: Instance?)
	local profile = State.profiles[player]
	if not profile or not seat or not seat:IsA("Seat") or seat.Occupant then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.SeatPart or profile.driving or profile.carryingBrainrot then
		return
	end
	local owner = seat.Parent and seat.Parent:GetAttribute("Owner")
	if owner == player.UserId then
		return
	end
	setMassless(character :: Model, true) -- so the driver's vehicle does not slow down
	seat:Sit(humanoid)
	local connection
	connection = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if seat.Occupant ~= humanoid then
			connection:Disconnect()
			if character and character.Parent then
				setMassless(character :: Model, false)
			end
		end
	end)
end

---------------------------------------------------------------------------
-- Petrol pumps
---------------------------------------------------------------------------
function Garage.refuel(player: Player, pad: Instance?)
	local profile = State.profiles[player]
	if not profile or not pad or not pad:IsA("BasePart") then
		return
	end
	if not State.isNear(player, pad.Position, Config.PUMP_DISTANCE + 8) then
		return
	end
	local drive = profile.driving
	if not drive then
		State.notify(player, "info", "Drive your vehicle up to the pump to fill up.")
		return
	end
	local missing = drive.tank - drive.entry.fuel
	if missing < 1 then
		State.notify(player, "info", "Your tank is already full!")
		return
	end
	local cost = math.ceil(missing * Config.FUEL_PRICE)
	local amount = missing
	if profile.data.rupees < cost then
		amount = math.floor(profile.data.rupees / Config.FUEL_PRICE)
		cost = math.ceil(amount * Config.FUEL_PRICE)
		if amount < 1 then
			State.notify(player, "bad", "You don't have enough rupees for petrol!")
			State.sound(player, "Error")
			return
		end
	end
	State.addRupees(profile, -cost)
	drive.entry.fuel = math.min(drive.tank, drive.entry.fuel + amount)
	refreshStats(profile)
	Garage.syncDrive(profile)
	State.sound(player, "Purchase")
	State.notify(
		player,
		"good",
		("Filled up for %s. Range: %d studs."):format(Format.rupees(cost), math.floor(drive.entry.fuel))
	)
end

---------------------------------------------------------------------------
-- The loop: fuel, parking at home and free refills
---------------------------------------------------------------------------
function Garage.tick(dt: number)
	for player, profile in State.profiles do
		local root = State.rootPart(player)
		local drive = profile.driving
		if drive and root then
			local position = root.Position
			local moved = ((position - drive.lastPos) * Vector3.new(1, 0, 1)).Magnitude
			drive.lastPos = position
			-- a rickshaw ride home or a respawn is not driving
			if moved < drive.topSpeed * dt * 2 + 8 then
				drive.entry.fuel = math.max(0, drive.entry.fuel - moved)
			end
			local empty = drive.entry.fuel <= 0
			if empty ~= drive.empty then
				drive.empty = empty
				Havelis.applyWalkSpeed(profile)
				if empty then
					State.sound(player, "Error")
					State.notify(
						player,
						"bad",
						("Out of petrol! Your %s crawls at walking speed. Find a petrol pump."):format(drive.def.name)
					)
				end
			end
			if math.floor(drive.entry.fuel) ~= player:GetAttribute("Fuel") then
				player:SetAttribute("Fuel", math.floor(drive.entry.fuel))
			end
			-- drove home: eggs go in the incubators, then the vehicle parks
			local home = Garage.atHome(profile, position)
			if not home then
				drive.leftHome = true
			elseif drive.leftHome then
				EggSystem.deliverBoot(profile)
				if #profile.boot == 0 then
					Garage.park(profile)
					Garage.sync(profile)
				end
			end
		elseif root and profile.haveli then
			-- parked vehicles fill up for free while you are home
			local near = ((root.Position - profile.haveli.doorOutside.Position) * Vector3.new(1, 0, 1)).Magnitude
			if near < HOME_REFILL_RANGE or Havelis.isInside(profile.haveli, root.Position) then
				local changed = false
				for id, entry in profile.data.vehicles do
					local tank = Vehicles.tank(Vehicles.byId[id], Vehicles.levels(entry))
					if entry.fuel < tank then
						entry.fuel = math.min(tank, entry.fuel + Config.FUEL_HOME_REFILL * dt)
						changed = true
					end
				end
				local t = os.clock()
				if changed and t - (profile.vehicleSyncAt or 0) > 1 then
					profile.vehicleSyncAt = t
					Garage.sync(profile)
				end
			end
		end
	end
end

-- A new character: the old vehicle went with the old character.
function Garage.reset(profile)
	if profile.driving then
		Garage.park(profile)
	end
	profile.baseHipHeight = nil
end

function Garage.init(gameMap)
	map = gameMap
	Remotes.BuyVehicle.OnServerEvent:Connect(Garage.buy)
	Remotes.UpgradeVehicle.OnServerEvent:Connect(Garage.upgrade)
	Remotes.Drive.OnServerEvent:Connect(Garage.drive)
	Remotes.SetPaint.OnServerEvent:Connect(Garage.setPaint)
	task.spawn(function()
		while true do
			Garage.tick(task.wait(0.25))
		end
	end)
end

return Garage
