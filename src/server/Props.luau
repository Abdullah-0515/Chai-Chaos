-- Props modelled in Blender: landmarks, trees, dhabas, trucks and the rest.
-- The models live in blender/ and are turned into PropData.luau.
--
-- Every prop can be built from plain Roblox parts, so the game works with no
-- imports at all. If you import the Blender meshes (assets/props/ChaiChaosProps.fbx)
-- into ServerStorage > ChaiChaosProps (see the README), each prop uses its
-- smoother mesh instead. The parts it would have used become invisible walls,
-- so you can still walk on bridges, jetties and decks.

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)

local PropData = require(script.Parent.PropData)

local Props = {}

local NOCOLLIDE, KEEP, GLASS, LIGHT, NOSHADOW, EYE, PAINT = 1, 2, 4, 8, 16, 64, 128
local SHAPES = { B = Enum.PartType.Block, C = Enum.PartType.Cylinder, L = Enum.PartType.Ball }
local MESH_FOLDER = "ChaiChaosProps"

local palette: { Color3 } = {}
for i, rgb in PropData.palette do
	palette[i] = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end
local materials: { Enum.Material } = {}
for i, name in PropData.materials do
	materials[i] = (Enum.Material :: any)[name]
end

local function v3(t: { number }, scale: number?): Vector3
	local s = scale or 1
	return Vector3.new(t[1] * s, t[2] * s, t[3] * s)
end

local function hasFlag(flags: number, flag: number): boolean
	return flags // flag % 2 == 1
end

---------------------------------------------------------------------------
-- Imported meshes
---------------------------------------------------------------------------
local meshes: { [string]: BasePart } = {}
local meshesLoaded = false

-- Looks for imported meshes again (for example after you add the folder).
function Props.reload()
	table.clear(meshes)
	meshesLoaded = true
	local folder = ServerStorage:FindFirstChild(MESH_FOLDER)
	if not folder then
		return
	end
	for name in PropData.props do
		local found = folder:FindFirstChild(name, true)
		if found and found:IsA("Model") then
			found = found:FindFirstChildWhichIsA("MeshPart", true)
		end
		if found and found:IsA("BasePart") then
			meshes[name] = found
		end
	end
end

function Props.meshFor(name: string): BasePart?
	if not meshesLoaded then
		Props.reload()
	end
	return meshes[name]
end

-- The 3D importer can bring a mesh in lying on its side (Z up instead of Y up).
-- Compares the imported size with the size the mesh should have and returns
-- the size to give it in its own axes and the turn that stands it up again.
local FIXES = {
	{ order = { 1, 2, 3 }, turn = CFrame.new() },
	{ order = { 1, 3, 2 }, turn = CFrame.Angles(math.rad(-90), 0, 0) }, -- height along its Z
	{ order = { 2, 1, 3 }, turn = CFrame.Angles(0, 0, math.rad(90)) }, -- height along its X
	{ order = { 3, 2, 1 }, turn = CFrame.Angles(0, math.rad(90), 0) }, -- turned sideways
}

local function shapeError(a: Vector3, b: Vector3): number
	local function logs(v: Vector3)
		local m = math.max(v.X, v.Y, v.Z, 1e-3)
		return math.log(math.max(v.X, 1e-3) / m), math.log(math.max(v.Y, 1e-3) / m), math.log(math.max(v.Z, 1e-3) / m)
	end
	local ax, ay, az = logs(a)
	local bx, by, bz = logs(b)
	return math.abs(ax - bx) + math.abs(ay - by) + math.abs(az - bz)
end

function Props.meshFit(imported: Vector3, expected: Vector3): (Vector3, CFrame)
	local e = { expected.X, expected.Y, expected.Z }
	local best, bestError = FIXES[1], math.huge
	for i, fix in FIXES do
		local candidate = Vector3.new(e[fix.order[1]], e[fix.order[2]], e[fix.order[3]])
		-- the importer's own guess wins unless another fits clearly better
		local err = shapeError(imported, candidate) + (if i == 1 then 0 else 0.15)
		if err < bestError then
			best, bestError = fix, err
		end
	end
	return Vector3.new(e[best.order[1]], e[best.order[2]], e[best.order[3]]), best.turn
end

---------------------------------------------------------------------------
-- Building
---------------------------------------------------------------------------
function Props.exists(name: string): boolean
	return PropData.props[name] ~= nil
end

