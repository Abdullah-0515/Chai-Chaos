-- Havelis: who lives where, which brainrot stands on which plot, the galla,
-- selling, unlocking plots and the lock (Taala) visuals.
--
-- Plots 1 and 2 are Lockers. Brainrots are always sorted so your most
-- valuable ones stand in the Lockers, where nobody can steal them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Brainrots = require(Shared.Brainrots)
local Format = require(Shared.Format)

local State = require(script.Parent.State)
local Models = require(script.Parent.Models)
local Mover = require(script.Parent.Mover)

local Havelis = {}

local havelis = {}
local nextUid = 0
local gallaCooldown: { [Player]: number } = {}

local LOCKER_COLOR = Color3.fromRGB(120, 170, 235)
local PLOT_COLOR = Color3.fromRGB(235, 225, 200)
local LOCKED_COLOR = Color3.fromRGB(90, 80, 70)

function Havelis.isLocker(plot: number): boolean
	return plot >= 1 and plot <= Config.LOCKER_PLOTS
end

local function plotGround(h, index: number): CFrame
	local plot = h.plots[index]
	return plot.CFrame * CFrame.new(0, plot.Size.Y / 2, 0)
end

local function isInside(h, position: Vector3): boolean
	local p = h.origin:PointToObjectSpace(position)
	return math.abs(p.X) < h.size.X / 2 and math.abs(p.Z) < h.size.Z / 2
end

local function findPrompt(model: Model, name: string): ProximityPrompt?
	local primary = model.PrimaryPart
	return primary and primary:FindFirstChild(name) :: ProximityPrompt?
end

function Havelis.incomePerSecond(profile): number
	local total = 0
	for _, entry in profile.owned do
		if not entry.carrier then
			total += entry.def.income
		end
	end
	return total * (1 + Config.REBIRTH_BONUS * profile.data.rebirths)
end

function Havelis.hasFreePlot(profile): boolean
	return profile.haveli ~= nil and #profile.owned < profile.data.plots
end

