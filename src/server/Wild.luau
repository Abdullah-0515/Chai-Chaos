-- Wild brainrots: rare brainrots that roam the zones.
--
-- * Every Config.WILD_EVERY seconds a new one turns up in a random zone (inner
--   zones more often) while there are fewer than Config.WILD_MAX. It wanders
--   between open spots in its zone and leaves after Config.WILD_LIFETIME.
-- * Walk up and hold E to catch it. The zone must be open for you and you need
--   a free plot. It hops into your pocket and a moment later walks out of your
--   haveli door to a plot.
-- * Vehicles that drive close and horns scare it: it runs off to the far side
--   of the zone. Park and sneak up on foot!
-- * Everyone sees wild brainrots on the radar (tag "ChaiWild").

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Biomes = require(Shared.Biomes)
local Brainrots = require(Shared.Brainrots)
local Events = require(Shared.Events)
local Mutations = require(Shared.Mutations)

local State = require(script.Parent.State)
local Models = require(script.Parent.Models)
local Mover = require(script.Parent.Mover)
local Havelis = require(script.Parent.Havelis)
local Picker = require(script.Parent.Picker)

local Wild = {}

Wild.TAG = "ChaiWild"
local FLAT = Vector3.new(1, 0, 1)
local HOP = 60 -- wander to a spot at most this far away
local REST = { 2, 6 } -- seconds to stand still between walks
local CALM_DOWN = 4 -- seconds after running away before it can be scared again
local TICK = 0.5

type Wild = {
	def: any,
	mutation: string?,
	biome: any,
	born: number,
	scaredAt: number,
	walkId: number,
}

local map = nil
local folder: Folder? = nil
local wild: { [Model]: Wild } = {}
local sinceSpawn = 0

local function spots(biome): { Vector3 }
	local plan = map and map.biomes and map.biomes[biome.id]
	return if plan then plan.eggSpots else {}
end

local function pickZone()
	local total = 0
	for _, biome in Biomes.list do
		if #spots(biome) > 0 then
			total += Config.WILD_RING_WEIGHT[biome.ring] or 0
		end
	end
	local roll = math.random() * total
	local last = nil
	for _, biome in Biomes.list do
		if #spots(biome) > 0 then
			last = biome
			roll -= Config.WILD_RING_WEIGHT[biome.ring] or 0
			if roll <= 0 then
				return biome
			end
		end
	end
	return last
end

local function facing(from: Vector3, to: Vector3): CFrame
	local dir = (to - from) * FLAT
	if dir.Magnitude < 0.01 then
		return CFrame.new(to)
	end
	return CFrame.lookAt(to, to + dir)
end

-- Walk to `target`, then rest and walk on (unless something else happened).
local function walkTo(model: Model, info: Wild, target: Vector3, speed: number)
	info.walkId += 1
	local id = info.walkId
	local here = Mover.pivot(model).Position
	local ground = Models.stand(model, facing(here, target))
	Mover.walk(model, { ground }, speed, function()
		task.delay(math.random(REST[1], REST[2]), function()
			if wild[model] == info and info.walkId == id then
				Wild.wander(model)
			end
		end)
	end)
end

-- Off to a nearby open spot in its zone.
function Wild.wander(model: Model)
	local info = wild[model]
	if not info then
		return
	end
	local list = spots(info.biome)
	local here = Mover.pivot(model).Position
	local near = {}
	for _, p in list do
		local d = ((p - here) * FLAT).Magnitude
		if d > 8 and d < HOP then
			table.insert(near, p)
		end
	end
	local target = if #near > 0 then near[math.random(#near)] else list[math.random(#list)]
	walkTo(model, info, target, Config.WILD_SPEED)
end

-- Runs to the open spot furthest from `from`.
function Wild.flee(model: Model, from: Vector3)
	local info = wild[model]
	local t = os.clock()
	if not info or t - info.scaredAt < CALM_DOWN then
		return
	end
	info.scaredAt = t
	local best, bestDistance = nil, -1
	for _, p in spots(info.biome) do
		local d = ((p - from) * FLAT).Magnitude
		if d > bestDistance then
			best, bestDistance = p, d
		end
	end
	if best then
		walkTo(model, info, best, Config.WILD_FLEE_SPEED)
	end
end

local function remove(model: Model)
	wild[model] = nil
	Mover.stop(model)
	model:Destroy()
end

