-- Moves brainrot models: walking home from the door or walking to a plot.
--
-- For smooth movement the server does not move models every frame. When a
-- brainrot starts walking, the server writes where from, where to, when and
-- how fast into attributes, and every player's screen animates it smoothly
-- (Smooth.client.luau). The server still updates the real position 10 times
-- a second so prompts and distance checks stay right.
--
-- Carrying a brainrot is done with a weld (Models.attach), not here.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Motion = require(Shared.Motion)

local Mover = {}

local UPDATE_EVERY = 0.1

local jobs: { [Model]: any } = {}
local sinceUpdate = 0

local function now(): number
	return workspace:GetServerTimeNow()
end

local function rest(model: Model, cf: CFrame)
	model:SetAttribute("MoveSpeed", 0)
	model:SetAttribute("Rest", cf)
end

local function startSegment(model: Model, job)
	job.from = model:GetPivot()
	job.startedAt = now()
	model:SetAttribute("MoveFrom", job.from)
	model:SetAttribute("MoveTo", job.points[job.index])
	model:SetAttribute("MoveStart", job.startedAt)
	model:SetAttribute("MoveSpeed", job.speed)
end

local function current(job, t: number): (CFrame, boolean)
	return Motion.at(job.from, job.points[job.index], job.startedAt, job.speed, t)
end

-- Walk through each CFrame in `points` at `speed` studs per second.
-- `onDone` runs after the last point is reached (not if the walk is replaced or stopped).
function Mover.walk(model: Model, points: { CFrame }, speed: number, onDone: (() -> ())?)
	local old = jobs[model]
	if old then
		model:PivotTo((current(old, now())))
	end
	local job = { points = points, index = 1, speed = speed, onDone = onDone }
	jobs[model] = job
	startSegment(model, job)
end

-- Put a model somewhere instantly.
function Mover.place(model: Model, cf: CFrame)
	jobs[model] = nil
	model:PivotTo(cf)
	rest(model, cf)
end

-- Stop walking right where it is.
function Mover.stop(model: Model)
	local job = jobs[model]
	if not job then
		return
	end
	jobs[model] = nil
	local cf = current(job, now())
	model:PivotTo(cf)
	rest(model, cf)
end

-- Where a model is right now, even mid-walk.
function Mover.pivot(model: Model): CFrame
	local job = jobs[model]
	if job then
		return (current(job, now()))
	end
	return model:GetPivot()
end

function Mover.isWalking(model: Model): boolean
	return jobs[model] ~= nil
end

RunService.Heartbeat:Connect(function(dt)
	sinceUpdate += dt
	if sinceUpdate < UPDATE_EVERY then
		return
	end
	sinceUpdate = 0
	local t = now()

	local finished = {}
	for model, job in jobs do
		if model.Parent == nil then
			jobs[model] = nil
			continue
		end
		local cf, arrived = current(job, t)
		model:PivotTo(cf)
		if arrived then
			if job.index < #job.points then
				job.index += 1
				startSegment(model, job)
			else
				jobs[model] = nil
				rest(model, cf)
				if job.onDone then
					table.insert(finished, job.onDone)
				end
			end
		end
	end

	-- Run callbacks after the loop so they can safely start new walks.
	for _, callback in finished do
		task.spawn(callback)
	end
end)

return Mover
