-- The on-screen HUD: rupees, income, the Taala button, the Collection Book,
-- the Naya Safar button and pop-up messages from the server.
-- (The Kismat Roll and Chor Pass windows are in Kismat.client.luau.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared:WaitForChild("Config"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Ui = require(script.Parent:WaitForChild("Ui"))

local player = Players.LocalPlayer
local leaderstats = player:WaitForChild("leaderstats")
local rupeesValue = leaderstats:WaitForChild("Rupees") :: IntValue

local WHITE, GOLD, FONT = Ui.WHITE, Ui.GOLD, Ui.FONT
local rgb, create, corner, label = Ui.rgb, Ui.create, Ui.corner, Ui.label

local gui = create("ScreenGui", {
	Name = "ChaiChaosHud",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

---------------------------------------------------------------------------
-- Money panel
---------------------------------------------------------------------------
local panelScale = create("UIScale", {})
local panel = create("Frame", {
	Name = "Money",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(300, 74),
	BackgroundColor3 = rgb(45, 30, 22),
	BackgroundTransparency = 0.1,
	Parent = gui,
}, {
	corner(14),
	create("UIStroke", { Thickness = 2, Color = GOLD, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	panelScale,
})
local rupeesLabel = label({
	Size = UDim2.new(1, -16, 0, 40),
	Position = UDim2.fromOffset(8, 4),
	TextColor3 = GOLD,
	Text = "Rs 0",
	Parent = panel,
})
local incomeLabel = label({
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.fromOffset(8, 46),
	Text = "+0/s",
	Parent = panel,
})
local statusLabel = label({
	AnchorPoint = Vector2.new(0.5, 0),
	Size = UDim2.fromOffset(300, 20),
	Position = UDim2.new(0.5, 0, 0, 86),
	TextColor3 = rgb(160, 230, 255),
	Text = "",
	Parent = gui,
})

local lastRupees = rupeesValue.Value
local function updateRupees()
	local value = rupeesValue.Value
	rupeesLabel.Text = Format.rupees(value)
	if value > lastRupees then
		panelScale.Scale = 1.07
		TweenService:Create(panelScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	lastRupees = value
end

local function updateIncome()
	local income = player:GetAttribute("Income") or 0
	local galla = player:GetAttribute("Galla") or 0
	incomeLabel.Text = ("+%s/s   ·   Galla %s"):format(Format.short(income), Format.rupees(galla))
end

rupeesValue.Changed:Connect(updateRupees)
player:GetAttributeChangedSignal("Income"):Connect(updateIncome)
player:GetAttributeChangedSignal("Galla"):Connect(updateIncome)
updateRupees()
updateIncome()

---------------------------------------------------------------------------
-- Pop-up messages
---------------------------------------------------------------------------
local toasts = create("Frame", {
	Name = "Toasts",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 112),
	Size = UDim2.new(0.9, 0, 0, 300),
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	create("UISizeConstraint", { MaxSize = Vector2.new(480, 300) }),
	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local TOAST_COLORS = {
	info = rgb(40, 40, 55),
	good = rgb(30, 130, 70),
	bad = rgb(165, 75, 40),
	alert = rgb(215, 30, 40),
	rare = rgb(135, 60, 195),
}
local MAX_TOASTS = 5
local toastCount = 0

local function toast(kind: string, text: string)
	toastCount += 1
	local isAlert = kind == "alert"
	local item = label({
		Size = UDim2.new(1, 0, 0, if isAlert then 50 else 34),
		BackgroundColor3 = TOAST_COLORS[kind] or TOAST_COLORS.info,
		BackgroundTransparency = 0.1,
		TextWrapped = true,
		Text = text,
		LayoutOrder = -toastCount, -- newest on top
		Parent = toasts,
	})
	corner(10).Parent = item
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		Parent = item,
	})

	local items = {}
	for _, child in toasts:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(items, child)
		end
	end
	table.sort(items, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = MAX_TOASTS + 1, #items do
		items[i]:Destroy()
	end

	task.delay(if isAlert then 6 else 4, function()
		if item.Parent then
			local fade =
				TweenService:Create(item, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 })
			fade:Play()
			fade.Completed:Wait()
			item:Destroy()
		end
	end)
end

Remotes.Notify.OnClientEvent:Connect(toast)

---------------------------------------------------------------------------
-- Buttons on the left
---------------------------------------------------------------------------
local buttons = create("Frame", {
	Name = "Buttons",
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.45, 0),
	Size = UDim2.fromOffset(150, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	Parent = gui,
}, {
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local function button(name: string, text: string, color: Color3, order: number): TextButton
	return Ui.sideButton(buttons, name, text, color, order)
end

local LOCK_READY = rgb(190, 70, 50)
local LOCK_ON = rgb(40, 150, 80)
local LOCK_WAIT = rgb(100, 100, 110)
local lockButton = button("Taala", "Taala (Lock)", LOCK_READY, 1)
local bookButton = button("Collection", "Collection Book", rgb(60, 120, 195), 2)
local rebirthButton = button("NayaSafar", "Naya Safar!", rgb(150, 70, 205), 10)
rebirthButton.Visible = false

lockButton.Activated:Connect(function()
	Remotes.LockHaveli:FireServer()
end)

local confirmUntil = 0
rebirthButton.Activated:Connect(function()
	if os.clock() < confirmUntil then
		confirmUntil = 0
		Remotes.Rebirth:FireServer()
		rebirthButton.Text = "Naya Safar!"
	else
		confirmUntil = os.clock() + 4
		rebirthButton.Text = "Sure? Tap again"
		task.delay(4, function()
			if os.clock() >= confirmUntil then
				rebirthButton.Text = "Naya Safar!"
			end
		end)
	end
end)

local function formatTime(seconds: number): string
	seconds = math.ceil(seconds)
	return ("%d:%02d"):format(seconds // 60, seconds % 60)
end

task.spawn(function()
	while gui.Parent do
		local now = workspace:GetServerTimeNow()
		local lockedUntil = player:GetAttribute("LockedUntil") or 0
		local readyAt = player:GetAttribute("LockReadyAt") or 0
		if now < lockedUntil then
			lockButton.Text = ("Locked %ds"):format(math.ceil(lockedUntil - now))
			lockButton.BackgroundColor3 = LOCK_ON
		elseif now < readyAt then
			lockButton.Text = ("Taala in %ds"):format(math.ceil(readyAt - now))
			lockButton.BackgroundColor3 = LOCK_WAIT
		else
			lockButton.Text = "Taala (Lock)"
			lockButton.BackgroundColor3 = LOCK_READY
		end

		local protectedUntil = player:GetAttribute("ProtectedUntil") or 0
		statusLabel.Text = if now < protectedUntil then "Steal protection " .. formatTime(protectedUntil - now) else ""

		rebirthButton.Visible = rupeesValue.Value >= Config.REBIRTH_COST
		task.wait(0.2)
	end
end)

---------------------------------------------------------------------------
-- Collection Book
---------------------------------------------------------------------------
local book = create("Frame", {
	Name = "CollectionBook",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.9, 0.8),
	BackgroundColor3 = rgb(250, 238, 210),
	Visible = false,
	ZIndex = 5,
	Parent = gui,
}, {
	corner(16),
	create("UISizeConstraint", { MaxSize = Vector2.new(680, 480) }),
	create("UIStroke", { Thickness = 3, Color = rgb(120, 70, 40), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
})
local bookTitle = label({
	Size = UDim2.new(1, -70, 0, 40),
	Position = UDim2.fromOffset(14, 8),
	TextColor3 = GOLD,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "Collection Book",
	ZIndex = 6,
	Parent = book,
})
local closeButton = create("TextButton", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 8),
	Size = UDim2.fromOffset(40, 40),
	BackgroundColor3 = rgb(200, 60, 50),
	Font = FONT,
	TextScaled = true,
	TextColor3 = WHITE,
	Text = "X",
	ZIndex = 6,
	Parent = book,
}, { corner(10) })
local grid = create("ScrollingFrame", {
	Position = UDim2.fromOffset(10, 56),
	Size = UDim2.new(1, -20, 1, -66),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 8,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ZIndex = 6,
	Parent = book,
}, {
	create("UIGridLayout", {
		CellSize = UDim2.fromOffset(150, 104),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}),
})

local cards = {}
local order = 0
for _, rarity in Brainrots.RARITY_ORDER do
	for _, def in Brainrots.byRarity[rarity] do
		order += 1
		local card = create("Frame", {
			Name = def.id,
			BackgroundColor3 = rgb(60, 45, 35),
			LayoutOrder = order,
			ZIndex = 6,
			Parent = grid,
		}, {
			corner(10),
			create("Frame", {
				Name = "Strip",
				Size = UDim2.new(1, 0, 0, 8),
				BackgroundColor3 = Brainrots.RARITY_COLORS[rarity],
				BorderSizePixel = 0,
				ZIndex = 7,
			}, { corner(10) }),
		})
		local nameLabel = label({
			Size = UDim2.new(1, -10, 0, 30),
			Position = UDim2.fromOffset(5, 12),
			ZIndex = 7,
			Parent = card,
		})
		local infoLabel = label({
			Size = UDim2.new(1, -10, 0, 20),
			Position = UDim2.fromOffset(5, 44),
			TextColor3 = Brainrots.RARITY_COLORS[rarity],
			ZIndex = 7,
			Parent = card,
		})
		local phraseLabel = label({
			Size = UDim2.new(1, -10, 0, 32),
			Position = UDim2.fromOffset(5, 66),
			TextColor3 = rgb(255, 230, 150),
			TextWrapped = true,
			ZIndex = 7,
			Parent = card,
		})
		table.insert(cards, { def = def, frame = card, name = nameLabel, info = infoLabel, phrase = phraseLabel })
	end
end

local function refreshBook()
	local found = {}
	for id in string.gmatch(player:GetAttribute("Discovered") or "", "[^,]+") do
		found[id] = true
	end
	local count = 0
	for _, card in cards do
		local def = card.def
		if found[def.id] then
			count += 1
			card.name.Text = def.name
			card.info.Text = ("%s  ·  +%s/s"):format(Format.rupees(def.price), Format.short(def.income))
			card.phrase.Text = '"' .. def.phrase .. '"'
			card.frame.BackgroundColor3 = rgb(70, 50, 38)
		else
			card.name.Text = "???"
			card.info.Text = def.rarity
			card.phrase.Text = if def.nightOnly then "Only comes out at night..." else "Not found yet"
			card.frame.BackgroundColor3 = rgb(35, 32, 38)
		end
	end
	bookTitle.Text = ("Collection Book  %d/%d"):format(count, #Brainrots.list)
end

player:GetAttributeChangedSignal("Discovered"):Connect(refreshBook)
refreshBook()

bookButton.Activated:Connect(function()
	book.Visible = not book.Visible
end)
closeButton.Activated:Connect(function()
	book.Visible = false
end)
