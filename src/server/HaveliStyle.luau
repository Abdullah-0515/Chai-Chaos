-- Paints a haveli in its owner's theme and adds decorations for its level.
--
-- Level 1: lanterns by the door and a little decor in the courtyard
-- Level 2: more courtyard decor
-- Level 4: the garden (the theme's third decoration everywhere)
-- Level 5: the second floor opens and gets decorations
-- Level 6: the Chowkidar stands guard by the door
-- Level 8: the rooftop with chhatris and kites
-- Level 9: golden fairy lights along the walls

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Themes = require(Shared.Themes)

local MapBuilder = require(script.Parent.MapBuilder)

local HaveliStyle = {}

local part = MapBuilder.part
local UP = CFrame.Angles(0, 0, math.rad(90))

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local BRIGHT = {
	rgb(255, 70, 90),
	rgb(255, 205, 40),
	rgb(70, 210, 110),
	rgb(70, 160, 255),
	rgb(255, 120, 220),
	rgb(255, 150, 40),
}

local function material(name: string): Enum.Material
	return (Enum.Material :: any)[name]
end

-- Small decoration parts never collide and cast no shadow.
local function deco(props: { [string]: any }): Part
	props.CanCollide = props.CanCollide or false
	props.CastShadow = false
	return part(props)
end

---------------------------------------------------------------------------
-- Decorations. Each takes (folder, cf, theme) where cf stands on the floor.
---------------------------------------------------------------------------
local DECOR = {}

function DECOR.lantern(folder, cf, theme)
	deco({
		Name = "Post",
		Size = Vector3.new(0.5, 6, 0.5),
		CFrame = cf * CFrame.new(0, 3, 0),
		Color = theme.trim,
		Parent = folder,
	})
	local lamp = deco({
		Name = "Lantern",
		Size = Vector3.new(1.4, 1.8, 1.4),
		CFrame = cf * CFrame.new(0, 6.6, 0),
		Color = rgb(255, 210, 110),
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	deco({
		Name = "Cap",
		Size = Vector3.new(1.8, 0.4, 1.8),
		CFrame = cf * CFrame.new(0, 7.7, 0),
		Color = theme.accent,
		Parent = folder,
	})
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 210, 140)
	light.Range = 14
	light.Brightness = 1.4
	light.Parent = lamp
end

function DECOR.planter(folder, cf, theme)
	deco({
		Name = "Pot",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.6, 2.4, 2.4),
		CFrame = cf * CFrame.new(0, 0.8, 0) * UP,
		Color = theme.trim,
		Parent = folder,
	})
	for i = 1, 5 do
		local angle = i * math.pi * 2 / 5
		deco({
			Name = "Flower",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.9,
			CFrame = cf * CFrame.new(math.cos(angle) * 0.7, 2.1 + (i % 2) * 0.3, math.sin(angle) * 0.7),
			Color = BRIGHT[i],
			Parent = folder,
		})
	end
	deco({
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.6,
		CFrame = cf * CFrame.new(0, 1.8, 0),
		Color = rgb(70, 175, 80),
		Parent = folder,
	})
end

function DECOR.fountain(folder, cf, theme)
	deco({
		Name = "Basin",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.2, 5, 5),
		CFrame = cf * CFrame.new(0, 0.6, 0) * UP,
		Color = theme.wall,
		Material = Enum.Material.Marble,
		CanCollide = true,
		Parent = folder,
	})
	deco({
		Name = "Water",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 4.3, 4.3),
		CFrame = cf * CFrame.new(0, 1.15, 0) * UP,
		Color = rgb(80, 185, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.3,
		Parent = folder,
	})
	deco({
		Name = "Top",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.2,
		CFrame = cf * CFrame.new(0, 2.4, 0),
		Color = theme.accent,
		Parent = folder,
	})
end

