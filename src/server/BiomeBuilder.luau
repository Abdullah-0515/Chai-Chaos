-- Builds the 12 zones out of Roblox Terrain (grass, sand, salt, snow, water...)
-- and the props modelled in Blender (see Props.luau): each zone's landmark,
-- its trees and plants, and desi things like tents, camels, stalls and boats.
--
-- Every zone is planned from a fixed random seed, so the world is the same
-- every time. Planning (where eggs, chests and hazard areas go) always runs;
-- building (creating terrain and parts) only runs when the map is new.
--
-- Positions inside a zone are given as (rf, sf): rf goes from 0 at the zone's
-- inner edge to 1 at its outer edge, sf from -1 at one side to 1 at the other.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Biomes = require(Shared.Biomes)

local Props = require(script.Parent.Props)

local BiomeBuilder = {}

local GROUND_Y = Biomes.GROUND_Y
local EGG_SPOTS = 40
local CELL = 16
local EDGE = 10 -- studs kept clear along the zone's walls and fences
local GATE_CLEAR = 26 -- studs kept clear around gates and shortcut doors

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

export type Zone = {
	kind: string, -- water, mud, ice, shore, dark, sandstorm, sand
	center: Vector3?, -- circles
	radius: number?,
	inner: number?, -- bands: distance from the Chowk (inside this zone)
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
	rickshaw: Vector3?, -- ring 3: where the rickshaw home waits
}

---------------------------------------------------------------------------
-- Context helpers
---------------------------------------------------------------------------
local function newContext(biome, folder: Instance?)
	local r1, r2 = Biomes.innerRadius(biome), Biomes.outerRadius(biome)
	local ctx = {
		biome = biome,
		folder = folder,
		building = folder ~= nil,
		rng = Random.new(2000 + biome.index),
		r1 = r1,
		r2 = r2,
		mid = biome.angle,
		terrain = workspace.Terrain,
		plan = { biome = biome, eggSpots = {}, chests = {}, zones = {}, balls = {} } :: Plan,
		occupied = {}, -- round areas already taken: { position, radius, blocksEggs }
		clear = {}, -- spots that must stay open (gates and doors)
	}
	-- keep the gates in and out of this zone and its shortcut doors clear
	local angle, radius = Biomes.gate(biome)
	table.insert(ctx.clear, Biomes.polar(angle, radius))
	local outer = Biomes.byRegion[biome.region][biome.ring + 1]
	if outer then
		local a2, rr2 = Biomes.gate(outer)
		table.insert(ctx.clear, Biomes.polar(a2, rr2))
	end
	for _, door in Biomes.shortcuts() do
		if door.a == biome or door.b == biome then
			table.insert(ctx.clear, Biomes.polar(door.angle, door.radius))
		end
	end
	for _, pump in Biomes.pumps() do
		if Biomes.at(pump) == biome then
			table.insert(ctx.clear, pump)
		end
	end
	return ctx
end

-- A ground position in the zone: rf from 0 (inner edge) to 1 (outer edge),
-- sf from -1 to 1 across it.
local function at(ctx, rf: number, sf: number): Vector3
	local r = ctx.r1 + EDGE + rf * (ctx.r2 - ctx.r1 - 2 * EDGE)
	local span = Biomes.SPAN - math.deg(EDGE / r)
	return Biomes.polar(ctx.mid + sf * span, r)
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

-- The whole zone is this kind (dark caves, sandy desert, sandstorms).
local function wholeZone(ctx, kind: string)
	zone(ctx, { kind = kind, inner = ctx.r1, outer = ctx.r2 })
end

local function chest(ctx, position: Vector3, kind: string, base: Vector3?, stand: Vector3?)
	table.insert(ctx.plan.chests, { position = position, kind = kind, base = base, stand = stand })
end

local function inZone(plan: Plan, position: Vector3, kinds: { [string]: boolean }): boolean
	local r = Biomes.radiusOf(position)
	for _, z in plan.zones do
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

-- Facing the Chowk.
local function facing(position: Vector3): CFrame
	local toward = Vector3.new(0, position.Y, 0)
	if (toward - position).Magnitude < 0.01 then
		return CFrame.new(position)
	end
	return CFrame.lookAt(position, toward)
end

