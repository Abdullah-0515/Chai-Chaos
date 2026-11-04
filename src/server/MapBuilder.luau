-- Builds the bazaar if the place does not have one yet, then finds all the
-- important parts. To customise the map: press Play, copy "ChaiChaosMap" from
-- Workspace, stop, paste it back into Workspace and decorate it. Keep the part
-- names (SpawnGate, LaneEnd, Havelis/HaveliN/Floor, PlotN, Galla, Door,
-- Barrier, Sign, Spawn, Walls) and this script will use your version.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)

local MapBuilder = {}

local MAP_NAME = "ChaiChaosMap"
local GROUND_Y = 1
local LANE_LENGTH = 280
local LANE_WIDTH = 16
local HAVELI_W = 50
local HAVELI_D = 40
local WALL_H = 10
local DOOR_W = 12
local HAVELI_X = { -93, -31, 31, 93 }
local HAVELI_Z = 38
local FLOOR_TOP = 0.4
local PLOT_COLUMNS = { -18, -9, 0, 9, 18 }
local PLOT_ROWS = { 13, 3 } -- plots 1-5 at the back, 6-10 in front

export type Haveli = {
	index: number,
	model: Model,
	origin: CFrame, -- centre of the floor's top, facing the lane
	size: Vector3,
	plots: { BasePart },
	plotLabels: { TextLabel },
	galla: BasePart,
	gallaLabel: TextLabel,
	door: BasePart,
	barrier: BasePart,
	signLabel: TextLabel,
	walls: { BasePart },
	spawn: CFrame,
	doorInside: CFrame,
	doorOutside: CFrame,
	brainrotFolder: Folder,
	owner: any, -- the profile of the player living here
}

export type Map = {
	model: Model,
	spawnGate: CFrame,
	laneEnd: CFrame,
	laneFolder: Folder,
	havelis: { Haveli },
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

local function cylinderUp(cf: CFrame): CFrame
	return cf * CFrame.Angles(0, 0, math.rad(90))
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

local function buildStall(parent: Instance, cf: CFrame, title: string, roofColor: Color3)
	local stall = Instance.new("Model")
	stall.Name = title .. "Stall"
	part({
		Name = "Counter",
		Size = Vector3.new(10, 3.5, 4),
		CFrame = cf * CFrame.new(0, 1.75, 0),
		Color = rgb(120, 75, 45),
		Material = Enum.Material.Wood,
		Parent = stall,
	})
	for _, x in { -4.6, 4.6 } do
		part({
			Name = "Pole",
			Size = Vector3.new(0.5, 8, 0.5),
			CFrame = cf * CFrame.new(x, 4, 1.6),
			Color = rgb(90, 60, 40),
			Parent = stall,
		})
	end
	part({
		Name = "Roof",
		Size = Vector3.new(11.5, 0.5, 6),
		CFrame = cf * CFrame.new(0, 8.2, 0.6) * CFrame.Angles(math.rad(-10), 0, 0),
		Color = roofColor,
		Material = Enum.Material.Fabric,
		Parent = stall,
	})
	part({
		Name = "Kettle",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.6, 1.5, 1.5),
		CFrame = cylinderUp(cf * CFrame.new(-2.5, 4.3, 0)),
		Color = rgb(170, 170, 180),
		Material = Enum.Material.Metal,
		Parent = stall,
	})
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(7, 1.6, 0.3),
		CFrame = cf * CFrame.new(0, 9.4, -2.2),
		Color = rgb(30, 120, 90),
		Parent = stall,
	})
	surfaceText(sign, Enum.NormalId.Front, title, rgb(255, 230, 120))
	stall.Parent = parent
end

