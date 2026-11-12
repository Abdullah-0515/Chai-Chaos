-- Bright, warm, kid-friendly lighting and the day and night cycle.
-- Nights go by twice as fast. Events can force night (Load Shedding).

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)

local World = {}

World.forceNight = false

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function effect(className: string, name: string): any
	local existing = Lighting:FindFirstChild(name)
	if existing then
		return existing
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = Lighting
	return created
end

function World.isNight(): boolean
	local t = Lighting.ClockTime
	return t >= 18.5 or t < 5.5
end

function World.init()
	Lighting.ClockTime = 13
	Lighting.Brightness = 3
	Lighting.Ambient = rgb(135, 125, 115)
	Lighting.OutdoorAmbient = rgb(180, 170, 160)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.ExposureCompensation = 0.15
	Lighting.GlobalShadows = true

	local color = effect("ColorCorrectionEffect", "ChaiChaosColor")
	color.Saturation = 0.3
	color.Contrast = 0.08
	color.Brightness = 0.02
	color.TintColor = rgb(255, 249, 238)
	local bloom = effect("BloomEffect", "ChaiChaosBloom")
	bloom.Intensity = 0.35
	bloom.Size = 24
	bloom.Threshold = 1.7
	local rays = effect("SunRaysEffect", "ChaiChaosRays")
	rays.Intensity = 0.06
	rays.Spread = 0.8
	local atmosphere = effect("Atmosphere", "ChaiChaosAir")
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.1
	atmosphere.Color = rgb(255, 232, 205)
	atmosphere.Decay = rgb(255, 205, 160)
	atmosphere.Glare = 0
	atmosphere.Haze = 0.6

	task.spawn(function()
		local savedTime: number? = nil
		while true do
			local dt = task.wait(0.25)
			if World.forceNight then
				savedTime = savedTime or Lighting.ClockTime
				Lighting.ClockTime = 0
			else
				if savedTime then
					Lighting.ClockTime = savedTime
					savedTime = nil
				end
				local speed = if World.isNight() then 2 else 1
				Lighting.ClockTime = (Lighting.ClockTime + dt * speed * 24 / Config.DAY_LENGTH) % 24
			end
		end
	end)
end

return World
