-- A small mock of the Roblox engine, good enough to run Chai Chaos headless.
-- Every property, method, event, class and enum the game touches is checked
-- against the real Roblox API dump (api.luau), so typos fail loudly.

local API = ...

local M = {}
M.errors = {}
M.warnings = {}
M.log = {}

---------------------------------------------------------------------------
-- Scheduler with a virtual clock
---------------------------------------------------------------------------
local clock = 0
local queue = {}

local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		local msg = debug.traceback(co, tostring(err))
		table.insert(M.errors, msg)
		print("SCRIPT ERROR: " .. msg)
	end
end

local task = {}
function task.spawn(f, ...)
	local co = if type(f) == "thread" then f else coroutine.create(f)
	resume(co, ...)
	return co
end
function task.defer(f, ...)
	local co = if type(f) == "thread" then f else coroutine.create(f)
	table.insert(queue, { t = clock, co = co, args = table.pack(...) })
	return co
end
function task.delay(d, f, ...)
	local co = if type(f) == "thread" then f else coroutine.create(f)
	table.insert(queue, { t = clock + (d or 0), co = co, args = table.pack(...) })
	return co
end
function task.wait(d)
	d = d or 0
	local co = coroutine.running()
	table.insert(queue, { t = clock + d, co = co, start = clock })
	return coroutine.yield()
end
function task.cancel() end
M.task = task

local function runDue()
	local ready, rest = {}, {}
	for _, item in queue do
		if item.t <= clock + 1e-9 then
			table.insert(ready, item)
		else
			table.insert(rest, item)
		end
	end
	queue = rest
	table.sort(ready, function(a, b)
		return a.t < b.t
	end)
	for _, item in ready do
		if coroutine.status(item.co) == "suspended" then
			if item.args then
				resume(item.co, table.unpack(item.args, 1, item.args.n))
			else
				resume(item.co, clock - item.start)
			end
		end
	end
end

M.os = {
	clock = function()
		return clock
	end,
	time = function()
		return 1_790_000_000 + math.floor(clock)
	end,
	date = os.date,
}

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------
local SignalMT = {}
SignalMT.__index = SignalMT
local function Signal()
	return setmetatable({ _conns = {}, _waiters = {} }, SignalMT)
end
function SignalMT:Connect(fn)
	assert(type(fn) == "function", "Connect expects a function")
	local c = { Connected = true }
	function c:Disconnect()
		c.Connected = false
	end
	table.insert(self._conns, { c = c, fn = fn })
	return c
end
function SignalMT:Once(fn)
	local c
	c = self:Connect(function(...)
		c:Disconnect()
		fn(...)
	end)
	return c
end
function SignalMT:Wait()
	table.insert(self._waiters, coroutine.running())
	return coroutine.yield()
end
function SignalMT:Fire(...)
	for _, entry in table.clone(self._conns) do
		if entry.c.Connected then
			task.spawn(entry.fn, ...)
		end
	end
	local waiters = self._waiters
	self._waiters = {}
	for _, co in waiters do
		task.spawn(co, ...)
	end
end
function SignalMT:DisconnectAll()
	for _, entry in self._conns do
		entry.c.Connected = false
	end
end
M.Signal = Signal

---------------------------------------------------------------------------
-- Data types
---------------------------------------------------------------------------
local V3MT = {}
local function v3(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3MT)
end
local function isV3(v)
	return getmetatable(v) == V3MT
end
V3MT.__index = function(v, k)
	if k == "Magnitude" then
		return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
	elseif k == "Unit" then
		local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		return v3(v.X / m, v.Y / m, v.Z / m)
	elseif k == "Lerp" then
		return function(a, b, t)
			return a + (b - a) * t
		end
	elseif k == "Dot" then
		return function(a, b)
			return a.X * b.X + a.Y * b.Y + a.Z * b.Z
		end
	elseif k == "Cross" then
		return function(a, b)
			return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
		end
	end
	error("Vector3 has no member " .. tostring(k), 2)
end
V3MT.__add = function(a, b)
	assert(isV3(a) and isV3(b), "Vector3 + needs two Vector3s")
	return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3MT.__sub = function(a, b)
	assert(isV3(a) and isV3(b), "Vector3 - needs two Vector3s")
	return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3MT.__mul = function(a, b)
	if type(a) == "number" then
		return v3(b.X * a, b.Y * a, b.Z * a)
	elseif type(b) == "number" then
		return v3(a.X * b, a.Y * b, a.Z * b)
	end
	assert(isV3(a) and isV3(b), "bad Vector3 multiply")
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3MT.__div = function(a, b)
	assert(type(b) == "number", "Vector3 / needs a number")
	return v3(a.X / b, a.Y / b, a.Z / b)
end
V3MT.__unm = function(a)
	return v3(-a.X, -a.Y, -a.Z)
end
V3MT.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
V3MT.__tostring = function(v)
	return ("%.2f, %.2f, %.2f"):format(v.X, v.Y, v.Z)
end
local Vector3 = {
	new = function(x, y, z)
		return v3(x, y, z)
	end,
	zero = v3(0, 0, 0),
	one = v3(1, 1, 1),
	xAxis = v3(1, 0, 0),
	yAxis = v3(0, 1, 0),
	zAxis = v3(0, 0, 1),
}
M.Vector3 = Vector3

