-- The new-player guide on this player's screen: a card at the top that says
-- what to do next, and a glowing beacon with a line on the ground to follow.
-- The server decides which step you are on (the Tutorial attribute).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Biomes = require(Shared:WaitForChild("Biomes"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Steps = require(Shared:WaitForChild("Tutorial"))
local Ui = require(script.Parent:WaitForChild("Ui"))

local rgb, create, label = Ui.rgb, Ui.create, Ui.label
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChaiChaosHud")

local YELLOW = rgb(255, 215, 70)

---------------------------------------------------------------------------
-- The card
---------------------------------------------------------------------------
local card = create("Frame", {
	Name = "Guide",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 90),
	Size = UDim2.new(0.9, 0, 0, 58),
	BackgroundColor3 = rgb(40, 90, 150),
	BackgroundTransparency = 0.1,
	Visible = false,
	Parent = gui,
}, {
	Ui.corner(12),
	create("UISizeConstraint", { MaxSize = Vector2.new(520, 58) }),
	create("UIStroke", { Thickness = 2, Color = YELLOW, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})
local stepLabel = label({
	Name = "Step",
	Position = UDim2.fromOffset(10, 2),
	Size = UDim2.new(1, -90, 0, 18),
	TextColor3 = YELLOW,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = card,
})
local textLabel = label({
	Name = "Text",
	Position = UDim2.fromOffset(10, 20),
	Size = UDim2.new(1, -90, 0, 34),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	Parent = card,
})
local skip = Ui.textButton({
	Name = "Skip",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -8, 0.5, 0),
	Size = UDim2.fromOffset(66, 34),
	BackgroundColor3 = rgb(110, 105, 100),
	Text = "Skip",
	Parent = card,
})
skip.Activated:Connect(function()
	Remotes.Guide:FireServer("skip")
end)

---------------------------------------------------------------------------
-- The beacon and the line to it
---------------------------------------------------------------------------
local beacon = create("Part", {
	Name = "GuideBeacon",
	Anchored = true,
	CanCollide = false,
	CanTouch = false,
	CanQuery = false,
	CastShadow = false,
	Shape = Enum.PartType.Cylinder,
	Size = Vector3.new(70, 3, 3),
	Color = YELLOW,
	Material = Enum.Material.Neon,
	Transparency = 0.45,
})
local beaconEnd = create("Attachment", { Name = "End", Parent = beacon })
local billboard = create("BillboardGui", {
	Name = "Label",
	Size = UDim2.fromOffset(220, 44),
	StudsOffsetWorldSpace = Vector3.new(0, 10, 0),
	AlwaysOnTop = true,
	MaxDistance = 2000,
	Parent = beacon,
})
local distanceLabel =
	label({ Name = "Distance", Size = UDim2.fromScale(1, 1), TextColor3 = YELLOW, Parent = billboard })
local line = create("Beam", {
	Name = "GuideLine",
	Attachment1 = beaconEnd,
	Width0 = 1.6,
	Width1 = 1.6,
	FaceCamera = true,
	Color = ColorSequence.new(YELLOW),
	Transparency = NumberSequence.new(0.35),
	LightEmission = 0.6,
	Segments = 1,
	Parent = beacon,
})
local rootAttachment: Attachment? = nil

local function rootPart(): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

-- Where the arrow points for a step's target (nil = nowhere).
local function targetPosition(target: string?, from: Vector3): Vector3?
	if not target then
		return nil
	end
	local zoneId = target:match("^zone:(%w+)$")
	if zoneId then
		local biome = Biomes.byId[zoneId]
		if biome then
			local angle, radius = Biomes.gate(biome)
			return Biomes.polar(angle, radius + 8)
		end
	elseif target == "home" then
		local home = player:GetAttribute("HomePosition")
		return if typeof(home) == "Vector3" then home else nil
	elseif target == "showroom" then
		local spot = workspace:GetAttribute("ShowroomPosition")
		return if typeof(spot) == "Vector3" then spot else nil
	elseif target == "egg" then
		local open = Biomes.decode(player:GetAttribute("OpenZones") or "")
		local eggs = workspace:FindFirstChild("ChaiChaosEggs")
		local best, bestDistance = nil, math.huge
		if eggs then
			for _, model in eggs:GetChildren() do
				if model:IsA("Model") and open[model:GetAttribute("Biome") or ""] and model.PrimaryPart then
					local prompt = model.PrimaryPart:FindFirstChild("EggPrompt")
					if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
						local position = model:GetPivot().Position
						local distance = (position - from).Magnitude
						if distance < bestDistance then
							best, bestDistance = position, distance
						end
					end
				end
			end
		end
		return best
	end
	return nil
end

local function refresh()
	local step = Steps.byId[player:GetAttribute("Tutorial") or ""]
	card.Visible = step ~= nil
	local root = rootPart()
	if not step or not root then
		beacon.Parent = nil
		return
	end
	stepLabel.Text = ("Guide · step %d of %d"):format(player:GetAttribute("TutorialStep") or 1, #Steps.steps)
	textLabel.Text = step.text
	local target = targetPosition(step.target, root.Position)
	if not target then
		beacon.Parent = nil
		return
	end
	local flat = Vector3.new(target.X, Biomes.GROUND_Y, target.Z)
	beacon.CFrame = CFrame.new(flat + Vector3.new(0, 35, 0)) * CFrame.Angles(0, 0, math.rad(90))
	beaconEnd.WorldPosition = flat + Vector3.new(0, 1.5, 0)
	distanceLabel.Text = ("%d studs"):format(math.floor((flat - root.Position).Magnitude))
	if not rootAttachment or rootAttachment.Parent ~= root then
		rootAttachment = create("Attachment", { Name = "GuideStart", Parent = root })
	end
	line.Attachment0 = rootAttachment
	beacon.Parent = workspace
end

player:GetAttributeChangedSignal("Tutorial"):Connect(refresh)
task.spawn(function()
	while gui.Parent do
		refresh()
		task.wait(0.5)
	end
end)
