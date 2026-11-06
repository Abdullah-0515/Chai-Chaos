-- Builds the 8 biomes out of Roblox Terrain (sand, snow, water, mud, salt...)
-- and the props modelled in Blender (see Props.luau): each biome's landmark,
-- its trees and plants, and desi things like charpais, boats and tents.
--
-- Every biome is planned from a fixed random seed, so the world is the same
-- every time. Planning (where eggs, chests and hazard zones go) always runs;
-- building (creating terrain and parts) only runs when the map is new.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Biomes = require(Shared.Biomes)

local Props = require(script.Parent.Props)

local BiomeBuilder = {}

local GROUND_Y = Biomes.GROUND_Y
local EGG_SPOTS = 40
local CELL = 16
local OLD_HALF_ANGLE = 22.5 -- builders place things in degrees off the road, as in a 45 degree wedge

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

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
	stand: Vector3?, -- where you land after climbing (next to the chest)
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
		occupied = {}, -- round areas already taken by props: { position, radius, blocksEggs }
	}
end

-- A ground position `d` studs from the Chowk and `side` across the biome:
-- -22.5 is its left edge, 0 the middle, 22.5 its right edge (the numbers are
-- degrees from when biomes were wedges). The oval narrows near its ends, so
-- things squeeze in towards the middle there.
local function at(ctx, d: number, side: number): Vector3
	local a, b = Biomes.halfSize(ctx.biome)
	local along = d - Biomes.centerDistance(ctx.biome)
	local width = b * 0.86 * math.max(0.4, math.sqrt(math.max(0, 1 - (along / a) ^ 2)))
	return Biomes.fromLocal(ctx.biome, along, side / OLD_HALF_ANGLE * width)
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

local function chest(ctx, position: Vector3, kind: string, base: Vector3?, stand: Vector3?)
	table.insert(ctx.plan.chests, { position = position, kind = kind, base = base, stand = stand })
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

-- Every grid cell whose middle is inside the biome's zone (and, with
-- `minDistance`, at least that far from the Chowk).
local function cells(ctx, minDistance: number?): { Vector3 }
	local list = {}
	local center = Biomes.center(ctx.biome)
	local a, b = Biomes.halfSize(ctx.biome)
	local reach = math.max(a, b) * 1.15
	local x0 = math.floor((center.X - reach) / CELL) * CELL
	local z0 = math.floor((center.Z - reach) / CELL) * CELL
	for x = x0, center.X + reach, CELL do
		for z = z0, center.Z + reach, CELL do
			local spot = Vector3.new(x, GROUND_Y, z)
			if Biomes.contains(ctx.biome, spot) and (minDistance == nil or math.sqrt(x * x + z * z) >= minDistance) then
				table.insert(list, spot)
			end
		end
	end
	return list
end

-- Fill the biome's ground with one terrain material, cell by cell.
local function ground(ctx, material: Enum.Material)
	if not ctx.building then
		return
	end
	for _, spot in cells(ctx) do
		ctx.terrain:FillBlock(CFrame.new(spot.X, GROUND_Y - 2, spot.Z), Vector3.new(CELL, 4, CELL), material)
	end
end