-- CFrame: rotation matrix r (row-major 3x3) and position p
local CFMT = {}
local function cfr(p, r)
	return setmetatable({ _p = p, _r = r }, CFMT)
end
local function isCF(v)
	return getmetatable(v) == CFMT
end
local IDENTITY = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local function matmul(a, b)
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			local s = 0
			for k = 0, 2 do
				s += a[i * 3 + k + 1] * b[k * 3 + j + 1]
			end
			r[i * 3 + j + 1] = s
		end
	end
	return r
end
local function rotate(r, v)
	return v3(
		r[1] * v.X + r[2] * v.Y + r[3] * v.Z,
		r[4] * v.X + r[5] * v.Y + r[6] * v.Z,
		r[7] * v.X + r[8] * v.Y + r[9] * v.Z
	)
end
local function transpose(r)
	return { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
end
local CFMethods = {}
-- exact 3x3 inverse so repeated PivotTo calls cannot drift
local function invert(r)
	local a, b, c, d, e, f, g, h, i = r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9]
	local A, B, C = e * i - f * h, -(d * i - f * g), d * h - e * g
	local det = a * A + b * B + c * C
	assert(math.abs(det) > 1e-9, "degenerate CFrame")
	return {
		A / det,
		-(b * i - c * h) / det,
		(b * f - c * e) / det,
		B / det,
		(a * i - c * g) / det,
		-(a * f - c * d) / det,
		C / det,
		-(a * h - b * g) / det,
		(a * e - b * d) / det,
	}
end
function CFMethods.Inverse(c)
	local ri = invert(c._r)
	return cfr(-rotate(ri, c._p), ri)
end
function CFMethods.PointToObjectSpace(c, v)
	return rotate(invert(c._r), v - c._p)
end
function CFMethods.PointToWorldSpace(c, v)
	return rotate(c._r, v) + c._p
end
function CFMethods.ToObjectSpace(c, o)
	return CFMethods.Inverse(c) * o
end
function CFMethods.ToWorldSpace(c, o)
	return c * o
end
function CFMethods.Lerp(a, b, t)
	return cfr(a._p:Lerp(b._p, t), if t < 0.5 then a._r else b._r)
end
CFMT.__index = function(c, k)
	local r = c._r
	if k == "Position" or k == "p" then
		return c._p
	elseif k == "X" then
		return c._p.X
	elseif k == "Y" then
		return c._p.Y
	elseif k == "Z" then
		return c._p.Z
	elseif k == "Rotation" then
		return cfr(v3(), r)
	elseif k == "LookVector" then
		return v3(-r[3], -r[6], -r[9])
	elseif k == "RightVector" then
		return v3(r[1], r[4], r[7])
	elseif k == "UpVector" then
		return v3(r[2], r[5], r[8])
	elseif CFMethods[k] then
		return CFMethods[k]
	end
	error("CFrame has no member " .. tostring(k), 2)
end
CFMT.__mul = function(a, b)
	assert(isCF(a), "CFrame * needs a CFrame on the left")
	if isCF(b) then
		return cfr(rotate(a._r, b._p) + a._p, matmul(a._r, b._r))
	elseif isV3(b) then
		return rotate(a._r, b) + a._p
	end
	error("bad CFrame multiply", 2)
end
CFMT.__add = function(a, b)
	assert(isCF(a) and isV3(b), "CFrame + needs a Vector3")
	return cfr(a._p + b, a._r)
end
CFMT.__sub = function(a, b)
	assert(isCF(a) and isV3(b), "CFrame - needs a Vector3")
	return cfr(a._p - b, a._r)
end
CFMT.__tostring = function(c)
	return "CFrame(" .. tostring(c._p) .. ")"
end
local function rx(a)
	local c, s = math.cos(a), math.sin(a)
	return { 1, 0, 0, 0, c, -s, 0, s, c }
end
local function ry(a)
	local c, s = math.cos(a), math.sin(a)
	return { c, 0, s, 0, 1, 0, -s, 0, c }
end
local function rz(a)
	local c, s = math.cos(a), math.sin(a)
	return { c, -s, 0, s, c, 0, 0, 0, 1 }
end
local CFrame = {}
function CFrame.new(x, y, z, ...)
	assert(select("#", ...) == 0, "mock CFrame.new only supports positions")
	if x == nil then
		return cfr(v3(), IDENTITY)
	elseif isV3(x) then
		return cfr(x, IDENTITY)
	end
	return cfr(v3(x, y, z), IDENTITY)
end
function CFrame.Angles(a, b, c)
	return cfr(v3(), matmul(matmul(rx(a), ry(b)), rz(c)))
end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
function CFrame.lookAt(at, target, up)
	up = up or Vector3.yAxis
	local look = (target - at).Unit
	local right = look:Cross(up)
	if right.Magnitude < 1e-6 then
		right = Vector3.xAxis
	end
	right = right.Unit
	local upv = right:Cross(look)
	local back = -look
	return cfr(at, { right.X, upv.X, back.X, right.Y, upv.Y, back.Y, right.Z, upv.Z, back.Z })
end
CFrame.identity = CFrame.new()
M.CFrame = CFrame

