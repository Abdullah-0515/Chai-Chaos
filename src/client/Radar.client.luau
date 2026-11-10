-- The radar in the bottom right corner.
--
-- * Egg dots for every zone you have unlocked, as far as your tracker's range
--   reaches. The nearest egg out of range shows as a pip on the edge, so you
--   always know where to go.
-- * Golden eggs from tracker level 3, treasure chests from level 5.
-- * Wild brainrots ("W", in their rarity's colour) roaming the zones.
-- * A house for your haveli and a dot for the Chowk.
-- * The countdown of the egg you are carrying, hazard warnings and egg rushes.
-- * A big title when you walk into a zone or a bazaar sector.
--
-- The radar turns with the camera: straight up is the way you are looking.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared:WaitForChild("Config"))
local Biomes = require(Shared:WaitForChild("Biomes"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Ui = require(script.Parent:WaitForChild("Ui"))

local rgb, create, label = Ui.rgb, Ui.create, Ui.label
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChaiChaosHud")

local SIZE = 190
local RADIUS = SIZE / 2 - 8
local GOLD = rgb(255, 205, 50)
local HOME = rgb(255, 120, 60)

---------------------------------------------------------------------------
-- Layout
---------------------------------------------------------------------------
local holder = create("Frame", {
	Name = "RadarHolder",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -12, 1, -12),
	Size = UDim2.fromOffset(SIZE, SIZE + 46),
	BackgroundTransparency = 1,
	Parent = gui,
})
local radar = create("Frame", {
	Name = "Radar",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 1),
	Size = UDim2.fromOffset(SIZE, SIZE),
	BackgroundColor3 = rgb(25, 45, 35),
	BackgroundTransparency = 0.15,
	Parent = holder,
}, {
	create("UICorner", { CornerRadius = UDim.new(1, 0) }),
	create("UIStroke", { Thickness = 3, Color = rgb(120, 230, 150), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})
for _, ring in { 0.33, 0.66 } do
	create("Frame", {
		Name = "Ring",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(ring, ring),
		BackgroundTransparency = 1,
		Parent = radar,
	}, {
		create("UICorner", { CornerRadius = UDim.new(1, 0) }),
		create("UIStroke", { Thickness = 1, Color = rgb(90, 170, 110), Transparency = 0.4 }),
	})
end
local dots = create("Frame", {
	Name = "Dots",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Parent = radar,
})
label({
	Name = "You",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(18, 18),
	Text = "▲",
	ZIndex = 3,
	Parent = radar,
})
local levelLabel = label({
	Name = "Level",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 6),
	Size = UDim2.fromOffset(120, 16),
	TextColor3 = rgb(160, 255, 180),
	ZIndex = 3,
	Parent = radar,
})
local areaLabel = label({
	Name = "Area",
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.new(1, 0, 0, 20),
	Parent = holder,
})
local tracksLabel = label({
	Name = "Tracks",
	Position = UDim2.fromOffset(0, 22),
	Size = UDim2.new(1, 0, 0, 16),
	TextColor3 = rgb(200, 230, 210),
	Parent = holder,
})

-- carried egg, hazard and egg rush, stacked above the radar
local status = create("Frame", {
	Name = "RadarStatus",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -12, 1, -(SIZE + 64)),
	Size = UDim2.fromOffset(260, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
local rushLabel = label({
	Name = "Rush",
	Size = UDim2.new(1, 0, 0, 26),
	BackgroundColor3 = rgb(200, 60, 160),
	BackgroundTransparency = 0.1,
	LayoutOrder = 1,
	Visible = false,
	Parent = status,
})
Ui.corner(8).Parent = rushLabel
local hazardLabel = label({
	Name = "Hazard",
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundColor3 = rgb(190, 70, 40),
	BackgroundTransparency = 0.1,
	LayoutOrder = 2,
	Visible = false,
	Parent = status,
})
Ui.corner(8).Parent = hazardLabel
local eggBar = create("Frame", {
	Name = "EggBar",
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = rgb(40, 30, 25),
	BackgroundTransparency = 0.1,
	LayoutOrder = 3,
	Visible = false,
	Parent = status,
}, { Ui.corner(8) })
local eggFill = create("Frame", {
	Name = "Fill",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = rgb(70, 200, 90),
	Parent = eggBar,
}, { Ui.corner(8) })
local eggText = label({
	Name = "Text",
	Size = UDim2.new(1, -10, 1, -4),
	Position = UDim2.fromOffset(5, 2),
	ZIndex = 2,
	Parent = eggBar,
})

-- the big title when you walk into a biome
local areaTitle = label({
	Name = "AreaTitle",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0.2),
	Size = UDim2.new(0.8, 0, 0, 54),
	TextTransparency = 1,
	Parent = gui,
})
local areaBlurb = label({
	Name = "AreaBlurb",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0.2, 56),
	Size = UDim2.new(0.8, 0, 0, 26),
	TextColor3 = rgb(255, 240, 200),
	TextTransparency = 1,
	Parent = gui,
})
for _, item in { areaTitle, areaBlurb, rushLabel, hazardLabel, eggText } do
	create("UISizeConstraint", { MaxSize = Vector2.new(640, 60) }).Parent = item
end

---------------------------------------------------------------------------
-- Dots
---------------------------------------------------------------------------
local pool: { Frame } = {}
local used = 0

local function dot(x: number, y: number, size: number, color: Color3, text: string?): Frame
	used += 1
	local d = pool[used]
	if not d then
		d = create("Frame", {
			Name = "Dot",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = dots,
		}, {
			create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			label({ Name = "Icon", Size = UDim2.fromScale(1, 1), ZIndex = 3 }),
		})
		pool[used] = d
	end
	d.Visible = true
	d.Position = UDim2.new(0.5, x, 0.5, y)
	d.Size = UDim2.fromOffset(size, size)
	d.BackgroundColor3 = color
	local icon = d:FindFirstChild("Icon") :: TextLabel
	icon.Text = text or ""
	return d
end

-- Where a world position goes on the radar, and whether it fits inside.
local function project(me: Vector3, look: Vector3, right: Vector3, position: Vector3, range: number)
	local offset = position - me
	local x = (offset.X * right.X + offset.Z * right.Z) / range * RADIUS
	local y = -(offset.X * look.X + offset.Z * look.Z) / range * RADIUS
	local distance = math.sqrt(x * x + y * y)
	if distance > RADIUS then
		return x / distance * RADIUS, y / distance * RADIUS, false
	end
	return x, y, true
end

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-3 then f.Unit else Vector3.new(0, 0, -1)
end

local function trackerLevel(): number
	return math.clamp(player:GetAttribute("TrackerLevel") or 1, 1, #Config.TRACKER_LEVELS)
end

local openZones: { [string]: boolean } = {}
local function refreshOpen()
	openZones = Biomes.decode(player:GetAttribute("OpenZones") or "")
end
player:GetAttributeChangedSignal("OpenZones"):Connect(refreshOpen)
refreshOpen()

local function isTracked(biome, _level: number): boolean
	return biome ~= nil and openZones[biome.id] == true
end

local function eggShown(model: Instance, level: number, info): (boolean, any, boolean)
	if not model:IsA("Model") then
		return false, nil, false
	end
	local shell = model.PrimaryPart
	if not shell or not shell.Anchored then
		return false, nil, false -- being carried
	end
	local biome = Biomes.byId[model:GetAttribute("Biome") or ""]
	local golden = model:GetAttribute("Golden") == true
	if not isTracked(biome, level) or (golden and not info.golden) then
		return false, biome, golden
	end
	return true, biome, golden
end

local function refreshDots()
	for i = 1, used do
		pool[i].Visible = false
	end
	used = 0
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end
	local camera = workspace.CurrentCamera
	local look = flat(camera.CFrame.LookVector)
	local right = Vector3.new(-look.Z, 0, look.X)
	local me = root.Position
	local level = trackerLevel()
	local info = Config.TRACKER_LEVELS[level]
	local range = info.range

	-- treasure first so eggs draw on top
	local treasure = workspace:FindFirstChild("ChaiChaosTreasure")
	if info.treasure and treasure then
		for _, chest in treasure:GetChildren() do
			if chest:IsA("Model") then
				local x, y, inside = project(me, look, right, chest:GetPivot().Position, range)
				if inside then
					dot(x, y, 10, rgb(140, 85, 40), "$")
				end
			end
		end
	end

	local eggs = workspace:FindFirstChild("ChaiChaosEggs")
	local nearest, nearestDistance = nil, math.huge
	local eggDots = 0
	if eggs then
		for _, model in eggs:GetChildren() do
			local shown, biome, golden = eggShown(model, level, info)
			if shown then
				local position = (model :: Model):GetPivot().Position
				local x, y, inside = project(me, look, right, position, range)
				if inside then
					eggDots += 1
					dot(x, y, if golden then 12 else 8, if golden then GOLD else biome.eggColor)
				else
					local distance = (position - me).Magnitude
					if distance < nearestDistance then
						nearest, nearestDistance = position, distance
					end
				end
			end
		end
	end
	if nearest and eggDots == 0 then
		-- no egg in range: a pip on the edge points to the nearest one
		local x, y = project(me, look, right, nearest, range)
		dot(x, y, 10, rgb(255, 255, 255), "•")
	end

	-- wild brainrots, in their rarity's colour
	local wild = workspace:FindFirstChild("ChaiChaosWild")
	if wild then
		for _, model in wild:GetChildren() do
			if model:IsA("Model") then
				local x, y, inside = project(me, look, right, model:GetPivot().Position, range)
				if inside then
					dot(x, y, 13, Brainrots.RARITY_COLORS[model:GetAttribute("Rarity") or ""] or GOLD, "W")
				end
			end
		end
	end

	local chowkX, chowkY = project(me, look, right, Vector3.zero, range)
	dot(chowkX, chowkY, 10, rgb(255, 215, 90), "C")
	local home = player:GetAttribute("HomePosition")
	if typeof(home) == "Vector3" then
		local x, y = project(me, look, right, home, range)
		dot(x, y, 16, HOME, "H")
	end
end

---------------------------------------------------------------------------
-- Labels
---------------------------------------------------------------------------
local shownArea: string? = nil

local function showAreaTitle(title: string, blurb: string, color: Color3)
	areaTitle.Text = title
	areaTitle.TextColor3 = color
	areaBlurb.Text = blurb
	areaTitle.TextTransparency = 0
	areaBlurb.TextTransparency = 0
	task.delay(3, function()
		if areaTitle.Text == title then
			TweenService:Create(areaTitle, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
			TweenService:Create(areaBlurb, TweenInfo.new(0.8), { TextTransparency = 1 }):Play()
		end
	end)
end

local function refreshLabels()
	local level = trackerLevel()
	local info = Config.TRACKER_LEVELS[level]
	levelLabel.Text = ("Radar Lv %d"):format(level)
	local count = 0
	for _ in openZones do
		count += 1
	end
	tracksLabel.Text = ("Tracks: %d open zone%s"):format(count, if count == 1 then "" else "s")
		.. (if info.golden then " + golden eggs" else "")
		.. (if info.treasure then " + treasure" else "")

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local position = if root and root:IsA("BasePart") then root.Position else nil
	local biome = if position then Biomes.at(position) else nil
	local sector = if position then Biomes.townSectorAt(position) else nil
	local area
	if biome then
		local tracked = isTracked(biome, level)
		area = biome.name .. (if tracked then "" else " (locked)")
		areaLabel.TextColor3 = biome.color
	elseif sector then
		area = sector.name
		areaLabel.TextColor3 = Ui.GOLD
	else
		area = "Chowk"
		areaLabel.TextColor3 = Ui.GOLD
	end
	areaLabel.Text = area
	local areaId = if biome then biome.id else area
	if areaId ~= shownArea then
		shownArea = areaId
		if biome then
			showAreaTitle(("%s · %s"):format(biome.name:upper(), biome.title), biome.blurb, biome.color)
		elseif sector then
			showAreaTitle(sector.name:upper(), "Lahore bazaar", Ui.GOLD)
		end
	end

	-- the egg you are carrying
	local eggBiome = Biomes.byId[player:GetAttribute("EggBiome") or ""]
	local total = player:GetAttribute("EggTimeTotal") or 0
	if eggBiome and total > 0 then
		local left = math.max(0, player:GetAttribute("EggTimeLeft") or 0)
		local share = math.clamp(left / total, 0, 1)
		eggBar.Visible = true
		eggFill.Size = UDim2.fromScale(share, 1)
		eggFill.BackgroundColor3 = if share > 0.5
			then rgb(70, 200, 90)
			elseif share > 0.25 then rgb(240, 190, 40)
			else rgb(220, 60, 50)
		local golden = player:GetAttribute("EggGolden") == true
		local carried = player:GetAttribute("EggCount") or 1
		eggText.Text = ("%s%s: %ds  ·  %s"):format(
			if golden then "Golden egg" else eggBiome.name .. " egg",
			if carried > 1 then (" (+%d more)"):format(carried - 1) else "",
			math.ceil(left),
			if share > 0.25 then "Take it home!" else "HURRY!"
		)
	else
		eggBar.Visible = false
	end

	local hazard = player:GetAttribute("Hazard") or ""
	hazardLabel.Visible = hazard ~= ""
	hazardLabel.Text = hazard

	local rush = Biomes.byId[workspace:GetAttribute("EggRush") or ""]
	rushLabel.Visible = rush ~= nil
	if rush then
		local left = math.max(0, (workspace:GetAttribute("EggRushEndsAt") or 0) - workspace:GetServerTimeNow())
		rushLabel.Text = ("EGG RUSH in %s! %d:%02d"):format(rush.name, left // 60, math.floor(left % 60))
	end
end

task.spawn(function()
	while gui.Parent do
		refreshLabels()
		refreshDots()
		task.wait(0.1)
	end
end)
