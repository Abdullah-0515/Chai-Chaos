-- Driving on this player's screen.
--
-- * Steering: push the stick (or WASD) the way you want to go and the vehicle
--   turns towards it like a car, instead of spinning on the spot. On ice it
--   slides and on sand it turns slowly, unless its tyres (Grip) are good enough.
-- * You sit in the seat (the default sit animation).
-- * A fuel gauge, the eggs in your boot, a Horn button (or H) and a Park
--   button while you drive.
-- * Crashes: the vehicle's bumper is solid (see Garage.luau). Hit a wall or a
--   tree at speed and you bounce back with a crunch and stop for a moment.
-- * Rangeela (rainbow) paint jobs change colour on everyone's screen.
-- The server sets the speed, uses the fuel and decides everything else.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Vehicles = require(Shared:WaitForChild("Vehicles"))
local Ui = require(script.Parent:WaitForChild("Ui"))
local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))

local rgb, create, label = Ui.rgb, Ui.create, Ui.label
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChaiChaosHud")

local BIND = "ChaiChaosDrive"
local ICE = { [Enum.Material.Ice] = true, [Enum.Material.Glacier] = true }
local SAND = { [Enum.Material.Sand] = true }
local CRASH_SPEED = 16 -- hitting something faster than this is a crash
local CRASH_STOP = 0.35 -- ...when the speed drops below this share in one frame
local CRASH_BOUNCE = 22 -- how hard you bounce back
local CRASH_STUN = 0.7 -- seconds before you can drive again

---------------------------------------------------------------------------
-- The dashboard: fuel, boot and the Park button
---------------------------------------------------------------------------
local dash = create("Frame", {
	Name = "Dashboard",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -12),
	Size = UDim2.fromOffset(420, 74),
	BackgroundColor3 = rgb(40, 30, 25),
	BackgroundTransparency = 0.15,
	Visible = false,
	Parent = gui,
}, { Ui.corner(14) })
local vehicleName = label({
	Name = "Vehicle",
	Position = UDim2.fromOffset(10, 4),
	Size = UDim2.new(1, -200, 0, 24),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = dash,
})
local fuelBar = create("Frame", {
	Name = "FuelBar",
	Position = UDim2.fromOffset(10, 32),
	Size = UDim2.new(1, -200, 0, 16),
	BackgroundColor3 = rgb(80, 70, 60),
	Parent = dash,
}, { Ui.corner(8) })
local fuelFill = create("Frame", {
	Name = "Fill",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = rgb(70, 200, 90),
	Parent = fuelBar,
}, { Ui.corner(8) })
local fuelText = label({
	Name = "FuelText",
	Position = UDim2.fromOffset(10, 50),
	Size = UDim2.new(1, -200, 0, 20),
	TextColor3 = rgb(255, 230, 170),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = dash,
})
local parkButton = Ui.textButton({
	Name = "Park",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -8, 0.5, 0),
	Size = UDim2.fromOffset(90, 56),
	BackgroundColor3 = rgb(190, 70, 50),
	Text = "Park",
	Parent = dash,
})
parkButton.Activated:Connect(function()
	Remotes.Drive:FireServer(nil)
end)
local hornButton = Ui.textButton({
	Name = "Horn",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -104, 0.5, 0),
	Size = UDim2.fromOffset(82, 56),
	BackgroundColor3 = rgb(230, 170, 40),
	Text = "Horn",
	Parent = dash,
})
hornButton.Activated:Connect(function()
	Remotes.Honk:FireServer()
end)
UserInputService.InputBegan:Connect(function(input: InputObject, typing: boolean)
	if not typing and input.KeyCode == Enum.KeyCode.H and (player:GetAttribute("Driving") or "") ~= "" then
		Remotes.Honk:FireServer()
	end
end)

local function refreshDash()
	local id = player:GetAttribute("Driving") or ""
	local def = Vehicles.byId[id]
	dash.Visible = def ~= nil
	if not def then
		return
	end
	local fuel = player:GetAttribute("Fuel") or 0
	local tank = math.max(1, player:GetAttribute("FuelMax") or 1)
	local share = math.clamp(fuel / tank, 0, 1)
	fuelFill.Size = UDim2.fromScale(share, 1)
	fuelFill.BackgroundColor3 = if share > 0.4
		then rgb(70, 200, 90)
		elseif share > 0.15 then rgb(240, 190, 40)
		else rgb(220, 60, 50)
	vehicleName.Text = def.name
	local boot = player:GetAttribute("BootEggs") or 0
	local space = player:GetAttribute("BootSpace") or def.eggs
	fuelText.Text = if fuel <= 0
		then "Out of petrol! Find a pump"
		else ("Petrol %d studs  ·  Boot %d/%d eggs"):format(fuel, boot, space)
end
for _, name in { "Driving", "Fuel", "FuelMax", "BootEggs", "BootSpace" } do
	player:GetAttributeChangedSignal(name):Connect(refreshDash)
end
refreshDash()

---------------------------------------------------------------------------
-- Steering and sitting
---------------------------------------------------------------------------
local sitTrack: AnimationTrack? = nil
local heading = Vector3.new(0, 0, -1)
local moveDir = heading
local throttle = 0
local lastSpeed = 0
local stunnedUntil = 0

