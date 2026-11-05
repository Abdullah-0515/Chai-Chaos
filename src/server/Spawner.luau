-- Spawns brainrots at the Spawn Gate, walks them down Bazaar Lane and lets
-- players buy them by pressing E. Brainrots nobody buys vanish at the Chowk.
-- Events boost some brainrots, can speed up spawning and make mutations likelier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Brainrots = require(Shared.Brainrots)
local Format = require(Shared.Format)
local Mutations = require(Shared.Mutations)
local Events = require(Shared.Events)

local State = require(script.Parent.State)
local Models = require(script.Parent.Models)
local Mover = require(script.Parent.Mover)
local Havelis = require(script.Parent.Havelis)
local World = require(script.Parent.World)

local Spawner = {}

local CHAPPAL_ID = "AmmiKiUdtiChappal"
local RARE_OR_BETTER = { Rare = true, Epic = true, Legendary = true, Mythic = true }

local map = nil
local walkers: { [Model]: { def: Brainrots.Def, mutation: string? } } = {}

function Spawner.isNight(): boolean
	return World.isNight()
end

local function canSpawn(def: Brainrots.Def, event): boolean
	if def.questOnly then
		return false
	end
	if def.nightOnly and not World.isNight() then
		return false
	end
	if def.eventOnly and (not event or event.id ~= def.eventOnly) then
		return false
	end
	return true
end

-- First pick a rarity using the odds (the lane's odds unless others are given),
-- then a brainrot inside it. Event boosts make some brainrots likelier inside
-- their rarity.
function Spawner.pick(odds: { [string]: number }?, useBoosts: boolean?): Brainrots.Def
	local weights = odds or Config.RARITY_ODDS
	local event = Events.current()
	local boosts = if useBoosts ~= false and event then event.boosts else nil
	local tiers = {}
	local total = 0
	for _, rarity in Brainrots.RARITY_ORDER do
		local pool, poolWeight = {}, 0
		for _, def in Brainrots.byRarity[rarity] do
			if canSpawn(def, event) then
				local w = if boosts then boosts[def.id] or 1 else 1
				table.insert(pool, { def = def, weight = w })
				poolWeight += w
			end
		end
		local weight = weights[rarity] or 0
		if #pool > 0 and weight > 0 then
			table.insert(tiers, { weight = weight, pool = pool, poolWeight = poolWeight })
			total += weight
		end
	end
	local function within(tier)
		local roll = math.random() * tier.poolWeight
		for _, item in tier.pool do
			roll -= item.weight
			if roll <= 0 then
				return item.def
			end
		end
		return tier.pool[#tier.pool].def
	end
	local roll = math.random() * total
	for _, tier in tiers do
		roll -= tier.weight
		if roll <= 0 then
			return within(tier)
		end
	end
	return within(tiers[#tiers])
end

function Spawner.spawn(def: Brainrots.Def?, mutation: string?)
	local event = Events.current()
	local chosen = def or Spawner.pick()
	local mutated = mutation or Mutations.roll("lane", event and event.mutationMult)
	local model = Models.create(chosen, mutated)
	Mover.place(model, Models.stand(model, map.spawnGate))

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy for " .. Format.rupees(Mutations.value(chosen, mutated))
	prompt.ObjectText = ("%s (%s)"):format(Mutations.displayName(chosen, mutated), chosen.rarity)
	prompt.MaxActivationDistance = Config.PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	model.Parent = map.laneFolder
	walkers[model] = { def = chosen, mutation = mutated }

	local laneLength = (map.laneEnd.Position - map.spawnGate.Position).Magnitude
	Mover.walk(model, { Models.stand(model, map.laneEnd) }, laneLength / Config.LANE_WALK_TIME, function()
		if walkers[model] then
			walkers[model] = nil
			model:Destroy()
		end
	end)

	local name = Mutations.displayName(chosen, mutated)
	if chosen.id == CHAPPAL_ID then
		Mover.freeze(Config.CHAPPAL_FREEZE_TIME, model)
		State.notifyAll("rare", "WHOOSH! Ammi ki Udti Chappal is here! Every brainrot freezes in fear!")
	elseif chosen.rarity == "Mythic" or chosen.rarity == "Legendary" then
		State.notifyAll("rare", ("A %s %s is walking down Bazaar Lane!"):format(chosen.rarity:upper(), name))
	elseif mutated == "Rainbow" or mutated == "Diamond" then
		State.notifyAll("rare", ("A %s is walking down Bazaar Lane!"):format(name))
	end
	return model
end

function Spawner.buy(player: Player, model: Model)
	local walker = walkers[model]
	local profile = State.profiles[player]
	if not walker or not profile then
		return
	end
	local def, mutation = walker.def, walker.mutation
	local price = Mutations.value(def, mutation)
	if not profile.haveli then
		State.notify(player, "bad", "You need a haveli first. The bazaar is full!")
		return
	end
	if not State.isNear(player, Mover.pivot(model).Position, Config.PROMPT_DISTANCE + 4) then
		return
	end
	if profile.data.rupees < price then
		State.notify(
			player,
			"bad",
			("Not enough rupees! %s costs %s."):format(Mutations.displayName(def, mutation), Format.rupees(price))
		)
		return
	end
	if not Havelis.hasFreePlot(profile) then
		State.notify(player, "bad", "No empty plot! Upgrade your haveli or sell a brainrot first.")
		return
	end

	walkers[model] = nil
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("BuyPrompt")
	if prompt then
		prompt:Destroy()
	end
	State.addRupees(profile, -price)
	Havelis.adopt(profile, def, mutation, model)
	State.notify(
		player,
		"good",
		("You bought %s! It is walking to your haveli."):format(Mutations.displayName(def, mutation))
	)
	State.track(profile, "buyLane")
	if RARE_OR_BETTER[def.rarity] then
		State.track(profile, "buyRare")
	end
	if mutation then
		State.track(profile, "mutation")
	end
	if Events.current() then
		State.track(profile, "eventBuy")
	end
end

function Spawner.init(gameMap)
	map = gameMap
	task.spawn(function()
		while true do
			local event = Events.current()
			task.wait(Config.SPAWN_INTERVAL / (if event then event.spawnRate or 1 else 1))
			local ok, err = pcall(Spawner.spawn)
			if not ok then
				warn("[ChaiChaos] Spawn failed:", err)
			end
		end
	end)
end

return Spawner
