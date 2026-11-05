-- Makes the 3D model for a brainrot.
--
-- If ServerStorage has a folder "Brainrots" with a Model named after the
-- brainrot's id (for example "SamosaSupremo"), that model is used. Otherwise a
-- blocky placeholder is built from the shape, colour and extras in Brainrots.luau.
-- The front of a model is its -Z side (the way Roblox models face by default).
--
-- Mutated brainrots (Golden, Diamond, Rainbow) are tinted; Rainbow ones change
-- colour on every player's screen (see Smooth.client.luau).

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Brainrots = require(Shared.Brainrots)
local Format = require(Shared.Format)
local Mutations = require(Shared.Mutations)

local Models = {}

local RARITY_SIZE = {
	Common = 3,
	Uncommon = 3.5,
	Rare = 4,
	Epic = 4.6,
	Legendary = 5.4,
	Mythic = 6.4,
	Special = 5,
}

local PARTICLE_RATE = {
	Epic = 4,
	Legendary = 8,
	Mythic = 16,
	Special = 10,
}

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.fromRGB(25, 25, 30)

local function newPart(
	model: Model,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	shape: Enum.PartType?
): BasePart
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local UP = CFrame.Angles(0, 0, math.rad(90)) -- turns a cylinder upright

-- Builds the body and returns where the face and add-ons should go.
local function buildBody(model: Model, shape: string, s: number, color: Color3)
	local body = {
		w = s,
		h = s,
		d = s,
		eyeY = s * 0.15,
		eyeX = 0,
		eyeGap = s * 0.2,
		front = -s / 2,
	}
	if shape == "Ball" then
		newPart(model, "Body", Vector3.one * s, CFrame.new(), color, Enum.PartType.Ball)
		body.front = -s * 0.42
	elseif shape == "Block" then
		body.h, body.d = s * 0.85, s * 0.9
		newPart(model, "Body", Vector3.new(body.w, body.h, body.d), CFrame.new(), color)
		body.front = -body.d / 2
		body.eyeY = body.h * 0.15
	elseif shape == "Tall" then
		body.w, body.h, body.d = s * 0.7, s * 1.4, s * 0.7
		newPart(model, "Body", Vector3.new(body.w, body.h, body.d), CFrame.new(), color)
		body.front = -body.d / 2
		body.eyeY = body.h * 0.25
	elseif shape == "Cylinder" then
		body.h = s * 1.1
		newPart(model, "Body", Vector3.new(body.h, s, s), UP, color, Enum.PartType.Cylinder)
		body.front = -s * 0.47
		body.eyeY = body.h * 0.2
	elseif shape == "Disc" then
		body.w, body.h, body.d = s * 1.3, s * 0.4, s * 1.3
		newPart(model, "Body", Vector3.new(body.h, body.w, body.d), UP, color, Enum.PartType.Cylinder)
		body.front = -body.d * 0.47
		body.eyeY = 0
		body.eyeGap = s * 0.25
	elseif shape == "Wheel" then
		body.w, body.h, body.d = s * 1.4, s * 1.4, s * 0.4
		newPart(
			model,
			"Body",
			Vector3.new(body.d, body.h, body.w),
			CFrame.Angles(0, math.rad(90), 0),
			color,
			Enum.PartType.Cylinder
		)
		body.front = -body.d / 2
		-- spokes so it reads as a wheel
		for i = 0, 3 do
			newPart(
				model,
				"Spoke",
				Vector3.new(body.w * 0.95, 0.25, 0.25),
				CFrame.new(0, 0, body.front - 0.05) * CFrame.Angles(0, 0, math.rad(45 * i)),
				color:Lerp(WHITE, 0.5)
			)
		end
		body.front -= 0.15
	elseif shape == "Wedge" then
		-- a wedge turned sideways so its triangle faces the front (samosa shape)
		body.h, body.d = s * 0.95, s * 0.8
		local wedge = Instance.new("WedgePart")
		wedge.Name = "Body"
		wedge.Size = Vector3.new(body.d, body.h, body.w)
		wedge.CFrame = CFrame.Angles(0, math.rad(90), 0)
		wedge.Color = color
		wedge.Material = Enum.Material.SmoothPlastic
		wedge.Parent = model
		body.front = -body.d / 2
		body.eyeX = s * 0.17
		body.eyeY = -body.h * 0.2
		body.eyeGap = s * 0.13
	elseif shape == "Slab" then
		body.w, body.h, body.d = s * 0.75, s * 1.3, s * 0.3
		newPart(model, "Body", Vector3.new(body.w, body.h, body.d), CFrame.new(), color)
		-- the chappal strap
		newPart(
			model,
			"Strap",
			Vector3.new(body.w * 1.05, s * 0.18, body.d * 1.3),
			CFrame.new(0, body.h * 0.22, 0),
			BLACK
		)
		body.front = -body.d / 2
		body.eyeY = -body.h * 0.05
	elseif shape == "Kite" then
		body.w, body.h, body.d = s * 1.3, s * 1.3, s * 0.15
		newPart(model, "Body", Vector3.new(s, s, body.d), CFrame.Angles(0, 0, math.rad(45)), color)
		newPart(model, "Stripe", Vector3.new(s * 1.4, 0.2, body.d + 0.05), CFrame.new(), color:Lerp(WHITE, 0.6))
		body.front = -body.d / 2
		body.eyeY = s * 0.1
	else
		newPart(model, "Body", Vector3.one * s, CFrame.new(), color)
	end
	return body