local function paintWalls(h, rebirths: number)
	local colors = Config.HAVELI_COLORS
	local color = colors[rebirths % #colors + 1]
	for _, wall in h.walls do
		wall.Color = color
	end
end

local function paintPlots(h, profile)
	local unlocked = if profile then profile.data.plots else Config.START_PLOTS
	for i, plot in h.plots do
		local label = h.plotLabels[i]
		local cost = Config.PLOT_COSTS[i]
		local isNext = profile ~= nil and i == unlocked + 1 and cost ~= nil
		if i <= unlocked then
			plot.Transparency = 0
			plot.Color = if Havelis.isLocker(i) then LOCKER_COLOR else PLOT_COLOR
			label.Text = if Havelis.isLocker(i) then "LOCKER" else ""
		else
			plot.Transparency = 0.5
			plot.Color = LOCKED_COLOR
			label.Text = if isNext then Format.rupees(cost) else ""
		end
		local prompt = plot:FindFirstChild("UnlockPrompt")
		if prompt then
			prompt:SetAttribute("OwnerId", if profile then profile.player.UserId else 0)
			prompt:SetAttribute("Active", isNext)
			prompt.ObjectText = ("Plot %d  ·  %s"):format(i, Format.rupees(cost or 0))
		end
	end
end

local function updateSign(h)
	local profile = h.owner
	if not profile then
		h.signLabel.Text = "Khaali Haveli"
		return
	end
	local locked = workspace:GetServerTimeNow() < profile.lockedUntil
	h.signLabel.Text = (if locked then "LOCKED · " else "") .. profile.player.DisplayName .. " ki Haveli"
end

function Havelis.updateGalla(profile)
	local h = profile.haveli
	if h then
		h.gallaLabel.Text = "Galla\n" .. Format.rupees(profile.data.galla)
	end
	profile.player:SetAttribute("Galla", math.floor(profile.data.galla))
end

-- Turns steal/sell/unlock prompts on or off and updates the sign and lock barrier.
function Havelis.refreshPrompts(profile)
	local h = profile.haveli
	if not h then
		return
	end
	local now = workspace:GetServerTimeNow()
	local open = now >= profile.lockedUntil and now >= profile.protectedUntil
	for _, entry in profile.owned do
		local steal = findPrompt(entry.model, "StealPrompt")
		if steal then
			steal:SetAttribute(
				"Active",
				open and entry.carrier == nil and entry.arrived and not Havelis.isLocker(entry.plot)
			)
		end
		local sell = findPrompt(entry.model, "SellPrompt")
		if sell then
			sell:SetAttribute("Active", entry.carrier == nil)
		end
	end
	paintPlots(h, profile)
	updateSign(h)
	h.barrier.Transparency = if now < profile.lockedUntil then 0.55 else 1
end

local function sendToPlot(profile, entry, instant: boolean?)
	local h = profile.haveli
	local model = entry.model
	local target = Models.stand(model, plotGround(h, entry.plot))
	if instant then
		Mover.stop(model)
		model:PivotTo(target)
		entry.arrived = true
		return
	end
	local points = {}
	if not isInside(h, model:GetPivot().Position) then
		table.insert(points, Models.stand(model, h.doorOutside))
		table.insert(points, Models.stand(model, h.doorInside))
	end
	table.insert(points, target)
	Mover.walk(model, points, Config.WALK_HOME_SPEED, function()
		if State.entries[model] == entry and not entry.carrier then
			entry.arrived = true
			Havelis.refreshPrompts(profile)
		end
	end)
end

-- Gives every brainrot a plot, most valuable first (so the best ones sit in Lockers).
-- A brainrot that is being carried by a thief keeps its plot free for when it comes back.
function Havelis.arrange(profile, instant: boolean?)
	if not profile.haveli then
		return
	end
	local reserved = {}
	local waiting = {}
	for _, entry in profile.owned do
		if entry.carrier then
			reserved[entry.plot] = true
		else
			table.insert(waiting, entry)
		end
	end
	table.sort(waiting, function(a, b)
		if a.def.price ~= b.def.price then
			return a.def.price > b.def.price
		end
		return a.uid < b.uid
	end)
	local nextIndex = 1
	for plot = 1, profile.data.plots do
		local entry = waiting[nextIndex]
		if not entry then
			break
		end
		if not reserved[plot] then
			nextIndex += 1
			if entry.plot ~= plot or instant then
				entry.plot = plot
				sendToPlot(profile, entry, instant)
			end
		end
	end
end

local function makePrompt(
	parent: Instance,
	name: string,
	action: string,
	hold: number,
	showFor: string
): ProximityPrompt
	local prompt = parent:FindFirstChild(name) :: ProximityPrompt?
	if not prompt then
		local created = Instance.new("ProximityPrompt")
		created.Name = name
		created.ActionText = action
		created.HoldDuration = hold
		created.MaxActivationDistance = Config.PROMPT_DISTANCE
		created.RequiresLineOfSight = false
		created:SetAttribute("ShowFor", showFor)
		created.Parent = parent
		prompt = created
	end
	return prompt :: ProximityPrompt
end

local function addEntry(profile, def, model: Model, arrived: boolean)
	local h = profile.haveli
	model.Parent = h.brainrotFolder
	model:SetAttribute("OwnerId", profile.player.UserId)
	nextUid += 1
	local entry = {
		uid = nextUid,
		def = def,
		model = model,
		plot = 0,
		carrier = nil,
		arrived = arrived,
		owner = profile,
	}
	table.insert(profile.owned, entry)
	State.entries[model] = entry

	local primary = model.PrimaryPart :: BasePart
	local sell = makePrompt(primary, "SellPrompt", "Sell", 0.6, "owner")
	sell.ObjectText = ("%s  ·  %s"):format(def.name, Format.rupees(math.floor(def.price * Config.SELL_RATE)))
	sell:SetAttribute("OwnerId", profile.player.UserId)
	local stealText = if Config.stealsCostRobux() then "Steal (1 Chor Pass)" else "Steal"
	local steal = makePrompt(primary, "StealPrompt", stealText, Config.STEAL_HOLD_TIME, "others")
	steal.ObjectText = ("%s (%s)"):format(def.name, def.rarity)
	steal:SetAttribute("OwnerId", profile.player.UserId)
	Models.setInfo(model, ("%s ka  ·  +%s/s"):format(profile.player.DisplayName, Format.short(def.income)))
	return entry
end

-- Adds a brainrot to a player's haveli. Pass the model if it already exists
-- (bought from the lane or stolen); otherwise a new one walks in from the door.
-- Returns the entry and whether this is the first time the player got it.
-- `quiet` skips the Collection Book message (the Kismat reveal shows it instead).
function Havelis.adopt(profile, def, model: Model?, quiet: boolean?)
	local h = profile.haveli
	if not h then
		return nil, false
	end
	if not model then
		local created = Models.create(def)
		created:PivotTo(Models.stand(created, h.doorOutside))
		model = created
	end
	local entry = addEntry(profile, def, model :: Model, false)
	local isNew = State.discover(profile, def)
	if isNew and not quiet then
		State.notify(profile.player, "rare", "New in your Collection Book: " .. def.name .. "!")
	end
	Havelis.arrange(profile)
	Havelis.refreshPrompts(profile)
	return entry, isNew
end

-- Takes a brainrot out of a haveli without destroying its model.
function Havelis.remove(profile, entry)
	local index = table.find(profile.owned, entry)
	if index then
		table.remove(profile.owned, index)
	end
	if State.entries[entry.model] == entry then
		State.entries[entry.model] = nil
	end
	Havelis.arrange(profile)
	Havelis.refreshPrompts(profile)
end

-- A stolen brainrot that got away from its thief walks back home.
function Havelis.returnHome(entry)
	local profile = entry.owner
	entry.carrier = nil
	entry.arrived = false
	entry.plot = 0
	Havelis.arrange(profile)
	Havelis.refreshPrompts(profile)
end

function Havelis.clearBrainrots(profile)
	for _, entry in profile.owned do
		if State.entries[entry.model] == entry then
			State.entries[entry.model] = nil
		end
		entry.model:Destroy()
	end
	table.clear(profile.owned)
end

-- Gives the player the first empty haveli and puts their saved brainrots on their plots.
function Havelis.claim(profile): boolean
	for _, h in havelis do
		if h.owner then
			continue
		end
		h.owner = profile
		profile.haveli = h
		paintWalls(h, profile.data.rebirths)
		for _, id in profile.data.owned do
			local def = Brainrots.byId[id]
			if def then
				addEntry(profile, def, Models.create(def), true)
			end
		end
		Havelis.arrange(profile, true)
		Havelis.refreshPrompts(profile)
		Havelis.updateGalla(profile)
		return true
	end
	return false
end

function Havelis.release(profile)
	local h = profile.haveli
	if not h then
		return
	end
	Havelis.clearBrainrots(profile)
	gallaCooldown[profile.player] = nil
	h.owner = nil
	profile.haveli = nil
	paintWalls(h, 0)
	paintPlots(h, nil)
	updateSign(h)
	h.barrier.Transparency = 1
	h.gallaLabel.Text = "Galla"
end

function Havelis.repaint(profile)
	local h = profile.haveli
	if h then
		paintWalls(h, profile.data.rebirths)
		Havelis.refreshPrompts(profile)
		Havelis.updateGalla(profile)
	end
end

-- Copies the brainrots currently owned into the save data. Only while the
-- player has a haveli: before claiming one (full server) or after leaving,
-- profile.owned is empty and must not overwrite what was loaded.
function Havelis.syncData(profile)
	if not profile.haveli then
		return
	end
	local ids = {}
	for _, entry in profile.owned do
		table.insert(ids, entry.def.id)
	end
	profile.data.owned = ids
end

function Havelis.teleportHome(profile)
	local h = profile.haveli
	local character = profile.player.Character
	if h and character then
		character:PivotTo(h.spawn)
	end
end

function Havelis.sell(player: Player, model: Model)
	local entry = State.entries[model]
	if not entry or entry.owner.player ~= player or entry.carrier then
		return
	end
	if not State.isNear(player, model:GetPivot().Position, Config.PROMPT_DISTANCE + 4) then
		return
	end
	local profile = entry.owner
	local amount = math.floor(entry.def.price * Config.SELL_RATE)
	Havelis.remove(profile, entry)
	model:Destroy()
	State.addRupees(profile, amount)
	State.notify(player, "good", ("Sold %s for %s"):format(entry.def.name, Format.rupees(amount)))
end

function Havelis.unlock(player: Player, plot: BasePart)
	local index = plot:GetAttribute("PlotIndex")
	local h = havelis[plot:GetAttribute("HaveliIndex")]
	local profile = h and h.owner
	if not profile or profile.player ~= player or index ~= profile.data.plots + 1 then
		return
	end
	local cost = Config.PLOT_COSTS[index]
	if not cost or not State.isNear(player, plot.Position, Config.PROMPT_DISTANCE + 4) then
		return
	end
	if profile.data.rupees < cost then
		State.notify(player, "bad", "You need " .. Format.rupees(cost) .. " to unlock this plot.")
		return
	end
	State.addRupees(profile, -cost)
	profile.data.plots += 1
	Havelis.refreshPrompts(profile)
	State.notify(player, "good", ("Plot %d unlocked!"):format(index))
end

local function collectGalla(h, hit: BasePart)
	local profile = h.owner
	if not profile or Players:GetPlayerFromCharacter(hit.Parent) ~= profile.player then
		return
	end
	local player = profile.player
	local now = os.clock()
	if (gallaCooldown[player] or 0) > now then
		return
	end
	gallaCooldown[player] = now + 0.5
	local amount = math.floor(profile.data.galla)
	if amount <= 0 then
		return
	end
	profile.data.galla -= amount
	State.addRupees(profile, amount)
	Havelis.updateGalla(profile)
	State.notify(player, "good", "+" .. Format.rupees(amount) .. " from your galla!")
end

function Havelis.init(map)
	havelis = map.havelis
	for i, h in havelis do
		-- Havelis are looked up by the index stored on their plots, so keep them in order.
		h.index = i
		for _, plot in h.plots do
			plot:SetAttribute("HaveliIndex", i)
			makePrompt(plot, "UnlockPrompt", "Unlock plot", 0.3, "owner")
		end
		h.galla.Touched:Connect(function(hit)
			collectGalla(h, hit)
		end)
		paintWalls(h, 0)
		paintPlots(h, nil)
		updateSign(h)
	end
end

function Havelis.byIndex(index: number)
	return havelis[index]
end

return Havelis