-- Random egg spots on the ground, away from the given zone kinds.
local function eggSpots(ctx, dMin: number, dMax: number, sideMax: number, avoid: { [string]: boolean })
	local tries = 0
	while #ctx.plan.eggSpots < EGG_SPOTS and tries < 2000 do
		tries += 1
		local d, side = randomSpot(ctx, dMin, dMax, sideMax)
		local spot = at(ctx, d, side)
		local blocked = false
		for _, o in ctx.occupied do
			if o.blocksEggs and ((spot - o.position) * Vector3.new(1, 0, 1)).Magnitude < o.radius then
				blocked = true
			end
		end
		if not blocked and not inZone(ctx, spot, avoid) and Biomes.contains(ctx.biome, spot, 0.05) then
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
-- Props (modelled in Blender, see Props.luau)
---------------------------------------------------------------------------
-- Marks a round area as taken so scattered props keep out of it. With
-- `blocksEggs`, eggs keep out too (inside a fort's walls, under a hut).
local function occupy(ctx, position: Vector3, radius: number, blocksEggs: boolean?)
	table.insert(ctx.occupied, { position = position, radius = radius, blocksEggs = blocksEggs == true })
end

local function isFree(ctx, position: Vector3, radius: number): boolean
	for _, o in ctx.occupied do
		local dx, dz = position.X - o.position.X, position.Z - o.position.Z
		if dx * dx + dz * dz < (radius + o.radius) ^ 2 then
			return false
		end
	end
	return true
end

-- Builds a prop at `cf` (only when building; planning just needs the numbers).
local function place(ctx, name: string, cf: CFrame, scale: number?)
	if ctx.building then
		Props.place(name, cf, ctx.folder, scale)
	end
end

-- A prop standing on the ground: turned `yaw` degrees, or facing the Chowk.
local function prop(ctx, name: string, position: Vector3, yaw: number?, scale: number?): CFrame
	local base = onGround(ctx, position)
	local cf = if yaw then CFrame.new(base) * CFrame.Angles(0, math.rad(yaw), 0) else facing(base)
	place(ctx, name, cf, scale)
	return cf
end

-- A prop floating on the water (boats, lily pads).
local function afloat(ctx, name: string, position: Vector3, yaw: number, sink: number?)
	local cf = CFrame.new(position.X, GROUND_Y - (sink or 0), position.Z) * CFrame.Angles(0, math.rad(yaw), 0)
	place(ctx, name, cf)
	return cf
end

-- Writes on a prop's sign (see the anchors in PropData.luau).
local function sign(ctx, name: string, cf: CFrame, anchor: string, width: number, height: number, text: string)
	if ctx.building then
		Props.text(ctx.folder, cf, Props.anchor(name, anchor, cf), width, height, text)
	end
end

type ScatterOptions = {
	dMin: number?, -- distance range from the Chowk
	dMax: number?,
	side: number?, -- how far across (22.5 = the zone's edge)
	spacing: number?, -- studs to keep from other props
	scale: { number }?, -- random size range
	avoid: { [string]: boolean }?, -- hazard zones to keep out of
	clearPath: number?, -- keep this many studs either side of the middle clear
	maxHeight: number?, -- not higher up a hill than this
}

-- Sprinkles `count` of a prop (or of a list of props) at random free spots.
local function scatter(ctx, names: string | { string }, count: number, opts: ScatterOptions)
	local list = if type(names) == "string" then { names } else names
	local placed, tries = 0, 0
	while placed < count and tries < count * 10 do
		tries += 1
		local d, side =
			randomSpot(ctx, opts.dMin or ctx.inner + 10, opts.dMax or ctx.inner + Biomes.DEPTH - 10, opts.side or 21)
		local name = list[ctx.rng:NextInteger(1, #list)]
		local scale = if opts.scale then ctx.rng:NextNumber(opts.scale[1], opts.scale[2]) else 1
		local yaw = ctx.rng:NextNumber(0, 360)
		local spot = at(ctx, d, side)
		local radius = (opts.spacing or 4) * scale
		local _, lateral = Biomes.toLocal(ctx.biome, spot)
		local ok = Biomes.contains(ctx.biome, spot, 0.06)
			and isFree(ctx, spot, radius)
			and not (opts.avoid and inZone(ctx, spot, opts.avoid))
			and not (opts.clearPath and math.abs(lateral) < opts.clearPath)
			and not (opts.maxHeight and surface(ctx, spot) > GROUND_Y + opts.maxHeight)
		if ok then
			prop(ctx, name, spot, yaw, scale)
			occupy(ctx, spot, radius * 0.6)
			placed += 1
		end
	end
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
	-- the canal across the fields, and the rehat (Persian water wheel) over it
	local canalD = inner + 150
	for side = -24, 24, 1.2 do
		local spot = at(ctx, canalD, side)
		if Biomes.contains(ctx.biome, spot, -0.02) then
			pond(ctx, spot, 4.5, 3, Enum.Material.Water)
		end
	end
	local rehat = facing(onGround(ctx, at(ctx, canalD, 7)))
	place(ctx, "Rehat", rehat)
	occupy(ctx, rehat.Position, 13, true)
	part(ctx, {
		Name = "CanalBridge",
		Size = Vector3.new(6, 0.6, 12),
		CFrame = facing(onGround(ctx, at(ctx, canalD, 0))) * CFrame.new(0, 0.5, 0),
		Color = rgb(150, 100, 60),
		Material = Enum.Material.WoodPlanks,
	})
	-- muddy rice paddies
	for _, spot in { { inner + 80, -12 }, { inner + 182, 11 }, { inner + 240, -7 } } do
		local center = at(ctx, spot[1], spot[2])
		pond(ctx, center, 14, 2, Enum.Material.Mud)
		zone(ctx, { kind = "mud", center = center, radius = 14 })
		occupy(ctx, center, 14)
	end
	-- the village: mud houses, charpais, a tandoor, matkas and the water tank
	for _, h in { { 196, 13, 8 }, { 214, 17, -12 }, { 182, 18, 20 } } do
		local spot = at(ctx, inner + h[1], h[2])
		place(ctx, "MudHut", facing(onGround(ctx, spot)) * CFrame.Angles(0, math.rad(h[3]), 0))
		occupy(ctx, spot, 7, true)
	end
	for _, c in { { 204, 8, 30 }, { 189, 12, 100 } } do
		local spot = at(ctx, inner + c[1], c[2])
		prop(ctx, "Charpai", spot, c[3])
		occupy(ctx, spot, 3)
	end
	prop(ctx, "Tandoor", at(ctx, inner + 205, 19), 0)
	occupy(ctx, at(ctx, inner + 205, 19), 2)
	prop(ctx, "Matka", at(ctx, inner + 222, 12))
	occupy(ctx, at(ctx, inner + 222, 12), 2.5)
	local pump = at(ctx, inner + 122, 15)
	prop(ctx, "TubeWell", pump)
	pond(ctx, pump + Vector3.new(0, 0, 5), 3, 2, Enum.Material.Water)
	occupy(ctx, pump, 6)
	local tank = facing(onGround(ctx, at(ctx, inner + 175, -15)))
	place(ctx, "WaterTank", tank)
	occupy(ctx, tank.Position, 6, true)
	chest(
		ctx,
		Props.anchor("WaterTank", "Top", tank),
		"climb",
		Props.anchor("WaterTank", "Base", tank),
		Props.anchor("WaterTank", "TopStand", tank)
	)
	local tractor = at(ctx, inner + 110, -15)
	prop(ctx, "TractorTrolley", tractor)
	occupy(ctx, tractor, 9)
	prop(ctx, "KiteLine", at(ctx, inner + 58, 9))
	occupy(ctx, at(ctx, inner + 58, 9), 6)
	-- fields of wheat and sarson between everything
	local crops = { "WheatField", "SarsonField" }
	local k = 0
	for _, d in { 36, 64, 92, 208, 236, 262 } do
		for _, side in { -17, -9, 9, 17 } do
			local spot = at(ctx, inner + d, side)
			if
				Biomes.contains(ctx.biome, spot, 0.14)
				and isFree(ctx, spot, 10.5)
				and math.abs(d + inner - canalD) > 16
			then
				k += 1
				prop(ctx, crops[k % 2 + 1], spot)
				occupy(ctx, spot, 10)
			end
		end
	end
	scatter(ctx, "Haystack", 5, { spacing = 4, clearPath = 6 })
	scatter(ctx, "KikarTree", 6, { spacing = 5, scale = { 0.9, 1.3 }, clearPath = 6 })
	scatter(ctx, "MangoTree", 3, { spacing = 5, scale = { 0.9, 1.2 }, clearPath = 6 })
	for _ = 1, 4 do
		local d, side = randomSpot(ctx, inner + 60, inner + 240, 18)
		animal(ctx, at(ctx, d, side), rgb(45, 40, 40), 2.6, "Buffalo")
	end
	chest(ctx, onGround(ctx, at(ctx, inner + 232, 13)), "dig")
	eggSpots(ctx, inner + 20, inner + 265, 18, {})
end

function BUILDERS.Jungle(ctx)
	local inner = ctx.inner
	ground(ctx, Enum.Material.LeafyGrass)
	-- the river crossing the jungle, and the rope bridge over it
	local riverD = inner + 160
	zone(ctx, { kind = "water", inner = riverD - 10, outer = riverD + 10 })
	for side = -24, 24, 2 do
		local spot = at(ctx, riverD, side)
		if Biomes.contains(ctx.biome, spot, -0.04) then
			pondBlock(
				ctx,
				CFrame.lookAt(spot, Vector3.new(0, spot.Y, 0)),
				Vector3.new(riverD * math.rad(2) + 4, 6, 20),
				6,
				Enum.Material.Water
			)
		end
	end
	local bridge = facing(onGround(ctx, at(ctx, riverD, 0)))
	place(ctx, "RopeBridge", bridge)
	occupy(ctx, bridge.Position, 19, true)
	-- the waterfall cliff, with treasure on top
	local cliff = at(ctx, inner + 255, -9)
	hill(ctx, cliff + Vector3.new(0, 4, 0), 24, Enum.Material.Rock)
	part(ctx, {
		Name = "Waterfall",
		Size = Vector3.new(8, 26, 1),
		CFrame = facing(cliff) * CFrame.new(0, 14, -21),
		Color = rgb(150, 210, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.4,
		CanCollide = false,
		CastShadow = false,
	})
	pond(ctx, cliff + facing(cliff).LookVector * 26, 9, 4, Enum.Material.Water)
	occupy(ctx, cliff, 26)
	chest(ctx, onGround(ctx, cliff), "climb", cliff + facing(cliff).LookVector * 28)
	-- the treehouse
	local tree = facing(onGround(ctx, at(ctx, inner + 92, -12)))
	place(ctx, "Treehouse", tree)
	occupy(ctx, tree.Position, 10, true)
	-- the jungle itself
	local water = { water = true }
	scatter(ctx, "BanyanTree", 4, { spacing = 11, avoid = water, clearPath = 9 })
	scatter(ctx, "JungleTree", 26, { spacing = 4.5, scale = { 0.85, 1.25 }, avoid = water, clearPath = 6 })
	scatter(ctx, "Bamboo", 8, { spacing = 4, avoid = water, clearPath = 6 })
	scatter(ctx, { "JungleBush", "Fern" }, 30, { spacing = 2.5, avoid = water, clearPath = 4 })
	scatter(ctx, "MossyRock", 8, { spacing = 3, avoid = water })
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
	eggSpots(ctx, inner + 15, inner + 265, 19, water)
end

function BUILDERS.Samandar(ctx)
	local inner = ctx.inner
	ground(ctx, Enum.Material.Sand)
	local seaFrom = inner + 215
	zone(ctx, { kind = "water", inner = seaFrom, outer = inner + Biomes.DEPTH + 20 })
	zone(ctx, { kind = "shore", inner = seaFrom - 30, outer = seaFrom })
	if ctx.building then
		for _, spot in cells(ctx, seaFrom) do
			pondBlock(ctx, CFrame.new(spot.X, 0, spot.Z), Vector3.new(CELL, 0, CELL), 10, Enum.Material.Water)
		end
	end
	-- the island and its lighthouse, with treasure on the gallery
	local island = at(ctx, seaFrom + 35, 12)
	hill(ctx, island - Vector3.new(0, 4, 0), 14, Enum.Material.Rock)
	local lighthouse = facing(onGround(ctx, island))
	place(ctx, "Lighthouse", lighthouse)
	chest(
		ctx,
		Props.anchor("Lighthouse", "Gallery", lighthouse),
		"climb",
		at(ctx, seaFrom - 5, 12),
		Props.anchor("Lighthouse", "GalleryStand", lighthouse)
	)
	-- beach huts facing the sea, boats, nets and a gola cart
	local huts = { "BeachHutTeal", "BeachHutPink", "BeachHutYellow" }
	for i, side in { -12, 0, 12 } do
		local spot = at(ctx, inner + 150, side + 3)
		place(ctx, huts[i], facing(onGround(ctx, spot)) * CFrame.Angles(0, math.pi, 0))
		occupy(ctx, spot, 6, true)
	end
	for _, b in { { seaFrom - 12, -6, 40 }, { seaFrom - 15, 9, -30 } } do
		local spot = at(ctx, b[1], b[2])
		prop(ctx, "FishingBoat", spot, b[3])
		occupy(ctx, spot, 8)
	end
	afloat(ctx, "FishingBoat", at(ctx, seaFrom + 25, -14), 70, 1.2)
	afloat(ctx, "FishingBoat", at(ctx, seaFrom + 42, 4), -20, 1.2)
	afloat(ctx, "RowBoat", at(ctx, seaFrom + 14, 2), 15, 0.7)
	for _, n in { { seaFrom - 26, -14 }, { seaFrom - 28, 15 } } do
		local spot = at(ctx, n[1], n[2])
		prop(ctx, "NetRack", spot)
		occupy(ctx, spot, 4)
	end
	prop(ctx, "GolaCart", at(ctx, inner + 118, 7))
	occupy(ctx, at(ctx, inner + 118, 7), 4)
	scatter(ctx, "CoconutPalm", 14, { dMin = inner + 20, dMax = seaFrom - 34, spacing = 4, scale = { 0.9, 1.2 } })
	scatter(ctx, "BeachUmbrella", 5, { dMin = inner + 80, dMax = seaFrom - 30, spacing = 5 })
	scatter(ctx, "BeachRocks", 6, { dMin = inner + 40, dMax = seaFrom - 4, spacing = 3 })
	scatter(ctx, "DuneGrass", 16, { dMax = seaFrom - 40, spacing = 2 })
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
	chest(ctx, onGround(ctx, at(ctx, inner + 120, -14)), "dig")
	eggSpots(ctx, inner + 15, seaFrom - 5, 19, { water = true })
end

function BUILDERS.Jheel(ctx)
	local inner = ctx.inner
	ground(ctx, Enum.Material.LeafyGrass)
	local lake = at(ctx, inner + 150, 0)
	pond(ctx, lake, 55, 8, Enum.Material.Water)
	zone(ctx, { kind = "water", center = lake, radius = 55 })
	occupy(ctx, lake, 56)
	-- mountains behind the meadows
	for _, side in { -15, 0, 15 } do
		local peak = at(ctx, inner + Biomes.DEPTH + 10, side)
		hill(ctx, peak - Vector3.new(0, 20, 0), 45, Enum.Material.Rock)
		fillBall(ctx, peak + Vector3.new(0, 14, 0), 18, Enum.Material.Snow)
	end
	-- the rest house, its jetty and the rowing boats
	local house = onGround(ctx, at(ctx, inner + 64, -13))
	local houseCF = CFrame.lookAt(house, Vector3.new(lake.X, house.Y, lake.Z))
	place(ctx, "RestHouse", houseCF)
	occupy(ctx, house, 13, true)
	local toHouse = ((house - lake) * Vector3.new(1, 0, 1)).Unit
	local shore = Vector3.new(lake.X, GROUND_Y, lake.Z) + toHouse * 53
	local jetty = CFrame.lookAt(shore, Vector3.new(lake.X, GROUND_Y, lake.Z))
	place(ctx, "Jetty", jetty)
	occupy(ctx, shore, 5)
	for i, offset in { Vector3.new(-7, 0, -30), Vector3.new(7, 0, -34), Vector3.new(-6, 0, -44) } do
		afloat(ctx, "RowBoat", (jetty * CFrame.new(offset)).Position, 40 * i, 0.7)
	end
	for i = 1, 6 do
		local a = i * math.pi / 3 + 0.4
		local r = 18 + (i % 3) * 9
		afloat(ctx, "LilyPads", lake + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r), i * 50, -0.05)
	end
	-- reeds on the shore and willows just behind them
	for i = 1, 18 do
		local a = i * 2 * math.pi / 18 + ctx.rng:NextNumber(-0.1, 0.1)
		local spot = lake + Vector3.new(math.cos(a), 0, math.sin(a)) * ctx.rng:NextNumber(54, 58)
		if Biomes.contains(ctx.biome, spot, 0.04) and isFree(ctx, spot, 0) then
			prop(ctx, "Reeds", spot, i * 37)
		end
	end
	for i = 1, 7 do
		local a = i * 2 * math.pi / 7 + 0.2
		local spot = lake + Vector3.new(math.cos(a), 0, math.sin(a)) * 66
		if Biomes.contains(ctx.biome, spot, 0.06) and isFree(ctx, spot, 5) then
			prop(ctx, "Willow", spot, i * 51)
			occupy(ctx, spot, 5)
		end
	end
	for _, a in { 2.2, 3.4 } do
		local spot = lake + Vector3.new(math.cos(a), 0, math.sin(a)) * 61
		local cf = CFrame.lookAt(onGround(ctx, spot), Vector3.new(lake.X, GROUND_Y, lake.Z))
		place(ctx, "Bench", cf * CFrame.Angles(0, math.pi, 0))
		occupy(ctx, spot, 3)
	end
	local water = { water = true }
	climbChest(ctx, at(ctx, inner + 70, 16), 26, Enum.Material.Rock)
	occupy(ctx, at(ctx, inner + 70, 16), 8)
	scatter(ctx, "Poplar", 12, { spacing = 4, avoid = water, scale = { 0.9, 1.3 }, clearPath = 5 })
	scatter(ctx, "FlowerPatch", 30, { spacing = 2.5, avoid = water })
	scatter(ctx, "Boulder", 4, { spacing = 4, avoid = water })
	chest(ctx, onGround(ctx, at(ctx, inner + 215, -10)), "dig")
	eggSpots(ctx, inner + 15, inner + 255, 19, water)
end

function BUILDERS.Registan(ctx)
	local inner = ctx.inner
	ground(ctx, Enum.Material.Sand)
	zone(ctx, { kind = "sandstorm", inner = inner, outer = inner + Biomes.DEPTH })
	local fortCenter = at(ctx, inner + 200, 8)
	-- dunes, but none on top of the fort
	for _ = 1, 16 do
		local d, side = randomSpot(ctx, inner + 30, inner + 270, 19)
		local radius = ctx.rng:NextNumber(22, 40)
		local spot = at(ctx, d, side)
		if ((spot - fortCenter) * Vector3.new(1, 0, 1)).Magnitude > radius + 46 then
			hill(ctx, spot - Vector3.new(0, radius * 0.65, 0), radius, Enum.Material.Sand)
		end
	end
	-- the old fort, with treasure on top of a tower
	local fort = facing(onGround(ctx, fortCenter))
	place(ctx, "DesertFort", fort)
	occupy(ctx, fortCenter, 44, true)
	chest(
		ctx,
		Props.anchor("DesertFort", "TowerTop", fort),
		"climb",
		Props.anchor("DesertFort", "TowerBase", fort),
		Props.anchor("DesertFort", "TowerStand", fort)
	)
	scatter(ctx, "DesertTent", 2, { spacing = 8, maxHeight = 3 })
	scatter(ctx, "RockMesa", 4, { spacing = 9, maxHeight = 4 })
	scatter(ctx, "KikarDry", 10, { spacing = 6, scale = { 0.8, 1.2 } })
	scatter(ctx, "DesertShrub", 14, { spacing = 3 })
	scatter(ctx, "DuneGrass", 14, { spacing = 2 })
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
	-- the stilt village over its own pool, with treasure on a hut roof
	local villageSpot = at(ctx, inner + 150, 9)
	pond(ctx, villageSpot, 20, 5, Enum.Material.Water)
	zone(ctx, { kind = "water", center = villageSpot, radius = 20 })
	local village = facing(onGround(ctx, villageSpot))
	place(ctx, "StiltVillage", village)
	occupy(ctx, villageSpot, 25, true)
	chest(
		ctx,
		Props.anchor("StiltVillage", "HutRoof", village),
		"climb",
		Props.anchor("StiltVillage", "HutBase", village),
		Props.anchor("StiltVillage", "HutRoofStand", village)
	)
	afloat(ctx, "RowBoat", Props.anchor("StiltVillage", "PierEnd", village) + village.RightVector * 4, 80, 0.7)
	-- muddy pools
	for _ = 1, 6 do
		local d, side = randomSpot(ctx, inner + 40, inner + 260, 17)
		local radius = ctx.rng:NextNumber(12, 22)
		local spot = at(ctx, d, side)
		if ((spot - villageSpot) * Vector3.new(1, 0, 1)).Magnitude > radius + 28 then
			pond(ctx, spot, radius, 4, Enum.Material.Water)
			zone(ctx, { kind = "water", center = spot, radius = radius })
		end
	end
	for _, n in { { 118, 4 }, { 124, 16 } } do
		local spot = at(ctx, inner + n[1], n[2])
		prop(ctx, "NetRack", spot)
		occupy(ctx, spot, 4)
	end
	scatter(ctx, "FishingBoat", 1, { dMin = inner + 60, dMax = inner + 120, spacing = 8 })
	scatter(ctx, "Mangrove", 30, { spacing = 4, scale = { 0.85, 1.3 }, clearPath = 5 })
	scatter(ctx, "Reeds", 18, { spacing = 2.5 })
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
	-- two rocky ridges and the suspension bridge across the gorge between them
	local mid = at(ctx, inner + 128, -13)
	local bridge = CFrame.new(mid.X, GROUND_Y + 16, mid.Z) * facing(mid).Rotation
	for _, z in { -30, 30 } do
		local top = (bridge * CFrame.new(0, 0, z * 1.1)).Position
		hill(ctx, top - Vector3.new(0, 22, 0), 22, Enum.Material.Rock)
		fillBall(ctx, top - Vector3.new(0, 4, 0), 9, Enum.Material.Snow)
	end
	place(ctx, "SuspensionBridge", bridge)
	occupy(ctx, mid, 34)
	-- the frozen lake and glaciers: slippery!
	local lake = at(ctx, inner + 140, -4)
	pond(ctx, lake, 30, 3, Enum.Material.Ice)
	zone(ctx, { kind = "ice", center = lake, radius = 30 })
	for _, g in { { 60, 6 }, { 200, 4 }, { 230, -10 } } do
		local spot = at(ctx, inner + g[1], g[2])
		pond(ctx, spot, 15, 3, Enum.Material.Glacier)
		zone(ctx, { kind = "ice", center = spot, radius = 15 })
	end
	-- the stone hut
	local hutSpot = at(ctx, inner + 172, 13)
	place(ctx, "MountainHut", facing(onGround(ctx, hutSpot)))
	occupy(ctx, hutSpot, 8, true)
	local ice = { ice = true }
	climbChest(ctx, at(ctx, inner + 220, 11), 30, Enum.Material.Rock)
	occupy(ctx, at(ctx, inner + 220, 11), 8)
	scatter(ctx, "DeodarSnowy", 34, { spacing = 5, scale = { 0.8, 1.3 }, avoid = ice, maxHeight = 20, clearPath = 5 })
	scatter(ctx, "SnowRock", 10, { spacing = 4, avoid = ice })
	scatter(ctx, "Juniper", 10, { spacing = 3, avoid = ice })
	for _ = 1, 3 do
		local d, side = randomSpot(ctx, inner + 40, inner + 200, 10)
		animal(ctx, at(ctx, d, side), rgb(70, 55, 45), 3, "Yak")
	end
	chest(ctx, onGround(ctx, at(ctx, inner + 80, 9)), "dig")
	eggSpots(ctx, inner + 15, inner + 250, 15, {})
end

-- The tunnels of the salt caves, as (distance, side) points.
local TUNNELS = {
	{ { 20, 0 }, { 70, 0 }, { 110, -7 }, { 160, -11 }, { 200, -4 }, { 245, 6 }, { 262, 14 } },
	{ { 110, -7 }, { 150, 8 }, { 190, 14 }, { 230, 15 } },
}
local TUNNEL_FLOOR = GROUND_Y - 2 -- the bottom of the carved tunnels

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
	-- carve the tunnels; timber frames hold them up, salt crystals glow on the walls
	local chamber = at(ctx, inner + 200, -4)
	for t, tunnel in TUNNELS do
		local sinceSupport = 0
		for i = 1, #tunnel - 1 do
			local a = at(ctx, inner + tunnel[i][1], tunnel[i][2])
			local b = at(ctx, inner + tunnel[i + 1][1], tunnel[i + 1][2])
			local dir = (b - a).Unit
			local steps = math.ceil((b - a).Magnitude / 4)
			for s = 0, steps do
				local p = a:Lerp(b, s / steps)
				fillBall(ctx, p + Vector3.new(0, 7, 0), 9, Enum.Material.Air)
				sinceSupport += 1
				if sinceSupport >= 6 and (p - chamber).Magnitude > 20 then
					sinceSupport = 0
					place(
						ctx,
						"CaveSupport",
						CFrame.lookAt(
							Vector3.new(p.X, TUNNEL_FLOOR + 1, p.Z),
							Vector3.new(p.X, TUNNEL_FLOOR + 1, p.Z) + dir
						)
					)
				end
				if s % 9 == 4 then
					local side = if s % 2 == 0 then 1 else -1
					local wall = p + dir:Cross(Vector3.yAxis) * 6.2 * side
					place(ctx, "SaltCrystals", CFrame.new(wall.X, TUNNEL_FLOOR + 1.2, wall.Z) * CFrame.Angles(0, s, 0))
				end
				if s % 2 == 0 then
					table.insert(
						ctx.plan.eggSpots,
						p + Vector3.new(ctx.rng:NextNumber(-2, 2), -1, ctx.rng:NextNumber(-2, 2))
					)
				end
			end
			-- mine-cart track along the main tunnel
			if t == 1 then
				local length = (b - a).Magnitude
				for k = 0, math.floor(length / 16) - 1 do
					local c = a + dir * (8 + k * 16)
					local floor = Vector3.new(c.X, TUNNEL_FLOOR + 0.6, c.Z)
					place(ctx, "MineTrack", CFrame.lookAt(floor, floor + dir))
					if (i + k) % 5 == 2 then
						place(
							ctx,
							"MineCart",
							CFrame.lookAt(floor + Vector3.new(0, 0.5, 0), floor + Vector3.new(0, 0.5, 0) + dir)
						)
					end
				end
			end
		end
	end
	-- the crystal chamber
	local chamberCenter = chamber + Vector3.new(0, 9, 0)
	fillBall(ctx, chamberCenter, 18, Enum.Material.Air)
	local function chamberFloor(offset: Vector3): Vector3
		local r = math.min(offset.Magnitude, 17)
		return Vector3.new(chamber.X + offset.X, chamberCenter.Y - math.sqrt(18 * 18 - r * r), chamber.Z + offset.Z)
	end
	for k = 1, 3 do
		local a = k * 2 * math.pi / 3 + 0.5
		place(
			ctx,
			"CrystalCluster",
			CFrame.new(chamberFloor(Vector3.new(math.cos(a) * 9, 0, math.sin(a) * 9))) * CFrame.Angles(0, a, 0)
		)
	end
	for k = 1, 6 do
		local a = k * math.pi / 3
		local name = if k % 2 == 0 then "SaltCrystals" else "Stalagmites"
		place(
			ctx,
			name,
			CFrame.new(chamberFloor(Vector3.new(math.cos(a) * 13.5, 0, math.sin(a) * 13.5))) * CFrame.Angles(0, a, 0)
		)
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
	chest(ctx, ledge + Vector3.new(0, 0.5, 0), "climb", chamber - Vector3.new(0, 1, 0), ledge + Vector3.new(-2, 0.5, 0))
	chest(ctx, chamber + Vector3.new(-6, -1, 6), "dig")
	-- the mine entrance, with salt crystals and rocks outside
	local entrance = facing(onGround(ctx, at(ctx, inner + 12, 0)))
	place(ctx, "MineEntrance", entrance)
	sign(ctx, "MineEntrance", entrance, "Sign", 9.6, 2.2, "NAMAK KAAN")
	occupy(ctx, entrance.Position, 11)
	scatter(ctx, "SaltCrystals", 8, { dMin = inner + 2, dMax = inner + 32, spacing = 3, clearPath = 9 })
	scatter(ctx, "Boulder", 4, { dMin = inner + 2, dMax = inner + 40, spacing = 4, clearPath = 9 })
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

-- A pond flush with the ground anywhere in the world (the countryside uses it).
function BiomeBuilder.pondAt(center: Vector3, radius: number, depth: number, material: Enum.Material)
	pond({ building = true, terrain = workspace.Terrain }, center, radius, depth, material)
end

-- Is the position inside a hazard zone of this kind?
function BiomeBuilder.inZone(plan: Plan, position: Vector3, kind: string): boolean
	return inZone({ plan = plan }, position, { [kind] = true })
end

return BiomeBuilder
