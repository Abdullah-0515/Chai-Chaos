-- Makes brainrots move smoothly on this player's screen.
--
-- Walking brainrots are animated every frame from the attributes the server
-- sets (MoveFrom, MoveTo, MoveStart, MoveSpeed), with a little hop. Brainrots
-- standing on a plot gently bob and sway. Rainbow brainrots change colour.
-- None of this changes anything for other players or the server.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Motion = require(Shared:WaitForChild("Motion"))

local IDLE_DISTANCE = 90 -- only animate idle brainrots this close to the camera (they have ~40 parts each)
local TAG = "ChaiBrainrot"

local tracked: { [Model]: { phase: number, tinted: { BasePart }? } } = {}

local function add(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	local info = { phase = math.random() * math.pi * 2, tinted = nil }
	tracked[instance] = info
	if instance:GetAttribute("Mutation") == "Rainbow" then
		local parts = {}
		for _, p in instance:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("Tint") then
				table.insert(parts, p)
			end
		end
		info.tinted = parts
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(add)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance)
	tracked[instance :: Model] = nil
end)
for _, instance in CollectionService:GetTagged(TAG) do
	add(instance)
end

local frame = 0
RunService.RenderStepped:Connect(function()
	frame += 1
	local t = os.clock()
	local serverNow = workspace:GetServerTimeNow()
	local camera = workspace.CurrentCamera
	local cameraPosition = if camera then camera.CFrame.Position else Vector3.zero
	local idleFrame = frame % 2 == 0 -- idle animation at half rate is plenty

	for model, info in tracked do
		if model.Parent == nil or not model.PrimaryPart or model:GetAttribute("Carried") then
			continue
		end
		local speed = model:GetAttribute("MoveSpeed")
		local from, to, started =
			model:GetAttribute("MoveFrom"), model:GetAttribute("MoveTo"), model:GetAttribute("MoveStart")
		if
			type(speed) == "number"
			and speed > 0
			and typeof(from) == "CFrame"
			and typeof(to) == "CFrame"
			and type(started) == "number"
		then
			local cf, arrived = Motion.at(from, to, started, speed, serverNow)
			local hop = if arrived then 0 else math.abs(math.sin(t * 8 + info.phase)) * 0.6
			model:PivotTo(cf + Vector3.new(0, hop, 0))
		elseif idleFrame then
			local restCF = model:GetAttribute("Rest")
			if typeof(restCF) == "CFrame" and (restCF.Position - cameraPosition).Magnitude < IDLE_DISTANCE then
				local bob = (math.sin(t * 2 + info.phase) + 1) * 0.15
				local sway = math.sin(t * 1.3 + info.phase) * 0.08
				model:PivotTo(restCF * CFrame.new(0, bob, 0) * CFrame.Angles(0, sway, 0))
			end
		end
		if info.tinted and idleFrame then
			local color = Color3.fromHSV((t * 0.25 + info.phase) % 1, 0.65, 1)
			for _, p in info.tinted do
				p.Color = color
			end
		end
	end
end)
