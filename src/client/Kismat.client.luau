-- Kismat Roll and Chor Pass windows, and the roll reveal animation.
-- The odds are shown before anyone spends rupees or Robux.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared:WaitForChild("Config"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Themes = require(Shared:WaitForChild("Themes"))
local Events = require(Shared:WaitForChild("Events"))
local Ui = require(script.Parent:WaitForChild("Ui"))
local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))

local rgb = Ui.rgb
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChaiChaosHud")
local buttons = gui:WaitForChild("Buttons")

local ROW_COLOR = rgb(60, 45, 35)
local BUY_COLOR = rgb(30, 140, 80)

local function attribute(name: string, default: any): any
	local value = player:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

local function plural(count: number, one: string, many: string): string
	return ("%d %s"):format(count, if count == 1 then one else many)
end

-- Fills in "R$ 25" once Roblox tells us the price set on the Creator Dashboard.
local function showPrice(button: TextButton, productId: number, text: string)
	button.Text = text .. "  ·  R$ ..."
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
		end)
		if ok and type(info) == "table" and info.PriceInRobux then
			button.Text = ("%s  ·  R$ %s"):format(text, Format.commas(info.PriceInRobux))
		else
			button.Text = text .. "  ·  Robux"
		end
	end)
end

---------------------------------------------------------------------------
-- Odds
---------------------------------------------------------------------------
local totalWeight = 0
for _, weight in Config.ROLL_ODDS do
	totalWeight += weight
end

local function chance(rarity: string): number
	return (Config.ROLL_ODDS[rarity] or 0) / totalWeight
end

local function percent(rarity: string): string
	local text = string.format("%.1f", chance(rarity) * 100):gsub("%.0$", "")
	return text .. "%"
end

local function oneIn(rarity: string): string
	local p = chance(rarity)
	if p <= 0 then
		return "never"
	end
	return "1 in " .. Format.commas(math.max(1, math.floor(1 / p + 0.5)))
end

---------------------------------------------------------------------------
-- Kismat Roll window
---------------------------------------------------------------------------
local kismatButton = Ui.sideButton(buttons, "Kismat", "Kismat Roll", rgb(230, 140, 30), 3)
local panel, content = Ui.panel(gui, "KismatPanel", "Kismat Roll", Vector2.new(440, 560))
local order = 0
local function nextOrder(): number
	order += 1
	return order
end

