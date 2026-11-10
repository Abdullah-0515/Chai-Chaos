-- Badges for first-time moments. Their ids are in Config.BADGES; a badge with
-- id 0 is skipped. Each badge is remembered in the player's save once Roblox
-- has awarded it, so Roblox is only asked once.

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Biomes = require(Shared.Biomes)

local State = require(script.Parent.State)

local Badges = {}

-- What a player does (see State.track) and the badge it earns.
local FOR = {
	eggHome = "FirstEgg",
	hatchRare = "FirstRare",
	vehicle = "Driver",
	catchWild = "WildCatcher",
	rebirth = "NayaSafar",
	hatchSecret = "SecretKeeper",
}

function Badges.award(profile, name: string)
	local badgeId = Config.BADGES[name]
	if not badgeId or badgeId == 0 or profile.data.badges[name] or profile.badgePending == name then
		return
	end
	profile.badgePending = name
	task.spawn(function()
		local ok, awarded = pcall(function()
			return BadgeService:AwardBadge(profile.player.UserId, badgeId)
		end)
		-- AwardBadge is false when they already have it: remember that too
		if ok and awarded ~= nil then
			profile.data.badges[name] = true
		end
		if profile.badgePending == name then
			profile.badgePending = nil
		end
	end)
end

local function ringOneDone(profile): boolean
	for _, biome in Biomes.list do
		if biome.ring == 1 and not State.isZoneOpen(profile, biome) then
			return false
		end
	end
	return true
end

function Badges.init()
	State.onTrack(function(profile, kind: string)
		local name = FOR[kind]
		if name then
			Badges.award(profile, name)
		end
		if kind == "zone" and ringOneDone(profile) then
			Badges.award(profile, "Explorer")
		end
	end)
	local any = false
	for _, badgeId in Config.BADGES do
		any = any or badgeId ~= 0
	end
	if not any then
		print("[ChaiChaos] Badges are off until you add their ids to Config.BADGES.")
	end
end

return Badges
