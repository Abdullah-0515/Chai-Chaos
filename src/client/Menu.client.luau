-- The Menu window: game passes, promo codes, your daily chai streak, the
-- Settings switches (music and sounds) and the new-player guide.
-- The server checks and saves everything.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Steps = require(Shared:WaitForChild("Tutorial"))
local Ui = require(script.Parent:WaitForChild("Ui"))

local rgb, create, label = Ui.rgb, Ui.create, Ui.label
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChaiChaosHud")
local buttons = gui:WaitForChild("Buttons")

local ROW = rgb(60, 45, 35)
local GREEN = rgb(30, 140, 80)
local GREY = rgb(110, 105, 100)
local ROBUX = rgb(40, 170, 90)
local BROWN = rgb(90, 55, 30)

local menuButton = Ui.sideButton(buttons, "Menu", "Menu", rgb(90, 90, 110), 8)
local panel, content = Ui.panel(gui, "MenuPanel", "Menu", Vector2.new(480, 600))

local function has(attribute: string, name: string): boolean
	for item in string.gmatch(player:GetAttribute(attribute) or "", "[^,]+") do
		if item == name then
			return true
		end
	end
	return false
end

local function heading(name: string, order: number, text: string): TextLabel
	return label({
		Name = name,
		Size = UDim2.new(1, -8, 0, 28),
		TextColor3 = BROWN,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
		LayoutOrder = order,
		Parent = content,
	})
end

local function row(name: string, order: number, title: string, text: string, height: number?)
	local frame = create("Frame", {
		Name = name,
		Size = UDim2.new(1, -8, 0, height or 62),
		BackgroundColor3 = ROW,
		LayoutOrder = order,
		Parent = content,
	}, { Ui.corner(10) })
	label({
		Name = "Title",
		Position = UDim2.fromOffset(10, 4),
		Size = UDim2.new(1, -150, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = title,
		Parent = frame,
	})
	label({
		Name = "Text",
		Position = UDim2.fromOffset(10, 28),
		Size = UDim2.new(1, -150, 0, (height or 62) - 32),
		TextColor3 = rgb(255, 230, 170),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Text = text,
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
	return frame, button
end

---------------------------------------------------------------------------
-- Codes (built once, so what you are typing is never wiped)
---------------------------------------------------------------------------
heading("CodesTitle", 30, "Codes")
local codeRow = create("Frame", {
	Name = "Code",
	Size = UDim2.new(1, -8, 0, 52),
	BackgroundColor3 = ROW,
	LayoutOrder = 31,
	Parent = content,
}, { Ui.corner(10) })
local codeBox = create("TextBox", {
	Name = "Box",
	Position = UDim2.fromOffset(10, 8),
	Size = UDim2.new(1, -160, 0, 36),
	BackgroundColor3 = rgb(250, 240, 220),
	Font = Ui.FONT,
	TextScaled = true,
	TextColor3 = rgb(40, 30, 25),
	PlaceholderText = "Type a code",
	Text = "",
	ClearTextOnFocus = false,
	Parent = codeRow,
}, { Ui.corner(8) })
local redeem = Ui.textButton({
	Name = "Redeem",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -8, 0.5, 0),
	Size = UDim2.fromOffset(130, 40),
	BackgroundColor3 = GREEN,
	Text = "Redeem",
	Parent = codeRow,
})
redeem.Activated:Connect(function()
	if codeBox.Text ~= "" then
		Remotes.RedeemCode:FireServer(codeBox.Text)
		codeBox.Text = ""
	end
end)

---------------------------------------------------------------------------
-- Everything else is rebuilt when something changes
---------------------------------------------------------------------------
local built: { Instance } = {}

local function refresh()
	for _, item in built do
		item:Destroy()
	end
	built = {}
	local function keep(item: Instance)
		table.insert(built, item)
	end

	-- daily chai streak
	local streak = player:GetAttribute("Streak") or 0
	local nextBonus = Config.streakRolls(streak + 1)
	local streakRow, streakButton = row(
		"Streak",
		1,
		("Daily chai: day %d in a row"):format(math.max(1, streak)),
		if nextBonus > 0
			then ("Come back tomorrow for %d extra Kismat Roll%s!"):format(
				nextBonus,
				if nextBonus == 1 then "" else "s"
			)
			else "Come back every day. From day 3 you get extra Kismat Rolls!"
	)
	streakButton.Visible = false
	keep(streakRow)

	-- game passes (hidden until their ids are in Config)
	local anyPass = false
	for i, info in Config.PASS_INFO do
		local passId = Config.GAME_PASSES[info.id]
		if passId and passId ~= 0 then
			if not anyPass then
				anyPass = true
				keep(heading("PassesTitle", 10, "Game passes"))
			end
			local frame, button = row("Pass" .. info.id, 10 + i, info.name, info.text, 70)
			if has("Passes", info.id) then
				button.Text = "Owned"
				button.BackgroundColor3 = GREY
			else
				button.Text = "Robux"
				button.BackgroundColor3 = ROBUX
				button.Activated:Connect(function()
					Remotes.BuyProduct:FireServer("pass", info.id)
				end)
			end
			keep(frame)
		end
	end

	-- settings
	keep(heading("SettingsTitle", 40, "Settings"))
	for i, setting in { { "music", "Music" }, { "sounds", "Sounds" } } do
		local on = player:GetAttribute("Settings") == nil or has("Settings", setting[1])
		local frame, button = row("Setting" .. setting[2], 40 + i, setting[2], if on then "On" else "Off", 52)
		button.Text = if on then "Turn off" else "Turn on"
		button.BackgroundColor3 = if on then GREY else GREEN
		button.Activated:Connect(function()
			Remotes.SetSetting:FireServer(setting[1], not on)
		end)
		keep(frame)
	end

	-- the guide
	keep(heading("GuideTitle", 50, "Guide"))
	local running = (player:GetAttribute("Tutorial") or "") ~= ""
	local guideRow, guideButton = row(
		"GuideRow",
		51,
		"New-player guide",
		if running
			then ("Step %d of %d. Follow the yellow line!"):format(
				player:GetAttribute("TutorialStep") or 1,
				#Steps.steps
			)
			else "Shows what to do next, one step at a time.",
		60
	)
	guideButton.Text = if running then "Hide it" else "Show it"
	guideButton.BackgroundColor3 = if running then GREY else GREEN
	guideButton.Activated:Connect(function()
		Remotes.Guide:FireServer(if running then "skip" else "restart")
	end)
	keep(guideRow)
end

menuButton.Activated:Connect(function()
	if not panel.Visible then
		refresh()
	end
	Ui.toggle(panel)
end)
for _, name in { "Passes", "Settings", "Streak", "Tutorial", "TutorialStep" } do
	player:GetAttributeChangedSignal(name):Connect(function()
		if panel.Visible then
			refresh()
		end
	end)
end
