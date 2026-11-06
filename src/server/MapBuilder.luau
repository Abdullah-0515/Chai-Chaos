-- Builds the world if the place does not have one yet, then finds all the
-- important parts.
--
-- The Chowk (town square) is in the middle with the fountain and the shops:
-- Sell, Gear, Tracker, Kismat Kettle, Naya Safar, Quests and the leaderboard.
-- The 8 havelis stand in a ring around it, facing the fountain. Between the
-- havelis, 8 roads lead out to the 8 biomes (see BiomeBuilder.luau).
--
-- Haveli layout (looking from the Chowk): the door is in the front wall, the
-- courtyard has the galla, the egg incubators and the stairs, plots 1-10 are on
-- the ground floor and plots 11-20 on the second floor above them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Themes = require(Shared.Themes)
local Biomes = require(Shared.Biomes)

local BiomeBuilder = require(script.Parent.BiomeBuilder)
local Props = require(script.Parent.Props)

local MapBuilder = {}

local MAP_NAME = "ChaiChaosMap"
local GROUND_Y = Biomes.GROUND_Y
local HAVELI_W = 72
local HAVELI_D = 52
local WALL_H = 12 -- ground floor height (the second floor is on top of it)
local UPPER_H = 9 -- second floor wall height
local DOOR_W = 14
local DOOR_H = 9
local FLOOR_TOP = 0.4
local PLOT_SIZE = 8
local PLOT_COLUMNS = { -20, -9, 2, 13, 24 }
local PLOT_ROWS = { 18, 6 } -- plots 1-5 at the back, 6-10 in front (same for 11-20 upstairs)
local DECK_FRONT = -6 -- the second floor covers z from here to the back wall
local STAIR_X = -31.5
local STAIR_W = 7
local STAIR_START = -22
local STAIR_STEPS = 16
local PLOTS_PER_FLOOR = 10
local INCUBATOR_SPOTS = { { 11, -11 }, { 19, -11 }, { -17, -11 }, { -21, -18 } }
local SHOP_RADIUS = 50

MapBuilder.PLOTS_PER_FLOOR = PLOTS_PER_FLOOR

export type Haveli = {
	index: number,
	model: Model,
	origin: CFrame, -- centre of the floor's top, facing the Chowk
	size: Vector3,
	upperY: number, -- height of the second floor above the ground floor
	plots: { BasePart },
	plotLabels: { TextLabel },
	incubators: { BasePart },
	incubatorLabels: { TextLabel },
	galla: BasePart,
	gallaLabel: TextLabel,
	door: BasePart,
	barrier: BasePart,
	signLabel: TextLabel,
	walls: { BasePart },
	trims: { BasePart },
	accents: { BasePart },
	floors: { BasePart },
	stairGates: { BasePart },
	roof: BasePart?,
	decor: Folder,
	guardSpot: CFrame,
	spawn: CFrame,
	doorInside: CFrame,
	doorOutside: CFrame,
	stairBottom: CFrame,
	stairTop: CFrame,
	brainrotFolder: Folder,
	owner: any, -- the profile of the player living here
	guard: Model?,
}

