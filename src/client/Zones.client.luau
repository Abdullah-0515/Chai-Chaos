-- The zone gates, shortcut doors and the train, on this player's screen.
--
-- * Gate barriers and shortcut doors are solid for everyone on the server.
--   Here they let you through the ones you have unlocked (OpenZones), and hide
--   the "Unlock" prompt on gates you can already walk through.
-- * The Railway Junction train and its crossing light move from the clock
--   (Biomes.trainAt), so every screen shows the same thing as the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared:WaitForChild("Config"))
local Biomes = require(Shared:WaitForChild("Biomes"))

local player = Players.LocalPlayer

local GREEN = Color3.fromRGB(80, 220, 80)
local RED = Color3.fromRGB(255, 50, 50)
local DARK = Color3.fromRGB(80, 20, 20)

local open: { [string]: boolean } = {}
local barriers: { [BasePart]: boolean } = {}

local function apply(part: BasePart)
	local passable
	if part.Name == "GateBarrier" then
		passable = open[part:GetAttribute("Zone") or ""] == true
		local prompt = part:FindFirstChild("GatePrompt")
		if prompt and prompt:IsA("ProximityPrompt") then
			prompt.Enabled = not passable
		end
	else
		passable = open[part:GetAttribute("ZoneA") or ""] == true and open[part:GetAttribute("ZoneB") or ""] == true
	end
	part.CanCollide = not passable
	part.Transparency = if passable then 0.85 else 0.45
end

local function watch(instance: Instance)
	if instance:IsA("BasePart") and (instance.Name == "GateBarrier" or instance.Name == "ShortcutDoor") then
		barriers[instance] = true
		apply(instance)
	end
end

local function refresh()
	open = Biomes.decode(player:GetAttribute("OpenZones") or "")
	for part in barriers do
		if part.Parent then
			apply(part)
		else
			barriers[part] = nil
		end
	end
end

player:GetAttributeChangedSignal("OpenZones"):Connect(refresh)
refresh()
-- with streaming, gates and doors load in as you get near them
workspace.DescendantAdded:Connect(watch)
for _, d in workspace:GetDescendants() do
	watch(d)
end

---------------------------------------------------------------------------
-- The train
---------------------------------------------------------------------------
local function findTrain(): (Model?, { BasePart })
	local map = workspace:FindFirstChild("ChaiChaosMap")
	local biomes = map and map:FindFirstChild("Biomes")
	local folder = biomes and biomes:FindFirstChild(Biomes.TRAIN.zone)
	if not folder then
		return nil, {}
	end
	local lights = {}
	for _, d in folder:GetChildren() do
		if d:IsA("BasePart") and d.Name == "CrossingLight" then
			table.insert(lights, d)
		end
	end
	local train = folder:FindFirstChild("Train")
	return if train and train:IsA("Model") then train else nil, lights
end

local train, lights = nil, {}
local lastLook = 0
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	if (not train or not train.Parent) and t - lastLook > 2 then
		lastLook = t
		train, lights = findTrain()
	end
	if not train then
		return
	end
	local angle, _, light, dir =
		Biomes.trainAt(workspace:GetServerTimeNow(), Config.TRAIN_WAIT, Config.TRAIN_BLINK, Config.TRAIN_SPEED)
	local a = math.rad(angle)
	local position = Biomes.polar(angle, Biomes.TRAIN.radius) + Vector3.new(0, 0.6, 0)
	local tangent = Vector3.new(-math.sin(a), 0, math.cos(a)) * dir
	train:PivotTo(CFrame.lookAt(position, position + tangent))
	local color = if light == "green"
		then GREEN
		elseif light == "red" then RED
		elseif math.floor(t / 0.4) % 2 == 0 then RED
		else DARK
	for _, lamp in lights do
		lamp.Color = color
	end
end)
