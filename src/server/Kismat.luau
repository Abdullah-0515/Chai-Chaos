-- Kismat Roll: an RNG roll for a random brainrot.
--
-- Pay Rs 2,500 or use a Kismat Roll. Rolls come free with daily chai and can
-- be bought with Robux (see Shop.luau and Config.ROLL_PRODUCTS).
--
-- The odds are in Config.ROLL_ODDS and are shown in the Kismat panel before
-- anyone buys. Every ROLL_PITY rolls an Epic or better is guaranteed; a
-- Legendary or Mythic is never guaranteed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local Havelis = require(script.Parent.Havelis)
local Spawner = require(script.Parent.Spawner)

local Kismat = {}

local EPIC_PLUS = { Epic = true, Legendary = true, Mythic = true }

local lastRoll: { [Player]: number } = {}

-- Picks a brainrot with the Kismat odds. With `pity`, only Epic or better.
function Kismat.pick(pity: boolean)
	if not pity then
		return Spawner.pick(Config.ROLL_ODDS)
	end
	local odds = {}
	for rarity, weight in Config.ROLL_ODDS do
		odds[rarity] = if EPIC_PLUS[rarity] then weight else 0
	end
	return Spawner.pick(odds)
end

function Kismat.roll(player: Player, method: any)
	local profile = State.profiles[player]
	if not profile or not profile.haveli or (method ~= "rupees" and method ~= "token") then
		return
	end
	local now = os.clock()
	if now < (lastRoll[player] or -math.huge) + Config.ROLL_COOLDOWN then
		return
	end
	local data = profile.data
	if not Havelis.hasFreePlot(profile) then
		State.notify(player, "bad", "No empty plot for a new brainrot! Unlock a plot or sell one first.")
		return
	end
	if method == "token" then
		if data.rollTokens < 1 then
			State.notify(player, "bad", "You have no Kismat Rolls left.")
			return
		end
		data.rollTokens -= 1
	else
		if data.rupees < Config.ROLL_RUPEE_COST then
			State.notify(player, "bad", ("A Kismat Roll costs %s."):format(Format.rupees(Config.ROLL_RUPEE_COST)))
			return
		end
		State.addRupees(profile, -Config.ROLL_RUPEE_COST)
	end
	lastRoll[player] = now

	local pity = data.rollPity + 1 >= Config.ROLL_PITY
	local def = Kismat.pick(pity)
	data.rollPity = if EPIC_PLUS[def.rarity] then 0 else data.rollPity + 1
	local _, isNew = Havelis.adopt(profile, def, nil, true)
	State.syncTokens(profile)
	Remotes.RollResult:FireClient(player, def.id, isNew, pity)

	if def.rarity == "Legendary" or def.rarity == "Mythic" then
		-- wait for the roller's reveal before telling everyone
		task.delay(Config.ROLL_COOLDOWN, function()
			State.notifyAll("rare", ("%s rolled a %s %s!"):format(player.DisplayName, def.rarity:upper(), def.name))
		end)
	end
end

function Kismat.forget(player: Player)
	lastRoll[player] = nil
end

function Kismat.init()
	Remotes.Roll.OnServerEvent:Connect(Kismat.roll)
end

return Kismat
