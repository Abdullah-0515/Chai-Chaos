-- The server side of the Menu window: promo codes, the Settings switches,
-- offline earnings and the daily chai streak.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local Havelis = require(script.Parent.Havelis)

local Menu = {}

local SETTINGS = { music = true, sounds = true }
local CODE_COOLDOWN = 1.5

function Menu.sync(profile)
	local on = {}
	for name in SETTINGS do
		if profile.data.settings[name] ~= false then
			table.insert(on, name)
		end
	end
	table.sort(on)
	profile.player:SetAttribute("Settings", table.concat(on, ","))
	profile.player:SetAttribute("Streak", profile.data.streak)
end

function Menu.setSetting(player: Player, name: any, on: any)
	local profile = State.profiles[player]
	if not profile or type(name) ~= "string" or not SETTINGS[name] or type(on) ~= "boolean" then
		return
	end
	profile.data.settings[name] = on
	Menu.sync(profile)
end

function Menu.redeem(player: Player, text: any)
	local profile = State.profiles[player]
	if not profile or type(text) ~= "string" or #text > 40 then
		return
	end
	local t = os.clock()
	if t - (profile.codeAt or -10) < CODE_COOLDOWN then
		return
	end
	profile.codeAt = t
	local code = string.upper((string.gsub(text, "%s", "")))
	local reward = Config.CODES[code]
	if not reward then
		State.sound(player, "Error")
		State.notify(player, "bad", "That code doesn't work. Check the spelling!")
		return
	end
	if profile.data.codes[code] then
		State.notify(player, "info", "You have already used that code.")
		return
	end
	profile.data.codes[code] = true
	local parts = {}
	if reward.rupees then
		State.addRupees(profile, reward.rupees)
		table.insert(parts, Format.rupees(reward.rupees))
	end
	if reward.rolls then
		profile.data.rollTokens += reward.rolls
		State.syncTokens(profile)
		table.insert(parts, ("%d Kismat Roll%s"):format(reward.rolls, if reward.rolls == 1 then "" else "s"))
	end
	State.sound(player, "Purchase")
	State.notify(player, "good", ("Code %s: you got %s!"):format(code, table.concat(parts, " and ")))
end

-- Brainrots keep earning a little while you are away. Call it when a player
-- joins, after their brainrots are back on their plots.
function Menu.offlineEarnings(profile)
	local data = profile.data
	local away = os.time() - data.lastSeen
	if data.lastSeen <= 0 or away < Config.OFFLINE_MIN then
		return
	end
	local seconds = math.min(away, Config.OFFLINE_MAX)
	local earned = math.floor(Havelis.incomePerSecond(profile) * seconds * Config.OFFLINE_RATE)
	if earned <= 0 then
		return
	end
	data.galla += earned
	Havelis.updateGalla(profile)
	State.notify(
		profile.player,
		"good",
		("While you were away your brainrots earned %s. It is waiting in your galla!"):format(Format.rupees(earned))
	)
end

-- Counts days in a row. Returns the streak and the bonus Kismat Rolls for it.
function Menu.streak(profile, today: number): (number, number)
	local data = profile.data
	data.streak = if data.lastDaily == today - 1 then data.streak + 1 else 1
	return data.streak, Config.streakRolls(data.streak)
end

function Menu.init()
	Remotes.RedeemCode.OnServerEvent:Connect(Menu.redeem)
	Remotes.SetSetting.OnServerEvent:Connect(Menu.setSetting)
end

return Menu