end

local function addEyes(model: Model, body, count: number)
	local size = math.clamp(body.w * 0.26, 0.6, 1.6)
	local xs = { body.eyeX - body.eyeGap, body.eyeX + body.eyeGap }
	if count == 1 then
		size *= 1.6
		xs = { body.eyeX }
	end
	for _, x in xs do
		local z = body.front - size * 0.1
		newPart(model, "Eye", Vector3.one * size, CFrame.new(x, body.eyeY, z), WHITE, Enum.PartType.Ball)
		newPart(
			model,
			"Pupil",
			Vector3.one * size * 0.5,
			CFrame.new(x, body.eyeY - size * 0.05, z - size * 0.32),
			BLACK,
			Enum.PartType.Ball
		)
	end
	return size
end

local EXTRAS = {}

function EXTRAS.glasses(model, body, eye, _color)
	newPart(
		model,
		"Glasses",
		Vector3.new(body.eyeGap * 2 + eye * 1.3, eye * 0.6, 0.25),
		CFrame.new(body.eyeX, body.eyeY, body.front - eye * 0.5),
		BLACK
	)
end

function EXTRAS.goggles(model, body, eye, _color)
	local y = body.eyeY + eye * 0.75
	newPart(
		model,
		"GoggleBand",
		Vector3.new(body.w * 1.04, eye * 0.35, body.d * 1.04),
		CFrame.new(0, y, 0),
		Color3.fromRGB(110, 70, 40)
	)
	for _, x in { body.eyeX - body.eyeGap, body.eyeX + body.eyeGap } do
		local lens = newPart(
			model,
			"Lens",
			Vector3.one * eye * 0.8,
			CFrame.new(x, y, body.front - 0.1),
			Color3.fromRGB(120, 230, 255),
			Enum.PartType.Ball
		)
		lens.Material = Enum.Material.Neon
	end
end

function EXTRAS.moustache(model, body, eye, _color)
	local y = body.eyeY - eye * 0.95
	for _, side in { -1, 1 } do
		newPart(
			model,
			"Moustache",
			Vector3.new(eye * 1.1, eye * 0.3, 0.3),
			CFrame.new(body.eyeX + side * eye * 0.5, y, body.front - 0.15) * CFrame.Angles(0, 0, math.rad(side * -15)),
			BLACK
		)
	end
end

