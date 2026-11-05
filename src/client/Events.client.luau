-- The event banner (with the event's boosts) and each event's look: Basant
-- kites, rain, cricket confetti, the Load Shedding blackout, Mela fireworks
-- and Sardi snow. The sky effects follow your camera, so you see them
-- wherever you are in the world. Everything here is only on this player's screen.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Events = require(Shared:WaitForChild("Events"))
local Ui = require(script.Parent:WaitForChild("Ui"))

local rgb = Ui.rgb
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChaiChaosHud")

---------------------------------------------------------------------------
-- Banner
---------------------------------------------------------------------------
local banner = Ui.create("Frame", {
	Name = "EventBanner",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 8),
	Size = UDim2.fromOffset(250, 80),
	BackgroundColor3 = rgb(45, 30, 22),
	BackgroundTransparency = 0.15,
	Parent = gui,
}, {
	Ui.corner(12),
	Ui.create(
		"UIStroke",
		{ Name = "Edge", Thickness = 2, Color = Ui.GOLD, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }
	),
})
local title =
	Ui.label({ Name = "Title", Size = UDim2.new(1, -12, 0, 28), Position = UDim2.fromOffset(6, 3), Parent = banner })
local timer = Ui.label({
	Name = "Timer",
	Size = UDim2.new(1, -12, 0, 20),
	Position = UDim2.fromOffset(6, 33),
	TextColor3 = rgb(255, 230, 150),
	Parent = banner,
})

local perks = Ui.label({
	Name = "Perks",
	Size = UDim2.new(1, -12, 0, 20),
	Position = UDim2.fromOffset(6, 55),
	TextColor3 = rgb(160, 255, 170),
	Parent = banner,
})

-- "Cash x2 · Luck x2" for the running event
local PERKS = {
	{ "cashMult", "Cash x%s" },
	{ "luckMult", "Luck x%s" },
	{ "eggMult", "Eggs x%s" },
	{ "hatchMult", "Hatching x%s" },
	{ "eggTimeMult", "Egg time x%s" },
}
local function perkText(event): string
	local parts = {}
	for _, perk in PERKS do
		local value = event[perk[1]]
		if value and value ~= 1 then
			table.insert(parts, perk[2]:format(tostring(value)))
		end
	end
	if event.rollDiscount then
		table.insert(parts, ("Kismat -%d%%"):format(math.floor(event.rollDiscount * 100 + 0.5)))
	end
	return table.concat(parts, " · ")
end

