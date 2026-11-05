-- Runs the server events from Events.luau: the first one a few minutes after
-- the server starts, then one every 15-20 minutes, each lasting 5 minutes.
-- The running event is stored in workspace attributes so every script (and
-- every player's screen) can read it: EventId, EventEndsAt and NextEventAt.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Events = require(Shared.Events)

local State = require(script.Parent.State)
local World = require(script.Parent.World)

local EventRunner = {}

local lastId: string? = nil

local function now(): number
	return workspace:GetServerTimeNow()
end

function EventRunner.start(id: string)
	local event = Events.byId[id]
	if not event then
		return
	end
	lastId = id
	workspace:SetAttribute("EventId", id)
	workspace:SetAttribute("EventEndsAt", now() + Config.EVENT_DURATION)
	World.forceNight = event.night == true
	State.notifyAll("rare", ("EVENT: %s %s"):format(event.name, event.blurb))
	State.soundAll("EventStart")
end

function EventRunner.stop()
	local event = Events.current()
	workspace:SetAttribute("EventId", "")
	World.forceNight = false
	if event then
		State.notifyAll("info", event.name .. " is over. The next event is coming soon!")
	end
end

-- A random event, never the same one twice in a row.
function EventRunner.pick(): string
	local choices = {}
	for _, event in Events.list do
		if event.id ~= lastId then
			table.insert(choices, event.id)
		end
	end
	return choices[math.random(#choices)]
end

function EventRunner.init()
	workspace:SetAttribute("EventId", "")
	task.spawn(function()
		local gap = Config.FIRST_EVENT_DELAY
		while true do
			workspace:SetAttribute("NextEventAt", now() + gap)
			task.wait(gap)
			EventRunner.start(EventRunner.pick())
			task.wait(Config.EVENT_DURATION)
			EventRunner.stop()
			gap = math.random(Config.EVENT_GAP_MIN, Config.EVENT_GAP_MAX)
		end
	end)
end

return EventRunner