function EXTRAS.crown(model, body, _eye, _color)
	local gold = Color3.fromRGB(255, 200, 40)
	local height = math.max(body.h * 0.25, 0.8)
	local crown = newPart(
		model,
		"Crown",
		Vector3.new(height, body.w * 0.5, body.w * 0.5),
		CFrame.new(0, body.h / 2 + height / 2, 0) * UP,
		gold,
		Enum.PartType.Cylinder
	)
	crown.Material = Enum.Material.Metal
	newPart(
		model,
		"Jewel",
		Vector3.one * height * 0.5,
		CFrame.new(0, body.h / 2 + height / 2, -body.w * 0.25),
		Color3.fromRGB(230, 30, 60),
		Enum.PartType.Ball
	)
end

function EXTRAS.headband(model, body, eye, _color)
	newPart(
		model,
		"Headband",
		Vector3.new(body.w * 1.04, eye * 0.4, body.d * 1.04),
		CFrame.new(0, body.eyeY + eye * 0.8, 0),
		Color3.fromRGB(200, 30, 40)
	)
end

function EXTRAS.legs(model, body, _eye, color)
	local legH = math.max(body.h * 0.35, 0.8)
	local legW = math.max(body.w * 0.18, 0.5)
	for _, side in { -1, 1 } do
		newPart(
			model,
			"Leg",
			Vector3.new(legW, legH, legW),
			CFrame.new(side * body.w * 0.22, -body.h / 2 - legH / 2 + 0.1, 0),
			color:Lerp(BLACK, 0.35)
		)
	end
end

function EXTRAS.horn(model, body, eye, _color)
	newPart(
		model,
		"Horn",
		Vector3.new(eye * 0.45, eye * 1.2, eye * 0.45),
		CFrame.new(0, body.eyeY + eye * 1.1, body.front - eye * 0.1) * CFrame.Angles(math.rad(-25), 0, 0),
		Color3.fromRGB(245, 240, 225)
	)
end

function EXTRAS.ears(model, body, _eye, color)
	local size = Vector3.new(body.w * 0.22, body.h * 0.28, body.w * 0.12)
	for _, side in { -1, 1 } do
		newPart(
			model,
			"Ear",
			size,
			CFrame.new(side * body.w * 0.3, body.h / 2 + size.Y / 2 - 0.1, 0),
			color:Lerp(BLACK, 0.2)
		)
	end
end

function EXTRAS.wings(model, body, _eye, color)
	local size = Vector3.new(body.w * 0.7, 0.25, body.d * 0.6)
	for _, side in { -1, 1 } do
		newPart(
			model,
			"Wing",
			size,
			CFrame.new(side * (body.w / 2 + size.X / 2 - 0.2), body.h * 0.1, 0)
				* CFrame.Angles(0, 0, math.rad(side * 25)),
			color:Lerp(WHITE, 0.4)
		)
	end
end

function EXTRAS.bat(model, body, _eye, _color)
	newPart(
		model,
		"Bat",
		Vector3.new(0.5, body.h * 1.1, 0.3),
		CFrame.new(body.w / 2 + 0.6, 0, body.front * 0.4) * CFrame.Angles(0, 0, math.rad(-30)),
		Color3.fromRGB(225, 195, 140)
	)
end

function EXTRAS.tail(model, body, _eye, color)
	local length = math.max(body.d * 0.6, 1)
	newPart(
		model,
		"Tail",
		Vector3.new(0.45, 0.45, length),
		CFrame.new(0, -body.h * 0.1, -body.front + length / 2 - 0.1) * CFrame.Angles(math.rad(20), 0, 0),
		color:Lerp(BLACK, 0.25)
	)
end

local function buildPlaceholder(def: Brainrots.Def): Model
	local model = Instance.new("Model")
	model.Name = def.id

	local root = newPart(model, "Root", Vector3.one, CFrame.new(), WHITE)
	root.Transparency = 1
	model.PrimaryPart = root

	local size = RARITY_SIZE[def.rarity] or 3
	local body = buildBody(model, def.shape, size, def.color)
	local eye = addEyes(model, body, def.eyes or 2)
	for _, extra in def.extras do
		local add = EXTRAS[extra]
		if add then
			add(model, body, eye, def.color)
		else
			warn("[ChaiChaos] Unknown extra '" .. extra .. "' on " .. def.id)
		end
	end
	return model
