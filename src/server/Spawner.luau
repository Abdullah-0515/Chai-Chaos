-- Spawns brainrots at the Spawn Gate, walks them down Bazaar Lane and lets
-- players buy them by pressing E. Brainrots nobody buys vanish at the Chowk.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Brainrots = require(Shared.Brainrots)
local Format = require(Shared.Format)

local State = require(script.Parent.State)
local Models = require(script.Parent.Models)
local Mover = require(script.Parent.Mover)
local Havelis = require(script.Parent.Havelis)

local Spawner = {}

local CHAPPAL_ID = "AmmiKiUdtiChappal"

local map = nil
local walkers: { [Model]: Brainrots.Def } = {}

function Spawner.isNight(): boolean
	local t = Lighting.ClockTime
	return t >= 18.5 or t < 5.5
end

local function canSpawn(def: Brainrots.Def): boolean
	if def.nightOnly and not Spawner.isNight() then
		return false
	end
	return true
end

-- First pick a rarity using the odds in Config, then a brainrot inside it.
function Spawner.pick(): Brainrots.Def
	local tiers = {}
	local total = 0
	for _, rarity in Brainrots.RARITY_ORDER do
		local pool = {}
		for _, def in Brainrots.byRarity[rarity] do
			if canSpawn(def) then
				table.insert(pool, def)
			end
		end
		local weight = Config.RARITY_ODDS[rarity] or 0
		if #pool > 0 and weight > 0 then
			table.insert(tiers, { weight = weight, pool = pool })
			total += weight
		end
	end
	local roll = math.random() * total
	for _, tier in tiers do
		roll -= tier.weight
		if roll <= 0 then
			return tier.pool[math.random(#tier.pool)]
		end
	end
	local last = tiers[#tiers]
	return last.pool[math.random(#last.pool)]
end

function Spawner.spawn(def: Brainrots.Def?)
	local chosen = def or Spawner.pick()
	local model = Models.create(chosen)
	model:PivotTo(Models.stand(model, map.spawnGate))

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy for " .. Format.rupees(chosen.price)
	prompt.ObjectText = ("%s (%s)"):format(chosen.name, chosen.rarity)
	prompt.MaxActivationDistance = Config.PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	model.Parent = map.laneFolder
	walkers[model] = chosen

	local laneLength = (map.laneEnd.Position - map.spawnGate.Position).Magnitude
	Mover.walk(model, { Models.stand(model, map.laneEnd) }, laneLength / Config.LANE_WALK_TIME, function()
		if walkers[model] then
			walkers[model] = nil
			model:Destroy()
		end
	end)

	if chosen.id == CHAPPAL_ID then
		Mover.freeze(Config.CHAPPAL_FREEZE_TIME, model)
		State.notifyAll("rare", "WHOOSH! Ammi ki Udti Chappal is here! Every brainrot freezes in fear!")
	elseif chosen.rarity == "Mythic" or chosen.rarity == "Legendary" then
		State.notifyAll("rare", ("A %s %s is walking down Bazaar Lane!"):format(chosen.rarity:upper(), chosen.name))
	end
	return model
end

function Spawner.buy(player: Player, model: Model)
	local def = walkers[model]
	local profile = State.profiles[player]
	if not def or not profile then
		return
	end
	if not profile.haveli then
		State.notify(player, "bad", "You need a haveli first. The bazaar is full!")
		return
	end
	if not State.isNear(player, model:GetPivot().Position, Config.PROMPT_DISTANCE + 4) then
		return
	end
	if profile.data.rupees < def.price then
		State.notify(player, "bad", ("Not enough rupees! %s costs %s."):format(def.name, Format.rupees(def.price)))
		return
	end
	if not Havelis.hasFreePlot(profile) then
		State.notify(player, "bad", "No empty plot! Unlock a plot or sell a brainrot first.")
		return
	end

	walkers[model] = nil
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("BuyPrompt")
	if prompt then
		prompt:Destroy()
	end
	State.addRupees(profile, -def.price)
	Havelis.adopt(profile, def, model)
	State.notify(player, "good", ("You bought %s! It is walking to your haveli."):format(def.name))
end

function Spawner.init(gameMap)
	map = gameMap
	task.spawn(function()
		while true do
			task.wait(Config.SPAWN_INTERVAL)
			local ok, err = pcall(Spawner.spawn)
			if not ok then
				warn("[ChaiChaos] Spawn failed:", err)
			end
		end
	end)
end

return Spawner
