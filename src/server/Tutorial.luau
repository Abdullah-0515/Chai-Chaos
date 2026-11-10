-- The new-player guide (the steps are in the shared Tutorial module).
--
-- Every player has a step saved in their data. When they do what the step
-- asks, they move on to the next one; steps they have already done are
-- skipped. Finishing the guide pays a few Kismat Rolls, once.
-- The Menu window can skip the guide or start it again.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Biomes = require(Shared.Biomes)
local Remotes = require(Shared.Remotes)
local Steps = require(Shared.Tutorial)

local State = require(script.Parent.State)

local Tutorial = {}

function Tutorial.sync(profile)
	local step = Steps.steps[profile.data.tutorial]
	profile.player:SetAttribute("Tutorial", if step then step.id else "")
	profile.player:SetAttribute("TutorialStep", profile.data.tutorial)
end

-- Has the player already done this step some other way?
local function alreadyDone(profile, step): boolean
	local data = profile.data
	if step.id == "vehicle" then
		return next(data.vehicles) ~= nil
	elseif step.id == "drive" then
		return profile.driving ~= nil
	elseif step.id == "zone" then
		return next(data.zones) ~= nil
	end
	return false
end

local function finish(profile)
	local data = profile.data
	if data.guideRewarded then
		State.notify(profile.player, "good", "Guide finished! You know your way around now.")
		return
	end
	data.guideRewarded = true
	data.rollTokens += Steps.REWARD_ROLLS
	State.syncTokens(profile)
	State.sound(profile.player, "Upgrade")
	State.notify(
		profile.player,
		"rare",
		("Guide finished! Here are %d Kismat Rolls. Try them at the Kismat Kettle in the Chowk."):format(
			Steps.REWARD_ROLLS
		)
	)
end

-- Something happened (see State.track): move on if it is what the step asks.
function Tutorial.onTrack(profile, kind: string)
	local data = profile.data
	local moved = false
	while true do
		local step = Steps.steps[data.tutorial]
		if not step then
			break
		end
		-- picking up an egg also means you found the zone
		local done = step.done == kind or (step.id == "leave" and kind == "eggPickup") or alreadyDone(profile, step)
		if not done then
			break
		end
		data.tutorial += 1
		moved = true
		if step.done == kind then
			kind = "" -- one action finishes one step
		end
	end
	if moved then
		Tutorial.sync(profile)
		if data.tutorial >= Steps.DONE then
			finish(profile)
		else
			State.sound(profile.player, "Click")
		end
	end
end

function Tutorial.command(player: Player, what: any)
	local profile = State.profiles[player]
	if not profile then
		return
	end
	if what == "skip" then
		if profile.data.tutorial < Steps.DONE then
			profile.data.tutorial = Steps.DONE
			Tutorial.sync(profile)
			State.notify(player, "info", "Guide hidden. You can start it again in the Menu.")
		end
	elseif what == "restart" then
		profile.data.tutorial = 1
		Tutorial.sync(profile)
		Tutorial.onTrack(profile, "")
	end
end

function Tutorial.init()
	State.onTrack(Tutorial.onTrack)
	Remotes.Guide.OnServerEvent:Connect(Tutorial.command)
	-- the first step is done by walking into Mango Bagh
	task.spawn(function()
		while true do
			task.wait(1)
			for player, profile in State.profiles do
				local step = Steps.steps[profile.data.tutorial]
				local root = step and step.done == "enterZone" and State.rootPart(player)
				if root then
					local biome = Biomes.at(root.Position)
					if biome and step.target == "zone:" .. biome.id then
						Tutorial.onTrack(profile, "enterZone")
					end
				end
			end
		end
	end)
end

return Tutorial