end

local function newLabel(name: string, position: number, height: number, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.fromScale(1, height)
	label.Position = UDim2.fromScale(0, position)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Parent = label
	return label
end

local NOT_TINTED = { Eye = true, Pupil = true, Root = true }

local function tint(model: Model, mutation: string?)
	local m = mutation and Mutations.byId[mutation]
	if not m then
		return
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and not NOT_TINTED[p.Name] and p.Transparency < 1 then
			p:SetAttribute("Tint", true)
			if m.id == "Golden" then
				p.Color = m.color:Lerp(p.Color, 0.15)
				p.Material = Enum.Material.Foil
			elseif m.id == "Diamond" then
				p.Color = m.color
				p.Material = Enum.Material.Glass
				p.Reflectance = 0.25
				p.Transparency = 0.1
			else
				p.Color = m.color
				p.Material = Enum.Material.Neon
			end
		end
	end
end

-- Anchors the model, adds the rarity ring, sparkles and the name pop-up.
local function decorate(model: Model, def: Brainrots.Def, mutation: string?)
	local primary = model.PrimaryPart :: BasePart
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CastShadow = false
		end
	end
	tint(model, mutation)

	local rarityColor = Brainrots.RARITY_COLORS[def.rarity]
	local boxCFrame, boxSize = model:GetBoundingBox()
	local pivot = model:GetPivot()
	local center = pivot:PointToObjectSpace(boxCFrame.Position)
	local bottom = center.Y - boxSize.Y / 2

	local ringSize = math.max(boxSize.X, boxSize.Z) * 1.15
	local ring = newPart(
		model,
		"RarityRing",
		Vector3.new(0.2, ringSize, ringSize),
		pivot * CFrame.new(center.X, bottom - 0.1, center.Z) * UP,
		rarityColor,
		Enum.PartType.Cylinder
	)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.35
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false

	local hover = if def.float then 1.5 else 0
	model:SetAttribute("GroundOffset", -(bottom - 0.2) + hover)
	model:SetAttribute("BrainrotId", def.id)
	model:SetAttribute("Mutation", mutation)

	-- welds hold the parts together while a thief carries the brainrot
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p ~= primary then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "Hold"
			weld.Part0 = primary
			weld.Part1 = p
			weld.Parent = p
		end
	end

	local m = mutation and Mutations.byId[mutation]
	if m then
		local glitter = Instance.new("ParticleEmitter")
		glitter.Name = "MutationSparkles"
		glitter.Rate = 8
		glitter.Lifetime = NumberRange.new(0.8, 1.4)
		glitter.Speed = NumberRange.new(1, 2.5)
		glitter.SpreadAngle = Vector2.new(180, 180)
		glitter.Size = NumberSequence.new(0.5, 0)
		glitter.LightEmission = 1
		glitter.Color = ColorSequence.new(m.color)
		glitter.Parent = primary
	end

	local rate = PARTICLE_RATE[def.rarity]
	if rate then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "RaritySparkles"
		sparkles.Rate = rate
		sparkles.Lifetime = NumberRange.new(1, 1.8)
		sparkles.Speed = NumberRange.new(1.5, 3)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new(0.4, 0)
		sparkles.LightEmission = 1
		if def.rarity == "Mythic" then
			sparkles.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
				ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 220, 60)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60, 220, 100)),
				ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 140, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 80, 255)),
			})
		else
			sparkles.Color = ColorSequence.new(rarityColor)
		end
		sparkles.Parent = primary
	end

	local primaryTop = primary.CFrame:PointToObjectSpace(boxCFrame.Position).Y + boxSize.Y / 2
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Popup"
	billboard.Size = UDim2.fromScale(9, 3.4)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, primaryTop + 2.2, 0)
	billboard.MaxDistance = 90
	billboard.LightInfluence = 0

	local nameLabel = newLabel("NameLabel", 0, 0.3, if m then m.color else WHITE)
	nameLabel.Text = Mutations.displayName(def, mutation)
	nameLabel.Parent = billboard
	local rarityLabel = newLabel("RarityLabel", 0.3, 0.2, rarityColor)
	rarityLabel.Text = def.rarity
	rarityLabel.Parent = billboard
	local phraseLabel = newLabel("PhraseLabel", 0.5, 0.26, Color3.fromRGB(255, 230, 120))
	phraseLabel.Text = '"' .. def.phrase .. '"'
	phraseLabel.Parent = billboard
	local infoLabel = newLabel("InfoLabel", 0.76, 0.24, Color3.fromRGB(140, 255, 140))
	infoLabel.Text = ("%s  ·  +%s/s"):format(
		Format.rupees(Mutations.value(def, mutation)),
		Format.short(Mutations.income(def, mutation))
	)
	infoLabel.Parent = billboard
	billboard.Parent = primary
	CollectionService:AddTag(model, "ChaiBrainrot")