-- Marks a round area as taken so scattered props keep out of it. With
-- `blocksEggs`, eggs keep out too (inside a fort's walls, under a hut).
local function occupy(ctx, position: Vector3, radius: number, blocksEggs: boolean?)
	table.insert(ctx.occupied, { position = position, radius = radius, blocksEggs = blocksEggs == true })
end

-- Is this spot free for something `radius` studs across: inside the zone, off
-- the roads, away from gates and doors and other props?
local function isFree(ctx, position: Vector3, radius: number, ignoreProps: boolean?): boolean
	if not Biomes.contains(ctx.biome, position, EDGE + radius) then
		return false
	end
	if Biomes.roadDistance(position) < radius + 3 then
		return false
	end
	for _, spot in ctx.clear do
		local dx, dz = position.X - spot.X, position.Z - spot.Z
		if dx * dx + dz * dz < (GATE_CLEAR + radius) ^ 2 then
			return false
		end
	end
	if ignoreProps then
		return true
	end
	for _, o in ctx.occupied do
		local dx, dz = position.X - o.position.X, position.Z - o.position.Z
		if dx * dx + dz * dz < (radius + o.radius) ^ 2 then
			return false
		end
	end
	return true
end

-- Every grid cell whose middle is inside the zone.
local function cells(ctx): { Vector3 }
	local list = {}
	local r = ctx.r2 + CELL
	for x = math.floor(-r / CELL) * CELL, r, CELL do
		for z = math.floor(-r / CELL) * CELL, r, CELL do
			local spot = Vector3.new(x, GROUND_Y, z)
			if Biomes.contains(ctx.biome, spot) then
				table.insert(list, spot)
			end
		end
	end
	return list
end

-- Fill the zone's ground with one terrain material (and some patches of a second).
local function ground(ctx, material: Enum.Material, patches: Enum.Material?, share: number?)
	if not ctx.building then
		return
	end
	local rng = Random.new(3000 + ctx.biome.index)
	for _, spot in cells(ctx) do
		local m = if patches and rng:NextNumber() < (share or 0.2) then patches else material
		ctx.terrain:FillBlock(CFrame.new(spot.X, GROUND_Y - 2, spot.Z), Vector3.new(CELL, 4, CELL), m)
	end
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

-- A prop facing along the zone (its front towards angle `toward` round the circle).
local function propFacing(ctx, name: string, position: Vector3, target: Vector3, scale: number?): CFrame
	local base = onGround(ctx, position)
	local flatTarget = Vector3.new(target.X, base.Y, target.Z)
	local cf = if (flatTarget - base).Magnitude > 0.01 then CFrame.lookAt(base, flatTarget) else CFrame.new(base)
	place(ctx, name, cf, scale)
	return cf
end

-- A landmark: placed if there is room, it keeps eggs and props out of `radius`.
local function landmark(ctx, name: string, rf: number, sf: number, radius: number, yaw: number?): CFrame?
	for k = 0, 12 do
		local spot = at(ctx, rf, sf + (if k % 2 == 0 then 1 else -1) * math.floor((k + 1) / 2) * 0.06)
		if isFree(ctx, spot, radius) then
			local cf = prop(ctx, name, spot, yaw)
			occupy(ctx, spot, radius, true)
			return cf
		end
	end
	return nil
end

-- Writes on a prop's sign (see the anchors in PropData.luau).
local function sign(ctx, name: string, cf: CFrame, anchor: string, width: number, height: number, text: string)
	if ctx.building then
		Props.text(ctx.folder, cf, Props.anchor(name, anchor, cf), width, height, text)
	end
end

-- A treasure chest at a landmark's own anchors (top, where you climb from, where you land).
local function climbAnchors(ctx, name: string, cf: CFrame?, top: string, base: string, stand: string)
	if cf then
		chest(ctx, Props.anchor(name, top, cf), "climb", Props.anchor(name, base, cf), Props.anchor(name, stand, cf))
	end
end

-- A treasure chest on top of a landmark, reached with a Rope Ladder.
local function climbOn(ctx, name: string, cf: CFrame?, anchor: string, baseOffset: Vector3)
	if not cf then
		return
	end
	local top = Props.anchor(name, anchor, cf)
	local stand = top + cf.RightVector * 2.5
	chest(ctx, top + Vector3.new(0, 0.1, 0), "climb", cf * baseOffset, stand)
end

type ScatterOptions = {
	rMin: number?,
	rMax: number?,
	spacing: number?,
	scale: { number }?,
	avoid: { [string]: boolean }?,
}

-- Sprinkles `count` of a prop (or of a list of props) at random free spots.
local function scatter(ctx, names: string | { string }, count: number, opts: ScatterOptions?)
	local o = opts or {}
	local list = if type(names) == "string" then { names } else names
	local placed, tries = 0, 0
	while placed < count and tries < count * 12 do
		tries += 1
		local spot = at(ctx, ctx.rng:NextNumber(o.rMin or 0, o.rMax or 1), ctx.rng:NextNumber(-1, 1))
		local name = list[ctx.rng:NextInteger(1, #list)]
		local scale = if o.scale then ctx.rng:NextNumber(o.scale[1], o.scale[2]) else 1
		local radius = (o.spacing or 4) * scale
		if isFree(ctx, spot, radius) and not (o.avoid and inZone(ctx.plan, spot, o.avoid)) then
			prop(ctx, name, spot, ctx.rng:NextNumber(0, 360), scale)
			occupy(ctx, spot, radius * 0.6)
			placed += 1
		end
	end
end

-- Random egg spots on the ground, away from the given hazard kinds.
local function eggSpots(ctx, avoid: { [string]: boolean }?)
	local tries = 0
	while #ctx.plan.eggSpots < EGG_SPOTS and tries < 3000 do
		tries += 1
		local spot = at(ctx, ctx.rng:NextNumber(0.02, 0.98), ctx.rng:NextNumber(-0.97, 0.97))
		local blocked = false
		for _, o in ctx.occupied do
			if o.blocksEggs and ((spot - o.position) * Vector3.new(1, 0, 1)).Magnitude < o.radius then
				blocked = true
				break
			end
		end
		if not blocked and isFree(ctx, spot, 2, true) and not (avoid and inZone(ctx.plan, spot, avoid)) then
			table.insert(ctx.plan.eggSpots, onGround(ctx, spot))
		end
	end
end

-- Buried treasure under an X, dug up with a Belcha.
local function digChests(ctx, count: number, avoid: { [string]: boolean }?)
	local placed, tries = 0, 0
	while placed < count and tries < 400 do
		tries += 1
		local spot = at(ctx, ctx.rng:NextNumber(0.15, 0.95), ctx.rng:NextNumber(-0.9, 0.9))
		if isFree(ctx, spot, 5) and not (avoid and inZone(ctx.plan, spot, avoid)) then
			chest(ctx, onGround(ctx, spot), "dig")
			occupy(ctx, spot, 5, true)
			placed += 1
		end
	end
end

-- A simple farm animal made of parts (buffaloes, goats, yaks).
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
	occupy(ctx, base, size * 1.4)
end

-- A string of little flags between two points.
local function bunting(ctx, from: Vector3, to: Vector3)
	local colors = { rgb(230, 60, 60), rgb(250, 190, 40), rgb(40, 160, 90), rgb(60, 120, 220), rgb(230, 90, 170) }
	local count = math.max(2, math.floor((to - from).Magnitude / 3))
	for i = 1, count - 1 do
		local p = from:Lerp(to, i / count) - Vector3.new(0, math.sin(i / count * math.pi) * 1.5, 0)
		part(ctx, {
			Name = "Flag",
			Size = Vector3.new(1.2, 1.2, 0.1),
			CFrame = CFrame.lookAt(p, p + (to - from):Cross(Vector3.yAxis)) * CFrame.Angles(0, 0, math.rad(45)),
			Color = colors[i % #colors + 1],
			Material = Enum.Material.Fabric,
			CanCollide = false,
			CastShadow = false,
		})
	end
end

-- A band of sea along the zone's outer edge (with a beach strip before it).
local function sea(ctx, from: number, shoreWidth: number)
	local cellList = if ctx.building then cells(ctx) else {}
	for _, spot in cellList do
		local r = Biomes.radiusOf(spot)
		if r >= from then
			ctx.terrain:FillBlock(
				CFrame.new(spot.X, GROUND_Y + 3, spot.Z),
				Vector3.new(CELL, 6, CELL),
				Enum.Material.Air
			)
			ctx.terrain:FillBlock(
				CFrame.new(spot.X, GROUND_Y - 3, spot.Z),
				Vector3.new(CELL, 6, CELL),
				Enum.Material.Water
			)
		end
	end
	zone(ctx, { kind = "water", inner = from, outer = ctx.r2 + 40 })
	zone(ctx, { kind = "shore", inner = from - shoreWidth, outer = from })
end

-- The rickshaw at the end of the road in every ring 3 zone: a free ride home.
local function rickshawHome(ctx)
	local stand = Biomes.roadEnd(ctx.biome)
	ctx.plan.rickshaw = stand
	occupy(ctx, stand, 14, true)
	if not ctx.building then
		return
	end
	local cf = facing(stand)
	local side = cf * CFrame.new(11, 0, 0)
	Props.place("Rickshaw", side * CFrame.Angles(0, math.rad(90), 0), ctx.folder)
	local signCF = cf * CFrame.new(-11, 0, 0)
	Props.place("Signboard", signCF, ctx.folder)
	Props.text(ctx.folder, signCF, Props.anchor("Signboard", "Face", signCF), 5.2, 2.2, "RICKSHAW\nTO THE CHOWK")
	local pad = part(ctx, {
		Name = "RickshawHome",
		Size = Vector3.new(8, 0.4, 8),
		CFrame = side * CFrame.new(0, 0.3, 0),
		Color = rgb(255, 220, 120),
		Material = Enum.Material.Neon,
		Transparency = 0.4,
		CanCollide = false,
	}) :: Part
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RickshawHome"
	prompt.ActionText = "Ride home"
	prompt.ObjectText = "Rickshaw to the Chowk"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad
end

---------------------------------------------------------------------------
-- The zones
---------------------------------------------------------------------------
local BUILDERS = {}

-------------------------------------------------------------------- Punjab
function BUILDERS.MangoBagh(ctx)
	ground(ctx, Enum.Material.Grass, Enum.Material.LeafyGrass, 0.3)
	-- tube wells with muddy puddles around them, and charpais in the shade
	for i, sf in { -0.55, 0.1, 0.65 } do
		local spot = at(ctx, 0.3 + (i % 2) * 0.35, sf)
		if isFree(ctx, spot, 12) then
			prop(ctx, "TubeWell", spot)
			pond(ctx, spot + Vector3.new(6, 0, 4), 9, 2, Enum.Material.Mud)
			zone(ctx, { kind = "mud", center = spot + Vector3.new(6, 0, 4), radius = 9 })
			occupy(ctx, spot, 12)
		end
	end
	scatter(ctx, "MangoTree", 34, { spacing = 9, scale = { 0.9, 1.2 }, avoid = { mud = true } })
	scatter(ctx, "KikarTree", 6, { spacing = 9 })
	scatter(ctx, "Charpai", 6, { spacing = 4 })
	scatter(ctx, { "Haystack", "Matka" }, 6, { spacing = 4 })
	for _ = 1, 4 do
		local spot = at(ctx, ctx.rng:NextNumber(0.2, 0.8), ctx.rng:NextNumber(-0.8, 0.8))
		if isFree(ctx, spot, 5) then
			animal(ctx, spot, rgb(50, 45, 45), 3, "Buffalo")
		end
	end
	local tank = landmark(ctx, "WaterTank", 0.8, -0.3, 10)
	climbAnchors(ctx, "WaterTank", tank, "Top", "Base", "TopStand")
	digChests(ctx, 2, { mud = true })
	eggSpots(ctx)
end

function BUILDERS.SarsonFields(ctx)
	ground(ctx, Enum.Material.Grass, Enum.Material.Mud, 0.08)
	-- muddy paths between the fields
	for _, rf in { 0.33, 0.66 } do
		for k = -6, 6 do
			local spot = at(ctx, rf, k / 6.5)
			if isFree(ctx, spot, 6, true) then
				pond(ctx, spot, 6, 2, Enum.Material.Mud)
				zone(ctx, { kind = "mud", center = spot, radius = 6 })
			end
		end
	end
	local fields = 0
	for row = 0, 2 do
		for col = -7, 7 do
			local spot = at(ctx, 0.16 + row * 0.33, col / 7.6)
			if isFree(ctx, spot, 11) and not inZone(ctx.plan, spot, { mud = true }) then
				prop(ctx, if (row + col) % 4 == 0 then "WheatField" else "SarsonField", spot, (col * 7) % 360)
				occupy(ctx, spot, 11)
				fields += 1
			end
		end
	end
	landmark(ctx, "TractorTrolley", 0.5, 0.45, 9, 20)
	for _, sf in { -0.6, 0.2, 0.75 } do
		landmark(ctx, "Scarecrow", 0.55, sf, 3)
	end
	landmark(ctx, "TubeWell", 0.85, -0.2, 5)
	scatter(ctx, { "KikarTree", "Poplar" }, 8, { spacing = 8, rMin = 0.85, rMax = 1 })
	local tank = landmark(ctx, "WaterTank", 0.9, 0.55, 10)
	climbAnchors(ctx, "WaterTank", tank, "Top", "Base", "TopStand")
	digChests(ctx, 2, { mud = true })
	eggSpots(ctx, { mud = true })
end

function BUILDERS.LahoreQila(ctx)
	ground(ctx, Enum.Material.Grass, Enum.Material.Brick, 0.06)
	-- the fort: a curved line of red walls with the gate where the road comes in
	local wallR = ctx.r1 + 80
	local road = Biomes.roads()
	local gateAngle = ctx.mid
	for _, r in road do
		if r.kind == "zone" and Biomes.at(r.a:Lerp(r.b, 0.5)) == ctx.biome then
			for t = 0, 1, 0.01 do
				local p = r.a:Lerp(r.b, t)
				if math.abs(Biomes.radiusOf(p) - wallR) < 2 then
					gateAngle = Biomes.angleOf(p)
				end
			end
		end
	end
	local gatePos = Biomes.polar(gateAngle, wallR)
	-- a moat in front of the walls, with a gap where the road crosses
	local moatR = wallR - 16
	for angle = ctx.mid - 38, ctx.mid + 38, 3 do
		local p = Biomes.polar(angle, moatR)
		if Biomes.roadDistance(p) > 6 then
			pond(ctx, p, 5, 4, Enum.Material.Water)
		end
	end
	zone(ctx, { kind = "water", inner = moatR - 4, outer = moatR + 4 })
	local gateCF = facing(onGround(ctx, gatePos))
	place(ctx, "QilaGate", gateCF)
	occupy(ctx, gatePos, 18, true)
	climbOn(ctx, "QilaGate", gateCF, "Top", Vector3.new(14, 0, -10))
	local step = math.deg(24 / wallR)
	for side = -1, 1, 2 do
		local angle = gateAngle + side * (math.deg(18 / wallR) + step / 2)
		while math.abs(Biomes.angleDiff(angle, ctx.mid)) < 36 do
			local p = Biomes.polar(angle, wallR)
			if Biomes.roadDistance(p) > 4 then
				place(ctx, "QilaWall", facing(onGround(ctx, p)))
			end
			occupy(ctx, p, 12, true)
			angle += side * step
		end
		local towerPos = Biomes.polar(angle, wallR)
		place(ctx, "QilaTower", facing(onGround(ctx, towerPos)))
		occupy(ctx, towerPos, 9, true)
	end
	-- inside the walls: pavilions and a garden
	for _, sf in { -0.35, 0.35 } do
		landmark(ctx, "Chhatri", 0.9, sf, 10)
	end
	scatter(ctx, "Poplar", 10, { spacing = 6, rMin = 0.82, rMax = 1 })
	scatter(ctx, { "Poplar", "MangoTree", "FlowerPatch" }, 14, { spacing = 6, rMax = 0.45 })
	rickshawHome(ctx)
	digChests(ctx, 2, { water = true })
	eggSpots(ctx, { water = true })
end

--------------------------------------------------------------------- Sindh
function BUILDERS.RailwayJunction(ctx)
	ground(ctx, Enum.Material.Ground, Enum.Material.Pavement, 0.15)
	local train = Biomes.TRAIN
	-- the curved track: two rails and sleepers
	local from, to = ctx.mid + train.from - 4, ctx.mid + train.to + 4
	local step = math.deg(16 / train.radius)
	local angle = from
	while angle < to do
		for _, offset in { -2.4, 2.4 } do
			local a, b = Biomes.polar(angle, train.radius + offset), Biomes.polar(angle + step, train.radius + offset)
			part(ctx, {
				Name = "Rail",
				Size = Vector3.new(0.5, 0.5, (b - a).Magnitude + 0.2),
				CFrame = CFrame.lookAt((a + b) / 2 + Vector3.new(0, 0.5, 0), b + Vector3.new(0, 0.5, 0)),
				Color = rgb(90, 90, 95),
				Material = Enum.Material.Metal,
			})
		end
		for k = 0, 1 do
			local a = Biomes.polar(angle + step * k / 2, train.radius)
			part(ctx, {
				Name = "Sleeper",
				Size = Vector3.new(7, 0.3, 1.2),
				CFrame = CFrame.lookAt(a + Vector3.new(0, 0.2, 0), Vector3.new(0, 0.2, 0)),
				Color = rgb(110, 80, 50),
				Material = Enum.Material.Wood,
			})
		end
		angle += step
	end
	zone(ctx, { kind = "track", inner = train.radius - 6, outer = train.radius + 6 })
	-- the station by the track, and the crossing light where the road crosses it
	local stationPos = Biomes.polar(ctx.mid - 24, train.radius - 20)
	local stationCF = CFrame.lookAt(onGround(ctx, stationPos), onGround(ctx, Biomes.polar(ctx.mid - 24, train.radius)))
	place(ctx, "RailwayStation", stationCF)
	sign(ctx, "RailwayStation", stationCF, "Sign", 9, 1.4, "JUNCTION")
	occupy(ctx, stationPos, 18, true)
	for _, r in Biomes.roads() do
		if r.kind == "zone" and Biomes.at(r.a:Lerp(r.b, 0.5)) == ctx.biome then
			for t = 0, 1, 0.005 do
				local p = r.a:Lerp(r.b, t)
				if math.abs(Biomes.radiusOf(p) - train.radius) < 1.5 then
					local post = p + (r.b - r.a).Unit:Cross(Vector3.yAxis) * 11
					part(ctx, {
						Name = "CrossingPost",
						Size = Vector3.new(0.6, 9, 0.6),
						CFrame = CFrame.new(post + Vector3.new(0, 4.5, 0)),
						Color = rgb(240, 240, 240),
					})
					part(ctx, {
						Name = "CrossingLight",
						Shape = Enum.PartType.Ball,
						Size = Vector3.one * 1.6,
						CFrame = CFrame.new(post + Vector3.new(0, 9.4, 0)),
						Color = rgb(80, 220, 80),
						Material = Enum.Material.Neon,
					})
					break
				end
			end
		end
	end
	-- the train itself: everyone's screen moves it along the track
	if ctx.building then
		local model = Props.place("Train", CFrame.new(Biomes.polar(ctx.mid + train.from, train.radius)), ctx.folder)
		model.Name = "Train"
		model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				p.CanCollide = false
			end
		end
	end
	scatter(ctx, { "KikarTree", "Bench", "Lamppost" }, 10, { spacing = 5, avoid = { track = true } })
	scatter(ctx, { "PakoraStall", "FruitStall", "ChaiDhaba" }, 4, { spacing = 8, avoid = { track = true } })
	scatter(ctx, "Rickshaw", 3, { spacing = 6, avoid = { track = true } })
	digChests(ctx, 2, { track = true })
	eggSpots(ctx)
end

function BUILDERS.SahilBeach(ctx)
	ground(ctx, Enum.Material.Sand)
	wholeZone(ctx, "sand")
	sea(ctx, ctx.r2 - 52, 22)
	for i, sf in { -0.7, -0.35, 0.3, 0.65 } do
		landmark(ctx, ({ "BeachHutTeal", "BeachHutPink", "BeachHutYellow", "BeachHutTeal" })[i], 0.55, sf, 7)
	end
	scatter(ctx, "BeachUmbrella", 8, { spacing = 5, rMin = 0.3, rMax = 0.6 })
	scatter(ctx, "CoconutPalm", 16, { spacing = 6, rMax = 0.55 })
	scatter(ctx, "BeachRocks", 6, { spacing = 5, rMin = 0.55, rMax = 0.62 })
	scatter(ctx, { "GolaCart", "FruitStall" }, 3, { spacing = 6, rMax = 0.35 })
	for _ = 1, 4 do
		local spot = at(ctx, ctx.rng:NextNumber(0.15, 0.5), ctx.rng:NextNumber(-0.8, 0.8))
		if isFree(ctx, spot, 6) then
			prop(ctx, "Camel", spot, ctx.rng:NextNumber(0, 360))
			occupy(ctx, spot, 6)
		end
	end
	if ctx.building then
		for _, sf in { -0.5, 0.15, 0.55 } do
			local p = at(ctx, 0.93, sf)
			Props.place(
				"FishingBoat",
				CFrame.new(p.X, GROUND_Y - 0.6, p.Z) * CFrame.Angles(0, math.rad(sf * 90), 0),
				ctx.folder
			)
		end
	end
	local light = landmark(ctx, "Lighthouse", 0.68, -0.05, 10)
	climbAnchors(ctx, "Lighthouse", light, "Gallery", "Door", "GalleryStand")
	digChests(ctx, 3, { water = true, shore = true })
	eggSpots(ctx, { water = true })
end

function BUILDERS.KarachiPort(ctx)
	ground(ctx, Enum.Material.Concrete, Enum.Material.Asphalt, 0.3)
	sea(ctx, ctx.r2 - 22, 4)
	-- stacks of containers in rows
	local names = { "ContainerRed", "ContainerBlue", "ContainerYellow", "ContainerGreen" }
	for row = 0, 1 do
		for col = -6, 6 do
			local spot = at(ctx, 0.25 + row * 0.3, col / 6.8)
			if isFree(ctx, spot, 11) then
				local base = onGround(ctx, spot)
				local cf = facing(base) * CFrame.Angles(0, math.rad(90), 0)
				for level = 0, ctx.rng:NextInteger(0, 2) do
					place(ctx, names[ctx.rng:NextInteger(1, #names)], cf + Vector3.new(0, level * 8, 0))
				end
				occupy(ctx, spot, 11, true)
			end
		end
	end
	local cranes = {}
	for _, sf in { -0.45, 0.3 } do
		local spot = at(ctx, 0.86, sf)
		if isFree(ctx, spot, 10) then
			local cf = CFrame.lookAt(onGround(ctx, spot), onGround(ctx, spot) * 2)
			place(ctx, "PortCrane", cf)
			occupy(ctx, spot, 10, true)
			table.insert(cranes, cf)
		end
	end
	climbOn(ctx, "PortCrane", cranes[1], "Top", Vector3.new(0, 0, 9))
	if ctx.building then
		local p = at(ctx, 1.12, 0.05)
		local tangent = Biomes.polar(ctx.mid + 10, Biomes.radiusOf(p))
		Props.place(
			"CargoShip",
			CFrame.lookAt(Vector3.new(p.X, GROUND_Y - 2, p.Z), Vector3.new(tangent.X, GROUND_Y - 2, tangent.Z)),
			ctx.folder
		)
	end
	scatter(ctx, { "TruckArt", "Lamppost" }, 6, { spacing = 8, rMax = 0.7 })
	rickshawHome(ctx)
	digChests(ctx, 1, { water = true })
	eggSpots(ctx, { water = true })
end

---------------------------------------------------------------------- Thar
function BUILDERS.CamelMela(ctx)
	ground(ctx, Enum.Material.Sand, Enum.Material.Ground, 0.25)
	local tents = {}
	for i, sf in { -0.7, -0.4, -0.1, 0.25, 0.55, 0.8 } do
		local cf = landmark(ctx, "MelaTent", 0.35 + (i % 2) * 0.3, sf, 10)
		if cf then
			table.insert(tents, cf)
		end
	end
	for i = 1, #tents - 1 do
		bunting(ctx, tents[i].Position + Vector3.new(0, 12, 0), tents[i + 1].Position + Vector3.new(0, 12, 0))
	end
	for _ = 1, 9 do
		local spot = at(ctx, ctx.rng:NextNumber(0.1, 0.9), ctx.rng:NextNumber(-0.9, 0.9))
		if isFree(ctx, spot, 6) then
			prop(ctx, "Camel", spot, ctx.rng:NextNumber(0, 360))
			occupy(ctx, spot, 6)
		end
	end
	scatter(ctx, { "PakoraStall", "GolaCart", "FruitStall", "DesertTent" }, 6, { spacing = 8 })
	scatter(ctx, { "KikarDry", "DesertShrub" }, 10, { spacing = 6 })
	local tank = landmark(ctx, "WaterTank", 0.85, 0.05, 10)
	climbAnchors(ctx, "WaterTank", tank, "Top", "Base", "TopStand")
	digChests(ctx, 2)
	eggSpots(ctx)
end

function BUILDERS.TharDesert(ctx)
	ground(ctx, Enum.Material.Sand)
	wholeZone(ctx, "sand")
	wholeZone(ctx, "sandstorm")
	-- rolling dunes: big balls of sand sunk into the ground
	for _ = 1, 14 do
		local spot = at(ctx, ctx.rng:NextNumber(0.1, 0.95), ctx.rng:NextNumber(-0.9, 0.9))
		local radius = ctx.rng:NextNumber(12, 22)
		if isFree(ctx, spot, radius * 0.8) then
			hill(ctx, spot - Vector3.new(0, radius * 0.72, 0), radius, Enum.Material.Sand)
			occupy(ctx, spot, radius * 0.8)
		end
	end
	local fort = landmark(ctx, "DesertFort", 0.62, -0.1, 34)
	climbAnchors(ctx, "DesertFort", fort, "TowerTop", "TowerBase", "TowerStand")
	scatter(ctx, { "KikarDry", "DesertShrub", "DuneGrass", "RockMesa" }, 22, { spacing = 5 })
	for _ = 1, 3 do
		local spot = at(ctx, ctx.rng:NextNumber(0.2, 0.8), ctx.rng:NextNumber(-0.8, 0.8))
		if isFree(ctx, spot, 6) then
			prop(ctx, "Camel", spot, ctx.rng:NextNumber(0, 360))
			occupy(ctx, spot, 6)
		end
	end
	digChests(ctx, 3)
	eggSpots(ctx)
end

function BUILDERS.MohenjoDaro(ctx)
	ground(ctx, Enum.Material.Sand, Enum.Material.Ground, 0.4)
	wholeZone(ctx, "sand")
	wholeZone(ctx, "sandstorm")
	local bath = landmark(ctx, "GreatBath", 0.45, 0.25, 22)
	local mound = landmark(ctx, "RuinMound", 0.75, -0.35, 22)
	climbOn(ctx, "RuinMound", mound, "Top", Vector3.new(0, 0, -17))
	-- the old city's streets: rows of broken brick walls
	for row = 0, 3 do
		for col = -9, 9 do
			local spot = at(ctx, 0.12 + row * 0.25, col / 9.5)
			if ctx.rng:NextNumber() < 0.55 and isFree(ctx, spot, 7) then
				local name = if ctx.rng:NextNumber() < 0.5 then "RuinWallA" else "RuinWallB"
				prop(ctx, name, spot, (col * 90) % 360)
				occupy(ctx, spot, 7)
			end
		end
	end
	scatter(ctx, { "DesertShrub", "DuneGrass" }, 10, { spacing = 4 })
	if bath == nil then
		landmark(ctx, "GreatBath", 0.3, -0.5, 22)
	end
	rickshawHome(ctx)
	digChests(ctx, 3)
	eggSpots(ctx)
end

----------------------------------------------------------------------- KPK
function BUILDERS.QissaKhawani(ctx)
	ground(ctx, Enum.Material.Cobblestone, Enum.Material.Pavement, 0.3)
	-- two rows of tall houses with carved balconies over the street
	for row = 0, 1 do
		for col = -8, 8 do
			local spot = at(ctx, 0.12 + row * 0.76, col / 8.4)
			if isFree(ctx, spot, 9) then
				local inward = row == 0
				local name = if (col + row) % 2 == 0 then "QissaHouseA" else "QissaHouseB"
				local target = if inward then spot * 1.2 else spot * 0.8
				propFacing(ctx, name, spot, target)
				occupy(ctx, spot, 9, true)
			end
		end
	end
	local tower = landmark(ctx, "GhantaGhar", 0.5, -0.25, 9)
	climbOn(ctx, "GhantaGhar", tower, "Top", Vector3.new(0, 0, -8))
	for _, sf in { -0.6, 0.05, 0.6 } do
		landmark(ctx, "KahwaStall", 0.4, sf, 6)
	end
	landmark(ctx, "DryFruitStall", 0.6, 0.35, 7)
	local stage = landmark(ctx, "MelaStage", 0.55, 0.7, 14)
	if stage and ctx.building then
		part(ctx, {
			Name = "StorytellerCarpet",
			Size = Vector3.new(14, 0.2, 8),
			CFrame = stage * CFrame.new(0, 4.1, 0),
			Color = rgb(170, 30, 40),
			Material = Enum.Material.Fabric,
		})
	end
	scatter(ctx, { "Matka", "Charpai", "Bench", "Lamppost" }, 10, { spacing = 4, rMin = 0.25, rMax = 0.75 })
	digChests(ctx, 1)
	eggSpots(ctx)
end

function BUILDERS.NamakCaves(ctx)
	ground(ctx, Enum.Material.Salt, Enum.Material.Rock, 0.25)
	wholeZone(ctx, "dark")
	-- pink salt hills and rocks
	for _ = 1, 10 do
		local spot = at(ctx, ctx.rng:NextNumber(0.1, 0.95), ctx.rng:NextNumber(-0.9, 0.9))
		local radius = ctx.rng:NextNumber(9, 16)
		if isFree(ctx, spot, radius) then
			hill(ctx, spot - Vector3.new(0, radius * 0.5, 0), radius, Enum.Material.Salt)
			occupy(ctx, spot, radius, true)
		end
	end
	local entrance = landmark(ctx, "MineEntrance", 0.85, 0.1, 12)
	if entrance then
		sign(ctx, "MineEntrance", entrance, "Sign", 9, 1.6, "NAMAK CAVES")
	end
	for _, sf in { -0.5, 0.45 } do
		landmark(ctx, "CrystalCluster", 0.5, sf, 8)
	end
	scatter(ctx, { "SaltCrystals", "Stalagmites", "CaveSupport" }, 20, { spacing = 5 })
	scatter(ctx, { "MineCart" }, 3, { spacing = 6 })
	digChests(ctx, 3)
	eggSpots(ctx)
end

function BUILDERS.BarfaniPahar(ctx)
	ground(ctx, Enum.Material.Snow, Enum.Material.Glacier, 0.15)
	-- snowy mountains along the far edge
	for k = -6, 6 do
		local spot = at(ctx, 1.05, k / 6.5)
		hill(ctx, spot - Vector3.new(0, 6, 0), ctx.rng:NextNumber(18, 26), Enum.Material.Snow)
		occupy(ctx, spot, 18, true)
	end
	-- frozen lakes with eggs right in the middle of the ice
	for _, sf in { -0.55, 0.5 } do
		local spot = at(ctx, 0.45, sf)
		if isFree(ctx, spot, 22) then
			pond(ctx, spot, 20, 2, Enum.Material.Ice)
			zone(ctx, { kind = "ice", center = spot, radius = 20 })
			occupy(ctx, spot, 20)
		end
	end
	local caves = {}
	for _, sf in { -0.15, 0.2 } do
		local cave = landmark(ctx, "IceCave", 0.8, sf, 14)
		if cave then
			table.insert(caves, cave)
		end
	end
	if caves[1] then
		climbOn(ctx, "IceCave", caves[1], "Top", Vector3.new(16, 0, 0))
	end
	landmark(ctx, "MountainHut", 0.65, -0.75, 10)
	for _, sf in { -0.3, 0.05, 0.75 } do
		landmark(ctx, "Snowman", 0.25, sf, 4)
	end
	scatter(ctx, { "DeodarSnowy", "DeodarSnowy", "SnowRock", "Juniper" }, 26, { spacing = 6, avoid = { ice = true } })
	for _ = 1, 3 do
		local spot = at(ctx, ctx.rng:NextNumber(0.2, 0.7), ctx.rng:NextNumber(-0.8, 0.8))
		if isFree(ctx, spot, 5) and not inZone(ctx.plan, spot, { ice = true }) then
			animal(ctx, spot, rgb(60, 50, 45), 2.6, "Yak")
		end
	end
	rickshawHome(ctx)
	digChests(ctx, 2, { ice = true })
	eggSpots(ctx)
end

---------------------------------------------------------------------------
-- Public
---------------------------------------------------------------------------

-- Plans (and, with a folder, builds) every zone. Returns plans by zone id.
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

-- Is the position inside a hazard area of this kind?
function BiomeBuilder.inZone(plan: Plan, position: Vector3, kind: string): boolean
	return inZone(plan, position, { [kind] = true })
end

return BiomeBuilder
