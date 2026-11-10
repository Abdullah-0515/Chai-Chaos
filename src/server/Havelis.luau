-- Havelis: who lives where, haveli levels and themes, which brainrot stands on
-- which plot, the galla, selling, the Taala lock and the Laser Darwaza.
--
-- Plots 1 and 2 are Lockers. Brainrots are always sorted so your most
-- valuable ones stand in the Lockers, where nobody can steal them.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Brainrots = require(Shared.Brainrots)
local Format = require(Shared.Format)
local Mutations = require(Shared.Mutations)
local Themes = require(Shared.Themes)
local Events = require(Shared.Events)
local Gear = require(Shared.Gear)

local State = require(script.Parent.State)
local Models = require(script.Parent.Models)
local Mover = require(script.Parent.Mover)
local MapBuilder = require(script.Parent.MapBuilder)
local HaveliStyle = require(script.Parent.HaveliStyle)
local Defenses = require(script.Parent.Defenses)

local Havelis = {}

local havelis = {}
local gameMap = nil
local nextUid = 0
local gallaCooldown: { [Player]: number } = {}

local LOCKER_COLOR = Color3.fromRGB(110, 175, 245)
local PLOT_COLOR = Color3.fromRGB(245, 235, 210)
local LOCKED_COLOR = Color3.fromRGB(95, 85, 75)

function Havelis.isLocker(plot: number): boolean
	return plot >= 1 and plot <= Config.LOCKER_PLOTS
end

function Havelis.plotCount(profile): number
	return Config.plotCount(profile.data.level, profile.data.passes.ExtraPlots)
end

function Havelis.entryValue(entry): number
	return Mutations.value(entry.def, entry.mutation)
end

function Havelis.entryIncome(entry): number
	return Mutations.income(entry.def, entry.mutation)
end

-- Rebirths, the theme perk and the running event all multiply income.
function Havelis.incomeMultiplier(profile): number
	local theme = profile.data.theme
	local mult = (1 + Config.REBIRTH_BONUS * profile.data.rebirths) * (Themes.perk(theme, "income") or 1)
	if profile.data.passes.DoubleCash then
		mult *= 2
	end
	local event = Events.current()
	if event then
		mult *= (event.cashMult or 1) * (Themes.perk(theme, "eventIncome") or 1)
	end
	return mult
end

function Havelis.incomePerSecond(profile): number
	local total = 0
	for _, entry in profile.owned do
		if not entry.carrier then
			total += Havelis.entryIncome(entry)
		end
	end
	return total * Havelis.incomeMultiplier(profile)
end

function Havelis.hasFreePlot(profile): boolean
	return profile.haveli ~= nil and #profile.owned < Havelis.plotCount(profile)
end

-- Running speed on foot: the theme perk and speed gear.
function Havelis.walkSpeed(profile): number
	return Config.WALK_SPEED
		* (Themes.perk(profile.data.theme, "walkSpeed") or 1)
		* Gear.best(profile.data.gear, "speed")
end

-- Sets the player's speed: on foot (slower while carrying a stolen brainrot
-- and in hazards like mud and sandstorms) or driving (see Vehicles.luau).
function Havelis.applyWalkSpeed(profile)
	local character = profile.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local drive = profile.driving
		if drive then
			humanoid.WalkSpeed = if drive.empty
				then Config.FUEL_EMPTY_SPEED
				else drive.topSpeed * (profile.surfaceSpeed or 1)
		else
			humanoid.WalkSpeed = Havelis.walkSpeed(profile) * (profile.carrySpeed or 1) * (profile.hazardSpeed or 1)
		end
	end
end

function Havelis.taalaTime(profile): number
	return Config.LOCK_TIME + (Themes.perk(profile.data.theme, "taalaBonus") or 0)
end

local function plotGround(h, index: number): CFrame
	local plot = h.plots[index]
	return plot.CFrame * CFrame.new(0, plot.Size.Y / 2, 0)
end

local function localPosition(h, position: Vector3): Vector3
	return h.origin:PointToObjectSpace(position)
end

function Havelis.isInside(h, position: Vector3): boolean
	local p = localPosition(h, position)
	return math.abs(p.X) < h.size.X / 2 and math.abs(p.Z) < h.size.Z / 2 and p.Y > -4 and p.Y < h.upperY + 14
end

local function findPrompt(model: Model, name: string): ProximityPrompt?
	local primary = model.PrimaryPart
	return primary and primary:FindFirstChild(name) :: ProximityPrompt?
