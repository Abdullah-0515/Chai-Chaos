-- Builds the 8 biomes out of Roblox Terrain (sand, snow, water, mud, salt...)
-- plus parts for trees, huts, boats, the desert fort and so on.
--
-- Every biome is planned from a fixed random seed, so the world is the same
-- every time. Planning (where eggs, chests and hazard zones go) always runs;
-- building (creating terrain and parts) only runs when the map is new.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Biomes = require(Shared.Biomes)

local BiomeBuilder = {}

local GROUND_Y = Biomes.GROUND_Y
local EGG_SPOTS = 40
local CELL = 24

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local UP = CFrame.Angles(0, 0, math.rad(90))

export type Zone = {
	kind: string, -- water, mud, ice, shore, dark
	center: Vector3?, -- circles
	radius: number?,
	inner: number?, -- bands: distance from the Chowk
	outer: number?,
}

export type Chest = {
	position: Vector3,
	kind: string, -- "dig" (needs a Shovel) or "climb" (needs a Rope Ladder)
	base: Vector3?, -- where you climb from
}

export type Plan = {
	biome: any,
	eggSpots: { Vector3 },
	chests: { Chest },
	zones: { Zone },
	balls: { { center: Vector3, radius: number } },
}

---------------------------------------------------------------------------
-- Context helpers
---------------------------------------------------------------------------
local function newContext(biome, folder: Instance?)
	return {
		biome = biome,
		folder = folder,
		building = folder ~= nil,
		rng = Random.new(1000 + biome.index),
		inner = Biomes.innerRadius(biome),
		terrain = workspace.Terrain,
		plan = { biome = biome, eggSpots = {}, chests = {}, zones = {}, balls = {} } :: Plan,
	}
end

-- A ground position `d` studs from the Chowk, `side` degrees off the biome's road.
local function at(ctx, d: number, side: number): Vector3
	return Biomes.point(ctx.biome, d, side)
end

-- The ground height at x, z (hills and dunes raise it).
local function surface(ctx, position: Vector3): number
	local height = GROUND_Y
	for _, ball in ctx.plan.balls do
		local dx, dz = position.X - ball.center.X, position.Z - ball.center.Z
		local flat = dx * dx + dz * dz
		if flat < ball.radius * ball.radius then
			height = math.max(height, ball.center.Y + math.sqrt(ball.radius * ball.radius - flat))
		end
	end
	return height
end

local function onGround(ctx, position: Vector3): Vector3
	return Vector3.new(position.X, surface(ctx, position), position.Z)
end

-- A raised ball of terrain (hill, dune, mountain). Recorded so things sit on top.
local function hill(ctx, center: Vector3, radius: number, material: Enum.Material)
	table.insert(ctx.plan.balls, { center = center, radius = radius })
	if ctx.building then
		ctx.terrain:FillBall(center, radius, material)
	end
end

local function fillBall(ctx, center: Vector3, radius: number, material: Enum.Material)
	if ctx.building then
		ctx.terrain:FillBall(center, radius, material)
	end
end

local function fillCylinder(ctx, cf: CFrame, height: number, radius: number, material: Enum.Material)
	if ctx.building then
		ctx.terrain:FillCylinder(cf, height, radius, material)
	end
end

-- Water, mud or ice that lies flush with the ground. Terrain is made of
-- 4-stud voxels and the ground's top layer (Y 0 to 4) is only a quarter full,
-- so a fill that stops below Y 0 would stay hidden under a crust of ground.
-- These clear that layer first, then fill up to the ground's surface.
local function pond(ctx, center: Vector3, radius: number, depth: number, material: Enum.Material)
	if ctx.building then
		ctx.terrain:FillCylinder(CFrame.new(center.X, GROUND_Y + 3, center.Z), 6, radius, Enum.Material.Air)
		ctx.terrain:FillCylinder(CFrame.new(center.X, GROUND_Y - depth / 2, center.Z), depth, radius, material)
	end
end

local function pondBlock(ctx, cf: CFrame, size: Vector3, depth: number, material: Enum.Material)
	if ctx.building then
		local flat = cf.Rotation + Vector3.new(cf.X, 0, cf.Z)
		ctx.terrain:FillBlock(flat + Vector3.new(0, GROUND_Y + 3, 0), Vector3.new(size.X, 6, size.Z), Enum.Material.Air)
		ctx.terrain:FillBlock(
			flat + Vector3.new(0, GROUND_Y - depth / 2, 0),
			Vector3.new(size.X, depth, size.Z),
			material
		)
	end
end

local function part(ctx, props: { [string]: any }): Part?
	if not ctx.building then
		return nil
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	p.CastShadow = props.CastShadow ~= false
	for name, value in props do
		if name ~= "Parent" and name ~= "CastShadow" then
			(p :: any)[name] = value
		end
	end
	p.Parent = props.Parent or ctx.folder
	return p
end

local function zone(ctx, z: Zone)
	table.insert(ctx.plan.zones, z)
end

local function chest(ctx, position: Vector3, kind: string, base: Vector3?)
	table.insert(ctx.plan.chests, { position = position, kind = kind, base = base })
end

