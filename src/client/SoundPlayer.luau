-- Plays the sounds from Sounds.luau on this player's screen.
--
-- One Sound instance per name lives in SoundService. A sound with a position
-- (an egg hatching, a treasure chest) gets quieter the further away it is.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Sounds = require(Shared:WaitForChild("Sounds"))

local SoundPlayer = {}

local HEARING_RANGE = 120 -- studs; further away than this a positioned sound is silent

local folder = Instance.new("Folder")
folder.Name = "ChaiChaosSounds"
folder.Parent = SoundService

local made: { [string]: Sound } = {}

-- The Sound for a name, or nil if the name is unknown or has no id yet.
function SoundPlayer.get(name: string): Sound?
	local info = Sounds.list[name]
	if not info or info.id == "" then
		return nil
	end
	local sound = made[name]
	if not sound then
		local created = Instance.new("Sound")
		created.Name = name
		created.SoundId = info.id
		created.Volume = info.volume
		created.PlaybackSpeed = info.pitch or 1
		created.Looped = info.looped == true
		created.Parent = folder
		made[name] = created
		sound = created
	end
	return sound
end

local function distanceVolume(position: Vector3?): number
	if not position then
		return 1
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return 1
	end
	local distance = (root.Position - position).Magnitude
	return math.clamp(1 - distance / HEARING_RANGE, 0, 1)
end

-- `pitch` multiplies the sound's own pitch (every vehicle's horn sounds different).
function SoundPlayer.play(name: string, position: Vector3?, pitch: number?)
	local sound = SoundPlayer.get(name)
	if not sound then
		return
	end
	local fade = distanceVolume(position)
	if fade <= 0 then
		return
	end
	sound.PlaybackSpeed = (Sounds.list[name].pitch or 1) * (pitch or 1)
	sound.Volume = Sounds.list[name].volume * fade
	sound.TimePosition = 0
	sound:Play()
end

-- Starts or stops a looping sound (wind, music).
function SoundPlayer.loop(name: string, on: boolean)
	local sound = SoundPlayer.get(name)
	if not sound then
		return
	end
	if on and not sound.IsPlaying then
		sound:Play()
	elseif not on and sound.IsPlaying then
		sound:Stop()
	end
end

return SoundPlayer