end

-- The level that unlocks plot `index`.
local function levelForPlot(index: number): number
	for level, info in Config.HAVELI_LEVELS do
		if info.plots >= index then
			return level
		end
	end
	return #Config.HAVELI_LEVELS
end

local function paintPlots(h, profile)
	local unlocked = if profile then Havelis.plotCount(profile) else Config.HAVELI_LEVELS[1].plots
	for i, plot in h.plots do
		local label = h.plotLabels[i]
		if i <= unlocked then
			plot.Transparency = 0
			plot.Color = if Havelis.isLocker(i) then LOCKER_COLOR else PLOT_COLOR
			label.Text = if Havelis.isLocker(i) then "LOCKER" else ""
		else
			plot.Transparency = 0.55
			plot.Color = LOCKED_COLOR
			label.Text = if profile then ("Level %d"):format(levelForPlot(i)) else ""
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
	h.signLabel.Text = ("%s%s ki Haveli · Lv %d"):format(
		if locked then "LOCKED · " else "",
		profile.player.DisplayName,
		profile.data.level
	)
end

function Havelis.updateGalla(profile)
	local h = profile.haveli
	if h then
		h.gallaLabel.Text = "Galla\n" .. Format.rupees(profile.data.galla)
	end
	profile.player:SetAttribute("Galla", math.floor(profile.data.galla))
end

-- Tells the player's screen which brainrots they own, for the Brainrots
-- window (ride and sell): "uid|key|carried" separated by commas.
function Havelis.syncOwned(profile)
	local items = {}
	for _, entry in profile.owned do
		table.insert(
			items,
			("%d|%s|%s"):format(
				entry.uid,
				Mutations.key(entry.def.id, entry.mutation),
				if entry.carrier then "1" else "0"
			)
		)
	end
	local text = table.concat(items, ",")
	if profile.player:GetAttribute("Owned") ~= text then
		profile.player:SetAttribute("Owned", text)
	end
end

-- Turns steal prompts on or off and updates the sign, the laser and the
-- player's list of brainrots.
function Havelis.refreshPrompts(profile)
	Havelis.syncOwned(profile)
	local h = profile.haveli
	if not h then
		return
	end
	local now = workspace:GetServerTimeNow()
	local locked = now < profile.lockedUntil
	local open = not locked and now >= profile.protectedUntil
	for _, entry in profile.owned do
		local steal = findPrompt(entry.model, "StealPrompt")
		if steal then
			steal:SetAttribute(
				"Active",
				open and entry.carrier == nil and entry.arrived and not Havelis.isLocker(entry.plot)
			)
		end
	end
	paintPlots(h, profile)
	updateSign(h)
	h.barrier.Transparency = if locked then 0.45 else 1
	Defenses.setLaser(h, locked and profile.data.level >= Config.LASER_LEVEL)
end

-- Repaints and redecorates for the owner's theme and level.
function Havelis.restyle(profile)
	local h = profile.haveli
	if not h then
		return
	end
	h.guard = HaveliStyle.apply(h, profile.data.theme, profile.data.level)
	Havelis.refreshPrompts(profile)
end

local function isUpstairs(h, position: Vector3): boolean
	return localPosition(h, position).Y > h.upperY / 2
end

local function sendToPlot(profile, entry, instant: boolean?)
	local h = profile.haveli
	local model = entry.model
	local target = Models.stand(model, plotGround(h, entry.plot))
	if instant then
		Mover.place(model, target)
		entry.arrived = true
		return
	end
	local here = Mover.pivot(model).Position
	local points = {}
	if not Havelis.isInside(h, here) then
		table.insert(points, Models.stand(model, h.doorOutside))
		table.insert(points, Models.stand(model, h.doorInside))
		here = h.doorInside.Position
	end
	local fromUp = isUpstairs(h, here)
	local toUp = entry.plot > MapBuilder.PLOTS_PER_FLOOR
	if fromUp ~= toUp then
		local first, second = h.stairBottom, h.stairTop
		if fromUp then
			first, second = h.stairTop, h.stairBottom
		end
		table.insert(points, Models.stand(model, first))
		table.insert(points, Models.stand(model, second))
	end
	table.insert(points, target)
	Mover.walk(model, points, Config.WALK_HOME_SPEED, function()
		if State.entries[model] == entry and not entry.carrier then
			entry.arrived = true
			Havelis.refreshPrompts(profile)
		end
	end)
end