function Wild.spawn(biome, def, mutation: string?): Model?
	biome = biome or pickZone()
	if not biome then
		return nil
	end
	local list = spots(biome)
	if #list == 0 then
		return nil
	end
	local luck = Events.mult("luckMult")
	def = def or Picker.pick(Brainrots.wildOdds(biome.odds), biome.pool, luck)
	if mutation == nil then
		mutation = Mutations.roll("egg", luck)
	end
	local model = Models.create(def, mutation)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- for everyone's radar
	model:SetAttribute("Wild", true)
	model:SetAttribute("Zone", biome.id)
	model:SetAttribute("Rarity", def.rarity)
	local start = list[math.random(#list)]
	Mover.place(model, Models.stand(model, CFrame.new(start)))

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CatchPrompt"
	prompt.ActionText = "Catch"
	prompt.ObjectText = ("Wild %s (%s)"):format(Mutations.displayName(def, mutation), def.rarity)
	prompt.HoldDuration = Config.WILD_CATCH_TIME
	prompt.MaxActivationDistance = Config.PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	model.Parent = folder
	CollectionService:AddTag(model, Wild.TAG)
	wild[model] = {
		def = def,
		mutation = mutation,
		biome = biome,
		born = os.clock(),
		scaredAt = -math.huge,
		walkId = 0,
	}
	Wild.wander(model)
	if def.rarity == "Legendary" or def.rarity == "Mythic" or mutation == "Rainbow" or mutation == "Diamond" then
		State.notifyAll(
			"rare",
			("A wild %s %s is roaming %s! Sneak up on it on foot."):format(
				def.rarity:upper(),
				Mutations.displayName(def, mutation),
				biome.name
			)
		)
	end
	return model
end

-- Hold E next to it.
function Wild.catch(player: Player, model: Model?)
	local info = model and wild[model]
	local profile = State.profiles[player]
	if not model or not info or not profile or not profile.haveli then
		return
	end
	if not State.isNear(player, Mover.pivot(model).Position, Config.PROMPT_DISTANCE + 4) then
		return
	end
	if not State.isZoneOpen(profile, info.biome) then
		State.notify(
			player,
			"bad",
			("Unlock %s at its gate before you can catch brainrots there."):format(info.biome.name)
		)
		return
	end
	if profile.carryingBrainrot then
		State.notify(player, "bad", "Your hands are full!")
		return
	end
	if not Havelis.hasFreePlot(profile) then
		State.notify(player, "bad", "No empty plot at home! Upgrade your haveli or sell a brainrot first.")
		return
	end
	local def, mutation = info.def, info.mutation
	remove(model)
	Havelis.adopt(profile, def, mutation)
	State.sound(player, "EggHatch")
	State.notify(
		player,
		"rare",
		("You caught a wild %s! It is walking into your haveli."):format(Mutations.displayName(def, mutation))
	)
	State.track(profile, "catchWild")
	if mutation then
		State.track(profile, "mutation")
	end
	return true
end

-- A horn: everything wild close enough runs away.
function Wild.scare(_player: Player?, position: Vector3, radius: number?)
	for model in wild do
		if ((Mover.pivot(model).Position - position) * FLAT).Magnitude < (radius or Config.WILD_HONK_RADIUS) then
			Wild.flee(model, position)
		end
	end
end

function Wild.count(): number
	local n = 0
	for _ in wild do
		n += 1
	end
	return n
end

function Wild.list(): { [Model]: Wild }
	return wild
end

function Wild.tick(dt: number)
	local t = os.clock()
	-- old ones wander off
	for model, info in wild do
		if model.Parent == nil then
			wild[model] = nil
		elseif t - info.born > Config.WILD_LIFETIME then
			remove(model)
		end
	end
	-- vehicles that come close scare them
	for player, profile in State.profiles do
		local root = profile.driving and State.rootPart(player)
		if root then
			for model in wild do
				local d = ((Mover.pivot(model).Position - root.Position) * FLAT).Magnitude
				if d < Config.WILD_SCARE_RADIUS then
					Wild.flee(model, root.Position)
				end
			end
		end
	end
	sinceSpawn += dt
	if sinceSpawn >= Config.WILD_EVERY then
		sinceSpawn = 0
		if Wild.count() < Config.WILD_MAX then
			Wild.spawn()
		end
	end
end

function Wild.init(gameMap)
	map = gameMap
	local f = Instance.new("Folder")
	f.Name = "ChaiChaosWild"
	f.Parent = workspace
	folder = f
	task.spawn(function()
		while true do
			local ok, err = pcall(Wild.tick, task.wait(TICK))
			if not ok then
				warn("[ChaiChaos] Wild brainrots:", err)
			end
		end
	end)
end

return Wild
