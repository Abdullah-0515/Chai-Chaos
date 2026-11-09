-- Vehicle windows:
--   Gaari button      : your vehicles. Drive one, park, and pick a paint job.
--   Gaari Showroom    : buy vehicles (at the Rickshaw Stand in the bazaar).
--   Ustad's Workshop  : upgrade Engine, Fuel Tank, Egg Space and Tyres
--                       (in the Chai Dhaba Bazaar), and buy Robux paint jobs.
-- The server checks you are at the right place before anything happens.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Vehicles = require(Shared:WaitForChild("Vehicles"))
local Ui = require(script.Parent:WaitForChild("Ui"))

local rgb, create, label = Ui.rgb, Ui.create, Ui.label
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChaiChaosHud")
local buttons = gui:WaitForChild("Buttons")
local rupeesValue = player:WaitForChild("leaderstats"):WaitForChild("Rupees") :: IntValue

local ROW = rgb(60, 45, 35)
local GREEN = rgb(30, 140, 80)
local GREY = rgb(110, 105, 100)
local BLUE = rgb(50, 120, 200)
local RED = rgb(190, 70, 50)
local ROBUX = rgb(40, 170, 90)

-- "Motorbike:2:1:0:0:1450,...": owned vehicles with their upgrade levels and fuel
local function owned(): { [string]: { speed: number, tank: number, eggs: number, grip: number, fuel: number } }
	local list = {}
	for item in string.gmatch(player:GetAttribute("Vehicles") or "", "[^,]+") do
		local id, speed, tank, eggs, grip, fuel = item:match("^(%w+):(%d+):(%d+):(%d+):(%d+):(%d+)$")
		if id and Vehicles.byId[id] then
			list[id] = {
				speed = tonumber(speed) :: number,
				tank = tonumber(tank) :: number,
				eggs = tonumber(eggs) :: number,
				grip = tonumber(grip) :: number,
				fuel = tonumber(fuel) :: number,
			}
		end
	end
	return list
end