-- Gives every brainrot a plot, most valuable first (so the best ones sit in
-- Lockers). Quest brainrots cannot be stolen, so they go last.
-- A brainrot being carried by a thief keeps its plot free for when it comes back.
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
		local aQuest, bQuest = a.def.questOnly == true, b.def.questOnly == true
		if aQuest ~= bQuest then
			return bQuest
		end
		local aValue, bValue = Havelis.entryValue(a), Havelis.entryValue(b)
		if aValue ~= bValue then
			return aValue > bValue
		end
		return a.uid < b.uid
	end)
	local nextIndex = 1
	for plot = 1, Havelis.plotCount(profile) do
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

local function addEntry(profile, def, mutation: string?, model: Model, arrived: boolean)
	local h = profile.haveli
	model.Parent = h.brainrotFolder
	model:SetAttribute("OwnerId", profile.player.UserId)
	nextUid += 1
	local entry = {
		uid = nextUid,
		def = def,
		mutation = mutation,
		model = model,
		plot = 0,
		carrier = nil,
		arrived = arrived,
		owner = profile,
	}
	table.insert(profile.owned, entry)
	State.entries[model] = entry

	local primary = model.PrimaryPart :: BasePart
	local name = Mutations.displayName(def, mutation)
	if not def.questOnly then
		local stealText = if Config.stealsCostRobux() then "Steal (1 Chor Pass)" else "Steal"
		local steal = makePrompt(primary, "StealPrompt", stealText, Config.STEAL_HOLD_TIME, "others")
		steal.ObjectText = ("%s (%s)"):format(name, def.rarity)
		steal:SetAttribute("OwnerId", profile.player.UserId)
	end
	Models.setInfo(
		model,
		("%s ka  ·  +%s/s"):format(profile.player.DisplayName, Format.short(Havelis.entryIncome(entry)))
	)
	return entry
end

-- Adds a brainrot to a player's haveli. Pass the model if it already exists
-- (stolen, or coming back from a ride); otherwise a new one walks in from the door.
-- Returns the entry and whether this is the first time the player got it.
-- `quiet` skips the Collection Book message (the Kismat reveal shows it instead).
function Havelis.adopt(profile, def, mutation: string?, model: Model?, quiet: boolean?)
	local h = profile.haveli
	if not h then
		return nil, false
	end
	if not model then
		local created = Models.create(def, mutation)
		created:PivotTo(Models.stand(created, h.doorOutside))
		model = created
	end
	local entry = addEntry(profile, def, mutation, model :: Model, false)
	local isNew = State.discover(profile, def, mutation)
	if isNew then
		State.track(profile, "discover")
		if not quiet then
			State.notify(profile.player, "rare", "New in your Collection Book: " .. def.name .. "!")
		end
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
	Havelis.syncOwned(profile)
end

-- Gives the player the first empty haveli and puts their saved brainrots on their plots.
function Havelis.claim(profile): boolean
	for _, h in havelis do
		if h.owner then
			continue
		end
		h.owner = profile
		profile.haveli = h
		for _, key in profile.data.owned do
			local id, mutation = Mutations.parse(key)
			local def = Brainrots.byId[id]
			if def then
				addEntry(profile, def, mutation, Models.create(def, mutation), true)
			end
		end
		Havelis.restyle(profile)
		Havelis.arrange(profile, true)
		Havelis.refreshPrompts(profile)
		Havelis.updateGalla(profile)
		Defenses.applyCharacter(profile)
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
	h.guard = nil
	profile.haveli = nil
	HaveliStyle.apply(h, nil, 1)
	paintPlots(h, nil)
	updateSign(h)
	h.barrier.Transparency = 1
	Defenses.setLaser(h, false)
	h.gallaLabel.Text = "Galla"
	Defenses.applyCharacter(profile)
end

-- Copies the brainrots currently owned into the save data. Only while the
-- player has a haveli: before claiming one (full server) or after leaving,
-- profile.owned is empty and must not overwrite what was loaded.
function Havelis.syncData(profile)
	if not profile.haveli then
		return
	end
	local keys = {}
	for _, entry in profile.owned do
		table.insert(keys, Mutations.key(entry.def.id, entry.mutation))
	end
	profile.data.owned = keys
end

function Havelis.teleportHome(profile)
	local h = profile.haveli
	local character = profile.player.Character
	if h and character then
		if workspace.StreamingEnabled then
			-- load the haveli on the player's screen first, so they don't fall through the floor
			pcall(function()
				profile.player:RequestStreamAroundAsync(h.spawn.Position, 3)
			end)
		end
		character:PivotTo(h.spawn)
	end
