-- The big board at the Chowk: the top players by Naya Safar, then rupees.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Format = require(Shared.Format)

local State = require(script.Parent.State)

local Leaderboard = {}

local ROWS = 9 -- a title and 8 players

local function row(list: Frame, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "Row" .. order
	label.LayoutOrder = order
	label.Size = UDim2.fromScale(1, 1 / ROWS)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = if order == 0 then Color3.fromRGB(255, 215, 80) else Color3.new(1, 1, 1)
	label.Text = if order == 0 then "TOP PLAYERS" else ""
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = list
	return label
end

function Leaderboard.refresh(rows: { TextLabel })
	local entries = {}
	for _, player in Players:GetPlayers() do
		local profile = State.profiles[player]
		if profile then
			table.insert(
				entries,
				{ name = player.DisplayName, rebirths = profile.data.rebirths, rupees = profile.data.rupees }
			)
		end
	end
	table.sort(entries, function(a, b)
		if a.rebirths ~= b.rebirths then
			return a.rebirths > b.rebirths
		end
		return a.rupees > b.rupees
	end)
	for i = 1, ROWS - 1 do
		local entry = entries[i]
		rows[i].Text = if entry
			then ("%d. %s  ·  Safar %d  ·  Rs %s"):format(i, entry.name, entry.rebirths, Format.short(entry.rupees))
			else ""
	end
end

function Leaderboard.init(map)
	local list = map.leaderboard
	if not list then
		return
	end
	list:ClearAllChildren()
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	row(list, 0)
	local rows = {}
	for i = 1, ROWS - 1 do
		rows[i] = row(list, i)
	end
	task.spawn(function()
		while true do
			Leaderboard.refresh(rows)
			task.wait(5)
		end
	end)
end

return Leaderboard
