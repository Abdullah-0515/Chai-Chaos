-- The Quests window: today's quests and the Collection Book rewards.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared:WaitForChild("Config"))
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Format = require(Shared:WaitForChild("Format"))
local Quests = require(Shared:WaitForChild("Quests"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Ui = require(script.Parent:WaitForChild("Ui"))

local rgb = Ui.rgb
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChaiChaosHud")
local buttons = gui:WaitForChild("Buttons")

local CARD_COLOR = rgb(60, 45, 35)
local GREEN = rgb(40, 160, 80)
local GREY = rgb(110, 105, 100)
local BAR_COLOR = rgb(255, 190, 40)

local questButton = Ui.sideButton(buttons, "Quests", "Quests", rgb(40, 150, 140), 4)
local panel, content = Ui.panel(gui, "QuestPanel", "Quests", Vector2.new(460, 560))
questButton.Activated:Connect(function()
	Ui.toggle(panel)
end)

local order = 0
local function add(props)
	order += 1
	props.LayoutOrder = order
	props.Parent = content
	return props
end

local resetLabel = Ui.label(add({ Name = "Reset", Size = UDim2.new(1, 0, 0, 22), TextColor3 = rgb(160, 230, 255) }))

local function claimButton(parent: Instance, onClick: () -> ()): TextButton
	local button = Ui.textButton({
		Name = "Claim",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(90, 36),
		BackgroundColor3 = GREEN,
		Text = "Claim",
		Parent = parent,
	})
	button.Activated:Connect(onClick)
	return button
end

local questRows = {}
for i = 1, Config.QUESTS_PER_DAY do
	local row =
		Ui.create("Frame", add({ Name = "Quest" .. i, Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = CARD_COLOR }), {
			Ui.corner(10),
		})
	local text = Ui.label({
		Name = "Text",
		Size = UDim2.new(1, -112, 0, 26),
		Position = UDim2.fromOffset(8, 4),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = row,
	})
	local barBack = Ui.create("Frame", {
		Name = "Bar",
		Size = UDim2.new(1, -112, 0, 10),
		Position = UDim2.fromOffset(8, 34),
		BackgroundColor3 = rgb(35, 28, 22),
		Parent = row,
	}, { Ui.corner(5) })
	local fill = Ui.create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = BAR_COLOR,
		Parent = barBack,
	}, { Ui.corner(5) })
	local reward = Ui.label({
		Name = "Reward",
		Size = UDim2.new(1, -112, 0, 18),
		Position = UDim2.fromOffset(8, 48),
		TextColor3 = rgb(255, 230, 150),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local claim = claimButton(row, function()
		Remotes.ClaimQuest:FireServer(i)
	end)
	questRows[i] = { row = row, text = text, fill = fill, reward = reward, claim = claim }
end

local bonusRow =
	Ui.create("Frame", add({ Name = "Bonus", Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = CARD_COLOR }), {
		Ui.corner(10),
	})
local bonusText = Ui.label({
	Size = UDim2.new(1, -112, 1, -8),
	Position = UDim2.fromOffset(8, 4),
	Text = ("Finish all quests: +%d Kismat Rolls"):format(Config.QUEST_BONUS_ROLLS),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextWrapped = true,
	Parent = bonusRow,
})
local bonusClaim = claimButton(bonusRow, function()
	Remotes.ClaimQuest:FireServer("bonus")
end)

Ui.label(add({
	Name = "CollectionTitle",
	Size = UDim2.new(1, 0, 0, 28),
	Text = "Collection Book Rewards",
	TextColor3 = Ui.GOLD,
}))

local collectionRows = {}
for _, rarity in Brainrots.RARITY_ORDER do
	local reward = Config.COLLECTION_REWARDS[rarity]
	local special = Brainrots.byId[reward.special]
	local row =
		Ui.create("Frame", add({ Name = rarity, Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = CARD_COLOR }), {
			Ui.corner(10),
		})
	local title = Ui.label({
		Name = "Title",
		Size = UDim2.new(1, -112, 0, 24),
		Position = UDim2.fromOffset(8, 4),
		TextColor3 = Brainrots.RARITY_COLORS[rarity],
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	Ui.label({
		Name = "Prize",
		Size = UDim2.new(1, -112, 0, 20),
		Position = UDim2.fromOffset(8, 30),
		Text = if special
			then ("%s + %d rolls + %s"):format(Format.rupees(reward.rupees), reward.rolls, special.name)
			else ("%s + %d rolls"):format(Format.rupees(reward.rupees), reward.rolls),
		TextColor3 = rgb(255, 230, 150),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = row,
	})
	local claim = claimButton(row, function()
		Remotes.ClaimCollection:FireServer(rarity)
	end)
	collectionRows[rarity] = { title = title, claim = claim }
end

local state = nil

local function tidy(n: number): number
	if n < 100 then
		return math.floor(n)
	end
	local step = 10 ^ (math.floor(math.log10(n)) - 1)
	return math.floor(n / step) * step
end

local function refresh()
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(player:GetAttribute("QuestState") or "{}")
	end)
	state = if ok and type(decoded) == "table" then decoded else {}
	local quests = (state.quests and state.quests.list) or {}
	local claimable = false

	local reward =
		tidy(math.max(Config.QUEST_MIN_REWARD, (player:GetAttribute("Income") or 0) * Config.QUEST_REWARD_SECONDS))
	local allClaimed = #quests > 0
	for i, rowInfo in questRows do
		local quest = quests[i]
		local def = quest and Quests.byId[quest.id]
		rowInfo.row.Visible = def ~= nil
		if quest and def then
			local target = if def.money then Format.rupees(quest.target) else tostring(quest.target)
			rowInfo.text.Text = def.text:format(target)
			local progress = math.min(quest.progress, quest.target)
			rowInfo.fill.Size = UDim2.fromScale(progress / math.max(quest.target, 1), 1)
			local rolls = def.rolls or 0
			rowInfo.reward.Text = ("Reward: %s%s  ·  %s/%s"):format(
				Format.rupees(reward),
				if rolls > 0 then (" + %d Kismat Roll"):format(rolls) else "",
				if def.money then Format.short(progress) else tostring(progress),
				if def.money then Format.short(quest.target) else tostring(quest.target)
			)
			local done = quest.progress >= quest.target
			rowInfo.claim.Text = if quest.claimed then "Done" elseif done then "Claim" else "..."
			rowInfo.claim.BackgroundColor3 = if done and not quest.claimed then GREEN else GREY
			claimable = claimable or (done and not quest.claimed)
			allClaimed = allClaimed and quest.claimed
		end
	end
	local bonusDone = state.quests and state.quests.bonusClaimed
	bonusClaim.Text = if bonusDone then "Done" elseif allClaimed then "Claim" else "..."
	bonusClaim.BackgroundColor3 = if allClaimed and not bonusDone then GREEN else GREY
	bonusText.TextTransparency = if bonusDone then 0.5 else 0
	claimable = claimable or (allClaimed and not bonusDone)

	local found = {}
	for id in string.gmatch(player:GetAttribute("Discovered") or "", "[^,]+") do
		found[id] = true
	end
	local rebirths = state.rebirths or 0
	for rarity, rowInfo in collectionRows do
		local have, total = 0, 0
		for _, def in Brainrots.byRarity[rarity] do
			total += 1
			if found[def.id] then
				have += 1
			end
		end
		local entry = state.collection and state.collection[rarity]
		local complete = have >= total
		local open = complete and (not entry or not entry.rewarded or entry.specialRebirth ~= rebirths)
		rowInfo.title.Text = ("%s  %d/%d"):format(rarity, have, total)
		rowInfo.claim.Text = if open then "Claim" elseif complete then "Done" else "..."
		rowInfo.claim.BackgroundColor3 = if open then GREEN else GREY
		claimable = claimable or open
	end

	questButton.Text = if claimable then "Quests (!)" else "Quests"
end

local function formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return ("%d:%02d:%02d"):format(seconds // 3600, (seconds // 60) % 60, seconds % 60)
end

for _, name in { "QuestState", "Discovered", "Income" } do
	player:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()

task.spawn(function()
	while gui.Parent do
		local untilReset = 86400 - (os.time() % 86400)
		resetLabel.Text = "New quests in " .. formatTime(untilReset)
		task.wait(1)
	end
end)
