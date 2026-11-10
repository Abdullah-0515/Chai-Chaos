-- The Mandi lane: brainrots walk out of the Brainrot Mandi arch (on the Punjab
-- road, by the Chowk) and all the way round the lane in front of the havelis.
-- Press E to buy one with rupees before it walks back into the Mandi.
--
-- Lane brainrots are mostly Common and Rare (Config.MANDI_ODDS, never Mythic or
-- Secret) and cost Config.MANDI_PRICE times their value, so hunting eggs stays
-- the best way to get brainrots. The lane is for filling an empty plot fast.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Biomes = require(Shared.Biomes)
local Events = require(Shared.Events)
local Format = require(Shared.Format)
local Mutations = require(Shared.Mutations)

local State = require(script.Parent.State)
local Models = require(script.Parent.Models)
local Mover = require(script.Parent.Mover)
local Havelis = require(script.Parent.Havelis)
local Picker = require(script.Parent.Picker)

local Mandi = {}

local STEP = 10 -- degrees between the lane's walk points

type Walker = { def: any, mutation: string?, price: number }

local folder: Folder? = nil
local walkers: { [Model]: Walker } = {}
local path: { CFrame } = {}
local pool: { string } = {} -- every brainrot that hatches from some zone's eggs
local sinceSpawn = 0

function Mandi.price(def, mutation: string?): number
	return math.floor(Mutations.value(def, mutation) * Config.MANDI_PRICE / 10 + 0.5) * 10
end

function Mandi.spawn(def, mutation: string?): Model
	local luck = Events.mult("luckMult")
	def = def or Picker.pick(Config.MANDI_ODDS, pool, luck)
	if mutation == nil then
		mutation = Mutations.roll("egg", luck)
	end
	local price = Mandi.price(def, mutation)
	local model = Models.create(def, mutation)
	Mover.place(model, Models.stand(model, path[1]))

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy for " .. Format.rupees(price)
	prompt.ObjectText = ("%s (%s)"):format(Mutations.displayName(def, mutation), def.rarity)
	prompt.MaxActivationDistance = Config.PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart

	model:SetAttribute("Mandi", true)
	model.Parent = folder
	walkers[model] = { def = def, mutation = mutation, price = price }

	local points = {}
	for i = 2, #path do
		table.insert(points, Models.stand(model, path[i]))
	end
	local length = 2 * math.pi * Biomes.MANDI_RADIUS
	Mover.walk(model, points, length / Config.MANDI_WALK_TIME, function()
		if walkers[model] then
			walkers[model] = nil
			model:Destroy()
		end
	end)

	if def.rarity == "Legendary" or mutation == "Rainbow" or mutation == "Diamond" then
		State.notifyAll(
			"rare",
			("A %s is walking round the Mandi lane! %s"):format(
				Mutations.displayName(def, mutation),
				Format.rupees(price)
			)
		)
	end
	return model
end

function Mandi.buy(player: Player, model: Model?)
	local walker = model and walkers[model]
	local profile = State.profiles[player]
	if not model or not walker or not profile then
		return
	end
	if not profile.haveli then
		return
	end
	if not State.isNear(player, Mover.pivot(model).Position, Config.PROMPT_DISTANCE + 4) then
		return
	end
	local name = Mutations.displayName(walker.def, walker.mutation)
	if profile.data.rupees < walker.price then
		State.sound(player, "Error")
		State.notify(player, "bad", ("Not enough rupees! %s costs %s."):format(name, Format.rupees(walker.price)))
		return
	end
	if not Havelis.hasFreePlot(profile) then
		State.sound(player, "Error")
		State.notify(player, "bad", "No empty plot! Upgrade your haveli or sell a brainrot first.")
		return
	end
	walkers[model] = nil
	local prompt = model.PrimaryPart and model.PrimaryPart:FindFirstChild("BuyPrompt")
	if prompt then
		prompt:Destroy()
	end
	model:SetAttribute("Mandi", nil)
	State.addRupees(profile, -walker.price)
	Havelis.adopt(profile, walker.def, walker.mutation, model)
	State.sound(player, "Purchase")
	State.notify(player, "good", ("You bought %s! It is walking to your haveli."):format(name))
	State.track(profile, "buyMandi")
	if walker.mutation then
		State.track(profile, "mutation")
	end
	return true
end

function Mandi.count(): number
	local n = 0
	for model in walkers do
		if model.Parent then
			n += 1
		end
	end
	return n
end

function Mandi.walkers(): { [Model]: Walker }
	return walkers
end

function Mandi.tick(dt: number)
	sinceSpawn += dt
	if sinceSpawn >= Config.MANDI_EVERY then
		sinceSpawn = 0
		if Mandi.count() < Config.MANDI_MAX then
			Mandi.spawn()
		end
	end
end

function Mandi.init()
	local f = Instance.new("Folder")
	f.Name = "ChaiChaosMandi"
	f.Parent = workspace
	folder = f
	local seen = {}
	for _, biome in Biomes.list do
		for _, id in biome.pool do
			if not seen[id] then
				seen[id] = true
				table.insert(pool, id)
			end
		end
	end
	local points = Biomes.mandiLane(STEP)
	path = {}
	for i, p in points do
		local nextPoint = points[i + 1] or Biomes.polar(Biomes.MANDI_START + 360 + STEP, Biomes.MANDI_RADIUS)
		table.insert(path, CFrame.lookAt(p, p + (nextPoint - p) * Vector3.new(1, 0, 1)))
	end
	task.spawn(function()
		while true do
			local ok, err = pcall(Mandi.tick, task.wait(0.5))
			if not ok then
				warn("[ChaiChaos] Mandi lane:", err)
			end
		end
	end)
end

return Mandi
