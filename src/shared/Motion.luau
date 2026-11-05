-- The walking maths shared by the server (Mover.luau) and every player's
-- screen (Smooth.client.luau), so both agree on where a brainrot is.

local Motion = {}

-- Where a brainrot walking from `from` to `to` at `speed` studs per second,
-- starting at `startedAt` (server time), is at server time `now`.
-- Returns the CFrame and whether it has arrived.
function Motion.at(from: CFrame, to: CFrame, startedAt: number, speed: number, now: number): (CFrame, boolean)
	local distance = (to.Position - from.Position).Magnitude
	local duration = math.max(distance / math.max(speed, 0.01), 0.05)
	local alpha = math.clamp((now - startedAt) / duration, 0, 1)
	if alpha >= 1 then
		return to, true
	end
	local position = from.Position:Lerp(to.Position, alpha)
	local flat = (to.Position - from.Position) * Vector3.new(1, 0, 1)
	if flat.Magnitude > 0.01 then
		return CFrame.lookAt(position, position + flat), false
	end
	return from.Rotation + position, false
end

function Motion.duration(from: CFrame, to: CFrame, speed: number): number
	return math.max((to.Position - from.Position).Magnitude / math.max(speed, 0.01), 0.05)
end

return Motion
