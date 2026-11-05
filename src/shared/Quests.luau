-- Daily quest types. Every day each player gets Config.QUESTS_PER_DAY of them.
--
-- text    : shown to the player; %s is the target
-- targets : one is picked at random
-- money   : the target is an amount of rupees that grows with your income
-- rolls   : extra Kismat Rolls on top of the rupee reward
-- needs   : only offered when this is possible ("upgrade", "undiscovered")

local Quests = {}

export type QuestDef = {
	id: string,
	text: string,
	targets: { number }?,
	money: boolean?,
	rolls: number?,
	needs: string?,
}

Quests.list = {
	{ id = "buyLane", text = "Buy %s brainrots on Bazaar Lane", targets = { 3, 5, 8 } },
	{ id = "buyRare", text = "Buy a Rare or better brainrot on Bazaar Lane", targets = { 1 }, rolls = 1 },
	{ id = "collect", text = "Collect %s from your galla", money = true },
	{ id = "roll", text = "Do a Kismat Roll", targets = { 1 } },
	{ id = "mutation", text = "Get a Golden, Diamond or Rainbow brainrot", targets = { 1 }, rolls = 1 },
	{ id = "sell", text = "Sell %s brainrots", targets = { 2, 3 } },
	{ id = "upgrade", text = "Upgrade your haveli", targets = { 1 }, needs = "upgrade" },
	{ id = "discover", text = "Discover a brainrot you have never had", targets = { 1 }, needs = "undiscovered" },
	{ id = "taala", text = "Lock your haveli with the Taala", targets = { 1 } },
	{ id = "eventBuy", text = "Buy a brainrot during an event", targets = { 1 }, rolls = 1 },
} :: { QuestDef }

Quests.byId = {} :: { [string]: QuestDef }
for _, quest in Quests.list do
	Quests.byId[quest.id] = quest
end

return Quests