local C3MT = {}
C3MT.__index = function(c, k)
	if k == "Lerp" then
		return function(a, b, t)
			return setmetatable(
				{ R = a.R + (b.R - a.R) * t, G = a.G + (b.G - a.G) * t, B = a.B + (b.B - a.B) * t },
				C3MT
			)
		end
	end
	error("Color3 has no member " .. tostring(k), 2)
end
C3MT.__eq = function(a, b)
	return a.R == b.R and a.G == b.G and a.B == b.B
end
local Color3 = {
	new = function(r, g, b)
		return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3MT)
	end,
	fromRGB = function(r, g, b)
		return setmetatable({ R = r / 255, G = g / 255, B = b / 255 }, C3MT)
	end,
	fromHSV = function(h, s, v)
		assert(h >= 0 and h <= 1 and s >= 0 and s <= 1 and v >= 0 and v <= 1, "fromHSV values must be 0-1")
		return setmetatable({ R = v, G = v * (1 - s), B = v * (1 - s * h) }, C3MT)
	end,
}
M.Color3 = Color3

local function opaque(kind)
	return {
		new = function(...)
			return { __kind = kind, args = table.pack(...) }
		end,
	}
end
local UDim = {
	new = function(s, o)
		return { Scale = s or 0, Offset = o or 0 }
	end,
}
local UDim2 = {
	new = function(xs, xo, ys, yo)
		return { X = UDim.new(xs, xo), Y = UDim.new(ys, yo) }
	end,
	fromScale = function(x, y)
		return { X = UDim.new(x, 0), Y = UDim.new(y, 0) }
	end,
	fromOffset = function(x, y)
		return { X = UDim.new(0, x), Y = UDim.new(0, y) }
	end,
}
M.UDim, M.UDim2 = UDim, UDim2
M.Vector2 = {
	new = function(x, y)
		return { X = x or 0, Y = y or 0 }
	end,
}
-- Random: a small deterministic generator (not Roblox's, but seeded the same way)
local RandomMT = {}
RandomMT.__index = {
	NextNumber = function(self, lo, hi)
		self.state = (self.state * 1103515245 + 12345) % 2147483648
		local t = self.state / 2147483648
		lo, hi = lo or 0, hi or 1
		return lo + (hi - lo) * t
	end,
	NextInteger = function(self, lo, hi)
		assert(type(lo) == "number" and type(hi) == "number" and lo <= hi, "NextInteger(min, max)")
		self.state = (self.state * 1103515245 + 12345) % 2147483648
		return lo + self.state % (hi - lo + 1)
	end,
}
M.Random = {
	new = function(seed)
		return setmetatable({ state = math.floor(seed or os.clock() * 1000) % 2147483648 }, RandomMT)
	end,
}
M.NumberRange = opaque("NumberRange")
M.NumberSequence = opaque("NumberSequence")
M.ColorSequence = opaque("ColorSequence")
M.ColorSequenceKeypoint = opaque("ColorSequenceKeypoint")
M.TweenInfo = opaque("TweenInfo")

local enumCache = {}
M.Enum = setmetatable({}, {
	__index = function(_, enumName)
		local items = API.enums[enumName]
		assert(items, "Unknown enum Enum." .. tostring(enumName))
		if not enumCache[enumName] then
			enumCache[enumName] = setmetatable({}, {
				__index = function(t, itemName)
					assert(items[itemName], ("Enum.%s has no item %s"):format(enumName, tostring(itemName)))
					local token = { EnumType = enumName, Name = itemName, Value = items[itemName] }
					rawset(t, itemName, token)
					return token
				end,
			})
		end
		return enumCache[enumName]
	end,
})

---------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------
local data = {}
local InstanceMT = {}

local function isInstance(v)
	return type(v) == "table" and getmetatable(v) == InstanceMT
end
M.isInstance = isInstance

local function classChain(className)
	local chain = {}
	local name = className
	while name and API.classes[name] do
		table.insert(chain, name)
		name = API.classes[name].super
	end
	return chain
end
local function hasMember(className, kind, member)
	for _, name in classChain(className) do
		if API.classes[name][kind][member] then
			return true
		end
	end
	return false
end
local function isA(className, target)
	return table.find(classChain(className), target) ~= nil
end

local DEFAULTS = {
	BasePart = function()
		return {
			Size = v3(4, 1, 2),
			Anchored = false,
			CanCollide = true,
			CanTouch = true,
			Transparency = 0,
			Color = Color3.new(0.64, 0.64, 0.64),
		}
	end,
	Humanoid = function()
		return { Health = 100, MaxHealth = 100, WalkSpeed = 16, HipHeight = 2 }
	end,
	Lighting = function()
		return { ClockTime = 14 }
	end,
	ProximityPrompt = function()
		return { Enabled = true, HoldDuration = 0, MaxActivationDistance = 10, ActionText = "Interact", ObjectText = "" }
	end,
	GuiObject = function()
		return { Visible = true, LayoutOrder = 0 }
	end,
	IntValue = function()
		return { Value = 0 }
	end,
	StringValue = function()
		return { Value = "" }
	end,
	UIScale = function()
		return { Scale = 1 }
	end,
	Sound = function()
		return { IsPlaying = false, Volume = 0.5, PlaybackSpeed = 1, Looped = false, TimePosition = 0, SoundId = "" }
	end,
}

local function newInstance(className, internal)
	local info = API.classes[className]
	assert(info, "Unknown class " .. tostring(className))
	if not internal then
		assert(info.creatable and not info.service, "Instance.new cannot create " .. className)
	end
	local self = setmetatable({}, InstanceMT)
	local props = { Name = className }
	for _, name in classChain(className) do
		local defaults = DEFAULTS[name]
		if defaults then
			for k, v in defaults() do
				if props[k] == nil then
					props[k] = v
				end
			end
		end
	end
	if isA(className, "BasePart") then
		props.CFrame = CFrame.new()
	end
	data[self] = {
		ClassName = className,
		props = props,
		attrs = {},
		children = {},
		signals = {},
		attrSignals = {},
		parent = nil,
		destroyed = false,
	}
	return self
end
M.newInstance = newInstance

local function signalOf(inst, name)
	local d = data[inst]
	d.signals[name] = d.signals[name] or Signal()
	return d.signals[name]
end
M.signalOf = signalOf

local function descendants(inst, out)
	out = out or {}
	for _, child in data[inst].children do
		table.insert(out, child)
		descendants(child, out)
	end
	return out
end

local function setParent(inst, parent)
	local d = data[inst]
	if d.destroyed then
		error(("The Parent property of %s is locked"):format(d.props.Name), 3)
	end
	if parent ~= nil then
		assert(isInstance(parent), "Parent must be an Instance")
		local node = parent
		while node do
			assert(node ~= inst, "Attempt to set parent to a descendant")
			node = data[node].parent
		end
	end
	if d.parent == parent then
		return
	end
	if d.parent then
		local siblings = data[d.parent].children
		local i = table.find(siblings, inst)
		if i then
			table.remove(siblings, i)
		end
	end
	d.parent = parent
	if parent then
		table.insert(data[parent].children, inst)
		local pd = data[parent]
		if pd.signals.ChildAdded then
			pd.signals.ChildAdded:Fire(inst)
		end
		local subtree = { inst }
		for _, x in descendants(inst) do
			table.insert(subtree, x)
		end
		local node = parent
		while node do
			local sig = data[node].signals.DescendantAdded
			if sig then
				for _, x in subtree do
					sig:Fire(x)
				end
			end
			node = data[node].parent
		end
	end
end

local function fullName(inst)
	local parts = {}
	local node = inst
	while node and data[node].ClassName ~= "DataModel" do
		table.insert(parts, 1, data[node].props.Name)
		node = data[node].parent
	end
	return table.concat(parts, ".")
end

local Methods = {}

function Methods.FindFirstChild(self, name, recursive)
	local list = if recursive then descendants(self) else data[self].children
	for _, child in list do
		if data[child].props.Name == name then
			return child
		end
	end
	return nil
end
function Methods.FindFirstChildOfClass(self, className)
	for _, child in data[self].children do
		if data[child].ClassName == className then
			return child
		end
	end
	return nil
end
function Methods.FindFirstChildWhichIsA(self, className, recursive)
	local list = if recursive then descendants(self) else data[self].children
	for _, child in list do
		if isA(data[child].ClassName, className) then
			return child
		end
	end
	return nil
end
function Methods.FindFirstAncestorOfClass(self, className)
	local node = data[self].parent
	while node do
		if data[node].ClassName == className then
			return node
		end
		node = data[node].parent
	end
	return nil
end
function Methods.WaitForChild(self, name, timeout)
	local waited = 0
	while true do
		local child = Methods.FindFirstChild(self, name)
		if child then
			return child
		end
		if timeout and waited >= timeout then
			return nil
		end
		if waited >= 10 then
			error(("Infinite yield on %s:WaitForChild(%q)"):format(fullName(self), name), 2)
		end
		waited += task.wait(0.05)
	end
end
function Methods.GetChildren(self)
	return table.clone(data[self].children)
end
function Methods.GetDescendants(self)
	return descendants(self)
end
function Methods.IsA(self, className)
	return isA(data[self].ClassName, className)
end
function Methods.IsDescendantOf(self, other)
	local node = data[self].parent
	while node do
		if node == other then
			return true
		end
		node = data[node].parent
	end
	return false
end
function Methods.GetFullName(self)
	return fullName(self)
end
function Methods.Destroy(self)
	local d = data[self]
	if d.destroyed then
		return
	end
	for _, child in table.clone(d.children) do
		Methods.Destroy(child)
	end
	setParent(self, nil)
	d.destroyed = true
	for tag, set in M.tags or {} do
		if set[self] then
			Methods.RemoveTag(self, tag)
		end
	end
	for _, sig in d.signals do
		sig:DisconnectAll()
	end
	for _, sig in d.attrSignals do
		sig:DisconnectAll()
	end
end
function Methods.ClearAllChildren(self)
	for _, child in table.clone(data[self].children) do
		Methods.Destroy(child)
	end
end
function Methods.Clone(self)
	local map = {}
	local function copy(inst)
		local d = data[inst]
		local new = newInstance(d.ClassName, true)
		local nd = data[new]
		for k, v in d.props do
			nd.props[k] = v
		end
		for k, v in d.attrs do
			nd.attrs[k] = v
		end
		map[inst] = new
		for _, child in d.children do
			setParent(copy(child), new)
		end
		return new
	end
	local root = copy(self)
	for _, new in map do
		local props = data[new].props
		for k, v in props do
			if isInstance(v) and map[v] then
				props[k] = map[v]
			end
		end
	end
	return root
end
local ATTRIBUTE_TYPES = { boolean = true, number = true, string = true }
function Methods.SetAttribute(self, name, value)
	assert(type(name) == "string", "attribute name must be a string")
	local ok = value == nil
		or ATTRIBUTE_TYPES[type(value)]
		or getmetatable(value) == V3MT
		or getmetatable(value) == C3MT
		or getmetatable(value) == CFMT
	assert(ok, ("SetAttribute(%q): %s is not a supported attribute type"):format(name, type(value)))
	local d = data[self]
	if d.attrs[name] == value then
		return
	end
	d.attrs[name] = value
	if d.signals.AttributeChanged then
		d.signals.AttributeChanged:Fire(name)
	end
	if d.attrSignals[name] then
		d.attrSignals[name]:Fire()
	end
end
function Methods.GetAttribute(self, name)
	return data[self].attrs[name]
end
function Methods.GetAttributes(self)
	return table.clone(data[self].attrs)
end
function Methods.GetAttributeChangedSignal(self, name)
	local d = data[self]
	d.attrSignals[name] = d.attrSignals[name] or Signal()
	return d.attrSignals[name]
end

-- PVInstance / Model
local function pivotOf(self)
	local d = data[self]
	if isA(d.ClassName, "BasePart") then
		return d.props.CFrame
	end
	local primary = d.props.PrimaryPart
	if primary and data[primary].parent then
		return data[primary].props.CFrame
	end
	return d.props.WorldPivot or CFrame.new()
end
function Methods.GetPivot(self)
	return pivotOf(self)
end
function Methods.PivotTo(self, target)
	assert(isCF(target), "PivotTo needs a CFrame")
	local d = data[self]
	if isA(d.ClassName, "BasePart") then
		d.props.CFrame = target
		return
	end
	local delta = target * pivotOf(self):Inverse()
	for _, x in descendants(self) do
		local xd = data[x]
		if isA(xd.ClassName, "BasePart") then
			xd.props.CFrame = delta * xd.props.CFrame
		end
	end
	if not d.props.PrimaryPart then
		d.props.WorldPivot = target
	end
end
function Methods.GetBoundingBox(self)
	local minV, maxV
	for _, x in descendants(self) do
		local xd = data[x]
		if isA(xd.ClassName, "BasePart") then
			local cf, s = xd.props.CFrame, xd.props.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local p = cf * v3(s.X * sx, s.Y * sy, s.Z * sz)
						if not minV then
							minV, maxV = p, p
						else
							minV = v3(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
							maxV = v3(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
						end
					end
				end
			end
		end
	end
	assert(minV, "GetBoundingBox on a model with no parts")
	return CFrame.new((minV + maxV) / 2), maxV - minV
end
function Methods.GetExtentsSize(self)
	local _, size = Methods.GetBoundingBox(self)
	return size
end

M.Methods = Methods

InstanceMT.__index = function(self, key)
	local d = data[self]
	if key == "Parent" then
		return d.parent
	elseif key == "ClassName" then
		return d.ClassName
	end
	local method = Methods[key]
	if method and hasMember(d.ClassName, "funcs", key) then
		return method
	end
	if hasMember(d.ClassName, "events", key) then
		return signalOf(self, key)
	end
	if hasMember(d.ClassName, "callbacks", key) then
		return d.props[key]
	end
	if hasMember(d.ClassName, "props", key) then
		if key == "Position" and isA(d.ClassName, "BasePart") then
			return d.props.CFrame.Position
		end
		return d.props[key]
	end
	local child = Methods.FindFirstChild(self, key)
	if child then
		return child
	end
	if hasMember(d.ClassName, "funcs", key) then
		error(("mock: %s:%s is not implemented"):format(d.ClassName, key), 2)
	end
	error(("%s is not a valid member of %s %q"):format(tostring(key), d.ClassName, tostring(d.props.Name)), 2)
end

InstanceMT.__newindex = function(self, key, value)
	local d = data[self]
	if key == "Parent" then
		setParent(self, value)
		return
	end
	if hasMember(d.ClassName, "callbacks", key) then
		assert(type(value) == "function" or value == nil, key .. " must be a function")
		d.props[key] = value
		return
	end
	if not hasMember(d.ClassName, "props", key) then
		error(("%s is not a valid property of %s"):format(tostring(key), d.ClassName), 2)
	end
	for _, name in classChain(d.ClassName) do
		if API.classes[name].ro[key] then
			error(("%s.%s is read-only"):format(d.ClassName, key), 2)
		end
	end
	if key == "Position" and isA(d.ClassName, "BasePart") then
		assert(isV3(value), "Position must be a Vector3")
		d.props.CFrame = cfr(value, d.props.CFrame._r)
		return
	end
	if key == "CFrame" then
		assert(isCF(value), "CFrame must be a CFrame")
	end
	if key == "Size" and isA(d.ClassName, "BasePart") then
		assert(isV3(value), "Size must be a Vector3")
	elseif key == "Size" and isA(d.ClassName, "GuiObject") then
		assert(type(value) == "table" and value.X and value.X.Scale, "Size must be a UDim2")
	end
	if key == "PrimaryPart" and value ~= nil then
		assert(Methods.IsDescendantOf(value, self), "PrimaryPart must be a descendant of the model")
	end
	d.props[key] = value
	if key == "Value" and isA(d.ClassName, "ValueBase") and d.signals.Changed then
		d.signals.Changed:Fire(value)
	end
end

InstanceMT.__tostring = function(self)
	return data[self].props.Name
end

-- Internal access for the harness (bypasses read-only checks)
function M.rawset(inst, key, value)
	data[inst].props[key] = value
end
function M.rawget(inst, key)
	return data[inst].props[key]
end

M.Instance = {
	new = function(className, parent)
		local inst = newInstance(className)
		if parent then
			inst.Parent = parent
		end
		return inst
	end,
}

---------------------------------------------------------------------------
-- The DataModel and services
---------------------------------------------------------------------------
local game = newInstance("DataModel", true)
M.rawset(game, "Name", "Game")
local services = {}
local function service(name)
	if not services[name] then
		local s = newInstance(name, true)
		M.rawset(s, "Name", name)
		data[s].parent = game
		table.insert(data[game].children, s)
		services[name] = s
	end
	return services[name]
end
for _, name in
	{
		"Workspace",
		"Players",
		"ReplicatedStorage",
		"ServerStorage",
		"ServerScriptService",
		"StarterPlayer",
		"StarterPack",
		"Lighting",
		"RunService",
		"DataStoreService",
		"ProximityPromptService",
		"TweenService",
		"Debris",
		"PolicyService",
		"MarketplaceService",
		"PhysicsService",
		"HttpService",
		"CollectionService",
		"SoundService",
	}
do
	service(name)
end
local spsFolder = newInstance("StarterPlayerScripts", true)
M.rawset(spsFolder, "Name", "StarterPlayerScripts")
spsFolder.Parent = services.StarterPlayer

local camera = newInstance("Camera", true)
M.rawset(camera, "Name", "Camera")
M.rawset(camera, "CFrame", CFrame.new(0, 20, 0))
data[camera].parent = services.Workspace
table.insert(data[services.Workspace].children, camera)
M.rawset(services.Workspace, "CurrentCamera", camera)

-- Terrain: fills are recorded, not voxelised
local terrain = newInstance("Terrain", true)
M.rawset(terrain, "Name", "Terrain")
data[terrain].parent = services.Workspace
table.insert(data[services.Workspace].children, terrain)
M.rawset(services.Workspace, "Terrain", terrain)
M.terrainFills = {}
local function material(m)
	assert(type(m) == "table" and m.EnumType == "Material", "terrain fill needs an Enum.Material")
	return m
end
function Methods.FillBall(_, center, radius, mat)
	assert(isV3(center) and type(radius) == "number" and radius > 0, "FillBall(center, radius, material)")
	table.insert(M.terrainFills, { kind = "Ball", position = center, radius = radius, material = material(mat) })
end
function Methods.FillBlock(_, cf, size, mat)
	assert(isCF(cf) and isV3(size), "FillBlock(cframe, size, material)")
	table.insert(M.terrainFills, { kind = "Block", position = cf.Position, size = size, material = material(mat) })
end
function Methods.FillCylinder(_, cf, height, radius, mat)
	assert(
		isCF(cf) and type(height) == "number" and type(radius) == "number",
		"FillCylinder(cframe, height, radius, material)"
	)
	table.insert(
		M.terrainFills,
		{ kind = "Cylinder", position = cf.Position, radius = radius, material = material(mat) }
	)
end
function Methods.FillWedge(_, cf, size, mat)
	assert(isCF(cf) and isV3(size), "FillWedge(cframe, size, material)")
	table.insert(M.terrainFills, { kind = "Wedge", position = cf.Position, size = size, material = material(mat) })
end

M.game = game
M.workspace = services.Workspace
M.services = services
M.context = "server"
M.studio = true

function Methods.GetService(_, name)
	return service(name)
end
function Methods.BindToClose(_, fn)
	M.bindToClose = fn
end
function Methods.IsServer()
	return M.context == "server"
end
function Methods.IsClient()
	return M.context == "client"
end
function Methods.IsStudio()
	return M.studio
end
function Methods.GetServerTimeNow()
	return 1_790_000_000 + clock
end
function Methods.GetPlayers(self)
	local list = {}
	for _, child in data[self].children do
		if data[child].ClassName == "Player" then
			table.insert(list, child)
		end
	end
	return list
end
function Methods.GetPlayerByUserId(_, userId)
	for _, player in Methods.GetPlayers(services.Players) do
		if data[player].props.UserId == userId then
			return player
		end
	end
	return nil
end
function Methods.GetPlayerFromCharacter(_, character)
	for _, player in Methods.GetPlayers(services.Players) do
		if character ~= nil and data[player].props.Character == character then
			return player
		end
	end
	return nil
end

-- DataStores (in memory)
M.store = {}
M.failLoadsFor = {}
function Methods.GetDataStore(_, name)
	local ds = newInstance("DataStore", true)
	M.rawset(ds, "Name", name)
	return ds
end
function Methods.GetAsync(_, key)
	task.wait(0.05)
	if M.failLoadsFor[key] then
		error("mock DataStore failure for " .. key)
	end
	return M.store[key]
end
M.failSavesFor = {}
function Methods.UpdateAsync(_, key, transform)
	task.wait(0.05)
	if M.failSavesFor[key] then
		error("mock DataStore save failure for " .. key)
	end
	local result = transform(M.store[key], nil)
	if result ~= nil then
		-- like the real thing, data must survive a JSON round trip
		M.store[key] = M.deepcopy(result)
	end
	return result
end
function M.deepcopy(v)
	if type(v) ~= "table" then
		assert(type(v) ~= "userdata" and type(v) ~= "function", "cannot store " .. type(v))
		return v
	end
	assert(getmetatable(v) == nil, "cannot store a table with a metatable (Roblox type) in a DataStore")
	local out = {}
	for k, x in v do
		assert(type(k) == "string" or type(k) == "number", "bad DataStore key type")
		out[k] = M.deepcopy(x)
	end
	return out
end

-- Tags
M.tags = {} -- [tag] = { [instance] = true }
local function tagSignal(kind, tag)
	local key = kind .. ":" .. tag
	M.tagSignals = M.tagSignals or {}
	M.tagSignals[key] = M.tagSignals[key] or Signal()
	return M.tagSignals[key]
end
function Methods.AddTag(self, a, b)
	local inst, tag = a, b
	if b == nil then
		inst, tag = self, a
	end
	M.tags[tag] = M.tags[tag] or {}
	if not M.tags[tag][inst] then
		M.tags[tag][inst] = true
		tagSignal("added", tag):Fire(inst)
	end
end
function Methods.RemoveTag(self, a, b)
	local inst, tag = a, b
	if b == nil then
		inst, tag = self, a
	end
	if M.tags[tag] and M.tags[tag][inst] then
		M.tags[tag][inst] = nil
		tagSignal("removed", tag):Fire(inst)
	end
end
function Methods.HasTag(self, a, b)
	local inst, tag = a, b
	if b == nil then
		inst, tag = self, a
	end
	return M.tags[tag] ~= nil and M.tags[tag][inst] == true
end
function Methods.GetTagged(_, tag)
	local list = {}
	for inst in M.tags[tag] or {} do
		table.insert(list, inst)
	end
	return list
end
function Methods.GetInstanceAddedSignal(_, tag)
	return tagSignal("added", tag)
end
function Methods.GetInstanceRemovedSignal(_, tag)
	return tagSignal("removed", tag)
end

-- Collision groups
M.groups = { Default = true }
M.noCollide = {}
function Methods.IsCollisionGroupRegistered(_, name)
	return M.groups[name] == true
end
function Methods.RegisterCollisionGroup(_, name)
	assert(not M.groups[name], "collision group already registered: " .. name)
	M.groups[name] = true
	local count = 0
	for _ in M.groups do
		count += 1
	end
	assert(count <= 32, "Roblox allows at most 32 collision groups")
end
function Methods.CollisionGroupSetCollidable(_, a, b, collidable)
	assert(M.groups[a] and M.groups[b], "unregistered collision group")
	M.noCollide[a .. "|" .. b] = not collidable
	M.noCollide[b .. "|" .. a] = not collidable
end

-- JSON (HttpService)
local function encode(v)
	local t = type(v)
	if t == "nil" then
		return "null"
	elseif t == "boolean" or t == "number" then
		return tostring(v)
	elseif t == "string" then
		return '"' .. v:gsub('[%c"\\]', function(c)
			return string.format("\\u%04x", string.byte(c))
		end) .. '"'
	elseif t == "table" then
		assert(getmetatable(v) == nil, "cannot JSON encode a Roblox type")
		if #v > 0 or next(v) == nil then
			local parts = {}
			for _, x in ipairs(v) do
				table.insert(parts, encode(x))
			end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local parts = {}
		for k, x in v do
			table.insert(parts, encode(tostring(k)) .. ":" .. encode(x))
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	error("cannot JSON encode " .. t)
end
local function decode(s)
	local i = 1
	local value
	local function ws()
		i = s:find("[^%s]", i) or #s + 1
	end
	function value()
		ws()
		local c = s:sub(i, i)
		if c == "{" then
			local out = {}
			i += 1
			ws()
			if s:sub(i, i) == "}" then
				i += 1
				return out
			end
			while true do
				ws()
				local k = value()
				ws()
				assert(s:sub(i, i) == ":", "JSON: expected :")
				i += 1
				out[k] = value()
				ws()
				local d = s:sub(i, i)
				i += 1
				if d == "}" then
					return out
				end
				assert(d == ",", "JSON: expected ,")
			end
		elseif c == "[" then
			local out = {}
			i += 1
			ws()
			if s:sub(i, i) == "]" then
				i += 1
				return out
			end
			while true do
				table.insert(out, value())
				ws()
				local d = s:sub(i, i)
				i += 1
				if d == "]" then
					return out
				end
				assert(d == ",", "JSON: expected ,")
			end
		elseif c == '"' then
			local j = i + 1
			local buf = {}
			while s:sub(j, j) ~= '"' do
				if s:sub(j, j) == "\\" then
					local n = tonumber(s:sub(j + 2, j + 5), 16)
					table.insert(buf, string.char(n))
					j += 6
				else
					table.insert(buf, s:sub(j, j))
					j += 1
				end
			end
			i = j + 1
			return table.concat(buf)
		else
			local token = s:match("^[%w%.%-+]+", i)
			i += #token
			if token == "true" then
				return true
			elseif token == "false" then
				return false
			elseif token == "null" then
				return nil
			end
			return tonumber(token)
		end
	end
	return value()
end
function Methods.JSONEncode(_, v)
	return encode(v)
end
function Methods.JSONDecode(_, s)
	return decode(s)
end

-- Policy and purchases
M.restricted = {} -- [userId] = true when paid random items are restricted
M.policyFail = false
function Methods.GetPolicyInfoForPlayerAsync(_, player)
	task.wait(0.05)
	if M.policyFail then
		error("mock PolicyService failure")
	end
	return {
		ArePaidRandomItemsRestricted = M.restricted[data[player].props.UserId] == true,
		AllowedExternalLinkReferences = {},
		IsPaidItemTradingAllowed = true,
		IsSubjectToChinaPolicies = false,
	}
end
M.prompts = {}
function Methods.PromptProductPurchase(_, player, productId)
	assert(isInstance(player) and data[player].ClassName == "Player", "PromptProductPurchase needs a Player")
	assert(type(productId) == "number" and productId > 0, "PromptProductPurchase needs a product id")
	table.insert(M.prompts, { player = data[player].props.Name, id = productId })
end
M.prices = {}
function Methods.GetProductInfo(_, id, infoType)
	assert(infoType and infoType.EnumType == "InfoType", "GetProductInfo needs an Enum.InfoType")
	task.wait(0.05)
	return { PriceInRobux = M.prices[id] or 25, Name = "Product " .. id }
end

-- Remotes
M.clientEvents = {}
function Methods.FireClient(self, player, ...)
	assert(isInstance(player) and data[player].ClassName == "Player", "FireClient needs a Player first")
	table.insert(M.log, { remote = data[self].props.Name, player = data[player].props.Name, args = table.pack(...) })
	if player == M.localPlayer then
		signalOf(self, "OnClientEvent"):Fire(...)
	end
end
function Methods.FireAllClients(self, ...)
	for _, player in Methods.GetPlayers(services.Players) do
		table.insert(
			M.log,
			{ remote = data[self].props.Name, player = data[player].props.Name, args = table.pack(...) }
		)
	end
	if M.localPlayer then
		signalOf(self, "OnClientEvent"):Fire(...)
	end
end
function Methods.FireServer(self, ...)
	assert(M.localPlayer, "FireServer needs a local player")
	signalOf(self, "OnServerEvent"):Fire(M.localPlayer, ...)
end

-- Tweens finish instantly
function Methods.Create(_, inst, _info, goals)
	local tween = newInstance("Tween", true)
	data[tween].goals = goals
	data[tween].target = inst
	return tween
end
M.streamRequests = {}
function Methods.RequestStreamAroundAsync(self, position, timeout)
	assert(isV3(position), "RequestStreamAroundAsync needs a Vector3")
	assert(timeout == nil or type(timeout) == "number", "RequestStreamAroundAsync timeout must be a number")
	table.insert(M.streamRequests, { player = data[self].props.Name, position = position })
end

M.soundsPlayed = {}
function Methods.Play(self)
	local d = data[self]
	if d.ClassName == "Sound" then
		assert(type(d.props.SoundId) == "string" and d.props.SoundId ~= "", "Sound:Play() needs a SoundId")
		d.props.IsPlaying = true
		table.insert(M.soundsPlayed, { name = d.props.Name, volume = d.props.Volume, at = clock })
		return
	end
	for k, v in d.goals do
		if not data[d.target].destroyed then
			d.target[k] = v
		end
	end
	task.defer(function()
		signalOf(self, "Completed"):Fire(Enum and nil)
	end)
end

function Methods.Stop(self)
	local d = data[self]
	assert(d.ClassName == "Sound", "mock: Stop is only for sounds")
	d.props.IsPlaying = false
end

function Methods.Emit(_, count)
	assert(type(count) == "number", "Emit needs a number")
end

function Methods.AddItem(_, inst, lifetime)
	task.delay(lifetime or 10, function()
		Methods.Destroy(inst)
	end)
end

---------------------------------------------------------------------------
-- Running the clock
---------------------------------------------------------------------------
function M.step(dt)
	clock += dt
	signalOf(services.RunService, "RenderStepped"):Fire(dt)
	signalOf(services.RunService, "Heartbeat"):Fire(dt)
	runDue()
end
function M.advance(seconds, dt)
	dt = dt or 1 / 30
	for _ = 1, math.ceil(seconds / dt) do
		M.step(dt)
	end
end
function M.now()
	return clock
end

M.typeof = function(v)
	if isInstance(v) then
		return "Instance"
	elseif isV3(v) then
		return "Vector3"
	elseif isCF(v) then
		return "CFrame"
	elseif getmetatable(v) == C3MT then
		return "Color3"
	end
	return type(v)
end

return M