Ui.label({
	Size = UDim2.new(1, 0, 0, 22),
	Text = "Roll for a random brainrot. The odds:",
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = nextOrder(),
	Parent = content,
})
for _, rarity in Brainrots.RARITY_ORDER do
	if not Config.ROLL_ODDS[rarity] then
		continue -- Secret brainrots never come from rolls
	end
	local row = Ui.create("Frame", {
		Name = rarity,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundColor3 = ROW_COLOR,
		LayoutOrder = nextOrder(),
		Parent = content,
	}, { Ui.corner(8) })
	local color = Brainrots.RARITY_COLORS[rarity]
	Ui.label({
		Size = UDim2.new(0.42, -8, 1, -4),
		Position = UDim2.fromOffset(8, 2),
		Text = rarity,
		TextColor3 = color,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	Ui.label({
		Name = "Percent",
		Size = UDim2.new(0.25, 0, 1, -4),
		Position = UDim2.new(0.42, 0, 0, 2),
		Text = percent(rarity),
		Parent = row,
	})
	Ui.label({
		Name = "OneIn",
		Size = UDim2.new(0.33, -8, 1, -4),
		Position = UDim2.new(0.67, 0, 0, 2),
		Text = oneIn(rarity),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
end
Ui.label({
	Size = UDim2.new(1, 0, 0, 48),
	Text = "Every brainrot in a rarity is equally likely. Chand Raat Cheetah only comes out at night, "
		.. "Pakora Panda only during Baarish and Gajar Halwa Gorilla only during Sardi.",
	TextWrapped = true,
	TextColor3 = rgb(255, 235, 170),
	LayoutOrder = nextOrder(),
	Parent = content,
})

-- Mutation chances, for this player right now (theme perk and event included)
local mutationTitle = Ui.label({
	Name = "MutationTitle",
	Size = UDim2.new(1, 0, 0, 22),
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = nextOrder(),
	Parent = content,
})
local mutationRows = {}
for _, m in Mutations.list do
	local row = Ui.create("Frame", {
		Name = m.id,
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = ROW_COLOR,
		LayoutOrder = nextOrder(),
		Parent = content,
	}, { Ui.corner(8) })
	Ui.label({
		Size = UDim2.new(0.5, -8, 1, -4),
		Position = UDim2.fromOffset(8, 2),
		Text = ("%s (x%d income)"):format(m.name, m.income),
		TextColor3 = m.color,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	mutationRows[m.id] = Ui.label({
		Name = "Chance",
		Size = UDim2.new(0.5, -8, 1, -4),
		Position = UDim2.new(0.5, 0, 0, 2),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	})
end

local function mutationBoost(): number
	local event = Events.current()
	return (Themes.perk(player:GetAttribute("Theme"), "rollMutation") or 1)
		* (if event then event.mutationMult or 1 else 1)
end

local function rollCost(): number
	local event = Events.current()
	local discount = (1 - (Themes.perk(player:GetAttribute("Theme"), "rollDiscount") or 0))
		* (1 - (if event then event.rollDiscount or 0 else 0))
	return math.floor(Config.ROLL_RUPEE_COST * discount)
end

local function refreshMutations()
	local boost = mutationBoost()
	mutationTitle.Text = if boost > 1
		then ("Mutation chances (x%s right now!):"):format(tostring(boost))
		else "Mutation chances:"
	for _, m in Mutations.list do
		local odds = m.roll * boost
		local pct = string.format("%.2f", odds * 100):gsub("0+$", ""):gsub("%.$", "")
		mutationRows[m.id].Text = ("%s%%  ·  1 in %s"):format(pct, Format.commas(math.floor(1 / odds + 0.5)))
	end
end
local pityLabel = Ui.label({
	Name = "Pity",
	Size = UDim2.new(1, 0, 0, 24),
	TextColor3 = rgb(200, 150, 255),
	LayoutOrder = nextOrder(),
	Parent = content,
})
local rollsLabel = Ui.label({
	Name = "Rolls",
	Size = UDim2.new(1, 0, 0, 24),
	LayoutOrder = nextOrder(),
	Parent = content,
})

local function contentButton(name: string, text: string, color: Color3): TextButton
	return Ui.textButton({
		Name = name,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = color,
		Text = text,
		LayoutOrder = nextOrder(),
		Parent = content,
	})
end

local rollRupees = contentButton("RollRupees", "Roll for " .. Format.rupees(Config.ROLL_RUPEE_COST), rgb(230, 140, 30))
local rollToken = contentButton("RollToken", "Use a Kismat Roll", rgb(150, 70, 205))

local rollPacks = {}
for index, pack in Config.ROLL_PRODUCTS do
	if pack.id ~= 0 then
		local packButton = contentButton("BuyRolls" .. index, "", BUY_COLOR)
		showPrice(packButton, pack.id, plural(pack.amount, "Kismat Roll", "Kismat Rolls"))
		packButton.Activated:Connect(function()
			Remotes.BuyProduct:FireServer("rolls", index)
		end)
		table.insert(rollPacks, packButton)
	end
end

local busyUntil = 0
local function roll(method: string)
	if os.clock() < busyUntil then
		return
	end
	busyUntil = os.clock() + Config.ROLL_COOLDOWN
	Remotes.Roll:FireServer(method)
end
rollRupees.Activated:Connect(function()
	roll("rupees")
end)
rollToken.Activated:Connect(function()
	roll("token")
end)
kismatButton.Activated:Connect(function()
	Ui.toggle(panel)
end)

local function refreshKismat()
	local tokens = attribute("RollTokens", 0)
	local left = math.max(1, Config.ROLL_PITY - attribute("RollPity", 0))
	pityLabel.Text = ("Epic or better guaranteed within %s"):format(plural(left, "roll", "rolls"))
	rollsLabel.Text = "Your Kismat Rolls: " .. tokens
	rollToken.Visible = tokens > 0
	rollToken.Text = ("Use a Kismat Roll (%d left)"):format(tokens)
	kismatButton.Text = if tokens > 0 then ("Kismat Roll (%d)"):format(tokens) else "Kismat Roll"
	local cost = rollCost()
	rollRupees.Text = if cost < Config.ROLL_RUPEE_COST
		then ("Roll for %s (sale!)"):format(Format.rupees(cost))
		else "Roll for " .. Format.rupees(cost)
	refreshMutations()
	local paidAllowed = attribute("PaidRollsAllowed", false) == true
	for _, packButton in rollPacks do
		packButton.Visible = paidAllowed
	end
end
for _, name in { "RollTokens", "RollPity", "PaidRollsAllowed", "Theme" } do
	player:GetAttributeChangedSignal(name):Connect(refreshKismat)
end
workspace:GetAttributeChangedSignal("EventId"):Connect(refreshKismat)
refreshKismat()

---------------------------------------------------------------------------
-- Chor Pass window (only when stealing costs Robux)
---------------------------------------------------------------------------
if Config.stealsCostRobux() then
	local chorButton = Ui.sideButton(buttons, "ChorPass", "Chor Pass", rgb(200, 50, 70), 7)
	local chorPanel, chorContent = Ui.panel(gui, "ChorPanel", "Chor Pass", Vector2.new(420, 340))
	local chorOrder = 0
	local function add(props)
		chorOrder += 1
		props.LayoutOrder = chorOrder
		props.Parent = chorContent
		return props
	end
	local refundText = if Config.STEAL_REFUND_ON_FAIL
		then " If you get bonked, die, or the owner leaves, you get it back."
		else ""
	Ui.label(add({
		Size = UDim2.new(1, 0, 0, 54),
		Text = "Every steal uses 1 Chor Pass." .. refundText,
		TextWrapped = true,
	}))
	local passesLabel = Ui.label(add({ Name = "Passes", Size = UDim2.new(1, 0, 0, 26) }))
	for index, pack in Config.STEAL_PRODUCTS do
		if pack.id ~= 0 then
			local packButton = Ui.textButton(add({
				Name = "BuyPasses" .. index,
				Size = UDim2.new(1, 0, 0, 44),
				BackgroundColor3 = BUY_COLOR,
				Text = "",
			}))
			showPrice(packButton, pack.id, plural(pack.amount, "Chor Pass", "Chor Passes"))
			packButton.Activated:Connect(function()
				Remotes.BuyProduct:FireServer("steals", index)
			end)
		end
	end
	local function refreshChor()
		local passes = attribute("StealTokens", 0)
		passesLabel.Text = "Your Chor Passes: " .. passes
		chorButton.Text = ("Chor Pass (%d)"):format(passes)
	end
	player:GetAttributeChangedSignal("StealTokens"):Connect(refreshChor)
	refreshChor()
	chorButton.Activated:Connect(function()
		Ui.toggle(chorPanel)
	end)
end

---------------------------------------------------------------------------
-- Roll reveal
---------------------------------------------------------------------------
local revealScale = Ui.create("UIScale", {})
local reveal = Ui.create("Frame", {
	Name = "KismatReveal",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.42),
	Size = UDim2.fromOffset(380, 170),
	BackgroundColor3 = rgb(40, 25, 20),
	BackgroundTransparency = 0.05,
	Visible = false,
	ZIndex = 20,
	Parent = gui,
}, {
	Ui.corner(18),
	Ui.create("UIStroke", { Thickness = 3, Color = Ui.GOLD, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	revealScale,
})
local revealHeader = Ui.label({
	Size = UDim2.new(1, -20, 0, 28),
	Position = UDim2.fromOffset(10, 8),
	TextColor3 = Ui.GOLD,
	Parent = reveal,
})
local revealName = Ui.label({
	Name = "BrainrotName",
	Size = UDim2.new(1, -20, 0, 56),
	Position = UDim2.fromOffset(10, 40),
	Parent = reveal,
})
local revealRarity = Ui.label({
	Name = "Rarity",
	Size = UDim2.new(1, -20, 0, 28),
	Position = UDim2.fromOffset(10, 100),
	Parent = reveal,
})
local revealNew = Ui.label({
	Name = "New",
	Size = UDim2.new(1, -20, 0, 26),
	Position = UDim2.fromOffset(10, 134),
	TextColor3 = rgb(120, 255, 140),
	Text = "NEW! Added to your Collection Book",
	Parent = reveal,
})

local revealCount = 0
local function showRoll(id: string, mutationId: string, isNew: boolean, wasPity: boolean)
	local def = Brainrots.byId[id]
	if not def then
		return
	end
	local mutation = Mutations.byId[mutationId]
	revealCount += 1
	local mine = revealCount
	reveal.Visible = true
	revealHeader.Text = "Rolling..."
	revealRarity.Text = ""
	revealNew.Visible = false

	-- flick through random brainrots, slowing down like a spinning wheel
	local step, elapsed = 0.04, 0
	while elapsed < 1.6 do
		local fake = Brainrots.list[math.random(#Brainrots.list)]
		revealName.Text = fake.name
		revealName.TextColor3 = Brainrots.RARITY_COLORS[fake.rarity]
		SoundPlayer.play("RollSpin")
		elapsed += task.wait(step)
		step *= 1.15
		if mine ~= revealCount then
			return
		end
	end

	revealHeader.Text = if mutation
		then ("%s! Kismat says..."):format(mutation.name:upper())
		elseif wasPity then "Pity roll! Kismat says..."
		else "Kismat says..."
	revealName.Text = Mutations.displayName(def, mutation and mutation.id)
	revealName.TextColor3 = if mutation then mutation.color else Brainrots.RARITY_COLORS[def.rarity]
	revealRarity.Text = ("%s  ·  %s"):format(def.rarity, oneIn(def.rarity))
	revealRarity.TextColor3 = Brainrots.RARITY_COLORS[def.rarity]
	revealNew.Visible = isNew
	SoundPlayer.play("RollReveal")
	revealScale.Scale = 1.15
	TweenService:Create(revealScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	task.delay(2.5, function()
		if mine == revealCount then
			reveal.Visible = false
		end
	end)
end

Remotes.RollResult.OnClientEvent:Connect(function(id, mutationId, isNew, wasPity)
	task.spawn(showRoll, id, mutationId, isNew, wasPity)
end)
