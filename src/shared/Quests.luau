-- Daily quest types. Every day each player gets Config.QUESTS_PER_DAY of them.
--
-- text    : shown to the player; %s is the target
-- targets : one is picked at random
-- money   : the target is an amount of rupees that grows with your income
-- rolls   : extra Kismat Rolls on top of the rupee reward
-- needs   : only offered when this is possible ("upgrade", "undiscovered", "treasureGear")

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
	{ id = "eggHome", text = "Bring %s eggs home", targets = { 2, 3, 5 } },
	{ id = "hatchRare", text = "Hatch a Rare or better brainrot", targets = { 1 }, rolls = 1 },
	{ id = "goldenEgg", text = "Bring home a golden egg", targets = { 1 }, rolls = 2 },
	{ id = "treasure", text = "Open a treasure chest", targets = { 1 }, rolls = 1, needs = "treasureGear" },
	{ id = "collect", text = "Collect %s from your galla", money = true },
	{ id = "roll", text = "Do a Kismat Roll", targets = { 1 } },
	{ id = "mutation", text = "Get a Golden, Diamond or Rainbow brainrot", targets = { 1 }, rolls = 1 },
	{ id = "upgrade", text = "Upgrade your haveli or tracker", targets = { 1 }, needs = "upgrade" },
	{ id = "discover", text = "Discover a brainrot you have never had", targets = { 1 }, needs = "undiscovered" },
	{ id = "taala", text = "Lock your haveli with the Taala", targets = { 1 } },
	{ id = "eventEgg", text = "Bring an egg home during an event", targets = { 1 }, rolls = 1 },
	{ id = "biomes", text = "Bring eggs home from %s different biomes", targets = { 2, 3 } },
	{ id = "catchWild", text = "Catch a wild brainrot", targets = { 1 }, rolls = 1 },
	{ id = "buyMandi", text = "Buy %s brainrots on the Mandi lane", targets = { 1, 2 } },
} :: { QuestDef }

Quests.byId = {} :: { [string]: QuestDef }
for _, quest in Quests.list do
	Quests.byId[quest.id] = quest
end

return Quests
