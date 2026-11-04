-- Moves brainrot models around without physics: walking down Bazaar Lane,
-- walking to a plot, or riding on a thief's back. Everything runs in one
-- Heartbeat loop. All brainrot parts are anchored, so PivotTo is all we need.

local RunService = game:GetService("RunService")

local Mover = {}

local jobs: { [Model]: any } = {}
local freezeUntil = 0
local freezeExempt: Model? = nil

local function startSegment(model: Model, job)
	local from = model:GetPivot()
	local to: CFrame = job.points[job.index]
	job.from = from
	job.t = 0
	job.duration = math.max((to.Position - from.Position).Magnitude / job.speed, 0.05)
end

-- Walk through each CFrame in `points` at `speed` studs per second.
-- `onDone` runs after the last point is reached (not if the walk is replaced or stopped).
function Mover.walk(model: Model, points: { CFrame }, speed: number, onDone: (() -> ())?)
	local job = {
		kind = "walk",
		points = points,
		index = 1,
		speed = speed,
		onDone = onDone,
		phase = math.random() * math.pi * 2,
	}
	startSegment(model, job)
	jobs[model] = job
end

-- Stick to `part` (for example a thief's HumanoidRootPart) with an offset.
function Mover.follow(model: Model, part: BasePart, offset: CFrame)
	jobs[model] = { kind = "follow", part = part, offset = offset }
end

function Mover.stop(model: Model)
	jobs[model] = nil
end

-- Every walking brainrot except `exempt` stops for `seconds`.
function Mover.freeze(seconds: number, exempt: Model?)
	freezeUntil = os.clock() + seconds
	freezeExempt = exempt
end

RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	local frozen = now < freezeUntil
	local finished = {}

	for model, job in jobs do
		if model.Parent == nil then
			jobs[model] = nil
			continue
		end

		if job.kind == "follow" then
			if job.part.Parent then
				model:PivotTo(job.part.CFrame * job.offset)
			end
			continue
		end

		if frozen and model ~= freezeExempt then
			continue
		end

		job.t += dt
		local to: CFrame = job.points[job.index]
		local alpha = math.min(job.t / job.duration, 1)

		if alpha < 1 then
			local position = job.from.Position:Lerp(to.Position, alpha)
			local flat = (to.Position - job.from.Position) * Vector3.new(1, 0, 1)
			local facing = if flat.Magnitude > 0.01
				then CFrame.lookAt(position, position + flat)
				else job.from.Rotation + position
			local hop = math.abs(math.sin(now * 8 + job.phase)) * 0.6
			model:PivotTo(facing + Vector3.new(0, hop, 0))
		else
			model:PivotTo(to)
			if job.index < #job.points then
				job.index += 1
				startSegment(model, job)
			else
				jobs[model] = nil
				if job.onDone then
					table.insert(finished, job.onDone)
				end
			end
		end
	end

	-- Run callbacks after the loop so they can safely start new jobs.
	for _, callback in finished do
		task.spawn(callback)
	end
end)

return Mover