local function formatTime(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	return ("%d:%02d"):format(seconds // 60, seconds % 60)
end

---------------------------------------------------------------------------
-- Effects
---------------------------------------------------------------------------
local effects = Instance.new("Folder")
effects.Name = "ChaiChaosEventEffects"
local cleanup: { () -> () } = {}
-- parts that move with the camera: { part, offset } (offset from the camera, in studs)
local followers: { { part: BasePart, offset: Vector3 } } = {}

local function weather(color: Color3, rate: number, speed: number, size: number, streak: boolean)
	local cloud = Instance.new("Part")
	cloud.Name = "Weather"
	cloud.Anchored = true
	cloud.CanCollide = false
	cloud.CanQuery = false
	cloud.CanTouch = false
	cloud.Transparency = 1
	cloud.Size = Vector3.new(160, 1, 160)
	cloud.Parent = effects
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(2, 3)
	emitter.Speed = NumberRange.new(speed, speed * 1.2)
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Size = NumberSequence.new(size)
	emitter.Transparency = NumberSequence.new(0.2)
	if streak then
		emitter.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp
		emitter.Squash = NumberSequence.new(2.5)
	end
	emitter.Parent = cloud
	table.insert(followers, { part = cloud, offset = Vector3.new(0, 40, 0) })
end

local function kites()
	local colors = { rgb(255, 60, 90), rgb(255, 205, 40), rgb(70, 200, 110), rgb(70, 160, 255), rgb(255, 120, 220) }
	local list = {}
	-- a ring of patang all around you, bobbing and drifting in the wind
	for i = 1, 24 do
		local color = colors[(i - 1) % #colors + 1]
		local kite = Instance.new("Part")
		kite.Name = "Kite"
		kite.Anchored = true
		kite.CanCollide = false
		kite.CanQuery = false
		kite.CanTouch = false
		kite.CastShadow = false
		kite.Size = Vector3.new(5, 5, 0.2)
		kite.Color = color
		kite.Material = Enum.Material.SmoothPlastic
		kite.Parent = effects
		local tail = Instance.new("Part")
		tail.Name = "KiteTail"
		tail.Anchored = true
		tail.CanCollide = false
		tail.CanQuery = false
		tail.CanTouch = false
		tail.CastShadow = false
		tail.Size = Vector3.new(0.4, 4, 0.1)
		tail.Color = colors[i % #colors + 1]
		tail.Parent = effects
		table.insert(list, {
			part = kite,
			tail = tail,
			angle = math.rad(i * 15),
			distance = 50 + (i % 4) * 22,
			height = 45 + (i % 5) * 7,
			phase = i,
		})
	end
	local connection = RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local camera = workspace.CurrentCamera
		local here = if camera then camera.CFrame.Position else Vector3.zero
		for _, k in list do
			local a = k.angle + t * 0.03
			local pos = Vector3.new(
				here.X + math.cos(a) * k.distance + math.sin(t * 0.4 + k.phase) * 6,
				here.Y + k.height + math.sin(t + k.phase) * 4,
				here.Z + math.sin(a) * k.distance
			)
			local facing = CFrame.lookAt(pos, Vector3.new(here.X, pos.Y, here.Z))
			local sway = math.sin(t * 2 + k.phase) * 0.3
			k.part.CFrame = facing * CFrame.Angles(0, 0, math.rad(45) + sway * 0.3)
			k.tail.CFrame = facing * CFrame.new(0, -5.2, 0) * CFrame.Angles(0, 0, sway)
		end
	end)
	table.insert(cleanup, function()
		connection:Disconnect()
	end)
end

local function bursts(colors: { Color3 }, height: number, every: number)
	local emitters = {}
	for i = 1, 6 do
		local spot = Instance.new("Part")
		spot.Name = "Burst"
		spot.Anchored = true
		spot.CanCollide = false
		spot.CanQuery = false
		spot.CanTouch = false
		spot.Transparency = 1
		spot.Size = Vector3.one
		spot.Parent = effects
		table.insert(
			followers,
			{ part = spot, offset = Vector3.new(-210 + i * 60, height, if i % 2 == 0 then 30 else -30) }
		)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(1, 1.6)
		emitter.Speed = NumberRange.new(18, 26)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Acceleration = Vector3.new(0, -12, 0)
		emitter.LightEmission = 1
		emitter.Size = NumberSequence.new(0.8, 0)
		emitter.Color = ColorSequence.new(colors[(i - 1) % #colors + 1])
		emitter.Parent = spot
		table.insert(emitters, emitter)
	end
	local running = true
	task.spawn(function()
		while running do
			local emitter = emitters[math.random(#emitters)]
			emitter:Emit(60)
			task.wait(every)
		end
	end)
	table.insert(cleanup, function()
		running = false
	end)
end

local function tint(color: Color3, brightness: number, saturation: number)
	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "ChaiChaosEventTint"
	correction.TintColor = color
	correction.Brightness = brightness
	correction.Saturation = saturation
	correction.Parent = Lighting
	table.insert(cleanup, function()
		correction:Destroy()
	end)
end

local LOOKS = {
	rain = function()
		weather(rgb(170, 200, 255), 400, 60, 0.15, true)
		tint(rgb(215, 225, 255), -0.03, -0.1)
	end,
	snow = function()
		weather(rgb(255, 255, 255), 250, 8, 0.35, false)
		tint(rgb(230, 240, 255), 0.03, -0.15)
	end,
	kites = function()
		kites()
		tint(rgb(255, 245, 215), 0.02, 0.1)
	end,
	cricket = function()
		bursts({ rgb(40, 200, 90), rgb(255, 255, 255), rgb(30, 120, 220) }, 30, 0.8)
	end,
	blackout = function()
		tint(rgb(170, 160, 255), -0.08, -0.2)
	end,
	mela = function()
		bursts({ rgb(255, 80, 120), rgb(255, 210, 60), rgb(120, 220, 255), rgb(200, 120, 255) }, 45, 0.5)
		tint(rgb(255, 235, 245), 0.02, 0.15)
	end,
}

local function stopEffects()
	for _, fn in cleanup do
		fn()
	end
	table.clear(cleanup)
	table.clear(followers)
	effects:ClearAllChildren()
end

local shownEvent: string? = nil
local function updateEffects()
	local event = Events.current()
	local id = event and event.id
	if id == shownEvent then
		return
	end
	shownEvent = id
	stopEffects()
	if event then
		effects.Parent = workspace.CurrentCamera
		local look = LOOKS[event.look]
		if look then
			look()
		end
	end
end

workspace:GetAttributeChangedSignal("EventId"):Connect(updateEffects)
updateEffects()

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	if camera and #followers > 0 then
		local position = camera.CFrame.Position
		for _, follower in followers do
			follower.part.CFrame = CFrame.new(position + follower.offset)
		end
	end
end)

task.spawn(function()
	while gui.Parent do
		local now = workspace:GetServerTimeNow()
		local event = Events.current()
		local edge = banner:FindFirstChild("Edge") :: UIStroke
		if event then
			title.Text = event.name
			title.TextColor3 = event.color
			timer.Text = formatTime((workspace:GetAttribute("EventEndsAt") or now) - now) .. " left"
			perks.Text = perkText(event)
			edge.Color = event.color
		else
			title.Text = "Next event"
			title.TextColor3 = Ui.WHITE
			timer.Text = "in " .. formatTime((workspace:GetAttribute("NextEventAt") or now) - now)
			perks.Text = ""
			edge.Color = Ui.GOLD
		end
		task.wait(0.5)
	end
end)
