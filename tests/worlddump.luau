-- Builds the world with the real scripts on the mock engine and prints every
-- visible part and terrain fill, one per line, for blender/world_preview.py:
--   tests/run.sh worlddump > /tmp/world.txt
-- P class shape  x y z  sx sy sz  rx ry rz  ux uy uz  r g b  transparency material
-- T kind material  x y z  sx sy sz  radius height
local DIR = TEST_DIR .. "/"
local SRC = SRC_DIR .. "/"
local FILES = loadchunk(readfile(CACHE_DIR .. "/filelist.luau"), "filelist", {})()
local API = loadchunk(readfile(CACHE_DIR .. "/api.luau"), "api", {})()
local M = loadchunk(readfile(DIR .. "mock.luau"), "mock", setmetatable({}, { __index = _G }))(API)
math.randomseed(42)

local sources, cache = {}, {}
local requireModule
local function scriptEnv(scriptInst)
	return setmetatable({
		game = M.game,
		workspace = M.workspace,
		script = scriptInst,
		Instance = M.Instance,
		Vector3 = M.Vector3,
		CFrame = M.CFrame,
		Color3 = M.Color3,
		UDim = M.UDim,
		UDim2 = M.UDim2,
		Vector2 = M.Vector2,
		NumberRange = M.NumberRange,
		NumberSequence = M.NumberSequence,
		ColorSequence = M.ColorSequence,
		ColorSequenceKeypoint = M.ColorSequenceKeypoint,
		TweenInfo = M.TweenInfo,
		Random = M.Random,
		Enum = M.Enum,
		task = M.task,
		os = M.os,
		typeof = M.typeof,
		warn = function() end,
		print = function() end,
		require = function(module)
			return requireModule(module)
		end,
	}, { __index = _G })
end
requireModule = function(module)
	if cache[module] == nil then
		cache[module] = loadchunk(readfile(sources[module]), sources[module], scriptEnv(module))()
	end
	return cache[module]
end
local function mount(folderName, parent, dir, files)
	local folder = M.Instance.new("Folder")
	folder.Name = folderName
	for _, file in files do
		local name, kind = file:match("^(.-)%.server%.luau$"), "Script"
		if not name then
			name, kind = file:match("^(.-)%.client%.luau$"), "LocalScript"
		end
		if not name then
			name, kind = file:match("^(.-)%.luau$"), "ModuleScript"
		end
		local inst = M.Instance.new(kind)
		inst.Name = name
		inst.Parent = folder
		sources[inst] = SRC .. dir .. "/" .. file
	end
	folder.Parent = parent
	return folder
end
mount("ChaiChaos", M.services.ReplicatedStorage, "shared", FILES.shared)
local server = mount("ChaiChaosServer", M.services.ServerScriptService, "server", FILES.server)
M.rawset(M.workspace, "StreamingEnabled", true)
for _, inst in server:GetChildren() do
	if inst.ClassName == "Script" then
		M.task.spawn(loadchunk(readfile(sources[inst]), sources[inst], scriptEnv(inst)))
	end
end
M.advance(0.2)

local function f(n)
	return string.format("%.3f", n)
end
for _, fill in M.terrainFills do
	local p, s = fill.position, fill.size
	print(table.concat({
		"T",
		fill.kind,
		fill.material.Name,
		f(p.X),
		f(p.Y),
		f(p.Z),
		f(s and s.X or 0),
		f(s and s.Y or 0),
		f(s and s.Z or 0),
		f(fill.radius or 0),
		f(fill.height or 0),
	}, " "))
end
-- where to write the names: L x z size name
local Biomes = requireModule(M.services.ReplicatedStorage.ChaiChaos.Biomes)
for _, biome in Biomes.list do
	-- the rings along a region's middle line would overlap, so each ring's name is turned a little
	local turn = ({ 0, 13, -13 })[biome.ring] or 0
	local p = Biomes.polar(biome.angle + turn, (Biomes.innerRadius(biome) + Biomes.outerRadius(biome)) / 2)
	print(("L %s %s 1 %s"):format(f(p.X), f(p.Z), biome.name:upper()))
end
for _, region in Biomes.REGIONS do
	local p = Biomes.polar(region.angle + 24, Biomes.WORLD_RADIUS - 20)
	print(("L %s %s 2 %s"):format(f(p.X), f(p.Z), region.name:upper()))
end
print("L 0 0 1 CHOWK")
for _, d in M.workspace:GetDescendants() do
	if d:IsA("BasePart") and d.Transparency < 0.95 and d.Name ~= "SignText" then
		local cf, s, c = d.CFrame, d.Size, d.Color
		local shape = if d.ClassName == "Part" and d.Shape then d.Shape.Name else d.ClassName
		local r, u = cf.RightVector, cf.UpVector
		print(table.concat({
			"P",
			d.ClassName,
			shape,
			f(cf.X),
			f(cf.Y),
			f(cf.Z),
			f(s.X),
			f(s.Y),
			f(s.Z),
			f(r.X),
			f(r.Y),
			f(r.Z),
			f(u.X),
			f(u.Y),
			f(u.Z),
			f(c.R),
			f(c.G),
			f(c.B),
			f(d.Transparency),
			if d.Material then d.Material.Name else "Plastic",
		}, " "))
	end
end