-- A random spot: distance from the Chowk and degrees off the road.
local function randomSpot(ctx, dMin: number, dMax: number, sideMax: number): (number, number)
	return ctx.rng:NextNumber(dMin, dMax), ctx.rng:NextNumber(-sideMax, sideMax)
end

local function inZone(ctx, position: Vector3, kinds: { [string]: boolean }): boolean
	local r = math.sqrt(position.X * position.X + position.Z * position.Z)
	for _, z in ctx.plan.zones do
		if kinds[z.kind] then
			if z.center then
				local dx, dz = position.X - z.center.X, position.Z - z.center.Z
				if dx * dx + dz * dz < (z.radius :: number) ^ 2 then
					return true
				end
			elseif z.inner and r >= z.inner and r <= (z.outer :: number) then
				return true
			end
		end
	end
	return false
end

-- Fill the biome's ground with one terrain material, cell by cell.
local function ground(ctx, material: Enum.Material)
	if not ctx.building then
		return
	end
	local inner, outer = ctx.inner, ctx.inner + Biomes.DEPTH
	local angle = ctx.biome.angle
	for x = -outer, outer, CELL do
		for z = -outer, outer, CELL do
			local r = math.sqrt(x * x + z * z)
			if r >= inner - CELL / 2 and r <= outer + CELL / 2 then
				local diff = math.abs((math.atan2(z, x) - angle + math.pi) % (2 * math.pi) - math.pi)
				if diff <= math.rad(22.5) then
					ctx.terrain:FillBlock(CFrame.new(x, GROUND_Y - 2, z), Vector3.new(CELL, 4, CELL), material)
				end
			end
		end
	end
end

-- Random egg spots on the ground, away from the given zone kinds.
local function eggSpots(ctx, dMin: number, dMax: number, sideMax: number, avoid: { [string]: boolean })
	local tries = 0
	while #ctx.plan.eggSpots < EGG_SPOTS and tries < 2000 do
		tries += 1
		local d, side = randomSpot(ctx, dMin, dMax, sideMax)
		local spot = at(ctx, d, side)
		if not inZone(ctx, spot, avoid) then
			table.insert(ctx.plan.eggSpots, onGround(ctx, spot))
		end
	end
end

-- Facing the Chowk.
local function facing(position: Vector3): CFrame
	local flat = Vector3.new(position.X, position.Y, position.Z)
	local toward = Vector3.new(0, position.Y, 0)
	if (toward - flat).Magnitude < 0.01 then
		return CFrame.new(flat)
	end
	return CFrame.lookAt(flat, toward)
end

---------------------------------------------------------------------------
-- Props
---------------------------------------------------------------------------
local function tree(ctx, position: Vector3, leaf: Color3, height: number)
	local base = onGround(ctx, position)
	part(ctx, {
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 1.6, 1.6),
		CFrame = CFrame.new(base + Vector3.new(0, height / 2, 0)) * UP,
		Color = rgb(120, 85, 55),
		Material = Enum.Material.Wood,
	})
	for i, offset in
		{ Vector3.new(0, height + 1, 0), Vector3.new(1.8, height - 0.5, 1), Vector3.new(-1.6, height, -1.2) }
	do
		part(ctx, {
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * (6 - i),
			CFrame = CFrame.new(base + offset),
			Color = leaf:Lerp(rgb(255, 255, 255), (i - 1) * 0.06),
			Material = Enum.Material.Grass,
			CanCollide = false,
		})
	end
end

local function pine(ctx, position: Vector3, snowy: boolean)
	local base = onGround(ctx, position)
	part(ctx, {
		Name = "Trunk",
		Size = Vector3.new(1.2, 4, 1.2),
		CFrame = CFrame.new(base + Vector3.new(0, 2, 0)),
		Color = rgb(100, 70, 45),
		Material = Enum.Material.Wood,
	})
	for i = 0, 3 do
		local size = 8 - i * 1.8
		part(ctx, {
			Name = "Needles",
			Size = Vector3.new(size, 2.4, size),
			CFrame = CFrame.new(base + Vector3.new(0, 4.5 + i * 2.2, 0)) * CFrame.Angles(0, math.rad(i * 25), 0),
			Color = if snowy and i == 3 then rgb(245, 250, 255) else rgb(40, 110, 60),
			Material = Enum.Material.Grass,
			CanCollide = false,
		})
	end
end

local function palm(ctx, position: Vector3)
	local base = onGround(ctx, position)
	local height = 14 + ctx.rng:NextNumber(0, 5)
	for i = 1, 5 do
		part(ctx, {
			Name = "Trunk",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(height / 5 + 0.1, 1.4 - i * 0.08, 1.4 - i * 0.08),
			CFrame = CFrame.new(base + Vector3.new(math.sin(i * 0.4) * 0.6, (i - 0.5) * height / 5, 0)) * UP,
			Color = if i % 2 == 0 then rgb(150, 105, 65) else rgb(170, 120, 75),
			Material = Enum.Material.Wood,
		})
	end
	local top = base + Vector3.new(math.sin(2) * 0.6, height, 0)
	for i = 0, 5 do
		part(ctx, {
			Name = "Leaf",
			Size = Vector3.new(1.4, 0.3, 7),
			CFrame = CFrame.new(top)
				* CFrame.Angles(0, math.rad(i * 60), 0)
				* CFrame.new(0, 0, -3)
				* CFrame.Angles(math.rad(-25), 0, 0),
			Color = rgb(60, 185, 80),
			CanCollide = false,
			CastShadow = false,
		})
	end