end

function Models.create(def: Brainrots.Def, mutation: string?): Model
	local folder = ServerStorage:FindFirstChild("Brainrots")
	local template = folder and folder:FindFirstChild(def.id)
	local model: Model
	if template and template:IsA("Model") then
		model = template:Clone()
		if not model.PrimaryPart then
			local biggest: BasePart? = nil
			for _, p in model:GetDescendants() do
				if p:IsA("BasePart") and (not biggest or p.Size.Magnitude > biggest.Size.Magnitude) then
					biggest = p
				end
			end
			assert(biggest, "[ChaiChaos] The model " .. def.id .. " in ServerStorage.Brainrots has no parts")
			model.PrimaryPart = biggest
		end
	else
		model = buildPlaceholder(def)
	end
	model.Name = def.id
	decorate(model, def, mutation)
	return model
end

-- Welds the brainrot onto a thief so it moves smoothly with their character.
function Models.attach(model: Model, root: BasePart, offset: CFrame)
	model:SetAttribute("Carried", true)
	model:PivotTo(root.CFrame * offset)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Massless = true
			p.Anchored = false
		end
	end
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
end

function Models.detach(model: Model)
	local primary = model.PrimaryPart
	local weld = primary and primary:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
	model:SetAttribute("Carried", false)
end

-- The brainrot model that a prompt (or any part) belongs to.
function Models.ownerModel(instance: Instance): Model?
	local node = instance.Parent
	while node and node ~= workspace do
		if node:IsA("Model") and node:GetAttribute("BrainrotId") then
			return node
		end
		node = node.Parent
	end
	return nil
end

-- Where the model's pivot must go so it stands on `ground` (a CFrame on a floor).
function Models.stand(model: Model, ground: CFrame): CFrame
	return ground * CFrame.new(0, model:GetAttribute("GroundOffset") or 0, 0)
end

local function popupLabel(model: Model, name: string): TextLabel?
	local primary = model.PrimaryPart
	local popup = primary and primary:FindFirstChild("Popup")
	return popup and popup:FindFirstChild(name) :: TextLabel?
end

function Models.setInfo(model: Model, text: string)
	local label = popupLabel(model, "InfoLabel")
	if label then
		label.Text = text
	end
end

-- While being stolen, the brainrot panics.
function Models.setPanic(model: Model, def: Brainrots.Def, panicking: boolean)
	local label = popupLabel(model, "PhraseLabel")
	if not label then
		return
	end
	if panicking then
		label.Text = "AAAA! " .. def.phrase:upper()
		label.TextColor3 = Color3.fromRGB(255, 80, 80)
	else
		label.Text = '"' .. def.phrase .. '"'
		label.TextColor3 = Color3.fromRGB(255, 230, 120)
	end
end

return Models
