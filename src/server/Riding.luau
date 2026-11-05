-- Riding a brainrot. Pick one of your brainrots in the Brainrots window and it
-- carries you everywhere, faster the rarer it is. Your ride leaves its plot
-- and does not earn rupees; the rest stay home and farm.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Brainrots = require(Shared.Brainrots)
local Mutations = require(Shared.Mutations)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local Models = require(script.Parent.Models)
local Havelis = require(script.Parent.Havelis)

local Riding = {}

function Riding.speedFor(def, mutation: string?): number
	return (Config.RIDE_SPEED[def.rarity] or 1) + (if mutation then Config.RIDE_MUTATION_BONUS[mutation] or 0 else 0)
end

local function sync(profile)
	local ride = profile.ride
	profile.player:SetAttribute("Ride", if ride then Mutations.displayName(ride.def, ride.mutation) else "")
	profile.player:SetAttribute("RideSpeed", if ride then Riding.speedFor(ride.def, ride.mutation) else 1)
	profile.data.ride = if ride then Mutations.key(ride.def.id, ride.mutation) else nil
end

function Riding.dismount(profile)
	local ride = profile.ride
	if ride and ride.model then
		ride.model:Destroy()
		ride.model = nil
	end
	local character = profile.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and profile.baseHipHeight then
		humanoid.HipHeight = profile.baseHipHeight
	end
	profile.rideSpeed = nil
	Havelis.applyWalkSpeed(profile)
end

-- Puts the ride under the player's character.
function Riding.mount(profile)
	local ride = profile.ride
	local character = profile.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = State.rootPart(profile.player)
	if not ride or not humanoid or not root then
		return
	end
	if ride.model then
		ride.model:Destroy()
	end
	local model = Models.create(ride.def, ride.mutation)
	local height = model:GetAttribute("Height") or 3
	profile.baseHipHeight = profile.baseHipHeight or humanoid.HipHeight
	humanoid.HipHeight = profile.baseHipHeight + height
	-- the ride's feet on the ground, the player sitting on top
	local rootHalf = root.Size.Y / 2
	local offset = CFrame.new(0, -rootHalf - humanoid.HipHeight + (model:GetAttribute("GroundOffset") or 0), 0)
	model:SetAttribute("Carried", true)
	model:PivotTo(root.CFrame * offset)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.Massless = true
			p.CanCollide = false
		elseif p:IsA("BillboardGui") then
			p.Enabled = false
		end
	end
	local weld = Instance.new("WeldConstraint")
	weld.Name = "RideWeld"
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
	model.Name = "Ride"
	model.Parent = character
	ride.model = model
	profile.rideSpeed = Riding.speedFor(ride.def, ride.mutation)
	Havelis.applyWalkSpeed(profile)
end

-- Pick a brainrot (by uid) to ride, or nil to stop riding.
function Riding.set(player: Player, uid: any)
	local profile = State.profiles[player]
	if not profile or not profile.haveli then
		return
	end
	if uid == nil then
		local ride = profile.ride
		if not ride then
			return
		end
		if not Havelis.hasFreePlot(profile) then
			State.notify(player, "bad", "No free plot for your ride to go home to!")
			return
		end
		Riding.dismount(profile)
		profile.ride = nil
		sync(profile)
		Havelis.adopt(profile, ride.def, ride.mutation, nil, true)
		State.notify(
			player,
			"info",
			("%s walked home to farm rupees."):format(Mutations.displayName(ride.def, ride.mutation))
		)
		return
	end
	if type(uid) ~= "number" then
		return
	end
	local entry = nil
	for _, e in profile.owned do
		if e.uid == uid then
			entry = e
		end
	end
	if not entry or entry.carrier then
		return
	end
	local old = profile.ride
	Havelis.remove(profile, entry)
	entry.model:Destroy()
	profile.ride = { def = entry.def, mutation = entry.mutation }
	if old then
		if old.model then
			old.model:Destroy()
		end
		Havelis.adopt(profile, old.def, old.mutation, nil, true)
	end
	sync(profile)
	Riding.mount(profile)
	State.sound(player, "Upgrade")
	State.notify(
		player,
		"good",
		("You're riding %s! %d%% faster."):format(
			Mutations.displayName(entry.def, entry.mutation),
			math.floor((Riding.speedFor(entry.def, entry.mutation) - 1) * 100 + 0.5)
		)
	)
end

-- After joining: get the saved ride back.
function Riding.restore(profile)
	local key = profile.data.ride
	if type(key) == "string" then
		local id, mutation = Mutations.parse(key)
		local def = Brainrots.byId[id]
		if def then
			profile.ride = { def = def, mutation = mutation }
		end
	end
	sync(profile)
end

-- Naya Safar: the ride goes too.
function Riding.reset(profile)
	Riding.dismount(profile)
	profile.ride = nil
	sync(profile)
end

function Riding.init()
	Remotes.SetRide.OnServerEvent:Connect(Riding.set)
end

return Riding
