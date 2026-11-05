-- Daily quests and Collection Book rewards.
--
-- Every day (UTC) each player gets Config.QUESTS_PER_DAY quests from
-- Quests.luau. Each finished quest pays rupees (and sometimes a Kismat Roll);
-- finishing all of them pays bonus Kismat Rolls.
--
-- Discovering every brainrot of a rarity unlocks a Collection Book reward:
-- rupees and Kismat Rolls once, plus a special quest brainrot that can be
-- claimed again after every Naya Safar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Brainrots = require(Shared.Brainrots)
local Format = require(Shared.Format)
local Quests = require(Shared.Quests)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local Havelis = require(script.Parent.Havelis)

local QuestBook = {}

local function today(): number
	return math.floor(os.time() / 86400)
end

-- 12345 -> 12000, so targets and rewards look tidy.
local function tidy(n: number): number
	if n < 100 then
		return math.floor(n)
	end
	local step = 10 ^ (math.floor(math.log10(n)) - 1)
	return math.floor(n / step) * step
end

local function canOffer(profile, quest): boolean
	if quest.needs == "upgrade" then
		return profile.data.level < #Config.HAVELI_LEVELS
	elseif quest.needs == "undiscovered" then
		for _, def in Brainrots.list do
			if
				not def.questOnly
				and not def.eventOnly
				and not def.nightOnly
				and not profile.data.discovered[def.id]
			then
				return true
			end
		end
		return false
	end
	return true
end

function QuestBook.moneyTarget(profile): number
	return tidy(math.max(2_000, Havelis.incomePerSecond(profile) * 120))
end

function QuestBook.reward(profile): number
	return tidy(math.max(Config.QUEST_MIN_REWARD, Havelis.incomePerSecond(profile) * Config.QUEST_REWARD_SECONDS))
end

-- Gives the player today's quests if they do not have them yet.
function QuestBook.ensure(profile)
	local quests = profile.data.quests
	if quests.day == today() and #quests.list > 0 then
		return
	end
	local pool = {}
	for _, quest in Quests.list do
		if canOffer(profile, quest) then
			table.insert(pool, quest)
		end
	end
	local list = {}
	for _ = 1, math.min(Config.QUESTS_PER_DAY, #pool) do
		local quest = table.remove(pool, math.random(#pool))
		local target = if quest.money
			then QuestBook.moneyTarget(profile)
			else quest.targets[math.random(#quest.targets)]
		table.insert(list, { id = quest.id, target = target, progress = 0, claimed = false })
	end
	profile.data.quests = { day = today(), list = list, bonusClaimed = false }
	State.syncQuests(profile)
end

function QuestBook.track(profile, kind: string, amount: number)
	QuestBook.ensure(profile)
	local changed = false
	for _, quest in profile.data.quests.list do
		if quest.id == kind and not quest.claimed and quest.progress < quest.target then
			quest.progress = math.min(quest.target, quest.progress + amount)
			changed = true
			if quest.progress >= quest.target then
				State.notify(profile.player, "good", "Quest done! Claim your reward in the Quests menu.")
			end
		end
	end
	if changed then
		State.syncQuests(profile)
	end
end

function QuestBook.claim(player: Player, which: any)
	local profile = State.profiles[player]
	if not profile then
		return
	end
	QuestBook.ensure(profile)
	local quests = profile.data.quests
	if which == "bonus" then
		for _, quest in quests.list do
			if not quest.claimed then
				return
			end
		end
		if quests.bonusClaimed then
			return
		end
		quests.bonusClaimed = true
		profile.data.rollTokens += Config.QUEST_BONUS_ROLLS
		State.syncTokens(profile)
		State.notify(
			player,
			"rare",
			("All quests done! Here are %d free Kismat Rolls. Shabash!"):format(Config.QUEST_BONUS_ROLLS)
		)
	else
		local quest = type(which) == "number" and quests.list[which]
		if not quest or quest.claimed or quest.progress < quest.target then
			return
		end
		quest.claimed = true
		local rupees = QuestBook.reward(profile)
		State.addRupees(profile, rupees)
		local rolls = (Quests.byId[quest.id] and Quests.byId[quest.id].rolls) or 0
		if rolls > 0 then
			profile.data.rollTokens += rolls
			State.syncTokens(profile)
		end
		State.notify(
			player,
			"good",
			("Quest reward: %s%s"):format(
				Format.rupees(rupees),
				if rolls > 0 then (" and %d Kismat Roll"):format(rolls) else ""
			)
		)
	end
	State.syncQuests(profile)
end

-- How many brainrots of a rarity the player has discovered.
function QuestBook.collectionProgress(profile, rarity: string): (number, number)
	local found, total = 0, 0
	for _, def in Brainrots.byRarity[rarity] or {} do
		total += 1
		if profile.data.discovered[def.id] then
			found += 1
		end
	end
	return found, total
end

function QuestBook.claimCollection(player: Player, rarity: any)
	local profile = State.profiles[player]
	local reward = type(rarity) == "string" and Config.COLLECTION_REWARDS[rarity]
	if not profile or not reward then
		return
	end
	local found, total = QuestBook.collectionProgress(profile, rarity)
	if found < total then
		return
	end
	local data = profile.data
	local entry = data.collection[rarity] or { rewarded = false }
	data.collection[rarity] = entry
	local given = {}
	if not entry.rewarded then
		entry.rewarded = true
		State.addRupees(profile, reward.rupees)
		data.rollTokens += reward.rolls
		State.syncTokens(profile)
		table.insert(given, ("%s and %d Kismat Rolls"):format(Format.rupees(reward.rupees), reward.rolls))
	end
	local special = Brainrots.byId[reward.special]
	if special and entry.specialRebirth ~= data.rebirths then
		if Havelis.hasFreePlot(profile) then
			entry.specialRebirth = data.rebirths
			Havelis.adopt(profile, special, nil, nil, true)
			table.insert(given, special.name)
		else
			State.notify(player, "bad", ("Make room on a plot to get %s!"):format(special.name))
		end
	end
	if #given > 0 then
		State.notify(player, "rare", ("Collection Book reward: %s!"):format(table.concat(given, " and ")))
	end
	State.syncQuests(profile)
end

function QuestBook.init()
	State.tracker = QuestBook.track
	Remotes.ClaimQuest.OnServerEvent:Connect(QuestBook.claim)
	Remotes.ClaimCollection.OnServerEvent:Connect(QuestBook.claimCollection)
	-- new quests at midnight (UTC) for players who are still playing
	task.spawn(function()
		while true do
			task.wait(60)
			for _, profile in State.profiles do
				QuestBook.ensure(profile)
			end
		end
	end)
end

return QuestBook
