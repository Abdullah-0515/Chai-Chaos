-- Zone gates. Ring 1 and ring 2 zones are unlocked with rupees at their gate
-- (Mango Bagh is free); ring 3 zones open once you have enough rebirths.
-- You must unlock the zone in front of a gate before the one behind it.
-- Unlocks are kept forever, even after a Naya Safar.
--
-- The gate barriers and shortcut doors are solid on the server. Each player's
-- screen lets them through the ones they have unlocked (Gates.client.luau),
-- and the server only lets you collect eggs and treasure in your open zones.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Biomes = require(Shared.Biomes)
local Format = require(Shared.Format)

local State = require(script.Parent.State)
local Havelis = require(script.Parent.Havelis)

local Zones = {}

local GATE_REACH = 22

function Zones.unlock(player: Player, barrier: Instance?)
	local profile = State.profiles[player]
	local biome = barrier and Biomes.byId[barrier:GetAttribute("Zone") or ""]
	if not profile or not biome or not barrier:IsA("BasePart") then
		return
	end
	if not State.isNear(player, barrier.Position, GATE_REACH) then
		return
	end
	local data = profile.data
	if State.isZoneOpen(profile, biome) then
		State.notify(player, "info", ("%s is already open for you. Walk right through!"):format(biome.name))
		return
	end
	if biome.rebirths > 0 then
		State.notify(
			player,
			"bad",
			("%s opens after %s. You have %d. Start a Naya Safar at the Chowk!"):format(
				biome.name,
				Biomes.costText(biome),
				data.rebirths
			)
		)
		State.sound(player, "Error")
		return
	end
	local before = Biomes.before(biome)
	if before and not State.isZoneOpen(profile, before) then
		State.notify(player, "bad", ("Unlock %s first!"):format(before.name))
		return
	end
	if data.rupees < biome.price then
		State.notify(player, "bad", ("%s costs %s to unlock."):format(biome.name, Format.rupees(biome.price)))
		State.sound(player, "Error")
		return
	end
	State.addRupees(profile, -biome.price)
	data.zones[biome.id] = true
	State.syncZones(profile)
	State.sound(player, "Purchase")
	State.track(profile, "zone")
	State.notify(player, "rare", ("%s unlocked! %s"):format(biome.name, biome.blurb))
end

-- The rickshaw at the end of every ring 3 road takes you back to the Chowk.
function Zones.rideHome(player: Player, pad: Instance?)
	local profile = State.profiles[player]
	if not profile or not pad or not pad:IsA("BasePart") then
		return
	end
	if not State.isNear(player, pad.Position, 18) then
		return
	end
	if profile.carryingBrainrot then
		State.notify(player, "bad", "The rickshaw wala won't take a stolen brainrot!")
		return
	end
	-- eggs have to make the trip home the slow way, or their timers mean nothing
	if profile.egg or #profile.boot > 0 then
		State.notify(player, "bad", "No eggs in the rickshaw! Drive or carry them home.")
		return
	end
	if profile.driving then
		State.notify(player, "bad", "Park your vehicle first. The rickshaw wala only takes people!")
		return
	end
	local character = player.Character
	if character then
		character:PivotTo(CFrame.new(Vector3.new(24, Biomes.GROUND_Y + 4, 0)))
		State.sound(player, "Purchase")
		State.notify(player, "good", "Pon pon! The rickshaw dropped you at the Chowk.")
	end
end

-- After a Naya Safar (ring 3 zones open with rebirths).
function Zones.refresh(profile)
	State.syncZones(profile)
	Havelis.applyWalkSpeed(profile)
end

return Zones
