-- Shared server state: one profile per player and one entry per owned brainrot.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local State = {}

-- profiles[player] = {
--   player, data (saved), canSave, haveli, owned = { entry },
--   lockedUntil, lockReadyAt, protectedUntil (all in workspace:GetServerTimeNow() time)
-- }
State.profiles = {} :: { [Player]: any }

-- entries[model] = { uid, def, mutation, model, plot, carrier, arrived, owner (a profile) }
State.entries = {} :: { [Model]: any }

function State.newProfile(player: Player, data: any, canSave: boolean)
	return {
		player = player,
		data = data,
		canSave = canSave,
		haveli = nil,
		owned = {},
		lockedUntil = 0,
		lockReadyAt = 0,
		protectedUntil = 0,
	}
end

-- Quest progress: any module can report what a player did; QuestBook listens.
State.tracker = nil :: ((any, string, number) -> ())?
function State.track(profile, kind: string, amount: number?)
	if State.tracker then
		State.tracker(profile, kind, amount or 1)
	end
end

function State.notify(player: Player, kind: string, text: string)
	Remotes.Notify:FireClient(player, kind, text)
end

function State.notifyAll(kind: string, text: string)
	Remotes.Notify:FireAllClients(kind, text)
end

local function leaderstat(player: Player, name: string): IntValue?
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild(name)
	return value :: IntValue?
end

-- Push saved numbers to the player list and to attributes the HUD reads.
function State.syncStats(profile)
	local rupees = leaderstat(profile.player, "Rupees")
	if rupees then
		rupees.Value = profile.data.rupees
	end
	local rebirths = leaderstat(profile.player, "Rebirths")
	if rebirths then
		rebirths.Value = profile.data.rebirths
	end
	profile.player:SetAttribute("RebirthCost", Config.rebirthCost(profile.data.rebirths))
	profile.player:SetAttribute("HaveliLevel", profile.data.level)
	profile.player:SetAttribute("Theme", profile.data.theme)
end

-- Quests and Collection Book claims, as JSON for the HUD.
function State.syncQuests(profile)
	local data = profile.data
	profile.player:SetAttribute(
		"QuestState",
		HttpService:JSONEncode({ quests = data.quests, collection = data.collection, rebirths = data.rebirths })
	)
end

function State.addRupees(profile, amount: number)
	profile.data.rupees = math.max(0, math.floor(profile.data.rupees + amount))
	State.syncStats(profile)
end

-- Kismat Rolls, Chor Passes and the pity counter, for the HUD.
function State.syncTokens(profile)
	local player, data = profile.player, profile.data
	player:SetAttribute("RollTokens", data.rollTokens)
	player:SetAttribute("StealTokens", data.stealTokens)
	player:SetAttribute("RollPity", data.rollPity)
end

function State.syncDiscovered(profile)
	local ids = {}
	for id in profile.data.discovered do
		table.insert(ids, id)
	end
	for key in profile.data.mutations do
		table.insert(ids, key)
	end
	table.sort(ids)
	profile.player:SetAttribute("Discovered", table.concat(ids, ","))
end

-- Returns true the first time a player gets this brainrot.
function State.discover(profile, def, mutation: string?): boolean
	local data = profile.data
	local isNew = not data.discovered[def.id]
	local mutationKey = mutation and (def.id .. ":" .. mutation)
	local newMutation = mutationKey ~= nil and not data.mutations[mutationKey]
	if not isNew and not newMutation then
		return false
	end
	data.discovered[def.id] = true
	if mutationKey then
		data.mutations[mutationKey] = true
	end
	State.syncDiscovered(profile)
	return isNew
end

function State.rootPart(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root :: BasePart?
end

-- Is the player's character alive and within `range` studs of `position`?
function State.isNear(player: Player, position: Vector3, range: number): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = State.rootPart(player)
	if not humanoid or humanoid.Health <= 0 or not root then
		return false
	end
	return (root.Position - position).Magnitude <= range
end

return State