function DECOR.tree(folder, cf, _theme)
	deco({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(5, 1.2, 1.2),
		CFrame = cf * CFrame.new(0, 2.5, 0) * UP,
		Color = rgb(140, 95, 60),
		Material = Enum.Material.Wood,
		Parent = folder,
	})
	for i, offset in { Vector3.new(0, 6, 0), Vector3.new(1.2, 5.2, 0.6), Vector3.new(-1, 5.4, -0.8) } do
		deco({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * (3.6 - i * 0.4),
			CFrame = cf * CFrame.new(offset),
			Color = if i == 1 then rgb(80, 190, 90) else rgb(100, 210, 100),
			Parent = folder,
		})
	end
	deco({
		Name = "Fruit",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 0.6,
		CFrame = cf * CFrame.new(1.4, 5.8, -1),
		Color = rgb(255, 150, 30),
		Parent = folder,
	})
end

function DECOR.hedge(folder, cf, _theme)
	deco({
		Name = "Hedge",
		Size = Vector3.new(5, 1.8, 1.6),
		CFrame = cf * CFrame.new(0, 0.9, 0),
		Color = rgb(70, 170, 80),
		Material = Enum.Material.Grass,
		Parent = folder,
	})
	for i = -2, 2 do
		deco({
			Name = "Bloom",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.7,
			CFrame = cf * CFrame.new(i * 1, 1.9, 0),
			Color = BRIGHT[(i + 3) % #BRIGHT + 1],
			Parent = folder,
		})
	end
end

function DECOR.bells(folder, cf, theme)
	deco({
		Name = "Bar",
		Size = Vector3.new(6, 0.3, 0.3),
		CFrame = cf * CFrame.new(0, 6, 0),
		Color = theme.trim,
		Parent = folder,
	})
	for _, x in { -2.5, 2.5 } do
		deco({
			Name = "Post",
			Size = Vector3.new(0.4, 6, 0.4),
			CFrame = cf * CFrame.new(x, 3, 0),
			Color = theme.trim,
			Parent = folder,
		})
	end
	for i = -2, 2 do
		deco({
			Name = "Bell",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.8,
			CFrame = cf * CFrame.new(i, 5.1, 0),
			Color = rgb(255, 210, 60),
			Material = Enum.Material.Metal,
			Parent = folder,
		})
		deco({
			Name = "Chain",
			Size = Vector3.new(0.1, 0.6, 0.1),
			CFrame = cf * CFrame.new(i, 5.6, 0),
			Color = rgb(200, 200, 210),
			Parent = folder,
		})
	end
end

function DECOR.banner(folder, cf, theme)
	deco({
		Name = "Pole",
		Size = Vector3.new(0.4, 8, 0.4),
		CFrame = cf * CFrame.new(0, 4, 0),
		Color = theme.trim,
		Parent = folder,
	})
	for i = 0, 2 do
		deco({
			Name = "Cloth",
			Size = Vector3.new(2.4, 1.2, 0.1),
			CFrame = cf * CFrame.new(1.4, 7 - i * 1.2, 0),
			Color = if i % 2 == 0 then theme.accent else theme.trim,
			Material = Enum.Material.Fabric,
			Parent = folder,
		})
	end
end

function DECOR.charpai(folder, cf, _theme)
	for _, x in { -1.6, 1.6 } do
		for _, z in { -2.8, 2.8 } do
			deco({
				Name = "Leg",
				Size = Vector3.new(0.4, 1.4, 0.4),
				CFrame = cf * CFrame.new(x, 0.7, z),
				Color = rgb(130, 85, 50),
				Parent = folder,
			})
		end
	end
	deco({
		Name = "Frame",
		Size = Vector3.new(3.6, 0.4, 6),
		CFrame = cf * CFrame.new(0, 1.5, 0),
		Color = rgb(150, 100, 60),
		Material = Enum.Material.Wood,
		CanCollide = true,
		Parent = folder,
	})
	deco({
		Name = "Weave",
		Size = Vector3.new(3.2, 0.1, 5.6),
		CFrame = cf * CFrame.new(0, 1.75, 0),
		Color = rgb(235, 215, 165),
		Material = Enum.Material.Fabric,
		Parent = folder,
	})
end

function DECOR.kettle(folder, cf, _theme)
	deco({
		Name = "Stove",
		Size = Vector3.new(2.6, 1.6, 2.6),
		CFrame = cf * CFrame.new(0, 0.8, 0),
		Color = rgb(90, 85, 80),
		Material = Enum.Material.Slate,
		Parent = folder,
	})
	deco({
		Name = "Kettle",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 2.2,
		CFrame = cf * CFrame.new(0, 2.6, 0),
		Color = rgb(200, 200, 210),
		Material = Enum.Material.Metal,
		Parent = folder,
	})
	deco({
		Name = "Spout",
		Size = Vector3.new(0.4, 0.4, 1.4),
		CFrame = cf * CFrame.new(0, 2.8, -1.3) * CFrame.Angles(math.rad(30), 0, 0),
		Color = rgb(200, 200, 210),
		Parent = folder,
	})
	local fire = deco({
		Name = "Fire",
		Size = Vector3.new(1.2, 0.3, 1.2),
		CFrame = cf * CFrame.new(0, 1.7, 0),
		Color = rgb(255, 120, 30),
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	local steam = Instance.new("ParticleEmitter")
	steam.Rate = 3
	steam.Lifetime = NumberRange.new(1.5, 2.5)
	steam.Speed = NumberRange.new(1, 2)
	steam.Size = NumberSequence.new(0.6, 1.4)
	steam.Transparency = NumberSequence.new(0.4, 1)
	steam.Color = ColorSequence.new(rgb(255, 255, 255))
	steam.Parent = fire
end

function DECOR.mirror(folder, cf, theme)
	deco({
		Name = "Frame",
		Size = Vector3.new(3.2, 6.2, 0.4),
		CFrame = cf * CFrame.new(0, 3.1, 0),
		Color = theme.trim,
		Parent = folder,
	})
	deco({
		Name = "Glass",
		Size = Vector3.new(2.6, 5.6, 0.2),
		CFrame = cf * CFrame.new(0, 3.1, -0.15),
		Color = rgb(220, 240, 255),
		Material = Enum.Material.Glass,
		Reflectance = 0.6,
		Parent = folder,
	})
end

function DECOR.crystal(folder, cf, theme)
	for i, h in { 3, 2.2, 1.6 } do
		deco({
			Name = "Crystal",
			Size = Vector3.new(0.9, h, 0.9),
			CFrame = cf
				* CFrame.new((i - 2) * 0.9, h / 2, (i % 2) * 0.5)
				* CFrame.Angles(0, math.rad(45), math.rad((i - 2) * 12)),
			Color = if i == 2 then theme.trim else rgb(170, 230, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.2,
			Parent = folder,
		})
	end
end

function DECOR.kiteStand(folder, cf, theme)
	deco({
		Name = "Pole",
		Size = Vector3.new(0.3, 7, 0.3),
		CFrame = cf * CFrame.new(0, 3.5, 0),
		Color = rgb(150, 110, 70),
		Parent = folder,
	})
	deco({
		Name = "Kite",
		Size = Vector3.new(2.4, 2.4, 0.15),
		CFrame = cf * CFrame.new(0, 8.2, 0) * CFrame.Angles(0, 0, math.rad(45)),
		Color = theme.trim,
		Parent = folder,
	})
	deco({
		Name = "Tail",
		Size = Vector3.new(0.15, 2, 0.1),
		CFrame = cf * CFrame.new(0, 6.4, 0),
		Color = theme.accent,
		Parent = folder,
	})
end

function DECOR.stumps(folder, cf, _theme)
	for i = -1, 1 do
		deco({
			Name = "Stump",
			Size = Vector3.new(0.3, 2.6, 0.3),
			CFrame = cf * CFrame.new(i * 0.5, 1.3, 0),
			Color = rgb(250, 240, 220),
			Parent = folder,
		})
	end
	deco({
		Name = "Bails",
		Size = Vector3.new(1.4, 0.15, 0.2),
		CFrame = cf * CFrame.new(0, 2.65, 0),
		Color = rgb(230, 60, 60),
		Parent = folder,
	})
	deco({
		Name = "Bat",
		Size = Vector3.new(0.5, 3, 0.25),
		CFrame = cf * CFrame.new(1.8, 1.4, 0) * CFrame.Angles(0, 0, math.rad(-15)),
		Color = rgb(225, 195, 140),
		Parent = folder,
	})
	deco({
		Name = "Ball",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 0.5,
		CFrame = cf * CFrame.new(-1.4, 0.25, 0.6),
		Color = rgb(255, 230, 40),
		Parent = folder,
	})
end

function DECOR.balloons(folder, cf, _theme)
	for i = 1, 5 do
		local offset = Vector3.new(math.cos(i * 1.3) * 1.2, 6 + (i % 3) * 0.8, math.sin(i * 1.3) * 1.2)
		deco({
			Name = "Balloon",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.5,
			CFrame = cf * CFrame.new(offset),
			Color = BRIGHT[i],
			Parent = folder,
		})
		deco({
			Name = "String",
			Size = Vector3.new(0.05, offset.Y - 1, 0.05),
			CFrame = CFrame.lookAt((cf * CFrame.new(offset / 2)).Position, (cf * CFrame.new(offset)).Position)
				* CFrame.Angles(math.rad(90), 0, 0),
			Color = rgb(255, 255, 255),
			Parent = folder,
		})
	end
	deco({
		Name = "Weight",
		Size = Vector3.new(0.8, 0.6, 0.8),
		CFrame = cf * CFrame.new(0, 0.3, 0),
		Color = rgb(255, 205, 50),
		Parent = folder,
	})
end

function DECOR.fairyLights(folder, cf, _theme)
	for i = -4, 4 do
		deco({
			Name = "Light",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.5,
			CFrame = cf * CFrame.new(i * 0.9, 7 - math.abs(i) * 0.15, 0),
			Color = BRIGHT[(i + 5) % #BRIGHT + 1],
			Material = Enum.Material.Neon,
			Parent = folder,
		})
	end
	for _, x in { -4, 4 } do
		deco({
			Name = "Post",
			Size = Vector3.new(0.3, 7, 0.3),
			CFrame = cf * CFrame.new(x, 3.5, 0),
			Color = rgb(150, 110, 70),
			Parent = folder,
		})
	end
end

function DECOR.bunting(folder, cf, _theme)
	for i = -5, 5 do
		deco({
			Name = "Flag",
			Size = Vector3.new(0.9, 0.9, 0.1),
			CFrame = cf
				* CFrame.new(i * 0.9, 6.5 - math.cos(i / 5 * math.pi / 2) * 0.8, 0)
				* CFrame.Angles(0, 0, math.rad(45)),
			Color = BRIGHT[(i + 6) % #BRIGHT + 1],
			Material = Enum.Material.Fabric,
			Parent = folder,
		})
	end
	for _, x in { -5, 5 } do
		deco({
			Name = "Post",
			Size = Vector3.new(0.3, 7, 0.3),
			CFrame = cf * CFrame.new(x, 3.5, 0),
			Color = rgb(150, 110, 70),
			Parent = folder,
		})
	end
end

function DECOR.chhatri(folder, cf, theme)
	for _, x in { -1.5, 1.5 } do
		for _, z in { -1.5, 1.5 } do
			deco({
				Name = "Pillar",
				Size = Vector3.new(0.5, 4, 0.5),
				CFrame = cf * CFrame.new(x, 2, z),
				Color = theme.trim,
				Parent = folder,
			})
		end
	end
	deco({
		Name = "Slab",
		Size = Vector3.new(4.4, 0.5, 4.4),
		CFrame = cf * CFrame.new(0, 4.25, 0),
		Color = theme.wall,
		Parent = folder,
	})
	deco({
		Name = "Dome",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 3.6,
		CFrame = cf * CFrame.new(0, 5.2, 0),
		Color = theme.accent,
		Parent = folder,
	})
end

function DECOR.kites(folder, cf, _theme)
	for i = 1, 4 do
		local offset = Vector3.new((i - 2.5) * 5, 12 + (i % 2) * 4, (i % 3) * 3)
		deco({
			Name = "Kite",
			Size = Vector3.new(3, 3, 0.15),
			CFrame = cf * CFrame.new(offset) * CFrame.Angles(0, math.rad(i * 25), math.rad(45)),
			Color = BRIGHT[i + 1],
			Parent = folder,
		})
		deco({
			Name = "Tail",
			Size = Vector3.new(0.2, 3, 0.1),
			CFrame = cf * CFrame.new(offset - Vector3.new(0, 2.6, 0)),
			Color = BRIGHT[i],
			Parent = folder,
		})
	end
end

---------------------------------------------------------------------------
-- The Chowkidar (level 6)
---------------------------------------------------------------------------
local function buildChowkidar(folder: Instance, cf: CFrame): Model
	local guard = Instance.new("Model")
	guard.Name = "Chowkidar"
	local khaki = rgb(195, 170, 110)
	local root = deco({
		Name = "Body",
		Size = Vector3.new(2, 3, 1.4),
		CFrame = cf * CFrame.new(0, 2.4, 0),
		Color = khaki,
		Parent = guard,
	})
	for _, x in { -0.5, 0.5 } do
		deco({
			Name = "Leg",
			Size = Vector3.new(0.7, 1.4, 0.8),
			CFrame = cf * CFrame.new(x, 0.7, 0),
			Color = rgb(90, 75, 55),
			Parent = guard,
		})
	end
	deco({
		Name = "Head",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.8,
		CFrame = cf * CFrame.new(0, 4.8, 0),
		Color = rgb(225, 170, 120),
		Parent = guard,
	})
	deco({
		Name = "Cap",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 1.9, 1.9),
		CFrame = cf * CFrame.new(0, 5.7, 0) * UP,
		Color = rgb(60, 80, 140),
		Parent = guard,
	})
	for _, side in { -1, 1 } do
		deco({
			Name = "Moustache",
			Size = Vector3.new(0.8, 0.25, 0.25),
			CFrame = cf * CFrame.new(side * 0.4, 4.4, -0.85) * CFrame.Angles(0, 0, math.rad(side * -15)),
			Color = rgb(30, 25, 25),
			Parent = guard,
		})
		deco({
			Name = "Eye",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.35,
			CFrame = cf * CFrame.new(side * 0.35, 5, -0.8),
			Color = rgb(20, 20, 20),
			Parent = guard,
		})
	end
	deco({
		Name = "Lathi",
		Size = Vector3.new(0.3, 5, 0.3),
		CFrame = cf * CFrame.new(1.5, 2.6, -0.3) * CFrame.Angles(0, 0, math.rad(-10)),
		Color = rgb(130, 85, 45),
		Parent = guard,
	})
	guard.PrimaryPart = root

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Status"
	billboard.Size = UDim2.fromScale(7, 1.6)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.MaxDistance = 70
	billboard.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = rgb(255, 235, 120)
	label.Text = "Jaagte Raho!"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = billboard
	billboard.Parent = root
	guard.Parent = folder
	return guard
end

---------------------------------------------------------------------------
-- Painting
---------------------------------------------------------------------------
local FRONT_SPOTS = { -- courtyard (x, z), clear of the door path, galla, incubators, stairs and plots
	{ -24, -8 },
	{ 31, -9 },
	{ -16, -24 },
	{ 16, -24 },
	{ 31, -24 },
	{ -10, -8 },
}
local UPPER_SPOTS = { { -30, 23 }, { 0, 24 }, { 30, 23 }, { -14, 24 }, { 15, 24 } }
local ROOF_SPOTS = { { -31, -2 }, { 31, -2 }, { -31, 22 }, { 31, 22 } }

local function paint(parts: { BasePart }, color: Color3, mat: Enum.Material?, reflectance: number?)
	for _, p in parts do
		p.Color = color
		if mat then
			p.Material = mat
		end
		p.Reflectance = reflectance or 0
	end
end

local function place(h, kind: string, theme, spots, y: number, from: number, to: number)
	local add = DECOR[kind]
	if not add then
		warn("[ChaiChaos] Unknown decoration " .. kind)
		return
	end
	for i = from, math.min(to, #spots) do
		local spot = spots[i]
		add(h.decor, h.origin * CFrame.new(spot[1], y, spot[2]), theme)
	end
end

-- Returns the Chowkidar model if this level has one.
function HaveliStyle.apply(h, themeId: string?, level: number): Model?
	local theme = themeId and Themes.byId[themeId]
	local look = theme or Themes.EMPTY
	paint(h.walls, look.wall, material(look.wallMaterial), look.reflectance)
	paint(h.trims, look.trim)
	paint(h.accents, look.accent, Enum.Material.SmoothPlastic)
	paint(h.floors, look.floor, material(look.floorMaterial))

	local upstairs = theme ~= nil and level >= Config.UPPER_FLOOR_LEVEL
	for _, gate in h.stairGates do
		gate.Transparency = if upstairs then 1 else (if gate.Name == "StairSign" then 0 else 0.5)
		gate.CanCollide = not upstairs
		local gui = gate:FindFirstChildOfClass("SurfaceGui")
		if gui then
			gui.Enabled = not upstairs
		end
	end
	-- egg incubators: more of them at higher levels
	local nests = if theme then Config.HAVELI_LEVELS[level].incubators else 1
	for i, nest in h.incubators do
		local on = i <= nests
		nest.Transparency = if on then 0 else 1
		nest.CanCollide = false
		local gui = nest:FindFirstChildOfClass("BillboardGui")
		if gui then
			gui.Enabled = on
		end
	end

	local rooftop = theme ~= nil and level >= Config.ROOFTOP_LEVEL
	if h.roof then
		h.roof.Transparency = if rooftop then 0 else 1
		h.roof.CanCollide = rooftop
		h.roof.Color = look.trim
	end

	h.decor:ClearAllChildren()
	if not theme then
		return nil
	end

	-- lanterns either side of the door, on the lane side
	for _, x in { -10, 10 } do
		DECOR.lantern(h.decor, h.origin * CFrame.new(x, 0, -h.size.Z / 2 - 1.5), theme)
	end
	place(h, theme.decor[1], theme, FRONT_SPOTS, 0, 1, 2)
	if level >= 2 then
		place(h, theme.decor[2], theme, FRONT_SPOTS, 0, 3, 4)
	end
	if level >= Config.GARDEN_LEVEL then
		place(h, theme.decor[3], theme, FRONT_SPOTS, 0, 5, 6)
	end
	if upstairs then
		place(h, theme.upperDecor, theme, UPPER_SPOTS, h.upperY, 1, 3)
	end
	local guard = nil
	if level >= Config.GUARD_LEVEL then
		guard = buildChowkidar(h.decor, h.guardSpot)
	end
	if rooftop then
		local roofY = h.roof and (h.origin:PointToObjectSpace(h.roof.Position).Y + h.roof.Size.Y / 2) or (h.upperY + 9)
		place(h, "chhatri", theme, ROOF_SPOTS, roofY, 1, 4)
		place(h, theme.roofDecor, theme, { { 0, 10 } }, roofY, 1, 1)
	end
	if level >= #Config.HAVELI_LEVELS then
		for _, x in { -18, 18 } do
			DECOR.fairyLights(h.decor, h.origin * CFrame.new(x, h.upperY - 0.4, -h.size.Z / 2 + 1), theme)
		end
		place(h, theme.upperDecor, theme, UPPER_SPOTS, h.upperY, 4, 5)
	end
	return guard
end

return HaveliStyle
