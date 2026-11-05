-- The Haveli window: upgrade your haveli and pick its theme.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Themes = require(Shared:WaitForChild("Themes"))
local Ui = require(script.Parent:WaitForChild("Ui"))

local rgb = Ui.rgb
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChaiChaosHud")
local buttons = gui:WaitForChild("Buttons")
local leaderstats = player:WaitForChild("leaderstats")
local rupeesValue = leaderstats:WaitForChild("Rupees") :: IntValue
local rebirthsValue = leaderstats:WaitForChild("Rebirths") :: IntValue

local CARD_COLOR = rgb(60, 45, 35)
local GREEN = rgb(40, 160, 80)
local GREY = rgb(110, 105, 100)

local haveliButton = Ui.sideButton(buttons, "Haveli", "Haveli", rgb(200, 120, 40), 2)
local panel, content = Ui.panel(gui, "HaveliPanel", "Meri Haveli", Vector2.new(460, 560))
haveliButton.Activated:Connect(function()
	Ui.toggle(panel)
end)

local order = 0
local function add(props)
	order += 1
	props.LayoutOrder = order
	props.Parent = content
	return props
end

local levelLabel = Ui.label(add({ Name = "Level", Size = UDim2.new(1, 0, 0, 30), TextColor3 = Ui.GOLD }))
local nextLabel = Ui.label(add({ Name = "Next", Size = UDim2.new(1, 0, 0, 44), TextWrapped = true }))
local upgradeButton = Ui.textButton(add({ Name = "Upgrade", Size = UDim2.new(1, 0, 0, 46), BackgroundColor3 = GREEN }))
upgradeButton.Activated:Connect(function()
	Remotes.UpgradeHaveli:FireServer()
end)
Ui.label(add({
	Name = "ThemesTitle",
	Size = UDim2.new(1, 0, 0, 28),
	Text = "Haveli Themes",
	TextColor3 = Ui.GOLD,
}))

local cards = {}
for _, theme in Themes.list do
	local card =
		Ui.create("Frame", add({ Name = theme.id, Size = UDim2.new(1, 0, 0, 74), BackgroundColor3 = CARD_COLOR }), {
			Ui.corner(10),
		})
	for i, color in { theme.wall, theme.trim, theme.accent } do
		Ui.create("Frame", {
			Name = "Swatch",
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.fromOffset(8 + (i - 1) * 20, 8),
			BackgroundColor3 = color,
			Parent = card,
		}, { Ui.corner(8) })
	end
	Ui.label({
		Name = "Name",
		Size = UDim2.new(1, -170, 0, 22),
		Position = UDim2.fromOffset(72, 4),
		Text = theme.name,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	Ui.label({
		Name = "Perk",
		Size = UDim2.new(1, -120, 0, 40),
		Position = UDim2.fromOffset(8, 30),
		Text = theme.perkText,
		TextWrapped = true,
		TextColor3 = rgb(255, 230, 150),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	local use = Ui.textButton({
		Name = "Use",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(100, 40),
		BackgroundColor3 = GREEN,
		Parent = card,
	})
	use.Activated:Connect(function()
		Remotes.SetTheme:FireServer(theme.id)
	end)
	cards[theme.id] = { theme = theme, button = use }
end

local function refresh()
	local level = player:GetAttribute("HaveliLevel") or 1
	local info = Config.HAVELI_LEVELS[level]
	levelLabel.Text = ("Level %d · %s · %d plots"):format(level, info.name, info.plots)
	local nextInfo = Config.HAVELI_LEVELS[level + 1]
	if nextInfo then
		nextLabel.Text = ("Next: %s · %d plots%s"):format(
			nextInfo.name,
			nextInfo.plots,
			if nextInfo.unlock then " · " .. nextInfo.unlock else ""
		)
		upgradeButton.Text = "Upgrade for " .. Format.rupees(nextInfo.cost)
		upgradeButton.BackgroundColor3 = if rupeesValue.Value >= nextInfo.cost then GREEN else GREY
	else
		nextLabel.Text = "Your haveli is as big and fancy as it gets. Shahi!"
		upgradeButton.Text = "Max level!"
		upgradeButton.BackgroundColor3 = GREY
	end

	local current = player:GetAttribute("Theme")
	local rebirths = rebirthsValue.Value
	for id, card in cards do
		local button = card.button
		if id == current then
			button.Text = "Using"
			button.BackgroundColor3 = Ui.GOLD:Lerp(rgb(0, 0, 0), 0.3)
		elseif rebirths >= card.theme.rebirths then
			button.Text = "Use"
			button.BackgroundColor3 = GREEN
		else
			button.Text = ("Safar %d"):format(card.theme.rebirths)
			button.BackgroundColor3 = GREY
		end
	end
	haveliButton.Text = ("Haveli Lv %d"):format(level)
end

for _, name in { "HaveliLevel", "Theme" } do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end
rupeesValue.Changed:Connect(refresh)
rebirthsValue.Changed:Connect(refresh)
refresh()