local function flat(v: Vector3): Vector3
	local f = Vector3.new(v.X, 0, v.Z)
	return if f.Magnitude > 1e-4 then f.Unit else Vector3.zero
end

local function stopDriving(humanoid: Humanoid?)
	RunService:UnbindFromRenderStep(BIND)
	if sitTrack then
		sitTrack:Stop()
		sitTrack = nil
	end
	if humanoid then
		humanoid.AutoRotate = true
	end
end

local function startDriving(character: Model, humanoid: Humanoid, root: BasePart)
	stopDriving(nil)
	humanoid.AutoRotate = false
	heading = flat(root.CFrame.LookVector)
	if heading.Magnitude == 0 then
		heading = Vector3.new(0, 0, -1)
	end
	moveDir = heading
	throttle = 0
	lastSpeed = 0
	-- sit in the seat with the character's own sit animation
	local animate = character:FindFirstChild("Animate")
	local sit = animate and animate:FindFirstChild("sit")
	local anim = sit and sit:FindFirstChildWhichIsA("Animation")
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if anim and animator then
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = true
			track:Play(0.2)
			sitTrack = track
		end
	end
	-- runs right after the controls have read the stick, so we can steer
	RunService:BindToRenderStep(BIND, Enum.RenderPriority.Input.Value + 1, function(dt: number)
		if not root.Parent or humanoid.Health <= 0 then
			return
		end
		local grip = player:GetAttribute("Grip") or 0
		local floor = humanoid.FloorMaterial
		local icy = ICE[floor] == true and grip < 3
		local sandy = SAND[floor] == true and grip < 2
		local raw = humanoid.MoveDirection or Vector3.zero
		local input = flat(raw)
		local strength = math.min(1, raw.Magnitude)
		local target = 0
		-- crashed into something? bounce back and stop for a moment
		local velocity = root.AssemblyLinearVelocity or Vector3.zero
		local speed = (velocity * Vector3.new(1, 0, 1)).Magnitude
		local now = os.clock()
		if lastSpeed > CRASH_SPEED and speed < lastSpeed * CRASH_STOP and throttle > 0.5 and now > stunnedUntil then
			stunnedUntil = now + CRASH_STUN
			throttle = 0
			root.AssemblyLinearVelocity = -moveDir * CRASH_BOUNCE + Vector3.new(0, 8, 0)
			SoundPlayer.play("Crash", root.Position)
		end
		lastSpeed = speed
		if now < stunnedUntil then
			strength = 0
		end
		if strength > 0.05 then
			local turnRate = math.rad(if icy then 80 elseif sandy then 110 else 170)
			local angle = math.atan2(heading:Cross(input).Y, heading:Dot(input))
			local step = math.clamp(angle, -turnRate * dt, turnRate * dt)
			heading = (CFrame.Angles(0, step, 0) * heading).Unit
			-- slow down while turning hard, like a real car
			target = strength * math.clamp((heading:Dot(input) + 0.4) / 1.4, 0.3, 1)
		end
		throttle += (target - throttle) * math.min(1, (if icy then 0.8 else 6) * dt)
		-- on ice the vehicle keeps sliding the way it was going
		moveDir = (moveDir:Lerp(heading, math.min(1, (if icy then 1.2 else 14) * dt))).Unit
		humanoid:Move(moveDir * throttle, false)
		root.CFrame = CFrame.lookAt(root.Position, root.Position + heading)
	end)
end

local function refreshDriving()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local driving = (player:GetAttribute("Driving") or "") ~= ""
	if driving and character and humanoid and root and root:IsA("BasePart") then
		startDriving(character, humanoid, root)
	else
		stopDriving(humanoid)
	end
end
player:GetAttributeChangedSignal("Driving"):Connect(refreshDriving)
player.CharacterAdded:Connect(function()
	stopDriving(nil)
	task.wait(0.2)
	refreshDriving()
end)

---------------------------------------------------------------------------
-- Rangeela paint: every colour of the rainbow
---------------------------------------------------------------------------
local painted: { [Model]: { BasePart } } = {}
local function track(model: Instance)
	if model:IsA("Model") then
		local list = {}
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") and p.Name == "Paint" then
				table.insert(list, p)
			end
		end
		painted[model] = list
	end
end
CollectionService:GetInstanceAddedSignal("ChaiVehicle"):Connect(track)
CollectionService:GetInstanceRemovedSignal("ChaiVehicle"):Connect(function(model)
	painted[model :: Model] = nil
end)
for _, model in CollectionService:GetTagged("ChaiVehicle") do
	track(model)
end

local frame = 0
RunService.RenderStepped:Connect(function()
	frame += 1
	if frame % 2 ~= 0 then
		return
	end
	local t = os.clock()
	for model, parts in painted do
		if model.Parent == nil then
			painted[model] = nil
		else
			for i, p in parts do
				if p:GetAttribute("Tint") then
					p.Color = Color3.fromHSV((t * 0.3 + i * 0.08) % 1, 0.7, 1)
				end
			end
		end
	end
end)