-- The prop's size (width, height, depth) at a scale.
function Props.size(name: string, scale: number?): Vector3
	return v3(PropData.props[name].size, scale)
end

-- Where a named point of the prop ends up when it is placed at `cf`.
function Props.anchor(name: string, anchorName: string, cf: CFrame, scale: number?): Vector3
	local spec = PropData.props[name]
	local point = spec and spec.anchors and spec.anchors[anchorName]
	assert(point, ("[ChaiChaos] prop %s has no anchor %s"):format(name, anchorName))
	return cf * v3(point, scale)
end

local function newPart(entry, cf: CFrame, scale: number, visible: boolean): Part
	local flags = entry[14]
	local p = Instance.new("Part")
	p.Shape = SHAPES[entry[1]]
	p.Size = Vector3.new(entry[5] * scale, entry[6] * scale, entry[7] * scale)
	p.CFrame = cf
		* CFrame.new(entry[2] * scale, entry[3] * scale, entry[4] * scale, entry[8], entry[9], entry[10], entry[11])
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = not hasFlag(flags, NOCOLLIDE)
	if visible then
		if hasFlag(flags, EYE) then
			p.Name = "Eye" -- eyes keep their colour on Golden, Diamond and Rainbow brainrots
		elseif hasFlag(flags, PAINT) then
			p.Name = "Paint" -- a vehicle's panels: paint jobs recolour these
		end
		p.Color = palette[entry[12]]
		p.Material = materials[entry[13]]
		p.CastShadow = not hasFlag(flags, NOSHADOW)
		if hasFlag(flags, GLASS) then
			p.Transparency = 0.5
		end
		if hasFlag(flags, LIGHT) then
			local light = Instance.new("PointLight")
			light.Color = p.Color
			light.Range = 16
			light.Brightness = 1.6
			light.Parent = p
		end
	else
		-- an invisible wall where the mesh is
		p.Transparency = 1
		p.CastShadow = false
		p.Name = "Collider"
	end
	return p
end

export type PlaceOptions = {
	parts: boolean?, -- always build from parts, even if a mesh was imported
	noColliders: boolean?, -- with a mesh, leave out the invisible walls
}

-- Builds a prop standing at `cf` (its ground point; it faces cf's front).
-- Pass nil as the parent to get the model without putting it anywhere yet.
function Props.place(name: string, cf: CFrame, parent: Instance?, scale: number?, options: PlaceOptions?): Model
	local spec = PropData.props[name]
	assert(spec, "[ChaiChaos] unknown prop " .. name)
	local s = scale or 1
	local model = Instance.new("Model")
	model.Name = name
	local mesh = spec.mesh and not (options and options.parts) and Props.meshFor(name)
	local colliders = not (options and options.noColliders)
	for _, entry in spec.parts do
		local flags = entry[14]
		local keep = hasFlag(flags, KEEP)
		if not mesh or keep then
			newPart(entry, cf, s, true).Parent = model
		elseif colliders and not hasFlag(flags, NOCOLLIDE) then
			newPart(entry, cf, s, false).Parent = model
		end
	end
	if mesh then
		local copy = mesh:Clone()
		local size, turn = Props.meshFit(mesh.Size, v3(spec.mesh.size, s))
		copy.Name = name
		copy.Anchored = true
		copy.CanCollide = false
		copy.Size = size
		copy.CFrame = cf
			* CFrame.Angles(0, math.rad(Config.PROP_MESH_TURN), 0)
			* CFrame.new(v3(spec.mesh.center, s))
			* turn
		copy.Parent = model
	end
	model.WorldPivot = cf
	model.Parent = parent
	return model
end

-- Writes text on a prop's sign: an invisible board at `position` (a sign
-- anchor), facing the same way as the prop placed at `cf`.
function Props.text(
	parent: Instance,
	cf: CFrame,
	position: Vector3,
	width: number,
	height: number,
	text: string,
	color: Color3?
): Part
	local board = Instance.new("Part")
	board.Name = "SignText"
	board.Anchored = true
	board.CanCollide = false
	board.CanQuery = false
	board.CanTouch = false
	board.CastShadow = false
	board.Transparency = 1
	board.Size = Vector3.new(width, height, 0.05)
	board.CFrame = cf.Rotation + position + cf.LookVector * 0.06
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Gui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.4
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(30, 20, 15)
	stroke.Parent = label
	label.Parent = gui
	gui.Parent = board
	board.Parent = parent
	return board
end

return Props