local function buildFruitCart(parent: Instance, cf: CFrame)
	local cart = Instance.new("Model")
	cart.Name = "FruitCart"
	part({
		Name = "Base",
		Size = Vector3.new(7, 1.2, 4),
		CFrame = cf * CFrame.new(0, 2.4, 0),
		Color = rgb(60, 140, 200),
		Material = Enum.Material.Wood,
		Parent = cart,
	})
	for _, x in { -2.5, 2.5 } do
		for _, z in { -2.2, 2.2 } do
			part({
				Name = "Wheel",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(0.5, 2.4, 2.4),
				CFrame = cf * CFrame.new(x, 1.2, z) * CFrame.Angles(0, math.rad(90), 0),
				Color = rgb(50, 40, 35),
				Parent = cart,
			})
		end
	end
	local fruitColors = { rgb(255, 140, 0), rgb(220, 30, 40), rgb(250, 220, 50), rgb(120, 200, 60) }
	for i = 1, 8 do
		local x = -2.7 + ((i - 1) % 4) * 1.8
		local z = if i <= 4 then -0.8 else 0.8
		part({
			Name = "Fruit",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.1,
			CFrame = cf * CFrame.new(x, 3.5, z),
			Color = fruitColors[(i - 1) % #fruitColors + 1],
			Parent = cart,
		})
	end
	cart.Parent = parent
end

local function buildLane(map: Model)
	part({
		Name = "Ground",
		Size = Vector3.new(430, 1, 200),
		Position = Vector3.new(20, GROUND_Y - 0.5, 0),
		Color = rgb(222, 196, 148),
		Material = Enum.Material.Sand,
		Parent = map,
	})
	part({
		Name = "Lane",
		Size = Vector3.new(LANE_LENGTH, 0.2, LANE_WIDTH),
		Position = Vector3.new(0, GROUND_Y + 0.1, 0),
		Color = rgb(176, 98, 72),
		Material = Enum.Material.Brick,
		Parent = map,
	})
	for _, side in { -1, 1 } do
		part({
			Name = "LaneEdge",
			Size = Vector3.new(LANE_LENGTH, 0.4, 1),
			Position = Vector3.new(0, GROUND_Y + 0.2, side * (LANE_WIDTH / 2 + 0.5)),
			Color = rgb(240, 200, 90),
			Parent = map,
		})
	end

	local startX = -LANE_LENGTH / 2 + 4
	local endX = LANE_LENGTH / 2 - 4
	local y = GROUND_Y + 0.2
	for name, x in { SpawnGate = startX, LaneEnd = endX } do
		part({
			Name = name,
			Size = Vector3.new(1, 1, LANE_WIDTH),
			CFrame = CFrame.lookAt(Vector3.new(x, y, 0), Vector3.new(x + 1, y, 0)),
			Transparency = 1,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
			Parent = map,
		})
	end

	-- Spawn Gate arch
	local gateX = -LANE_LENGTH / 2
	for _, side in { -1, 1 } do
		part({
			Name = "GatePillar",
			Size = Vector3.new(3, 16, 3),
			Position = Vector3.new(gateX, GROUND_Y + 8, side * (LANE_WIDTH / 2 + 2)),
			Color = rgb(200, 80, 60),
			Parent = map,
		})
	end
	local gateSign = part({
		Name = "GateSign",
		Size = Vector3.new(3, 4, LANE_WIDTH + 7),
		Position = Vector3.new(gateX, GROUND_Y + 17.5, 0),
		Color = rgb(40, 140, 120),
		Parent = map,
	})
	surfaceText(gateSign, Enum.NormalId.Right, "BAZAAR LANE", rgb(255, 225, 90))
	surfaceText(gateSign, Enum.NormalId.Left, "CHAI CHAOS", rgb(255, 225, 90))

	-- Chowk (town square) with a fountain
	local chowkX = LANE_LENGTH / 2 + 24
	part({
		Name = "Chowk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 48, 48),
		CFrame = cylinderUp(CFrame.new(chowkX, GROUND_Y + 0.15, 0)),
		Color = rgb(205, 190, 170),
		Material = Enum.Material.Slate,
		Parent = map,
	})
	part({
		Name = "FountainBasin",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 14, 14),
		CFrame = cylinderUp(CFrame.new(chowkX, GROUND_Y + 1.2, 0)),
		Color = rgb(235, 235, 240),
		Material = Enum.Material.Marble,
		Parent = map,
	})
	part({
		Name = "FountainWater",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 12.5, 12.5),
		CFrame = cylinderUp(CFrame.new(chowkX, GROUND_Y + 2.1, 0)),
		Color = rgb(70, 170, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.3,
		CanCollide = false,
		Parent = map,
	})
	part({
		Name = "FountainColumn",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6, 2, 2),
		CFrame = cylinderUp(CFrame.new(chowkX, GROUND_Y + 4, 0)),
		Color = rgb(235, 235, 240),
		Material = Enum.Material.Marble,
		Parent = map,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "ChowkSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(chowkX + 15, GROUND_Y + 0.5, 0)
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Color = rgb(240, 200, 90)
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = map

	-- String lights on both sides of the lane
	local bulbColors = { rgb(255, 80, 80), rgb(255, 210, 60), rgb(80, 220, 120), rgb(90, 160, 255), rgb(255, 120, 220) }
	local first = -LANE_LENGTH / 2 + 10
	local last = LANE_LENGTH / 2 - 10
	for _, side in { -1, 1 } do
		local z = side * (LANE_WIDTH / 2 + 2)
		for x = first, last, 30 do
			part({
				Name = "LightPole",
				Size = Vector3.new(0.5, 8.5, 0.5),
				Position = Vector3.new(x, GROUND_Y + 4.25, z),
				Color = rgb(90, 60, 40),
				Parent = map,
			})
		end
		local i = 0
		for x = first, last, 5 do
			i += 1
			local sag = math.sin(((x - first) % 30) / 30 * math.pi) * 1.4
			local bulb = part({
				Name = "Bulb",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 0.7,
				Position = Vector3.new(x, GROUND_Y + 8.3 - sag, z),
				Color = bulbColors[i % #bulbColors + 1],
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = map,
			})
			if i % 6 == 0 then
				local light = Instance.new("PointLight")
				light.Color = bulb.Color
				light.Range = 14
				light.Brightness = 1.2
				light.Parent = bulb
			end
		end
	end

	-- Stalls and carts at both ends of the lane
	local function facingLane(position: Vector3): CFrame
		return CFrame.lookAt(position, Vector3.new(position.X, position.Y, 0))
	end
	buildStall(map, facingLane(Vector3.new(-150, GROUND_Y, -24)), "CHAI", rgb(220, 60, 60))
	buildFruitCart(map, facingLane(Vector3.new(-150, GROUND_Y, 24)))
	buildStall(map, facingLane(Vector3.new(150, GROUND_Y, -32)), "PARATHA", rgb(250, 170, 40))
	buildFruitCart(map, facingLane(Vector3.new(150, GROUND_Y, 32)))
end

local function buildHaveli(parent: Instance, index: number, center: Vector3)
	local origin = CFrame.lookAt(center, Vector3.new(center.X, center.Y, 0))
	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end

	local haveli = Instance.new("Model")
	haveli.Name = "Haveli" .. index
	haveli:SetAttribute("HaveliIndex", index)

	part({
		Name = "Floor",
		Size = Vector3.new(HAVELI_W, FLOOR_TOP, HAVELI_D),
		CFrame = at(0, FLOOR_TOP / 2, 0),
		Color = rgb(240, 230, 210),
		Material = Enum.Material.Marble,
		Parent = haveli,
	})

	local walls = Instance.new("Folder")
	walls.Name = "Walls"
	walls.Parent = haveli
	local wallColor = Config.HAVELI_COLORS[1]
	local wallY = FLOOR_TOP + WALL_H / 2
	local front = -HAVELI_D / 2 + 0.5
	local segment = (HAVELI_W - DOOR_W) / 2
	local wallPieces = {
		{ Vector3.new(HAVELI_W, WALL_H, 1), at(0, wallY, HAVELI_D / 2 - 0.5) },
		{ Vector3.new(1, WALL_H, HAVELI_D), at(-HAVELI_W / 2 + 0.5, wallY, 0) },
		{ Vector3.new(1, WALL_H, HAVELI_D), at(HAVELI_W / 2 - 0.5, wallY, 0) },
		{ Vector3.new(segment, WALL_H, 1), at(-(DOOR_W / 2 + segment / 2), wallY, front) },
		{ Vector3.new(segment, WALL_H, 1), at(DOOR_W / 2 + segment / 2, wallY, front) },
		{ Vector3.new(DOOR_W, 2, 1), at(0, FLOOR_TOP + WALL_H - 1, front) },
	}
	for _, piece in wallPieces do
		part({ Name = "Wall", Size = piece[1], CFrame = piece[2], Color = wallColor, Parent = walls })
	end
	for _, x in { -HAVELI_W / 2, HAVELI_W / 2 } do
		for _, z in { -HAVELI_D / 2, HAVELI_D / 2 } do
			part({
				Name = "Tower",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(WALL_H + 3, 3.4, 3.4),
				CFrame = cylinderUp(at(x, FLOOR_TOP + (WALL_H + 3) / 2, z)),
				Color = wallColor,
				Parent = walls,
			})
			part({
				Name = "Dome",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 3.8,
				CFrame = at(x, FLOOR_TOP + WALL_H + 3.6, z),
				Color = wallColor,
				Parent = walls,
			})
		end
	end
	for _, x in { -DOOR_W / 2, DOOR_W / 2 } do
		part({
			Name = "DoorPillar",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(WALL_H + 1, 1.6, 1.6),
			CFrame = cylinderUp(at(x, FLOOR_TOP + (WALL_H + 1) / 2, front)),
			Color = wallColor,
			Parent = walls,
		})
	end

	part({
		Name = "Door",
		Size = Vector3.new(DOOR_W - 1, 8, 2),
		CFrame = at(0, FLOOR_TOP + 4, front),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		Parent = haveli,
	})
	part({
		Name = "Barrier",
		Size = Vector3.new(DOOR_W, 8.6, 0.4),
		CFrame = at(0, FLOOR_TOP + 4.3, front),
		Color = rgb(255, 60, 60),
		Material = Enum.Material.Neon,
		Transparency = 1,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Parent = haveli,
	})
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(18, 3, 0.6),
		CFrame = at(0, FLOOR_TOP + WALL_H + 1.5, front),
		Color = rgb(30, 110, 85),
		Parent = haveli,
	})
	surfaceText(sign, Enum.NormalId.Front, "Khaali Haveli", rgb(255, 235, 150))

	for i = 1, Config.MAX_PLOTS do
		local column = PLOT_COLUMNS[(i - 1) % #PLOT_COLUMNS + 1]
		local row = PLOT_ROWS[math.ceil(i / #PLOT_COLUMNS)]
		local plot = part({
			Name = "Plot" .. i,
			Size = Vector3.new(7, 0.3, 7),
			CFrame = at(column, FLOOR_TOP + 0.15, row),
			Color = rgb(235, 225, 200),
			Parent = haveli,
		})
		plot:SetAttribute("HaveliIndex", index)
		plot:SetAttribute("PlotIndex", i)
		surfaceText(plot, Enum.NormalId.Top, "", rgb(255, 255, 255))
	end

	local galla = part({
		Name = "Galla",
		Size = Vector3.new(4, 3, 3),
		CFrame = at(15, FLOOR_TOP + 1.5, -13),
		Color = rgb(110, 70, 40),
		Material = Enum.Material.Wood,
		Parent = haveli,
	})
	part({
		Name = "GallaTrim",
		Size = Vector3.new(4.2, 0.4, 0.8),
		CFrame = at(15, FLOOR_TOP + 3.1, -13),
		Color = rgb(255, 200, 60),
		Material = Enum.Material.Metal,
		CanCollide = false,
		Parent = haveli,
	})
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GallaGui"
	billboard.Size = UDim2.fromScale(7, 2.2)
	billboard.StudsOffset = Vector3.new(0, 3.4, 0)
	billboard.MaxDistance = 70
	billboard.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = rgb(255, 220, 90)
	label.Text = "Galla"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = billboard
	billboard.Parent = galla

	part({
		Name = "Spawn",
		Size = Vector3.new(4, 1, 4),
		CFrame = at(0, FLOOR_TOP + 0.5, -12) * CFrame.Angles(0, math.pi, 0),
		Transparency = 1,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Parent = haveli,
	})

	local brainrots = Instance.new("Folder")
	brainrots.Name = "Brainrots"
	brainrots.Parent = haveli

	haveli.Parent = parent
end

local function build(): Model
	local map = Instance.new("Model")
	map.Name = MAP_NAME
	buildLane(map)

	local havelis = Instance.new("Folder")
	havelis.Name = "Havelis"
	havelis.Parent = map
	local index = 0
	for _, side in { -1, 1 } do
		for _, x in HAVELI_X do
			index += 1
			buildHaveli(havelis, index, Vector3.new(x, GROUND_Y, side * HAVELI_Z))
		end
	end

	map.Parent = workspace
	return map
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

function MapBuilder.read(map: Model): Map
	local laneFolder = map:FindFirstChild("LaneBrainrots")
	if not laneFolder then
		laneFolder = Instance.new("Folder")
		laneFolder.Name = "LaneBrainrots"
		laneFolder.Parent = map
	end

	local havelis: { Haveli } = {}
	for _, model in child(map, "Havelis"):GetChildren() do
		if not model:IsA("Model") then
			continue
		end
		local floor: BasePart = child(model, "Floor")
		local origin = floor.CFrame * CFrame.new(0, floor.Size.Y / 2, 0)
		local halfDepth = floor.Size.Z / 2

		local plots, plotLabels = {}, {}
		for i = 1, Config.MAX_PLOTS do
			local plot: BasePart = child(model, "Plot" .. i)
			plots[i] = plot
			plotLabels[i] = labelIn(plot)
		end

		local walls = {}
		local wallFolder = model:FindFirstChild("Walls")
		if wallFolder then
			for _, p in wallFolder:GetDescendants() do
				if p:IsA("BasePart") then
					table.insert(walls, p)
				end
			end
		end

		local galla: BasePart = child(model, "Galla")
		local brainrotFolder = model:FindFirstChild("Brainrots")
		if not brainrotFolder then
			brainrotFolder = Instance.new("Folder")
			brainrotFolder.Name = "Brainrots"
			brainrotFolder.Parent = model
		end

		local index = model:GetAttribute("HaveliIndex") or tonumber(model.Name:match("%d+")) or (#havelis + 1)
		table.insert(havelis, {
			index = index,
			model = model,
			origin = origin,
			size = floor.Size,
			plots = plots,
			plotLabels = plotLabels,
			galla = galla,
			gallaLabel = labelIn(galla),
			door = child(model, "Door"),
			barrier = child(model, "Barrier"),
			signLabel = labelIn(child(model, "Sign")),
			walls = walls,
			spawn = (child(model, "Spawn") :: BasePart).CFrame + Vector3.new(0, 3, 0),
			doorInside = origin * CFrame.new(0, 0, -halfDepth + 5),
			doorOutside = origin * CFrame.new(0, 0, -halfDepth - 5),
			brainrotFolder = brainrotFolder,
			owner = nil,
		})
	end
	table.sort(havelis, function(a, b)
		return a.index < b.index
	end)

	return {
		model = map,
		spawnGate = (child(map, "SpawnGate") :: BasePart).CFrame,
		laneEnd = (child(map, "LaneEnd") :: BasePart).CFrame,
		laneFolder = laneFolder,
		havelis = havelis,
	}
end

function MapBuilder.ensure(): Map
	local map = workspace:FindFirstChild(MAP_NAME)
	if not map then
		map = build()
	end
	return MapBuilder.read(map)
end

return MapBuilder
