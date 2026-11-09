-- The Chowk's shops and the Brainrots window.
--
-- Walk up to a stall in the Chowk and press E to open its window:
--   BECHO (Sell)  : the Brainrots window, where you can sell
--   GEAR SHOP     : speed, egg, treasure and hazard gear
--   RADAR WALA    : tracker upgrades
--   NAYA SAFAR    : rebirth
--   KISMAT KETTLE : the Kismat Roll window
--   QUESTS board  : the Quests window
-- The Brainrots button opens the Brainrots window anywhere.
-- (The Gaari Showroom, Ustad's Workshop and your Garage are in Garage.client.luau.)
-- The server checks that you are at the right stall before anything happens.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared:WaitForChild("Config"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Biomes = require(Shared:WaitForChild("Biomes"))
local Format = require(Shared:WaitForChild("Format"))
local Gear = require(Shared:WaitForChild("Gear"))
local Mutations = require(Shared:WaitForChild("Mutations"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Themes = require(Shared:WaitForChild("Themes"))
local Ui = require(script.Parent:WaitForChild("Ui"))

local rgb, create, label = Ui.rgb, Ui.create, Ui.label
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChaiChaosHud")
local buttons = gui:WaitForChild("Buttons")
local rupeesValue = player:WaitForChild("leaderstats"):WaitForChild("Rupees") :: IntValue
local rebirthsValue = player:WaitForChild("leaderstats"):WaitForChild("Rebirths") :: IntValue

local ROW = rgb(60, 45, 35)
local GREEN = rgb(30, 140, 80)
local GREY = rgb(110, 105, 100)
local BLUE = rgb(50, 120, 200)
local RED = rgb(190, 70, 50)

local function attribute(name: string, default: any): any
	local value = player:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

-- A list row: a dark box with a title line, a small text line and a button on the right.
local function row(parent: Instance, name: string, order: number, height: number?)
	local frame = create("Frame", {
		Name = name,
		Size = UDim2.new(1, -8, 0, height or 62),
		BackgroundColor3 = ROW,
		LayoutOrder = order,
		Parent = parent,
	}, { Ui.corner(10) })
	local title = label({
		Name = "Title",
		Position = UDim2.fromOffset(10, 4),
		Size = UDim2.new(1, -150, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	local text = label({
		Name = "Text",
		Position = UDim2.fromOffset(10, 32),
		Size = UDim2.new(1, -150, 0, 22),
		TextColor3 = rgb(255, 230, 170),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	local button = Ui.textButton({
		Name = "Button",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(130, 40),
		BackgroundColor3 = GREEN,
		Parent = frame,
	})
	return frame, title, text, button
end

local function info(parent: Instance, name: string, order: number, height: number, color: Color3?): TextLabel
	return label({
		Name = name,
		Size = UDim2.new(1, -8, 0, height),
		TextColor3 = color or rgb(90, 55, 30),
		TextWrapped = true,
		LayoutOrder = order,
		Parent = parent,
	})
end

-- the stall parts in the Chowk, to know whether we are standing at one
local stalls: { [string]: BasePart } = {}
local function shopPart(shop: string): BasePart?
	local known = stalls[shop]
	if known and known.Parent then
		return known
	end
	local map = workspace:FindFirstChild("ChaiChaosMap")
	if not map then
		return nil
	end
	for _, d in map:GetDescendants() do
		if d:IsA("BasePart") and type(d:GetAttribute("Shop")) == "string" then
			stalls[d:GetAttribute("Shop")] = d
		end
	end
	return stalls[shop]
end

local function isNear(shop: string, distance: number): boolean
	local part = shopPart(shop)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return part ~= nil
		and root ~= nil
		and root:IsA("BasePart")
		and (root.Position - part.Position).Magnitude <= distance
end

---------------------------------------------------------------------------
-- Gear shop
---------------------------------------------------------------------------
local gearPanel, gearContent = Ui.panel(gui, "GearPanel", "Gear Shop", Vector2.new(480, 580))
info(gearContent, "Intro", 0, 40, nil).Text = "Gear is yours forever, even after a Naya Safar. It works by itself!"
local KIND_TEXT = { speed = "Speed", egg = "Egg care", treasure = "Treasure", hazard = "Hazard" }
local gearRows = {}
for i, item in Gear.list do
	local _, title, text, button = row(gearContent, item.id, i)
	title.Text = ("%s  ·  %s"):format(item.name, KIND_TEXT[item.kind] or item.kind)
	text.Text = item.text
	button.Activated:Connect(function()
		Remotes.BuyGear:FireServer(item.id)
	end)
	gearRows[item.id] = { item = item, button = button }
end

local function refreshGear()
	local owned = Gear.decode(attribute("Gear", ""))
	for id, r in gearRows do
		if owned[id] then
			r.button.Text = "Owned"
			r.button.BackgroundColor3 = GREY
		else
			r.button.Text = Format.rupees(r.item.cost)
			r.button.BackgroundColor3 = if rupeesValue.Value >= r.item.cost then GREEN else GREY
		end
	end
end

---------------------------------------------------------------------------
-- Radar Wala (tracker)
---------------------------------------------------------------------------
local trackerPanel, trackerContent = Ui.panel(gui, "TrackerPanel", "Radar Wala", Vector2.new(480, 580))
local trackerNow = info(trackerContent, "Now", 1, 50, nil)
local trackerNext = info(trackerContent, "Next", 2, 50, rgb(40, 110, 60))
local trackerButton = Ui.textButton({
	Name = "Upgrade",
	Size = UDim2.new(1, -8, 0, 46),
	BackgroundColor3 = GREEN,
	LayoutOrder = 3,
	Parent = trackerContent,
})
trackerButton.Activated:Connect(function()
	Remotes.UpgradeTracker:FireServer()
end)

local function levelText(level: number): string
	local t = Config.TRACKER_LEVELS[level]
	local extras = {}
	if t.golden then
		table.insert(extras, "golden eggs")
	end
	if t.treasure then
		table.insert(extras, "treasure")
	end
	return ("Finds eggs %d studs away%s"):format(
		t.range,
		if #extras > 0 then " · shows " .. table.concat(extras, " and ") else ""
	)
end

local trackerRows = {}
for level, t in Config.TRACKER_LEVELS do
	local _, title, text, button = row(trackerContent, "Level" .. level, 10 + level, 58)
	title.Text = ("Level %d"):format(level)
	text.Text = levelText(level)
	button.Text = if t.cost > 0 then Format.rupees(t.cost) else "Free"
	button.AutoButtonColor = false
	trackerRows[level] = button
end

local function refreshTracker()
	local level = attribute("TrackerLevel", 1)
	local open = Biomes.decode(attribute("OpenZones", ""))
	local count = 0
	for _ in open do
		count += 1
	end
	trackerNow.Text = ("Your radar: Level %d. It tracks eggs in your %d open zone%s."):format(
		level,
		count,
		if count == 1 then "" else "s"
	)
	local nextLevel = Config.TRACKER_LEVELS[level + 1]
	if nextLevel then
		trackerNext.Text = ("Next: %s"):format(levelText(level + 1))
		trackerButton.Text = "Upgrade for " .. Format.rupees(nextLevel.cost)
		trackerButton.BackgroundColor3 = if rupeesValue.Value >= nextLevel.cost then GREEN else GREY
	else
		trackerNext.Text = "Your radar finds everything. Kamaal!"
		trackerButton.Text = "Max level!"
		trackerButton.BackgroundColor3 = GREY
	end
	for i, button in trackerRows do
		button.BackgroundColor3 = if i <= level then GREEN elseif i == level + 1 then BLUE else GREY
		button.Text = if i <= level
			then "Have it"
			else (if Config.TRACKER_LEVELS[i].cost > 0
				then Format.rupees(Config.TRACKER_LEVELS[i].cost)
				else "Free")
	end
end

---------------------------------------------------------------------------
-- Brainrots (see them all, and sell at the BECHO stall)
---------------------------------------------------------------------------
local brainrotButton = Ui.sideButton(buttons, "Brainrots", "Brainrots", rgb(220, 90, 140), 6)
local brainrotPanel, brainrotContent = Ui.panel(gui, "BrainrotPanel", "Meri Brainrots", Vector2.new(500, 600))
local sellInfo = info(brainrotContent, "SellInfo", 3, 40, nil)

local brainrotRows: { Frame } = {}
local NEAR_SELL = Config.SELL_DISTANCE - 2

local function parseOwned()
	local list = {}
	for item in string.gmatch(attribute("Owned", ""), "[^,]+") do
		local uid, key, carried = item:match("^(%d+)|([^|]+)|(%d)$")
		if uid then
			local id, mutation = Mutations.parse(key)
			local def = Brainrots.byId[id]
			if def then
				table.insert(list, { uid = tonumber(uid), def = def, mutation = mutation, carried = carried == "1" })
			end
		end
	end
	table.sort(list, function(a, b)
		local av, bv = Mutations.value(a.def, a.mutation), Mutations.value(b.def, b.mutation)
		if av ~= bv then
			return av > bv
		end
		return a.uid < b.uid
	end)
	return list
end

local function refreshBrainrots()
	local nearSell = isNear("Sell", NEAR_SELL)
	sellInfo.Text = if nearSell
		then "You are at the BECHO stall: sell for half the value."
		else "To sell, come to the BECHO stall in the Chowk."

	for _, frame in brainrotRows do
		frame:Destroy()
	end
	table.clear(brainrotRows)
	for i, item in parseOwned() do
		local def, mutation = item.def, item.mutation
		local frame, title, text, stealButton = row(brainrotContent, "Brainrot" .. i, 10 + i, 62)
		stealButton:Destroy()
		title.Text = Mutations.displayName(def, mutation)
		title.TextColor3 = if mutation then Mutations.byId[mutation].color else Brainrots.RARITY_COLORS[def.rarity]
		text.Text = ("%s · +%s/s · worth %s"):format(
			def.rarity,
			Format.short(Mutations.income(def, mutation)),
			Format.short(Mutations.value(def, mutation))
		)
		if nearSell and not def.questOnly then
			local sell = Ui.textButton({
				Name = "Sell",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(64, 40),
				BackgroundColor3 = if item.carried then GREY else RED,
				Text = Format.short(math.floor(Mutations.value(def, mutation) * Config.SELL_RATE)),
				Parent = frame,
			})
			sell.Activated:Connect(function()
				if not item.carried then
					Remotes.SellBrainrot:FireServer(item.uid)
				end
			end)
		end
		table.insert(brainrotRows, frame)
	end
	if #brainrotRows == 0 then
		local empty = info(brainrotContent, "Empty", 10, 40, nil)
		empty.Text = "No brainrots yet! Bring eggs home from the zones to hatch some."
		table.insert(brainrotRows, empty :: any)
	end
end

brainrotButton.Activated:Connect(function()
	if not brainrotPanel.Visible then
		refreshBrainrots()
	end
	Ui.toggle(brainrotPanel)
end)

---------------------------------------------------------------------------
-- Naya Safar (rebirth)
---------------------------------------------------------------------------
local rebirthPanel, rebirthContent = Ui.panel(gui, "RebirthPanel", "Naya Safar", Vector2.new(480, 560))
local rebirthCost = info(rebirthContent, "Cost", 1, 50, nil)
local rebirthBonus = info(rebirthContent, "Bonus", 2, 40, rgb(40, 110, 60))
info(rebirthContent, "Resets", 3, 56, rgb(150, 60, 40)).Text =
	"Starts over: rupees, haveli level, radar level, brainrots and eggs."
info(rebirthContent, "Keeps", 4, 56, rgb(40, 90, 150)).Text =
	"You keep: gear, vehicles, unlocked zones, haveli themes, the Collection Book, Kismat Rolls and Chor Passes."
local rebirthTheme = info(rebirthContent, "Theme", 5, 40, rgb(130, 50, 160))
local rebirthButton = Ui.textButton({
	Name = "Rebirth",
	Size = UDim2.new(1, -8, 0, 50),
	BackgroundColor3 = rgb(150, 70, 205),
	LayoutOrder = 6,
	Parent = rebirthContent,
})

local confirmUntil = 0
local function refreshRebirth()
	local cost = attribute("RebirthCost", Config.REBIRTH_COST)
	local rebirths = rebirthsValue.Value
	rebirthCost.Text = ("Naya Safar %d costs %s. You have %s."):format(
		rebirths + 1,
		Format.rupees(cost),
		Format.rupees(rupeesValue.Value)
	)
	rebirthBonus.Text = ("Income bonus: +%d%% now, +%d%% after."):format(
		math.floor(Config.REBIRTH_BONUS * rebirths * 100 + 0.5),
		math.floor(Config.REBIRTH_BONUS * (rebirths + 1) * 100 + 0.5)
	)
	local unlock = nil
	for _, theme in Themes.list do
		if theme.rebirths == rebirths + 1 then
			unlock = theme
		end
	end
	local zone = nil
	for _, biome in Biomes.list do
		if biome.rebirths == rebirths + 1 then
			zone = biome
		end
	end
	local texts = {}
	if zone then
		table.insert(texts, ("Opens the gate to %s!"):format(zone.name))
	end
	if unlock then
		table.insert(texts, ("Unlocks the %s haveli theme: %s"):format(unlock.name, unlock.perkText))
	end
	rebirthTheme.Text = if #texts > 0
		then table.concat(texts, " ")
		else "Every Naya Safar makes you earn more, forever."
	if os.clock() >= confirmUntil then
		rebirthButton.Text = if rupeesValue.Value >= cost then "Start Naya Safar!" else "Not enough rupees yet"
	end
	rebirthButton.BackgroundColor3 = if rupeesValue.Value >= cost then rgb(150, 70, 205) else GREY
end

rebirthButton.Activated:Connect(function()
	if rupeesValue.Value < attribute("RebirthCost", Config.REBIRTH_COST) then
		return
	end
	if os.clock() < confirmUntil then
		confirmUntil = 0
		Remotes.Rebirth:FireServer()
		rebirthPanel.Visible = false
	else
		confirmUntil = os.clock() + 4
		rebirthButton.Text = "Sure? Tap again"
		task.delay(4.1, refreshRebirth)
	end
end)

---------------------------------------------------------------------------
-- Opening windows from the stalls
---------------------------------------------------------------------------
local OPEN = {
	Gear = function()
		refreshGear()
		Ui.open(gearPanel)
	end,
	Tracker = function()
		refreshTracker()
		Ui.open(trackerPanel)
	end,
	Sell = function()
		refreshBrainrots()
		Ui.open(brainrotPanel)
	end,
	Rebirth = function()
		refreshRebirth()
		Ui.open(rebirthPanel)
	end,
	Kismat = function()
		local panel = gui:FindFirstChild("KismatPanel")
		if panel then
			Ui.open(panel)
		end
	end,
	Quests = function()
		local panel = gui:FindFirstChild("QuestPanel")
		if panel then
			Ui.open(panel)
		end
	end,
}

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, who: Player)
	if who ~= player or prompt.Name ~= "ShopPrompt" then
		return
	end
	local open = OPEN[prompt:GetAttribute("Shop") or ""]
	if open then
		open()
	end
end)

for _, name in { "Gear", "TrackerLevel" } do
	player:GetAttributeChangedSignal(name):Connect(function()
		refreshGear()
		refreshTracker()
	end)
end
player:GetAttributeChangedSignal("Owned"):Connect(function()
	if brainrotPanel.Visible then
		refreshBrainrots()
	end
end)
player:GetAttributeChangedSignal("OpenZones"):Connect(refreshTracker)
rupeesValue.Changed:Connect(function()
	refreshGear()
	refreshTracker()
	if rebirthPanel.Visible then
		refreshRebirth()
	end
end)
refreshGear()
refreshTracker()
refreshRebirth()

-- the Sell buttons appear and disappear as you walk to and from the stall
task.spawn(function()
	local wasNear = false
	while gui.Parent do
		if brainrotPanel.Visible then
			local near = isNear("Sell", NEAR_SELL)
			if near ~= wasNear then
				wasNear = near
				refreshBrainrots()
			end
		end
		task.wait(0.5)
	end
end)