end

function Havelis.upgrade(player: Player)
	local profile = State.profiles[player]
	if not profile or not profile.haveli then
		return
	end
	local data = profile.data
	local nextLevel = Config.HAVELI_LEVELS[data.level + 1]
	if not nextLevel then
		State.notify(player, "info", "Your haveli is already as big as it gets!")
		return
	end
	if data.rupees < nextLevel.cost then
		State.notify(player, "bad", ("You need %s to upgrade your haveli."):format(Format.rupees(nextLevel.cost)))
		return
	end
	State.addRupees(profile, -nextLevel.cost)
	data.level += 1
	State.syncStats(profile)
	Havelis.restyle(profile)
	State.notify(
		player,
		"rare",
		("Haveli Level %d: %s!%s"):format(
			data.level,
			nextLevel.name,
			if nextLevel.unlock then " " .. nextLevel.unlock .. "." else ""
		)
	)
	State.sound(player, "Upgrade")
	State.track(profile, "upgrade")
end

function Havelis.setTheme(player: Player, themeId: any)
	local profile = State.profiles[player]
	if not profile or type(themeId) ~= "string" or not Themes.byId[themeId] then
		return
	end
	if not Themes.isUnlocked(themeId, profile.data.rebirths) then
		State.notify(
			player,
			"bad",
			("%s unlocks after %d Naya Safar."):format(Themes.byId[themeId].name, Themes.byId[themeId].rebirths)
		)
		return
	end
	if profile.data.theme == themeId then
		return
	end
	profile.data.theme = themeId
	State.syncStats(profile)
	Havelis.restyle(profile)
	Havelis.applyWalkSpeed(profile)
	State.notify(
		player,
		"good",
		("Your haveli is now %s! %s"):format(Themes.byId[themeId].name, Themes.byId[themeId].perkText)
	)
end

-- Taala: lock your haveli. From Level 3 the Laser Darwaza also blocks the door.
function Havelis.lock(player: Player)
	local profile = State.profiles[player]
	local h = profile and profile.haveli
	if not h then
		return
	end
	local now = workspace:GetServerTimeNow()
	if now < profile.lockReadyAt then
		State.notify(player, "bad", ("Your taala is not ready yet (%ds)."):format(math.ceil(profile.lockReadyAt - now)))
		return
	end
	local duration = Havelis.taalaTime(profile)
	profile.lockedUntil = now + duration
	profile.lockReadyAt = now + duration + Config.LOCK_COOLDOWN
	player:SetAttribute("LockedUntil", profile.lockedUntil)
	player:SetAttribute("LockReadyAt", profile.lockReadyAt)
	Havelis.refreshPrompts(profile)

	local laser = profile.data.level >= Config.LASER_LEVEL
	if laser then
		-- nobody gets trapped inside: other players are moved out of the door
		for _, other in Players:GetPlayers() do
			local root = State.rootPart(other)
			if other ~= player and root and Havelis.isInside(h, root.Position) then
				(other.Character :: Model):PivotTo(h.doorOutside + Vector3.new(0, 4, 0))
			end
		end
	end
	State.notify(
		player,
		"good",
		("Taala laga diya! Your haveli is locked for %d seconds%s."):format(
			duration,
			if laser then " and the Laser Darwaza is on" else ""
		)
	)
	State.track(profile, "taala")
	task.delay(duration + 0.1, function()
		if State.profiles[player] == profile then
			Havelis.refreshPrompts(profile)
			State.notify(player, "info", "Your taala is open again.")
		end
	end)
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
	State.sound(player, "Coin")
	State.track(profile, "collect", amount)
end

function Havelis.init(map)
	gameMap = map
	havelis = map.havelis
	for i, h in havelis do
		-- Havelis are looked up by the index stored on their plots, so keep them in order.
		h.index = i
		for _, plot in h.plots do
			plot:SetAttribute("HaveliIndex", i)
		end
		h.galla.Touched:Connect(function(hit)
			collectGalla(h, hit)
		end)
		HaveliStyle.apply(h, nil, 1)
		paintPlots(h, nil)
		updateSign(h)
	end
end

function Havelis.byIndex(index: number)
	return havelis[index]
end

-- The whole map (gates, doors, pumps...), for other modules and the tests.
function Havelis.map()
	return gameMap
end

function Havelis.all()
	return havelis
end

return Havelis
