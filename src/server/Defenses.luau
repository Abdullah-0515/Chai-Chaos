-- The Laser Darwaza: while a haveli with Level 3 or more is locked with the
-- Taala, its doorway physically blocks everyone except the owner.
--
-- Each haveli gets two collision groups: one for its laser and one for its
-- owner's character. They do not collide with each other, so only the owner
-- can walk through.

local PhysicsService = game:GetService("PhysicsService")

local Defenses = {}

local function laserGroup(index: number): string
	return "ChaiLaser" .. index
end

local function ownerGroup(index: number): string
	return "ChaiOwner" .. index
end

local function register(name: string)
	if not PhysicsService:IsCollisionGroupRegistered(name) then
		PhysicsService:RegisterCollisionGroup(name)
	end
end

local function setGroup(character: Model, group: string)
	for _, p in character:GetDescendants() do
		if p:IsA("BasePart") then
			p.CollisionGroup = group
		end
	end
end

function Defenses.init(map)
	for _, h in map.havelis do
		local laser, owner = laserGroup(h.index), ownerGroup(h.index)
		register(laser)
		register(owner)
		PhysicsService:CollisionGroupSetCollidable(laser, owner, false)
		h.barrier.CollisionGroup = laser
		h.barrier.CanCollide = false
	end
end

-- Put a player's character in their haveli's owner group (or back to Default).
-- Call when they claim or leave a haveli and every time their character spawns.
function Defenses.applyCharacter(profile)
	local character = profile.player.Character
	if not character then
		return
	end
	local group = if profile.haveli then ownerGroup(profile.haveli.index) else "Default"
	setGroup(character, group)
	if profile.groupConnection then
		profile.groupConnection:Disconnect()
	end
	profile.groupConnection = character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = group
		end
	end)
end

function Defenses.setLaser(h, on: boolean)
	h.barrier.CanCollide = on
end

return Defenses