end

local function hut(ctx, position: Vector3, wall: Color3, roof: Color3)
	local base = onGround(ctx, position)
	local cf = facing(base)
	part(ctx, {
		Name = "Hut",
		Size = Vector3.new(10, 7, 9),
		CFrame = cf * CFrame.new(0, 3.5, 0),
		Color = wall,
		Material = Enum.Material.Brick,
	})
	part(ctx, {
		Name = "Roof",
		Size = Vector3.new(12, 1.4, 11),
		CFrame = cf * CFrame.new(0, 7.7, 0),
		Color = roof,
		Material = Enum.Material.Fabric,
	})
	part(ctx, {
		Name = "Doorway",
		Size = Vector3.new(3, 5, 0.3),
		CFrame = cf * CFrame.new(0, 2.5, -4.6),
		Color = rgb(70, 45, 30),
		Material = Enum.Material.Wood,
	})
end

local function animal(ctx, position: Vector3, color: Color3, size: number, name: string)
	local base = onGround(ctx, position)
	local cf = CFrame.new(base) * CFrame.Angles(0, ctx.rng:NextNumber(0, math.pi * 2), 0)
	part(ctx, {
		Name = name,
		Size = Vector3.new(size * 0.9, size * 0.8, size * 1.8),
		CFrame = cf * CFrame.new(0, size * 1.1, 0),
		Color = color,
	})
	part(ctx, {
		Name = name .. "Head",
		Size = Vector3.new(size * 0.6, size * 0.6, size * 0.7),
		CFrame = cf * CFrame.new(0, size * 1.4, -size * 1.15),
		Color = color:Lerp(rgb(0, 0, 0), 0.15),
	})
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			part(ctx, {
				Name = "Leg",
				Size = Vector3.new(size * 0.22, size * 0.8, size * 0.22),
				CFrame = cf * CFrame.new(x * size * 0.3, size * 0.4, z * size * 0.65),
				Color = color:Lerp(rgb(0, 0, 0), 0.3),
			})
		end
	end
end

local function boat(ctx, position: Vector3, color: Color3, afloat: boolean)
	local base = if afloat then Vector3.new(position.X, GROUND_Y - 0.6, position.Z) else onGround(ctx, position)
	local cf = CFrame.new(base) * CFrame.Angles(0, ctx.rng:NextNumber(0, math.pi * 2), 0)
	part(ctx, { Name = "Boat", Size = Vector3.new(5, 1.6, 12), CFrame = cf * CFrame.new(0, 0.8, 0), Color = color })
	part(ctx, {
		Name = "BoatStripe",
		Size = Vector3.new(5.1, 0.5, 12.1),
		CFrame = cf * CFrame.new(0, 1.4, 0),
		Color = rgb(255, 255, 255),
	})
	part(ctx, {
		Name = "Mast",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(9, 0.5, 0.5),
		CFrame = cf * CFrame.new(0, 5.5, 1) * UP,
		Color = rgb(130, 90, 60),
	})
	part(ctx, {
		Name = "Sail",
		Size = Vector3.new(0.2, 6, 5),
		CFrame = cf * CFrame.new(0, 6, 2.5),
		Color = rgb(255, 245, 225),
		Material = Enum.Material.Fabric,
		CanCollide = false,
	})
end

local function crystal(ctx, position: Vector3, height: number, light: boolean)
	local p = part(ctx, {
		Name = "SaltCrystal",
		Size = Vector3.new(1.4, height, 1.4),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0))
			* CFrame.Angles(ctx.rng:NextNumber(-0.4, 0.4), ctx.rng:NextNumber(0, 3), ctx.rng:NextNumber(-0.4, 0.4)),
		Color = rgb(255, 120, 180),
		Material = Enum.Material.Neon,
		Transparency = 0.15,
		CanCollide = false,
		CastShadow = false,
	})
	if p and light then
		local glow = Instance.new("PointLight")
		glow.Color = rgb(255, 140, 190)
		glow.Range = 18
		glow.Brightness = 1.5
		glow.Parent = p
	end
end

-- A tall rock pillar with treasure on top that needs a Rope Ladder.
local function climbChest(ctx, position: Vector3, height: number, material: Enum.Material)
	local base = onGround(ctx, position)
	fillCylinder(ctx, CFrame.new(base + Vector3.new(0, height / 2, 0)), height, 7, material)
	table.insert(ctx.plan.balls, { center = base + Vector3.new(0, height - 7, 0), radius = 7 })
	chest(ctx, base + Vector3.new(0, height + 0.5, 0), "climb", base + Vector3.new(0, 0, 0))
end

---------------------------------------------------------------------------
-- The biomes
---------------------------------------------------------------------------
local BUILDERS = {}

