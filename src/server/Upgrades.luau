-- The Chowk's shops: Gear, the Tracker (radar) and the Sell stall.
-- You have to stand at the shop to use it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Gear = require(Shared.Gear)
local Mutations = require(Shared.Mutations)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local Havelis = require(script.Parent.Havelis)

local Upgrades = {}

local map = nil

-- Is the player standing at this Chowk shop?
function Upgrades.atShop(player: Player, shop: string, distance: number?): boolean
	local part = map and map.shops[shop]
	return part ~= nil and State.isNear(player, part.Position, distance or 24)
end

function Upgrades.buyGear(player: Player, id: any)
	local profile = State.profiles[player]
	local item = type(id) == "string" and Gear.byId[id]
	if not profile or not item or not Upgrades.atShop(player, "Gear") then
		return
	end
	local data = profile.data
	if data.gear[item.id] then
		return
	end
	if data.rupees < item.cost then
		State.notify(player, "bad", ("%s costs %s."):format(item.name, Format.rupees(item.cost)))
		State.sound(player, "Error")
		return
	end
	State.addRupees(profile, -item.cost)
	data.gear[item.id] = true
	State.syncGear(profile)
	Havelis.applyWalkSpeed(profile)
	State.sound(player, "Purchase")
	State.notify(player, "good", ("You got the %s! %s."):format(item.name, item.text))
end

function Upgrades.upgradeTracker(player: Player)
	local profile = State.profiles[player]
	if not profile or not Upgrades.atShop(player, "Tracker") then
		return
	end
	local data = profile.data
	local nextLevel = Config.TRACKER_LEVELS[data.trackerLevel + 1]
	if not nextLevel then
		State.notify(player, "info", "Your tracker is the best there is!")
		return
	end
	if data.rupees < nextLevel.cost then
		State.notify(player, "bad", ("The next tracker costs %s."):format(Format.rupees(nextLevel.cost)))
		State.sound(player, "Error")
		return
	end
	State.addRupees(profile, -nextLevel.cost)
	data.trackerLevel += 1
	State.syncGear(profile)
	State.sound(player, "Upgrade")
	State.notify(
		player,
		"rare",
		("Tracker level %d! It now finds eggs in %d biomes, %d studs away."):format(
			data.trackerLevel,
			data.trackerLevel,
			nextLevel.range
		)
	)
	State.track(profile, "upgrade")
end

function Upgrades.sell(player: Player, uid: any)
	local profile = State.profiles[player]
	if not profile or type(uid) ~= "number" then
		return
	end
	if not Upgrades.atShop(player, "Sell", Config.SELL_DISTANCE) then
		State.notify(player, "bad", "Selling happens at the BECHO stall in the Chowk.")
		return
	end
	local entry = nil
	for _, e in profile.owned do
		if e.uid == uid then
			entry = e
		end
	end
	if not entry or entry.carrier or entry.def.questOnly then
		return
	end
	local amount = math.floor(Havelis.entryValue(entry) * Config.SELL_RATE)
	Havelis.remove(profile, entry)
	entry.model:Destroy()
	State.addRupees(profile, amount)
	State.sound(player, "Coin")
	State.notify(
		player,
		"good",
		("Sold %s for %s"):format(Mutations.displayName(entry.def, entry.mutation), Format.rupees(amount))
	)
	State.track(profile, "sell")
end

function Upgrades.init(gameMap)
	map = gameMap
	Remotes.BuyGear.OnServerEvent:Connect(Upgrades.buyGear)
	Remotes.UpgradeTracker.OnServerEvent:Connect(Upgrades.upgradeTracker)
	Remotes.SellBrainrot.OnServerEvent:Connect(Upgrades.sell)
end

return Upgrades