local function row(parent: Instance, name: string, order: number, height: number?)
	local frame = create("Frame", {
		Name = name,
		Size = UDim2.new(1, -8, 0, height or 70),
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
		Size = UDim2.new(1, -150, 0, (height or 70) - 38),
		TextColor3 = rgb(255, 230, 170),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Parent = frame,
	})
	local button = Ui.textButton({
		Name = "Button",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(130, 42),
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

local function stats(def, levels): string
	return ("Speed %d  ·  Range %d  ·  Boot %d eggs  ·  Tyres %d"):format(
		math.floor(Vehicles.speed(def, levels)),
		Vehicles.tank(def, levels),
		Vehicles.eggs(def, levels),
		Vehicles.grip(def, levels)
	)
end

local function clear(content: Instance)
	for _, child in content:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

---------------------------------------------------------------------------
-- Gaari: your vehicles
---------------------------------------------------------------------------
local garageButton = Ui.sideButton(buttons, "Gaari", "Gaari", rgb(60, 150, 70), 5)
local garagePanel, garageContent = Ui.panel(gui, "GaragePanel", "Meri Gaari", Vector2.new(500, 600))

local function paintRows(parent: Instance, start: number, atWorkshop: boolean)
	local have = {}
	for id in string.gmatch(player:GetAttribute("Paints") or "", "[^,]+") do
		have[id] = true
	end
	local current = player:GetAttribute("Paint") or "Factory"
	info(parent, "PaintTitle", start, 30, rgb(130, 50, 160)).Text = "Paint jobs (looks only)"
	for i, paint in Vehicles.PAINTS do
		local productId = Config.PAINT_PRODUCTS[paint.id]
		local mine = paint.id == "Factory" or have[paint.id]
		if mine or (atWorkshop and productId and productId ~= 0) then
			local _, title, text, button = row(parent, "Paint" .. paint.id, start + i, 62)
			title.Text = paint.name
			text.Text = paint.text
			if paint.id == current then
				button.Text = "Painted"
				button.BackgroundColor3 = GREY
			elseif mine then
				button.Text = "Use"
				button.BackgroundColor3 = BLUE
				button.Activated:Connect(function()
					Remotes.SetPaint:FireServer(paint.id)
				end)
			else
				button.Text = "Robux"
				button.BackgroundColor3 = ROBUX
				button.Activated:Connect(function()
					Remotes.BuyProduct:FireServer("paint", paint.id)
				end)
			end
		end
	end
end

local function refreshGarage()
	clear(garageContent)
	local mine = owned()
	local driving = player:GetAttribute("Driving") or ""
	local any = false
	if driving ~= "" then
		local park = Ui.textButton({
			Name = "Park",
			Size = UDim2.new(1, -8, 0, 44),
			BackgroundColor3 = RED,
			Text = "Park and get out",
			LayoutOrder = 1,
			Parent = garageContent,
		})
		park.Activated:Connect(function()
			Remotes.Drive:FireServer(nil)
			garagePanel.Visible = false
		end)
	end
	for i, def in Vehicles.list do
		local levels = mine[def.id]
		if levels then
			any = true
			local tank = Vehicles.tank(def, Vehicles.levels(levels))
			local _, title, text, button = row(garageContent, def.id, 10 + i, 74)
			title.Text = def.name
			text.Text = ("%s\nPetrol: %d / %d"):format(stats(def, Vehicles.levels(levels)), levels.fuel, tank)
			if driving == def.id then
				button.Text = "Driving"
				button.BackgroundColor3 = GREY
			else
				button.Text = "Drive"
				button.Activated:Connect(function()
					Remotes.Drive:FireServer(def.id)
					garagePanel.Visible = false
				end)
			end
		end
	end
	if not any then
		info(garageContent, "None", 10, 70, nil).Text = "No vehicle yet! Visit the Gaari Showroom at the Rickshaw Stand in the bazaar. A Motorbike costs "
			.. Format.rupees(Vehicles.byId.Motorbike.cost)
			.. "."
	end
	paintRows(garageContent, 40, false)
end

garageButton.Activated:Connect(function()
	if not garagePanel.Visible then
		refreshGarage()
	end
	Ui.toggle(garagePanel)
end)

---------------------------------------------------------------------------
-- Gaari Showroom
---------------------------------------------------------------------------
local showroomPanel, showroomContent = Ui.panel(gui, "ShowroomPanel", "Gaari Showroom", Vector2.new(500, 600))

local function refreshShowroom()
	clear(showroomContent)
	info(showroomContent, "Intro", 0, 46, nil).Text =
		"Vehicles are yours forever, even after a Naya Safar. Faster than walking, and eggs ride in the boot!"
	local mine = owned()
	for i, def in Vehicles.list do
		local _, title, text, button = row(showroomContent, def.id, i, 92)
		title.Text = def.name
		text.Text = def.text .. "\n" .. stats(def, Vehicles.levels(nil))
		if mine[def.id] then
			button.Text = "Owned"
			button.BackgroundColor3 = GREY
		else
			button.Text = Format.rupees(def.cost)
			button.BackgroundColor3 = if rupeesValue.Value >= def.cost then GREEN else GREY
			button.Activated:Connect(function()
				Remotes.BuyVehicle:FireServer(def.id)
			end)
		end
	end
end

---------------------------------------------------------------------------
-- Ustad's Workshop
---------------------------------------------------------------------------
local workshopPanel, workshopContent = Ui.panel(gui, "WorkshopPanel", "Ustad's Workshop", Vector2.new(500, 620))

local function refreshWorkshop()
	clear(workshopContent)
	local mine = owned()
	local order = 0
	local any = false
	for _, def in Vehicles.list do
		local saved = mine[def.id]
		if saved then
			any = true
			order += 1
			info(workshopContent, def.id .. "Title", order, 30, rgb(40, 90, 150)).Text = def.name
			local levels = Vehicles.levels(saved)
			for _, upgrade in Vehicles.UPGRADES do
				order += 1
				local level = (levels :: any)[upgrade.id]
				local max = Vehicles.maxLevel(def, upgrade.id)
				local _, title, text, button = row(workshopContent, def.id .. upgrade.id, order, 62)
				title.Text = ("%s  ·  level %d/%d"):format(upgrade.name, level, max)
				text.Text = upgrade.text
				if max == 0 then
					text.Text = "Already the best tyres there are!"
					button.Text = "Max"
					button.BackgroundColor3 = GREY
				elseif level >= max then
					button.Text = "Max"
					button.BackgroundColor3 = GREY
				else
					local cost = Vehicles.upgradeCost(def, upgrade.id, level + 1)
					button.Text = Format.rupees(cost)
					button.BackgroundColor3 = if rupeesValue.Value >= cost then GREEN else GREY
					button.Activated:Connect(function()
						Remotes.UpgradeVehicle:FireServer(def.id, upgrade.id)
					end)
				end
			end
		end
	end
	if not any then
		info(workshopContent, "None", 1, 60, nil).Text =
			"Ustad says: bring me a vehicle! Buy one at the Gaari Showroom first."
	end
	paintRows(workshopContent, 100, true)
end

---------------------------------------------------------------------------
-- Opening and refreshing
---------------------------------------------------------------------------
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, who: Player)
	if who ~= player or prompt.Name ~= "ShopPrompt" then
		return
	end
	local shop = prompt:GetAttribute("Shop")
	if shop == "Showroom" then
		refreshShowroom()
		Ui.open(showroomPanel)
	elseif shop == "Workshop" then
		refreshWorkshop()
		Ui.open(workshopPanel)
	end
end)

local function refreshOpen()
	if garagePanel.Visible then
		refreshGarage()
	end
	if showroomPanel.Visible then
		refreshShowroom()
	end
	if workshopPanel.Visible then
		refreshWorkshop()
	end
end
for _, name in { "Vehicles", "Driving", "Paint", "Paints" } do
	player:GetAttributeChangedSignal(name):Connect(refreshOpen)
end
rupeesValue.Changed:Connect(function()
	if showroomPanel.Visible then
		refreshShowroom()
	end
	if workshopPanel.Visible then
		refreshWorkshop()
	end
end)