function BUILDERS.Khet(ctx)
	local inner = ctx.inner
	ground(ctx, Enum.Material.Ground) -- ploughed farmland
	-- wheat and sarson fields, with a path down the middle
	local wheat, sarson = rgb(226, 186, 72), rgb(250, 220, 40)
	local i = 0
	for d = inner + 35, inner + 250, 32 do
		for side = -16, 16, 7 do
			if math.abs(side) > 3 then
				i += 1
				local spot = at(ctx, d, side)
				part(ctx, {
					Name = "Crop",
					Size = Vector3.new(22, 2.6, 22),
					CFrame = facing(spot) * CFrame.new(0, 1.3, 0),
					Color = if i % 3 == 0 then sarson else wheat,
					Material = Enum.Material.Grass,
					CanCollide = false,
					CastShadow = false,
				})
			end
		end
	end
	-- muddy rice paddies
	for _, spot in { { inner + 80, -12 }, { inner + 170, 11 }, { inner + 240, -7 } } do
		local center = at(ctx, spot[1], spot[2])
		pond(ctx, center, 14, 2, Enum.Material.Mud)
		zone(ctx, { kind = "mud", center = center, radius = 14 })
	end
	-- a little village
	for side = 14, 19, 5 do
		hut(ctx, at(ctx, inner + 205, side), rgb(200, 150, 100), rgb(230, 200, 120))
	end
	hut(ctx, at(ctx, inner + 125, 17), rgb(210, 210, 215), rgb(60, 120, 200)) -- the tube well hut
	local pool = at(ctx, inner + 135, 14)
	pond(ctx, pool, 5, 3, Enum.Material.Water)
	for k = 1, 6 do
		local d, side = randomSpot(ctx, inner + 40, inner + 260, 18)
		local base = onGround(ctx, at(ctx, d, side))
		part(ctx, {
			Name = "Haystack",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(7, 7, 7),
			CFrame = CFrame.new(base + Vector3.new(0, 2, 0)),
			Color = rgb(235, 200, 100):Lerp(rgb(150, 110, 50), (k % 3) * 0.15),
			Material = Enum.Material.Grass,
		})
	end
	for _ = 1, 4 do
		local d, side = randomSpot(ctx, inner + 60, inner + 240, 18)
		animal(ctx, at(ctx, d, side), rgb(45, 40, 40), 2.6, "Buffalo")
	end
	chest(ctx, onGround(ctx, at(ctx, inner + 232, 13)), "dig")
	-- the village water tank on stilts, with treasure on its lid
	local tank = at(ctx, inner + 185, -15)
	for _, offset in { Vector3.new(-3, 0, -3), Vector3.new(3, 0, -3), Vector3.new(-3, 0, 3), Vector3.new(3, 0, 3) } do
		part(ctx, {
			Name = "TankLeg",
			Size = Vector3.new(0.8, 16, 0.8),
			CFrame = CFrame.new(tank + offset + Vector3.new(0, 8, 0)),
			Color = rgb(150, 150, 155),
			Material = Enum.Material.Metal,
		})
	end
	part(ctx, {
		Name = "WaterTank",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 9, 9),
		CFrame = CFrame.new(tank + Vector3.new(0, 19, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = rgb(70, 80, 90),
		Material = Enum.Material.SmoothPlastic,
	})
	chest(ctx, tank + Vector3.new(0, 22, 0), "climb", tank + Vector3.new(0, 0, 7))
	eggSpots(ctx, inner + 20, inner + 265, 18, {})
end

function BUILDERS.Jungle(ctx)
	local inner = ctx.inner
	ground(ctx, Enum.Material.LeafyGrass)
	-- the river crossing the jungle
	local riverR = inner + 160
	zone(ctx, { kind = "water", inner = riverR - 10, outer = riverR + 10 })
	for side = -24, 24, 2 do
		local spot = at(ctx, riverR, side)
		pondBlock(
			ctx,
			CFrame.lookAt(spot, Vector3.new(0, spot.Y, 0)),
			Vector3.new(riverR * math.rad(2) + 4, 6, 20),
			6,
			Enum.Material.Water
		)
	end
	-- the bridge
	local bridge = at(ctx, riverR, 0)
	part(ctx, {
		Name = "Bridge",
		Size = Vector3.new(8, 0.8, 30),
		CFrame = facing(bridge) * CFrame.new(0, 0.6, 0),
		Color = rgb(150, 100, 60),
		Material = Enum.Material.WoodPlanks,
	})
	for _, x in { -4, 4 } do
		part(ctx, {
			Name = "Rail",
			Size = Vector3.new(0.4, 2.5, 30),
			CFrame = facing(bridge) * CFrame.new(x, 2, 0),
			Color = rgb(120, 80, 50),
		})
	end
	-- the waterfall cliff
	local cliff = at(ctx, inner + 255, -9)
	hill(ctx, cliff + Vector3.new(0, 4, 0), 24, Enum.Material.Rock)
	local fall = facing(cliff) * CFrame.new(0, 14, -21)
	part(ctx, {
		Name = "Waterfall",
		Size = Vector3.new(8, 26, 1),
		CFrame = fall,
		Color = rgb(150, 210, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.4,
		CanCollide = false,
		CastShadow = false,
	})
	pond(ctx, cliff + facing(cliff).LookVector * 26, 9, 4, Enum.Material.Water)
	chest(ctx, onGround(ctx, cliff), "climb", cliff + facing(cliff).LookVector * 28)
	for _ = 1, 55 do
		local d, side = randomSpot(ctx, inner + 15, inner + 270, 20)
		local spot = at(ctx, d, side)
		if not inZone(ctx, spot, { water = true }) and math.abs(side) > 2 then
			tree(ctx, spot, rgb(40, 140, 55), 10 + ctx.rng:NextNumber(0, 8))
		end
	end
	for _ = 1, 3 do
		local d, side = randomSpot(ctx, inner + 40, inner + 140, 15)
		local base = onGround(ctx, at(ctx, d, side))
		part(ctx, {
			Name = "Peacock",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.8,
			CFrame = CFrame.new(base + Vector3.new(0, 1.2, 0)),
			Color = rgb(30, 90, 200),
		})
		part(ctx, {
			Name = "PeacockTail",
			Size = Vector3.new(3.5, 3, 0.2),
			CFrame = CFrame.new(base + Vector3.new(0, 2.2, 1)),
			Color = rgb(40, 170, 120),
			CanCollide = false,
		})
	end
	chest(ctx, onGround(ctx, at(ctx, inner + 60, 15)), "dig")
	eggSpots(ctx, inner + 15, inner + 265, 19, { water = true })
end

function BUILDERS.Samandar(ctx)
	local inner = ctx.inner
	ground(ctx, Enum.Material.Sand)
	local seaFrom = inner + 215
	zone(ctx, { kind = "water", inner = seaFrom, outer = inner + Biomes.DEPTH + 20 })
	zone(ctx, { kind = "shore", inner = seaFrom - 30, outer = seaFrom })
	if ctx.building then
		local angle = ctx.biome.angle
		local outer = inner + Biomes.DEPTH
		for x = -outer - CELL, outer + CELL, CELL do
			for z = -outer - CELL, outer + CELL, CELL do
				local r = math.sqrt(x * x + z * z)
				local diff = math.abs((math.atan2(z, x) - angle + math.pi) % (2 * math.pi) - math.pi)
				if r >= seaFrom and r <= outer + CELL and diff <= math.rad(23) then
					pondBlock(ctx, CFrame.new(x, 0, z), Vector3.new(CELL, 0, CELL), 10, Enum.Material.Water)
				end
			end
		end
	end
	for _ = 1, 14 do
		local d, side = randomSpot(ctx, inner + 20, seaFrom - 35, 19)
		palm(ctx, at(ctx, d, side))
	end
	for side = -12, 12, 12 do
		hut(ctx, at(ctx, inner + 150, side + 3), rgb(240, 220, 180), rgb(60, 170, 200))
	end
	boat(ctx, at(ctx, seaFrom - 12, -6), rgb(220, 60, 60), false)
	boat(ctx, at(ctx, seaFrom - 15, 9), rgb(60, 120, 220), false)
	boat(ctx, at(ctx, seaFrom + 25, -14), rgb(250, 200, 40), true)
	boat(ctx, at(ctx, seaFrom + 40, 4), rgb(60, 180, 100), true)
	for _ = 1, 6 do
		local d, side = randomSpot(ctx, inner + 60, seaFrom - 5, 18)
		local base = onGround(ctx, at(ctx, d, side))
		part(ctx, {
			Name = "Crab",
			Size = Vector3.new(1.6, 0.7, 1.2),
			CFrame = CFrame.new(base + Vector3.new(0, 0.35, 0)),
			Color = rgb(230, 70, 50),
		})
	end
	for _ = 1, 5 do
		local d, side = randomSpot(ctx, inner + 80, seaFrom - 40, 16)
		local base = onGround(ctx, at(ctx, d, side))
		part(ctx, {
			Name = "UmbrellaPole",
			Size = Vector3.new(0.3, 6, 0.3),
			CFrame = CFrame.new(base + Vector3.new(0, 3, 0)),
			Color = rgb(255, 255, 255),
		})
		part(ctx, {
			Name = "Umbrella",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.6, 8, 8),
			CFrame = CFrame.new(base + Vector3.new(0, 6, 0)) * UP,
			Color = rgb(255, 90, 120),
			Material = Enum.Material.Fabric,
		})
	end
	-- a rocky island with treasure, and buried treasure on the beach
	local island = at(ctx, seaFrom + 35, 12)
	hill(ctx, island - Vector3.new(0, 4, 0), 14, Enum.Material.Rock)
	chest(ctx, onGround(ctx, island), "climb", at(ctx, seaFrom - 5, 12))
	chest(ctx, onGround(ctx, at(ctx, inner + 120, -14)), "dig")
	eggSpots(ctx, inner + 15, seaFrom - 5, 19, { water = true })
end

function BUILDERS.Jheel(ctx)
	local inner = ctx.inner
	ground(ctx, Enum.Material.LeafyGrass)
	local lake = at(ctx, inner + 150, 0)
	pond(ctx, lake, 55, 8, Enum.Material.Water)
	zone(ctx, { kind = "water", center = lake, radius = 55 })
	-- the dock
	local dock = at(ctx, inner + 92, 0)
	part(ctx, {
		Name = "Dock",
		Size = Vector3.new(6, 0.6, 22),
		CFrame = facing(dock) * CFrame.new(0, 0.4, -6),
		Color = rgb(150, 100, 60),
		Material = Enum.Material.WoodPlanks,
	})
	-- mountains behind the meadows
	for _, side in { -15, 0, 15 } do
		local peak = at(ctx, inner + Biomes.DEPTH + 10, side)
		hill(ctx, peak - Vector3.new(0, 20, 0), 45, Enum.Material.Rock)
		fillBall(ctx, peak + Vector3.new(0, 14, 0), 18, Enum.Material.Snow)
	end
	local colors = { rgb(255, 90, 140), rgb(255, 220, 60), rgb(160, 110, 255), rgb(255, 255, 255), rgb(255, 140, 40) }
	for k = 1, 120 do
		local d, side = randomSpot(ctx, inner + 10, inner + 250, 20)
		local spot = at(ctx, d, side)
		if not inZone(ctx, spot, { water = true }) then
			part(ctx, {
				Name = "Flower",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 0.9,
				CFrame = CFrame.new(onGround(ctx, spot) + Vector3.new(0, 0.8, 0)),
				Color = colors[k % #colors + 1],
				CanCollide = false,
				CastShadow = false,
			})
		end
	end
	for _ = 1, 25 do
		local d, side = randomSpot(ctx, inner + 20, inner + 260, 20)
		local spot = at(ctx, d, side)
		if not inZone(ctx, spot, { water = true }) and math.abs(side) > 6 then
			pine(ctx, spot, false)
		end
	end
	climbChest(ctx, at(ctx, inner + 70, 16), 26, Enum.Material.Rock)
	chest(ctx, onGround(ctx, at(ctx, inner + 215, -10)), "dig")
	eggSpots(ctx, inner + 15, inner + 255, 19, { water = true })
end

function BUILDERS.Registan(ctx)
	local inner = ctx.inner
	ground(ctx, Enum.Material.Sand)
	zone(ctx, { kind = "sandstorm", inner = inner, outer = inner + Biomes.DEPTH })
	for _ = 1, 16 do
		local d, side = randomSpot(ctx, inner + 30, inner + 270, 19)
		local radius = ctx.rng:NextNumber(22, 40)
		local spot = at(ctx, d, side)
		hill(ctx, spot - Vector3.new(0, radius * 0.65, 0), radius, Enum.Material.Sand)
	end
	-- the old fort
	local fortCenter = at(ctx, inner + 200, 8)
	local fort = facing(fortCenter)
	local stone = rgb(215, 160, 100)
	for _, wall in
		{
			{ Vector3.new(44, 12, 3), CFrame.new(0, 6, 22) },
			{ Vector3.new(3, 12, 44), CFrame.new(-22, 6, 0) },
			{ Vector3.new(3, 12, 44), CFrame.new(22, 6, 0) },
			{ Vector3.new(16, 12, 3), CFrame.new(-14, 6, -22) },
			{ Vector3.new(16, 12, 3), CFrame.new(14, 6, -22) },
		}
	do
		part(ctx, {
			Name = "FortWall",
			Size = wall[1],
			CFrame = fort * wall[2],
			Color = stone,
			Material = Enum.Material.Sandstone,
		})
	end
	for _, corner in { { -22, -22 }, { 22, -22 }, { -22, 22 }, { 22, 22 } } do
		part(ctx, {
			Name = "FortTower",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(20, 9, 9),
			CFrame = fort * CFrame.new(corner[1], 10, corner[2]) * UP,
			Color = stone:Lerp(rgb(255, 255, 255), 0.1),
			Material = Enum.Material.Sandstone,
		})
	end
	local towerTop = (fort * CFrame.new(22, 20.5, 22)).Position
	chest(ctx, towerTop, "climb", (fort * CFrame.new(22, 0, 16)).Position)
	for _ = 1, 18 do
		local d, side = randomSpot(ctx, inner + 20, inner + 270, 19)
		local base = onGround(ctx, at(ctx, d, side))
		part(ctx, {
			Name = "Cactus",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(6, 1.6, 1.6),
			CFrame = CFrame.new(base + Vector3.new(0, 3, 0)) * UP,
			Color = rgb(70, 150, 70),
			Material = Enum.Material.Grass,
		})
		part(ctx, {
			Name = "CactusArm",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(2.5, 1.1, 1.1),
			CFrame = CFrame.new(base + Vector3.new(1, 3.5, 0)) * UP,
			Color = rgb(70, 150, 70),
			Material = Enum.Material.Grass,
		})
	end
	for _ = 1, 4 do
		local d, side = randomSpot(ctx, inner + 40, inner + 260, 18)
		animal(ctx, at(ctx, d, side), rgb(200, 150, 90), 3.2, "Camel")
	end
	chest(ctx, onGround(ctx, at(ctx, inner + 120, -15)), "dig")
	eggSpots(ctx, inner + 15, inner + 268, 19, {})
end

function BUILDERS.Delta(ctx)
	local inner = ctx.inner
	ground(ctx, Enum.Material.Mud)
	zone(ctx, { kind = "mud", inner = inner, outer = inner + Biomes.DEPTH })
	for _ = 1, 6 do
		local d, side = randomSpot(ctx, inner + 40, inner + 260, 17)
		local radius = ctx.rng:NextNumber(12, 22)
		local spot = at(ctx, d, side)
		pond(ctx, spot, radius, 4, Enum.Material.Water)
		zone(ctx, { kind = "water", center = spot, radius = radius })
	end
	for _ = 1, 40 do
		local d, side = randomSpot(ctx, inner + 15, inner + 270, 20)
		local base = onGround(ctx, at(ctx, d, side))
		for k = 0, 3 do
			local a = k * math.pi / 2
			part(ctx, {
				Name = "Root",
				Size = Vector3.new(0.5, 4, 0.5),
				CFrame = CFrame.new(base + Vector3.new(math.cos(a) * 1.4, 1.5, math.sin(a) * 1.4))
					* CFrame.Angles(math.sin(a) * 0.5, 0, -math.cos(a) * 0.5),
				Color = rgb(110, 80, 55),
				Material = Enum.Material.Wood,
			})
		end
		part(ctx, {
			Name = "Trunk",
			Size = Vector3.new(1.2, 6, 1.2),
			CFrame = CFrame.new(base + Vector3.new(0, 6, 0)),
			Color = rgb(110, 80, 55),
			Material = Enum.Material.Wood,
		})
		part(ctx, {
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 7,
			CFrame = CFrame.new(base + Vector3.new(0, 10, 0)),
			Color = rgb(40, 110, 50),
			Material = Enum.Material.Grass,
			CanCollide = false,
		})
	end
	for k = 1, 4 do
		local base = onGround(ctx, at(ctx, inner + 60 + k * 45, if k % 2 == 0 then 12 else -12))
		for _, x in { -3, 3 } do
			for _, z in { -3, 3 } do
				part(ctx, {
					Name = "Stilt",
					Size = Vector3.new(0.6, 7, 0.6),
					CFrame = CFrame.new(base + Vector3.new(x, 3.5, z)),
					Color = rgb(120, 85, 55),
					Material = Enum.Material.Wood,
				})
			end
		end
		part(ctx, {
			Name = "StiltHut",
			Size = Vector3.new(9, 5, 9),
			CFrame = CFrame.new(base + Vector3.new(0, 9.5, 0)),
			Color = rgb(190, 150, 100),
			Material = Enum.Material.WoodPlanks,
		})
		part(ctx, {
			Name = "Roof",
			Size = Vector3.new(11, 1, 11),
			CFrame = CFrame.new(base + Vector3.new(0, 12.5, 0)),
			Color = rgb(150, 120, 70),
			Material = Enum.Material.Fabric,
		})
		if k == 3 then
			chest(ctx, base + Vector3.new(0, 13.5, 0), "climb", base + Vector3.new(0, 0, 6))
		end
	end
	boat(ctx, at(ctx, inner + 100, 4), rgb(200, 90, 50), false)
	chest(ctx, onGround(ctx, at(ctx, inner + 90, -16)), "dig")
	eggSpots(ctx, inner + 15, inner + 268, 19, { water = true })
end

function BUILDERS.Pahar(ctx)
	local inner = ctx.inner
	ground(ctx, Enum.Material.Snow)
	zone(ctx, { kind = "snowballs", inner = inner, outer = inner + Biomes.DEPTH })
	-- mountains around the valley
	for _, m in
		{
			{ 60, -19, 38 },
			{ 140, 19, 42 },
			{ 210, -18, 50 },
			{ 270, 0, 60 },
			{ 260, 16, 45 },
			{ 110, -20, 34 },
			{ 30, 18, 30 },
		}
	do
		local spot = at(ctx, inner + m[1], m[2])
		hill(ctx, spot - Vector3.new(0, m[3] * 0.45, 0), m[3], Enum.Material.Rock)
		fillBall(ctx, spot + Vector3.new(0, m[3] * 0.3, 0), m[3] * 0.4, Enum.Material.Snow)
	end
	-- the frozen lake and glaciers: slippery!
	local lake = at(ctx, inner + 140, -4)
	pond(ctx, lake, 30, 3, Enum.Material.Ice)
	zone(ctx, { kind = "ice", center = lake, radius = 30 })
	for _, g in { { 60, 6 }, { 200, 4 }, { 230, -10 } } do
		local spot = at(ctx, inner + g[1], g[2])
		pond(ctx, spot, 15, 3, Enum.Material.Glacier)
		zone(ctx, { kind = "ice", center = spot, radius = 15 })
	end
	for _ = 1, 40 do
		local d, side = randomSpot(ctx, inner + 10, inner + 260, 20)
		local spot = at(ctx, d, side)
		if not inZone(ctx, spot, { ice = true }) and surface(ctx, spot) < GROUND_Y + 20 then
			pine(ctx, spot, true)
		end
	end
	for _ = 1, 3 do
		local d, side = randomSpot(ctx, inner + 40, inner + 200, 10)
		animal(ctx, at(ctx, d, side), rgb(70, 55, 45), 3, "Yak")
	end
	climbChest(ctx, at(ctx, inner + 220, 11), 30, Enum.Material.Rock)
	chest(ctx, onGround(ctx, at(ctx, inner + 80, 9)), "dig")
	eggSpots(ctx, inner + 15, inner + 250, 15, {})
end

-- The tunnels of the salt caves, as (distance, degrees) points.
local TUNNELS = {
	{ { 20, 0 }, { 70, 0 }, { 110, -7 }, { 160, -11 }, { 200, -4 }, { 245, 6 }, { 262, 14 } },
	{ { 110, -7 }, { 150, 8 }, { 190, 14 }, { 230, 15 } },
}

function BUILDERS.NamakKaan(ctx)
	local inner = ctx.inner
	ground(ctx, Enum.Material.Rock)
	zone(ctx, { kind = "dark", inner = inner, outer = inner + Biomes.DEPTH })
	-- the salt mountain
	for k = 0, 9 do
		local spot = at(ctx, inner + 40 + k * 25, if k % 2 == 0 then -8 else 8)
		local radius = 38 + (k % 3) * 6
		fillBall(
			ctx,
			spot - Vector3.new(0, 4, 0),
			radius,
			if k % 2 == 0 then Enum.Material.Salt else Enum.Material.Rock
		)
	end
	-- carve the tunnels and the crystal chamber
	local chamber = at(ctx, inner + 200, -4)
	for _, tunnel in TUNNELS do
		for i = 1, #tunnel - 1 do
			local a = at(ctx, inner + tunnel[i][1], tunnel[i][2])
			local b = at(ctx, inner + tunnel[i + 1][1], tunnel[i + 1][2])
			local steps = math.ceil((b - a).Magnitude / 4)
			for s = 0, steps do
				local p = a:Lerp(b, s / steps)
				fillBall(ctx, p + Vector3.new(0, 7, 0), 9, Enum.Material.Air)
				if s % 3 == 0 then
					local side = if s % 2 == 0 then 1 else -1
					local wall = p + (b - a).Unit:Cross(Vector3.yAxis) * 6.5 * side
					crystal(ctx, wall + Vector3.new(0, -1, 0), ctx.rng:NextNumber(2.5, 5), s % 9 == 0)
				end
				if s % 2 == 0 then
					table.insert(
						ctx.plan.eggSpots,
						p + Vector3.new(ctx.rng:NextNumber(-2, 2), -1, ctx.rng:NextNumber(-2, 2))
					)
				end
			end
		end
	end
	fillBall(ctx, chamber + Vector3.new(0, 9, 0), 18, Enum.Material.Air)
	for k = 1, 8 do
		local a = k * math.pi / 4
		crystal(ctx, chamber + Vector3.new(math.cos(a) * 14, -2, math.sin(a) * 14), 6 + (k % 3) * 2, k % 2 == 0)
	end
	-- a ledge in the chamber (Rope Ladder) and a dig spot (Shovel)
	local ledge = chamber + Vector3.new(0, 11, 0) + (at(ctx, inner + 220, -4) - chamber).Unit * 12
	part(ctx, {
		Name = "SaltLedge",
		Size = Vector3.new(8, 1, 8),
		CFrame = CFrame.new(ledge - Vector3.new(0, 0.5, 0)),
		Color = rgb(255, 170, 200),
		Material = Enum.Material.Salt,
	})
	chest(ctx, ledge + Vector3.new(0, 0.5, 0), "climb", chamber - Vector3.new(0, 1, 0))
	chest(ctx, chamber + Vector3.new(-6, -1, 6), "dig")
	-- crystals outside too
	for _ = 1, 14 do
		local d, side = randomSpot(ctx, inner + 5, inner + 30, 20)
		crystal(ctx, at(ctx, d, side), ctx.rng:NextNumber(3, 7), false)
	end
	-- keep only 40 cave egg spots
	while #ctx.plan.eggSpots > EGG_SPOTS do
		table.remove(ctx.plan.eggSpots, ctx.rng:NextInteger(1, #ctx.plan.eggSpots))
	end
end

---------------------------------------------------------------------------
-- Public
---------------------------------------------------------------------------

-- Plans (and, with a folder, builds) every biome. Returns plans by biome id.
function BiomeBuilder.run(parent: Instance?): { [string]: Plan }
	local plans = {}
	for _, biome in Biomes.list do
		local folder = nil
		if parent then
			folder = Instance.new("Folder")
			folder.Name = biome.id
			folder.Parent = parent
		end
		local ctx = newContext(biome, folder)
		BUILDERS[biome.id](ctx)
		plans[biome.id] = ctx.plan
	end
	return plans
end

-- Is the position inside a hazard zone of this kind?
function BiomeBuilder.inZone(plan: Plan, position: Vector3, kind: string): boolean
	return inZone({ plan = plan }, position, { [kind] = true })
end

return BiomeBuilder