export type Map = {
	model: Model,
	havelis: { Haveli },
	shops: { [string]: BasePart },
	leaderboard: Frame?,
	biomes: { [string]: any },
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	local parent = props.Parent
	for name, value in props do
		if name ~= "Parent" then
			(p :: any)[name] = value
		end
	end
	p.Parent = parent
	return p
end
MapBuilder.part = part

local UP = CFrame.Angles(0, 0, math.rad(90)) -- turns a cylinder upright
local function cylinderUp(cf: CFrame): CFrame
	return cf * UP
end

local function surfaceText(target: BasePart, face: Enum.NormalId, text: string, color: Color3?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Gui"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = target
	return label
end
MapBuilder.surfaceText = surfaceText

local BRIGHT = {
	rgb(255, 70, 90),
	rgb(255, 205, 40),
	rgb(70, 210, 110),
	rgb(70, 160, 255),
	rgb(255, 120, 220),
	rgb(255, 150, 40),
}

local function buildBunting(parent: Instance, from: Vector3, to: Vector3)
	local count = math.floor((to - from).Magnitude / 2)
	local along = (to - from).Unit
	for i = 0, count do
		local t = i / count
		local sag = math.sin(t * math.pi) * 1.5
		local pos = from:Lerp(to, t) - Vector3.new(0, sag, 0)
		part({
			Name = "Flag",
			Size = Vector3.new(0.1, 1.2, 1.2),
			-- a diamond hanging on the string
			CFrame = CFrame.lookAt(pos, pos + along) * CFrame.Angles(math.rad(45), 0, 0),
			Color = BRIGHT[i % #BRIGHT + 1],
			Material = Enum.Material.Fabric,
			CanCollide = false,
			CastShadow = false,
			Parent = parent,
		})
	end
end

local function buildHaveli(parent: Instance, index: number, center: Vector3)
	local origin = CFrame.lookAt(center, Vector3.new(0, center.Y, 0))
	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end
	local look = Themes.EMPTY
	local halfW, halfD = HAVELI_W / 2, HAVELI_D / 2
	local deckY = FLOOR_TOP + WALL_H
	local front = -halfD + 0.5

	local haveli = Instance.new("Model")
	haveli.Name = "Haveli" .. index
	haveli:SetAttribute("HaveliIndex", index)

	part({
		Name = "Floor",
		Size = Vector3.new(HAVELI_W, FLOOR_TOP, HAVELI_D),
		CFrame = at(0, FLOOR_TOP / 2, 0),
		Color = look.floor,
		Parent = haveli,
	})
	local deckDepth = halfD - DECK_FRONT
	part({
		Name = "Deck",
		Size = Vector3.new(HAVELI_W - 2, 1, deckDepth),
		CFrame = at(0, deckY - 0.5, DECK_FRONT + deckDepth / 2),
		Color = look.floor,
		Parent = haveli,
	})

	local walls = Instance.new("Folder")
	walls.Name = "Walls"
	walls.Parent = haveli
	local trim = Instance.new("Folder")
	trim.Name = "Trim"
	trim.Parent = haveli
	local accent = Instance.new("Folder")
	accent.Name = "Accent"
	accent.Parent = haveli

	local segment = (HAVELI_W - DOOR_W) / 2
	local upperY = deckY + UPPER_H / 2
	local wallPieces = {
		-- back wall, both floors
		{ Vector3.new(HAVELI_W, WALL_H + UPPER_H, 1), at(0, FLOOR_TOP + (WALL_H + UPPER_H) / 2, halfD - 0.5) },
		-- side walls, ground floor
		{ Vector3.new(1, WALL_H, HAVELI_D), at(-halfW + 0.5, FLOOR_TOP + WALL_H / 2, 0) },
		{ Vector3.new(1, WALL_H, HAVELI_D), at(halfW - 0.5, FLOOR_TOP + WALL_H / 2, 0) },
		-- side walls, second floor
		{ Vector3.new(1, UPPER_H, deckDepth), at(-halfW + 0.5, upperY, DECK_FRONT + deckDepth / 2) },
		{ Vector3.new(1, UPPER_H, deckDepth), at(halfW - 0.5, upperY, DECK_FRONT + deckDepth / 2) },
		-- front wall with the door gap
		{ Vector3.new(segment, WALL_H, 1), at(-(DOOR_W / 2 + segment / 2), FLOOR_TOP + WALL_H / 2, front) },
		{ Vector3.new(segment, WALL_H, 1), at(DOOR_W / 2 + segment / 2, FLOOR_TOP + WALL_H / 2, front) },
		{ Vector3.new(DOOR_W, WALL_H - DOOR_H, 1), at(0, FLOOR_TOP + DOOR_H + (WALL_H - DOOR_H) / 2, front) },
	}
	for _, piece in wallPieces do
		part({ Name = "Wall", Size = piece[1], CFrame = piece[2], Color = look.wall, Parent = walls })
	end

	-- corner towers with domes
	for _, corner in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		local height = if corner[2] < 0 then WALL_H + 3 else WALL_H + UPPER_H + 3
		local x, z = corner[1] * halfW, corner[2] * halfD
		part({
			Name = "Tower",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(height, 4, 4),
			CFrame = cylinderUp(at(x, FLOOR_TOP + height / 2, z)),
			Color = look.trim,
			Parent = trim,
		})
		part({
			Name = "Dome",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 4.6,
			CFrame = at(x, FLOOR_TOP + height + 0.8, z),
			Color = look.accent,
			Parent = accent,
		})
	end
	for _, x in { -DOOR_W / 2, DOOR_W / 2 } do
		part({
			Name = "DoorPillar",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(WALL_H + 1, 1.8, 1.8),
			CFrame = cylinderUp(at(x, FLOOR_TOP + (WALL_H + 1) / 2, front - 0.2)),
			Color = look.trim,
			Parent = trim,
		})
	end
	-- top edge of the front wall and second floor railing
	part({
		Name = "Parapet",
		Size = Vector3.new(HAVELI_W, 1, 1.4),
		CFrame = at(0, FLOOR_TOP + WALL_H + 0.5, front),
		Color = look.trim,
		Parent = trim,
	})
	local railFrom = STAIR_X + STAIR_W / 2
	local railLength = halfW - 1 - railFrom
	part({
		Name = "Railing",
		Size = Vector3.new(railLength, 3, 0.6),
		CFrame = at(railFrom + railLength / 2, deckY + 1.5, DECK_FRONT),
		Color = look.trim,
		Parent = trim,
	})
	for _, x in { -20, -4, 12, 28 } do
		part({
			Name = "DeckPillar",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(WALL_H, 1.6, 1.6),
			CFrame = cylinderUp(at(x, FLOOR_TOP + WALL_H / 2, DECK_FRONT)),
			Color = look.trim,
			Parent = trim,
		})
	end

	-- stairs up to the second floor
	local stepH = WALL_H / STAIR_STEPS
	for i = 1, STAIR_STEPS do
		part({
			Name = "Step",
			Size = Vector3.new(STAIR_W, stepH * i, 1),
			CFrame = at(STAIR_X, FLOOR_TOP + stepH * i / 2, STAIR_START + i - 0.5),
			Color = look.trim,
			Parent = trim,
		})
	end
	-- blocked until the second floor is unlocked
	local gates = Instance.new("Folder")
	gates.Name = "StairGates"
	gates.Parent = haveli
	local gateStripe = rgb(255, 150, 30)
	part({
		Name = "StairGate",
		Size = Vector3.new(STAIR_W, 10, 0.6),
		CFrame = at(STAIR_X, FLOOR_TOP + 5, STAIR_START - 0.6),
		Color = gateStripe,
		Material = Enum.Material.Neon,
		Transparency = 0.5,
		Parent = gates,
	})
	part({
		Name = "StairGate",
		Size = Vector3.new(0.6, WALL_H + 3, STAIR_STEPS + 0.6),
		CFrame = at(STAIR_X + STAIR_W / 2 + 0.3, FLOOR_TOP + (WALL_H + 3) / 2, STAIR_START + STAIR_STEPS / 2 - 0.3),
		Color = gateStripe,
		Material = Enum.Material.Neon,
		Transparency = 0.5,
		Parent = gates,
	})
	local gateSign = part({
		Name = "StairSign",
		Size = Vector3.new(STAIR_W, 2, 0.3),
		CFrame = at(STAIR_X, FLOOR_TOP + 7, STAIR_START - 1),
		Color = rgb(40, 40, 45),
		Parent = gates,
	})
	surfaceText(gateSign, Enum.NormalId.Front, ("2nd floor at Level %d"):format(Config.UPPER_FLOOR_LEVEL))

	part({
		Name = "Roof",
		Size = Vector3.new(HAVELI_W, 1, deckDepth),
		CFrame = at(0, deckY + UPPER_H + 0.5, DECK_FRONT + deckDepth / 2),
		Color = look.trim,
		Transparency = 1,
		CanCollide = false,
		Parent = haveli,
	})

	-- door, laser barrier and sign
	part({
		Name = "Door",
		Size = Vector3.new(DOOR_W - 1, DOOR_H, 2),
		CFrame = at(0, FLOOR_TOP + DOOR_H / 2, front),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = haveli,
	})
	part({
		Name = "Barrier",
		Size = Vector3.new(DOOR_W, DOOR_H, 0.5),
		CFrame = at(0, FLOOR_TOP + DOOR_H / 2, front),
		Color = rgb(255, 50, 70),
		Material = Enum.Material.Neon,
		Transparency = 1,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Parent = haveli,
	})
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(24, 3.6, 0.6),
		CFrame = at(0, FLOOR_TOP + WALL_H + 2.8, front),
		Color = rgb(30, 130, 100),
		Parent = haveli,
	})
	surfaceText(sign, Enum.NormalId.Front, "Khaali Haveli", rgb(255, 240, 160))

	for i = 1, 2 * PLOTS_PER_FLOOR do
		local j = (i - 1) % PLOTS_PER_FLOOR + 1
		local upstairs = i > PLOTS_PER_FLOOR
		local column = PLOT_COLUMNS[(j - 1) % #PLOT_COLUMNS + 1]
		local row = PLOT_ROWS[math.ceil(j / #PLOT_COLUMNS)]
		local plot = part({
			Name = "Plot" .. i,
			Size = Vector3.new(PLOT_SIZE, 0.3, PLOT_SIZE),
			CFrame = at(column, (if upstairs then deckY else FLOOR_TOP) + 0.15, row),
			Color = rgb(240, 230, 205),
			Parent = haveli,
		})
		plot:SetAttribute("HaveliIndex", index)
		plot:SetAttribute("PlotIndex", i)
		surfaceText(plot, Enum.NormalId.Top, "", rgb(255, 255, 255))
	end

	local galla = part({
		Name = "Galla",
		Size = Vector3.new(5, 3.5, 3.5),
		CFrame = at(26, FLOOR_TOP + 1.75, -18),
		Color = rgb(120, 75, 40),
		Material = Enum.Material.WoodPlanks,
		Parent = haveli,
	})
	part({
		Name = "GallaTrim",
		Size = Vector3.new(5.2, 0.5, 1),
		CFrame = at(26, FLOOR_TOP + 3.6, -18),
		Color = rgb(255, 205, 60),
		Material = Enum.Material.Metal,
		CanCollide = false,
		Parent = haveli,
	})
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GallaGui"
	billboard.Size = UDim2.fromScale(8, 2.4)
	billboard.StudsOffset = Vector3.new(0, 3.8, 0)
	billboard.MaxDistance = 80
	billboard.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = rgb(255, 225, 90)
	label.Text = "Galla"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = billboard
	billboard.Parent = galla

	for name, cf in
		{
			Spawn = at(0, FLOOR_TOP + 0.5, -16) * CFrame.Angles(0, math.pi, 0),
			GuardSpot = at(-10, FLOOR_TOP, -21),
		}
	do
		part({
			Name = name,
			Size = Vector3.new(4, 1, 4),
			CFrame = cf,
			Transparency = 1,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			Parent = haveli,
		})
	end

	-- egg incubators (nests) in the courtyard; haveli levels unlock more of them
	for i, spot in INCUBATOR_SPOTS do
		local nest = part({
			Name = "Incubator" .. i,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.2, 5, 5),
			CFrame = at(spot[1], FLOOR_TOP + 0.6, spot[2]) * CFrame.Angles(0, 0, math.rad(90)),
			Color = rgb(150, 105, 60),
			Material = Enum.Material.Fabric,
			Parent = haveli,
		})
		nest:SetAttribute("IncubatorIndex", i)
		local straw = Instance.new("BillboardGui")
		straw.Name = "IncubatorGui"
		straw.Size = UDim2.fromScale(7, 1.8)
		straw.StudsOffset = Vector3.new(0, 4.2, 0)
		straw.MaxDistance = 60
		straw.LightInfluence = 0
		local text = Instance.new("TextLabel")
		text.Name = "Label"
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextColor3 = rgb(255, 240, 180)
		text.Text = "Incubator"
		local outline = Instance.new("UIStroke")
		outline.Thickness = 2
		outline.Parent = text
		text.Parent = straw
		straw.Parent = nest
	end

	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = haveli
	local brainrots = Instance.new("Folder")
	brainrots.Name = "Brainrots"
	brainrots.Parent = haveli

	haveli.Parent = parent
end

---------------------------------------------------------------------------
-- The Chowk
---------------------------------------------------------------------------
local function shopPrompt(target: BasePart, shop: string, label: string)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Open"
	prompt.ObjectText = label
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Shop", shop)
	prompt.Parent = target
	target:SetAttribute("Shop", shop)
end

local function shopStall(parent: Instance, cf: CFrame, shop: string, title: string, color: Color3)
	local stall = Instance.new("Model")
	stall.Name = shop .. "Shop"
	local counter = part({
		Name = "Counter",
		Size = Vector3.new(12, 3.5, 4),
		CFrame = cf * CFrame.new(0, 1.75, 0),
		Color = rgb(150, 95, 55),
		Material = Enum.Material.WoodPlanks,
		Parent = stall,
	})
	for _, x in { -5.6, 5.6 } do
		part({
			Name = "Pole",
			Size = Vector3.new(0.6, 9, 0.6),
			CFrame = cf * CFrame.new(x, 4.5, 1.6),
			Color = rgb(110, 70, 45),
			Parent = stall,
		})
	end
	for i = 0, 3 do
		part({
			Name = "Awning",
			Size = Vector3.new(13.5 / 4, 0.5, 6.5),
			CFrame = cf * CFrame.new(-5 + i * 3.375, 9.2, 0.4) * CFrame.Angles(math.rad(-12), 0, 0),
			Color = if i % 2 == 0 then color else rgb(255, 255, 255),
			Material = Enum.Material.Fabric,
			Parent = stall,
		})
	end
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(11, 2.2, 0.4),
		CFrame = cf * CFrame.new(0, 10.8, -2.6),
		Color = color:Lerp(rgb(0, 0, 0), 0.35),
		Parent = stall,
	})
	surfaceText(sign, Enum.NormalId.Front, title, rgb(255, 240, 160))
	shopPrompt(counter, shop, title)
	stall.Parent = parent
	return counter
end

local function buildHub(map: Model): { [string]: BasePart }
	local terrain = workspace.Terrain
	-- grass everywhere, a paved bazaar around the Chowk
	terrain:FillCylinder(CFrame.new(0, GROUND_Y - 4, 0), 8, Biomes.WORLD_RADIUS + 30, Enum.Material.Grass)
	terrain:FillCylinder(CFrame.new(0, GROUND_Y - 2, 0), 4, 130, Enum.Material.Pavement)

	local center = Vector3.new(0, GROUND_Y, 0)
	part({
		Name = "Plaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, Biomes.PLAZA_RADIUS * 2, Biomes.PLAZA_RADIUS * 2),
		CFrame = cylinderUp(CFrame.new(center + Vector3.new(0, 0.3, 0))),
		Color = rgb(235, 215, 185),
		Material = Enum.Material.Slate,
		Parent = map,
	})
	-- a tiered fountain
	for i, tier in { { 2, 26, 0 }, { 1.6, 14, 2.4 }, { 1.2, 6, 4.6 } } do
		part({
			Name = "FountainTier",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(tier[1], tier[2], tier[2]),
			CFrame = cylinderUp(CFrame.new(center + Vector3.new(0, 1 + tier[3], 0))),
			Color = rgb(245, 245, 250),
			Material = Enum.Material.Marble,
			Parent = map,
		})
		part({
			Name = "FountainWater",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.3, tier[2] - 1.5, tier[2] - 1.5),
			CFrame = cylinderUp(CFrame.new(center + Vector3.new(0, 1.9 + tier[3] + (tier[1] - 2) / 2, 0))),
			Color = rgb(70, 180, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.3,
			CanCollide = false,
			Parent = map,
		})
		if i == 3 then
			local top = part({
				Name = "FountainTop",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 2.4,
				CFrame = CFrame.new(center + Vector3.new(0, 7.2, 0)),
				Color = rgb(255, 205, 60),
				Material = Enum.Material.Metal,
				Parent = map,
			})
			local spray = Instance.new("ParticleEmitter")
			spray.Name = "Spray"
			spray.Color = ColorSequence.new(rgb(170, 225, 255))
			spray.Rate = 40
			spray.Lifetime = NumberRange.new(1.2, 1.6)
			spray.Speed = NumberRange.new(10, 13)
			spray.SpreadAngle = Vector2.new(20, 20)
			spray.Acceleration = Vector3.new(0, -20, 0)
			spray.Size = NumberSequence.new(0.5, 0.1)
			spray.Transparency = NumberSequence.new(0.2, 1)
			spray.Parent = top
		end
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "ChowkSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = center + Vector3.new(22, 0.4, 0)
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Color = rgb(255, 210, 80)
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = map

	-- the shops, around the fountain and facing it
	local shops = {}
	local function spot(k: number): CFrame
		local a = math.rad(45 * k)
		local position = center + Vector3.new(math.cos(a), 0, math.sin(a)) * SHOP_RADIUS
		return CFrame.lookAt(position, center)
	end
	shops.Sell = shopStall(map, spot(0), "Sell", "BECHO (Sell)", rgb(60, 170, 90))
	shops.Gear = shopStall(map, spot(1), "Gear", "GEAR SHOP", rgb(60, 130, 220))
	shops.Tracker = shopStall(map, spot(2), "Tracker", "RADAR WALA", rgb(150, 70, 210))

	-- the Kismat Kettle
	local kettleCF = spot(3)
	local kettle = part({
		Name = "KismatKettle",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 9,
		CFrame = kettleCF * CFrame.new(0, 5, 0),
		Color = rgb(255, 175, 40),
		Material = Enum.Material.Metal,
		Parent = map,
	})
	part({
		Name = "KismatSpout",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 1.6, 1.6),
		CFrame = kettleCF * CFrame.new(5, 7, 0) * CFrame.Angles(0, 0, math.rad(35)),
		Color = rgb(255, 175, 40),
		Material = Enum.Material.Metal,
		Parent = map,
	})
	local kettleSign = part({
		Name = "KismatSign",
		Size = Vector3.new(10, 2.4, 0.4),
		CFrame = kettleCF * CFrame.new(0, 11.5, 0),
		Color = rgb(140, 60, 200),
		Parent = map,
	})
	surfaceText(kettleSign, Enum.NormalId.Front, "KISMAT KETTLE", rgb(255, 230, 90))
	shopPrompt(kettle, "Kismat", "Kismat Roll")
	shops.Kismat = kettle

	-- the Naya Safar gate
	local gateCF = spot(4)
	for _, x in { -5, 5 } do
		part({
			Name = "SafarPillar",
			Size = Vector3.new(2, 14, 2),
			CFrame = gateCF * CFrame.new(x, 7, 0),
			Color = rgb(255, 205, 60),
			Material = Enum.Material.Marble,
			Parent = map,
		})
	end
	part({
		Name = "SafarArch",
		Size = Vector3.new(12, 2, 2),
		CFrame = gateCF * CFrame.new(0, 15, 0),
		Color = rgb(255, 205, 60),
		Material = Enum.Material.Marble,
		Parent = map,
	})
	local portal = part({
		Name = "SafarPortal",
		Size = Vector3.new(8, 13, 0.4),
		CFrame = gateCF * CFrame.new(0, 7.5, 0),
		Color = rgb(190, 120, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
		Parent = map,
	})
	local safarSign = part({
		Name = "SafarSign",
		Size = Vector3.new(12, 2.4, 0.4),
		CFrame = gateCF * CFrame.new(0, 17.4, 0),
		Color = rgb(90, 40, 140),
		Parent = map,
	})
	surfaceText(safarSign, Enum.NormalId.Front, "NAYA SAFAR", rgb(255, 230, 90))
	shopPrompt(portal, "Rebirth", "Naya Safar")
	shops.Rebirth = portal

	-- the quest board
	local boardCF = spot(5)
	local questBoard = part({
		Name = "QuestBoard",
		Size = Vector3.new(10, 7, 0.6),
		CFrame = boardCF * CFrame.new(0, 5, 0),
		Color = rgb(130, 85, 50),
		Material = Enum.Material.WoodPlanks,
		Parent = map,
	})
	surfaceText(questBoard, Enum.NormalId.Front, "QUESTS", rgb(255, 235, 150))
	for _, x in { -4.5, 4.5 } do
		part({
			Name = "BoardLeg",
			Size = Vector3.new(0.6, 5, 0.6),
			CFrame = boardCF * CFrame.new(x, 1.5, 0.4),
			Color = rgb(100, 65, 40),
			Parent = map,
		})
	end
	shopPrompt(questBoard, "Quests", "Quests")
	shops.Quests = questBoard

	-- the leaderboard
	local lbCF = spot(6)
	local board = part({
		Name = "Leaderboard",
		Size = Vector3.new(16, 11, 0.6),
		CFrame = lbCF * CFrame.new(0, 7, 0),
		Color = rgb(40, 30, 25),
		Parent = map,
	})
	local boardGui = Instance.new("SurfaceGui")
	boardGui.Name = "Gui"
	boardGui.Face = Enum.NormalId.Front
	boardGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	boardGui.PixelsPerStud = 30
	boardGui.LightInfluence = 0
	local list = Instance.new("Frame")
	list.Name = "List"
	list.Size = UDim2.fromScale(1, 1)
	list.BackgroundTransparency = 1
	list.Parent = boardGui
	boardGui.Parent = board

	-- a chai dhaba, a fruit cart and parked rickshaws (props modelled in Blender)
	local dhaba = spot(7)
	Props.place("ChaiDhaba", dhaba, map)
	Props.text(map, dhaba, Props.anchor("ChaiDhaba", "Sign", dhaba), 5.6, 1.2, "CHAI")
	Props.place("Charpai", dhaba * CFrame.new(9, 0, -2) * CFrame.Angles(0, math.rad(80), 0), map)
	Props.place("FruitStall", CFrame.lookAt(center + Vector3.new(-18, 0, -40), center), map)
	Props.place("Rickshaw", CFrame.new(center + Vector3.new(30, 0, 40)) * CFrame.Angles(0, math.rad(30), 0), map)
	Props.place("Rickshaw", CFrame.new(center + Vector3.new(-36, 0, 30)) * CFrame.Angles(0, math.rad(-50), 0), map)

	-- string lights around the plaza
	local i = 0
	for degree = 0, 355, 5 do
		i += 1
		local a = math.rad(degree)
		local bulb = part({
			Name = "Bulb",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.8,
			Position = center + Vector3.new(math.cos(a) * 68, 9 - (i % 6 == 0 and 0 or 0.6), math.sin(a) * 68),
			Color = BRIGHT[i % #BRIGHT + 1],
			Material = Enum.Material.Neon,
			CanCollide = false,
			CastShadow = false,
			Parent = map,
		})
		if i % 9 == 0 then
			local light = Instance.new("PointLight")
			light.Color = bulb.Color
			light.Range = 16
			light.Brightness = 1.2
			light.Parent = bulb
			part({
				Name = "LightPole",
				Size = Vector3.new(0.5, 9, 0.5),
				Position = center + Vector3.new(math.cos(a) * 68, 4.5, math.sin(a) * 68),
				Color = rgb(110, 70, 45),
				Parent = map,
			})
		end
	end
	return shops
end

---------------------------------------------------------------------------
-- Roads, gates, countryside and the edge of the world
---------------------------------------------------------------------------
local function buildRoads(map: Model)
	local roads = Instance.new("Folder")
	roads.Name = "Roads"
	roads.Parent = map
	for _, biome in Biomes.list do
		local dir = Biomes.direction(biome)
		local from, to = Biomes.PLAZA_RADIUS - 2, Biomes.innerRadius(biome)
		local mid = dir * ((from + to) / 2) + Vector3.new(0, GROUND_Y + 0.15, 0)
		local cf = CFrame.lookAt(mid, mid + dir)
		part({
			Name = "Road",
			Size = Vector3.new(14, 0.3, to - from),
			CFrame = cf,
			Color = rgb(200, 175, 140),
			Material = Enum.Material.Cobblestone,
			Parent = roads,
		})
		for _, x in { -7.5, 7.5 } do
			part({
				Name = "RoadEdge",
				Size = Vector3.new(1, 0.5, to - from),
				CFrame = cf * CFrame.new(x, 0.1, 0),
				Color = biome.color,
				Parent = roads,
			})
		end
		-- the biome gate
		local gatePos = dir * to + Vector3.new(0, GROUND_Y, 0)
		local gate = CFrame.lookAt(gatePos, Vector3.new(0, GROUND_Y, 0))
		for _, x in { -9, 9 } do
			part({
				Name = "GatePillar",
				Size = Vector3.new(3, 16, 3),
				CFrame = gate * CFrame.new(x, 8, 0),
				Color = biome.color,
				Parent = roads,
			})
		end
		local sign = part({
			Name = "GateSign",
			Size = Vector3.new(21, 4.5, 1),
			CFrame = gate * CFrame.new(0, 17, 0),
			Color = biome.color:Lerp(rgb(0, 0, 0), 0.45),
			Parent = roads,
		})
		local label = ("%s · %s"):format(biome.name:upper(), biome.title)
		surfaceText(sign, Enum.NormalId.Front, label, rgb(255, 240, 170))
		surfaceText(sign, Enum.NormalId.Back, "TO THE CHOWK", rgb(255, 240, 170))
		buildBunting(roads, (gate * CFrame.new(-8, 13.5, 0)).Position, (gate * CFrame.new(8, 13.5, 0)).Position)
		-- a road sign by the Chowk for players heading out
		local signPos = dir * (Biomes.PLAZA_RADIUS + 14) + Vector3.new(0, GROUND_Y, 0) + dir:Cross(Vector3.yAxis) * 10
		local signCF = CFrame.lookAt(signPos, Vector3.new(0, GROUND_Y, 0))
		Props.place("Signboard", signCF, roads)
		Props.text(
			roads,
			signCF,
			Props.anchor("Signboard", "Face", signCF),
			5.2,
			2.2,
			("%s\nTier %d"):format(biome.name:upper(), biome.tier)
		)
	end

	-- the edge of the world
	local edge = Instance.new("Folder")
	edge.Name = "WorldEdge"
	edge.Parent = map
	for k = 0, 47 do
		local a = math.rad(k * 7.5)
		local position = Vector3.new(math.cos(a), 0, math.sin(a)) * Biomes.WORLD_RADIUS + Vector3.new(0, 100, 0)
		part({
			Name = "Edge",
			Size = Vector3.new(Biomes.WORLD_RADIUS * math.rad(7.5) + 4, 220, 4),
			CFrame = CFrame.lookAt(position, Vector3.new(0, 100, 0)),
			Transparency = 1,
			CanQuery = false,
			Parent = edge,
		})
	end
end

---------------------------------------------------------------------------
-- The countryside between the bazaar and the biomes: roadside dhabas and
-- stalls, parked trucks and rickshaws, bus stops, milestones, little farms,
-- ponds and trees. Everything comes from Props (modelled in Blender).
---------------------------------------------------------------------------
local Countryside = {}

local function roadInfo(biome)
	local dir = Biomes.direction(biome)
	return dir, Vector3.new(-dir.Z, 0, dir.X), Biomes.innerRadius(biome)
end

-- Is this spot open countryside, `radius` studs clear of roads, biomes and the bazaar?
function Countryside.isOpen(position: Vector3, radius: number): boolean
	local r = math.sqrt(position.X * position.X + position.Z * position.Z)
	if r < Biomes.HUB_RADIUS + 6 + radius or r > Biomes.WORLD_RADIUS - 40 - radius then
		return false
	end
	for _, biome in Biomes.list do
		if Biomes.zoneDistance(biome, position) < 1 + (radius + 8) / 100 then
			return false
		end
		local dir, across, inner = roadInfo(biome)
		local along = position.X * dir.X + position.Z * dir.Z
		local side = math.abs(position.X * across.X + position.Z * across.Z)
		if along > Biomes.PLAZA_RADIUS - 10 and along < inner + 12 and side < 9 + radius then
			return false
		end
	end
	return true
end

local function buildCountryside(map: Model)
	local folder = Instance.new("Folder")
	folder.Name = "Countryside"
	folder.Parent = map
	local rng = Random.new(77)
	local taken: { { position: Vector3, radius: number } } = {}
	local function free(position: Vector3, radius: number): boolean
		for _, t in taken do
			if ((position - t.position) * Vector3.new(1, 0, 1)).Magnitude < radius + t.radius then
				return false
			end
		end
		return true
	end
	local function put(name: string, cf: CFrame, radius: number, scale: number?)
		Props.place(name, cf, folder, scale)
		table.insert(taken, { position = cf.Position, radius = radius })
	end
	local function ground(x: number, z: number): Vector3
		return Vector3.new(x, GROUND_Y, z)
	end

	-- along every road
	local stalls = { "FruitStall", "PakoraStall", "GolaCart" }
	local vehicles = { "TruckArt", "Rickshaw" }
	for i, biome in Biomes.list do
		local dir, across, inner = roadInfo(biome)
		local side = if i % 2 == 0 then 1 else -1
		local function roadside(along: number, offset: number): Vector3
			local p = dir * along + across * offset
			return ground(p.X, p.Z)
		end
		local function facingRoad(position: Vector3, offset: number): CFrame
			return CFrame.lookAt(position, position - across * math.sign(offset))
		end
		-- lamp posts between the havelis
		for _, offset in { -9.5, 9.5 } do
			local p = roadside(118, offset)
			Props.place("Lamppost", facingRoad(p, offset), folder)
		end
		-- milestones counting down to the biome
		local along = 214
		local n = 0
		while along < inner - 12 do
			n += 1
			local offset = if n % 2 == 0 then 10.5 else -10.5
			local cf = facingRoad(roadside(along, offset), offset)
			put("Milestone", cf, 1.5)
			Props.text(
				folder,
				cf,
				Props.anchor("Milestone", "Face", cf),
				1.5,
				1.3,
				("%s\n%d"):format(biome.name:upper(), math.ceil((inner - along) / 10))
			)
			along += 60
		end
		local length = inner - Biomes.HUB_RADIUS
		-- a bus stop just outside the bazaar on every other road
		if i % 2 == 1 then
			put("BusStop", facingRoad(roadside(212, -side * 11.5), -side * 11.5), 5)
		end
		-- a chai dhaba with charpais and a parked truck or rickshaw
		if length >= 70 then
			local at = Biomes.HUB_RADIUS + length * 0.45
			local offset = side * 19
			local cf = facingRoad(roadside(at, offset), offset)
			put("ChaiDhaba", cf, 9)
			Props.text(folder, cf, Props.anchor("ChaiDhaba", "Sign", cf), 5.6, 1.2, "CHAI")
			for k, dz in { -10.5, 10.5 } do
				put("Charpai", CFrame.new(roadside(at + dz, side * 17)) * CFrame.Angles(0, math.rad(20 + k * 70), 0), 3)
			end
			local spot = roadside(at + 20, side * 14)
			put(vehicles[i % 2 + 1], CFrame.lookAt(spot, spot - dir), 8)
		end
		-- a snack stall near the biome gate
		if length >= 45 then
			local offset = -side * 13
			put(stalls[i % 3 + 1], facingRoad(roadside(inner - 26, offset), offset), 4)
		end
	end

	-- little farms in the open land between the biomes
	local crops = { "WheatField", "SarsonField", "SugarcaneField", "WheatField" }
	local farms = 0
	for k = 0, 7 do
		local a = math.rad(45 * k)
		for _, r in { 300, 470, 640 } do
			local c = ground(math.cos(a) * r, math.sin(a) * r)
			if Countryside.isOpen(c, 26) and free(c, 26) then
				farms += 1
				local frame = CFrame.lookAt(c, ground(0, 0))
				for _, offset in
					{
						Vector3.new(-11, 0, -11),
						Vector3.new(11, 0, -11),
						Vector3.new(-11, 0, 11),
						Vector3.new(11, 0, 11),
					}
				do
					local spot = frame * CFrame.new(offset)
					if Countryside.isOpen(spot.Position, 10) then
						put(crops[rng:NextInteger(1, #crops)], spot, 10)
					end
				end
				local edge = frame * CFrame.new(0, 0, -25)
				put("TubeWell", edge * CFrame.new(-6, 0, 0), 3)
				put("Charpai", edge * CFrame.new(3, 0, 0) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 180)), 0), 3)
				put("Haystack", frame * CFrame.new(26, 0, 6), 3)
				put("Haystack", frame * CFrame.new(28, 0, -4), 3)
				if farms % 2 == 1 then
					put("TractorTrolley", frame * CFrame.new(-28, 0, 0), 9)
				end
				if farms % 3 == 1 then
					put("MudHut", frame * CFrame.new(-26, 0, 20) * CFrame.Angles(0, math.rad(15), 0), 7)
				end
			end
		end
	end

	-- ponds with reeds
	local ponds = 0
	for _ = 1, 400 do
		if ponds >= 6 then
			break
		end
		local r = rng:NextNumber(260, 700)
		local a = rng:NextNumber(0, math.pi * 2)
		local c = ground(math.cos(a) * r, math.sin(a) * r)
		local radius = rng:NextNumber(8, 13)
		if Countryside.isOpen(c, radius + 4) and free(c, radius + 4) then
			ponds += 1
			BiomeBuilder.pondAt(c, radius, 3, Enum.Material.Water)
			table.insert(taken, { position = c, radius = radius + 2 })
			for j = 1, 5 do
				local b = j * 2 * math.pi / 5 + rng:NextNumber(-0.3, 0.3)
				local spot = c + Vector3.new(math.cos(b), 0, math.sin(b)) * (radius + 0.5)
				Props.place("Reeds", CFrame.new(spot) * CFrame.Angles(0, b, 0), folder)
			end
		end
	end

	-- street cricket and kites near the bazaar
	local fun = { "CricketStumps", "KiteLine", "CricketStumps", "KiteLine" }
	local placed = 0
	for _ = 1, 300 do
		if placed >= #fun then
			break
		end
		local r = rng:NextNumber(215, 290)
		local a = rng:NextNumber(0, math.pi * 2)
		local c = ground(math.cos(a) * r, math.sin(a) * r)
		if Countryside.isOpen(c, 11) and free(c, 11) then
			placed += 1
			put(fun[placed], CFrame.lookAt(c, ground(0, 0)) * CFrame.Angles(0, math.rad(90), 0), 11)
		end
	end

	-- trees, bushes and rocks everywhere else
	local scatter = {
		{ "KikarTree", 46, 5, { 0.9, 1.35 } },
		{ "MangoTree", 26, 5, { 0.9, 1.25 } },
		{ "JungleBush", 24, 2.5, { 0.8, 1.2 } },
		{ "Boulder", 12, 3, { 0.7, 1.3 } },
	}
	for _, entry in scatter do
		local name, count, radius, scales = entry[1], entry[2], entry[3], entry[4]
		local done = 0
		for _ = 1, count * 12 do
			if done >= count then
				break
			end
			local r = rng:NextNumber(Biomes.HUB_RADIUS + 10, Biomes.WORLD_RADIUS - 50)
			local a = rng:NextNumber(0, math.pi * 2)
			local c = ground(math.cos(a) * r, math.sin(a) * r)
			local scale = rng:NextNumber(scales[1], scales[2])
			if Countryside.isOpen(c, radius * scale) and free(c, radius * scale) then
				done += 1
				put(name, CFrame.new(c) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0), radius * scale, scale)
			end
		end
	end
end

MapBuilder.isCountryside = Countryside.isOpen

local function build(): (Model, { [string]: any })
	local map = Instance.new("Model")
	map.Name = MAP_NAME
	buildHub(map)
	local havelis = Instance.new("Folder")
	havelis.Name = "Havelis"
	havelis.Parent = map
	for index = 1, 8 do
		local a = Biomes.haveliAngle(index)
		buildHaveli(
			havelis,
			index,
			Vector3.new(math.cos(a), 0, math.sin(a)) * Biomes.HAVELI_RADIUS + Vector3.new(0, GROUND_Y, 0)
		)
	end
	buildRoads(map)
	buildCountryside(map)
	local biomes = Instance.new("Folder")
	biomes.Name = "Biomes"
	biomes.Parent = map
	local plans = BiomeBuilder.run(biomes)
	map.Parent = workspace
	return map, plans
end

local function child(parent: Instance, name: string): any
	local found = parent:FindFirstChild(name)
	assert(found, ("[ChaiChaos] %s is missing %s"):format(parent:GetFullName(), name))
	return found
end

local function labelIn(parent: Instance): TextLabel
	local label = parent:FindFirstChild("Label", true)
	assert(
		label and label:IsA("TextLabel"),
		("[ChaiChaos] %s needs a TextLabel named Label"):format(parent:GetFullName())
	)
	return label
end

local function partsIn(model: Instance, name: string): { BasePart }
	local list = {}
	local folder = model:FindFirstChild(name)
	if folder then
		for _, p in folder:GetDescendants() do
			if p:IsA("BasePart") then
				table.insert(list, p)
			end
		end
	end
	return list
end

function MapBuilder.read(map: Model, plans: { [string]: any }): Map
	local havelis: { Haveli } = {}
	for _, model in child(map, "Havelis"):GetChildren() do
		if not model:IsA("Model") then
			continue
		end
		local floor: BasePart = child(model, "Floor")
		local deck: BasePart = child(model, "Deck")
		local origin = floor.CFrame * CFrame.new(0, floor.Size.Y / 2, 0)
		local halfDepth = floor.Size.Z / 2
		local upperY = origin:PointToObjectSpace(deck.Position).Y + deck.Size.Y / 2

		local plots, plotLabels = {}, {}
		for i = 1, 2 * PLOTS_PER_FLOOR do
			local plot: BasePart = child(model, "Plot" .. i)
			plots[i] = plot
			plotLabels[i] = labelIn(plot)
		end
		local incubators, incubatorLabels = {}, {}
		for i = 1, Config.MAX_INCUBATORS do
			local nest: BasePart = child(model, "Incubator" .. i)
			incubators[i] = nest
			incubatorLabels[i] = labelIn(nest)
		end

		local galla: BasePart = child(model, "Galla")
		local brainrotFolder = model:FindFirstChild("Brainrots")
		if not brainrotFolder then
			brainrotFolder = Instance.new("Folder")
			brainrotFolder.Name = "Brainrots"
			brainrotFolder.Parent = model
		end
		local decor = model:FindFirstChild("Decor")
		if not decor then
			decor = Instance.new("Folder")
			decor.Name = "Decor"
			decor.Parent = model
		end

		local index = model:GetAttribute("HaveliIndex") or tonumber(model.Name:match("%d+")) or (#havelis + 1)
		table.insert(havelis, {
			index = index,
			model = model,
			origin = origin,
			size = floor.Size,
			upperY = upperY,
			plots = plots,
			plotLabels = plotLabels,
			incubators = incubators,
			incubatorLabels = incubatorLabels,
			galla = galla,
			gallaLabel = labelIn(galla),
			door = child(model, "Door"),
			barrier = child(model, "Barrier"),
			signLabel = labelIn(child(model, "Sign")),
			walls = partsIn(model, "Walls"),
			trims = partsIn(model, "Trim"),
			accents = partsIn(model, "Accent"),
			floors = { floor, deck },
			stairGates = partsIn(model, "StairGates"),
			roof = model:FindFirstChild("Roof"),
			decor = decor,
			guardSpot = (child(model, "GuardSpot") :: BasePart).CFrame,
			spawn = (child(model, "Spawn") :: BasePart).CFrame + Vector3.new(0, 3, 0),
			doorInside = origin * CFrame.new(0, 0, -halfDepth + 6),
			doorOutside = origin * CFrame.new(0, 0, -halfDepth - 5),
			stairBottom = origin * CFrame.new(STAIR_X, 0, STAIR_START - 2),
			stairTop = origin * CFrame.new(STAIR_X, upperY, DECK_FRONT + 2),
			brainrotFolder = brainrotFolder,
			owner = nil,
			guard = nil,
		})
	end
	table.sort(havelis, function(a, b)
		return a.index < b.index
	end)

	local shops = {}
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") and type(d:GetAttribute("Shop")) == "string" then
			shops[d:GetAttribute("Shop")] = d
		end
	end
	local board = map:FindFirstChild("Leaderboard")
	local list = board and board:FindFirstChild("List", true)
	return {
		model = map,
		havelis = havelis,
		shops = shops,
		leaderboard = if list and list:IsA("Frame") then list else nil,
		biomes = plans,
	}
end

function MapBuilder.ensure(): Map
	local existing = workspace:FindFirstChild(MAP_NAME)
	if existing then
		return MapBuilder.read(existing, BiomeBuilder.run(nil))
	end
	local map, plans = build()
	return MapBuilder.read(map, plans)
end

return MapBuilder
