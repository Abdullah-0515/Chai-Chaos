-- How the biomes look and feel on this player's screen:
-- * Registan: a dusty sandstorm every so often (Sand Goggles let you see)
-- * Namak Kaan: dark, pink salt caves (a Lantern lights the way)
-- * Pahar: snow drifting down
-- * Samandar: a splash when a big wave rolls in
-- The server decides what actually happens; this is only the look.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Biomes = require(Shared:WaitForChild("Biomes"))
local Gear = require(Shared:WaitForChild("Gear"))
local Ui = require(script.Parent:WaitForChild("Ui"))

local rgb = Ui.rgb
local player = Players.LocalPlayer

-- one tint for every biome effect, blended towards the look we want
local tint = Instance.new("ColorCorrectionEffect")
tint.Name = "ChaiChaosBiomeTint"
tint.Parent = Lighting

-- particles that follow the camera
local cloud = Instance.new("Part")
cloud.Name = "ChaiChaosWeather"
cloud.Anchored = true
cloud.CanCollide = false
cloud.CanQuery = false
cloud.CanTouch = false
cloud.Transparency = 1
cloud.Size = Vector3.new(120, 1, 120)

local function emitter(name: string, color: Color3, size: number, speed: number, rate: number): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(size)
	e.Speed = NumberRange.new(speed, speed * 1.4)
	e.Lifetime = NumberRange.new(2, 3.5)
	e.Rate = rate
	e.Enabled = false
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Transparency = NumberSequence.new(0.3)
	e.Parent = cloud
	return e
end
local snow = emitter("Snow", rgb(255, 255, 255), 0.4, 6, 220)
local sand = emitter("Sand", rgb(225, 180, 110), 0.8, 30, 500)
sand.Acceleration = Vector3.new(40, 0, 10)
local salt = emitter("Salt", rgb(255, 200, 215), 0.25, 4, 60)

-- the lantern glow, on your character in the salt caves
local glow = Instance.new("PointLight")
glow.Name = "LanternGlow"
glow.Color = rgb(255, 220, 160)
glow.Range = 28
glow.Brightness = 2.2
glow.Shadows = false

local LOOKS = {
	none = { tint = rgb(255, 255, 255), brightness = 0, saturation = 0, contrast = 0 },
	sandstorm = { tint = rgb(255, 215, 160), brightness = -0.06, saturation = -0.35, contrast = -0.15 },
	goggles = { tint = rgb(255, 235, 200), brightness = 0, saturation = -0.1, contrast = 0 },
	cave = { tint = rgb(255, 170, 200), brightness = -0.32, saturation = -0.1, contrast = 0.1 },
	lantern = { tint = rgb(255, 205, 220), brightness = -0.1, saturation = 0, contrast = 0.05 },
	snow = { tint = rgb(225, 238, 255), brightness = 0.03, saturation = -0.15, contrast = 0 },
}

local shownLook = ""
local function setLook(name: string)
	if name == shownLook then
		return
	end
	shownLook = name
	local look = LOOKS[name]
	TweenService:Create(tint, TweenInfo.new(1.2), {
		TintColor = look.tint,
		Brightness = look.brightness,
		Saturation = look.saturation,
		Contrast = look.contrast,
	}):Play()
end

local lastWave = workspace:GetAttribute("WaveAt") or 0

local function update()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local biome = if root and root:IsA("BasePart") then Biomes.at(root.Position) else nil
	local id = if biome then biome.id else ""
	local owned = Gear.decode(player:GetAttribute("Gear") or "")
	local storm = id == "Registan" and workspace:GetAttribute("Sandstorm") == true

	snow.Enabled = id == "Pahar"
	sand.Enabled = storm
	sand.Rate = if owned.SandGoggles then 150 else 500
	salt.Enabled = id == "NamakKaan"
	cloud.Parent = if snow.Enabled or sand.Enabled or salt.Enabled then workspace.CurrentCamera else nil

	if storm then
		setLook(if owned.SandGoggles then "goggles" else "sandstorm")
	elseif id == "NamakKaan" then
		setLook(if owned.Lantern then "lantern" else "cave")
	elseif id == "Pahar" then
		setLook("snow")
	else
		setLook("none")
	end
	glow.Parent = if id == "NamakKaan" and owned.Lantern and root then root else nil

	-- a big wave: splash if we are on the beach
	local waveAt = workspace:GetAttribute("WaveAt") or 0
	if waveAt ~= lastWave then
		lastWave = waveAt
		if id == "Samandar" and root and root:IsA("BasePart") then
			local splash = Instance.new("Part")
			splash.Name = "Splash"
			splash.Anchored = true
			splash.CanCollide = false
			splash.CanQuery = false
			splash.CanTouch = false
			splash.Transparency = 1
			splash.Size = Vector3.new(16, 1, 16)
			splash.Position = root.Position
			local drops = Instance.new("ParticleEmitter")
			drops.Color = ColorSequence.new(rgb(140, 210, 255))
			drops.Size = NumberSequence.new(0.6, 0.1)
			drops.Speed = NumberRange.new(14, 22)
			drops.SpreadAngle = Vector2.new(50, 50)
			drops.Acceleration = Vector3.new(0, -35, 0)
			drops.Lifetime = NumberRange.new(0.8, 1.2)
			drops.Rate = 0
			drops.EmissionDirection = Enum.NormalId.Top
			drops.Parent = splash
			splash.Parent = workspace.CurrentCamera
			drops:Emit(120)
			task.delay(2, function()
				splash:Destroy()
			end)
		end
	end
end

RunService.RenderStepped:Connect(function()
	if cloud.Parent then
		cloud.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 30, 0))
	end
end)

task.spawn(function()
	while true do
		update()
		task.wait(0.25)
	end
end)
