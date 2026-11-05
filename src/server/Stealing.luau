-- Stealing brainrots from other havelis.
--
-- Hold E for 1.5 seconds on someone else's brainrot and it rides on your back.
-- Run through your own haveli door to keep it. If you die, fall off the map,
-- reset or leave, or someone bonks you with a chappal, it walks back home.
--
-- Every steal uses one Chor Pass, bought with Robux (Config.STEAL_PRODUCTS).
-- If the steal fails, the Chor Pass is given back (Config.STEAL_REFUND_ON_FAIL).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Mutations = require(Shared.Mutations)
local Themes = require(Shared.Themes)

local State = require(script.Parent.State)
local Models = require(script.Parent.Models)
local Mover = require(script.Parent.Mover)
local Havelis = require(script.Parent.Havelis)
local Shop = require(script.Parent.Shop)

local Stealing = {}

local CARRY_OFFSET = CFrame.new(0, 2.6, 2)

-- carrying[thief] = { entry, connections, marker, tag, usedPass }
local carrying: { [Player]: any } = {}
local lastSteal: { [Player]: number } = {}
local lastTarget: { [Player]: { ownerId: number, time: number } } = {}
local lastBonk: { [Player]: number } = {}

local function cleanup(carry)
	for _, connection in carry.connections do
		connection:Disconnect()
	end
	if carry.marker then
		carry.marker:Destroy()
	end
	if carry.tag then
		carry.tag:Destroy()
	end
end

local function markThief(character: Model)
	local marker = Instance.new("Highlight")
	marker.Name = "ChorMarker"
	marker.FillColor = Color3.fromRGB(255, 40, 40)
	marker.FillTransparency = 0.6
	marker.OutlineColor = Color3.fromRGB(255, 220, 60)
	marker.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	marker.Parent = character

	local tag = Instance.new("BillboardGui")
	tag.Name = "ChorTag"
	tag.Size = UDim2.fromScale(5, 1.5)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 6.5, 0)
	tag.AlwaysOnTop = true
	tag.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 70, 70)
	label.Text = "CHOR!"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Parent = label
	label.Parent = tag
	tag.Parent = character:FindFirstChild("Head") or character.PrimaryPart
	return marker, tag
end

-- A failed steal gives the thief their Chor Pass back.
local function refund(thief: Player, carry)
	if not carry.usedPass or not Config.STEAL_REFUND_ON_FAIL then
		return
	end
	local profile = State.profiles[thief]
	if profile then
		profile.data.stealTokens += 1
		State.syncTokens(profile)
		if thief.Parent then
			State.notify(thief, "info", "Your Chor Pass was given back.")
		end
	end
end

-- Puts the thief's walking speed back to normal.
local function unslow(thief: Player)
	local profile = State.profiles[thief]
	if profile then
		profile.carrySpeed = nil
		Havelis.applyWalkSpeed(profile)
	end
end

-- Sends a carried brainrot back to its owner.
function Stealing.returnToOwner(thief: Player, reason: string?)
	local carry = carrying[thief]
	if not carry then
		return
	end
	carrying[thief] = nil
	cleanup(carry)
	refund(thief, carry)
	unslow(thief)

	local entry = carry.entry
	Models.detach(entry.model)
	Models.setPanic(entry.model, entry.def, false)
	if State.entries[entry.model] ~= entry or not entry.model.Parent then
		return
	end
	Havelis.returnHome(entry)
	local owner = entry.owner.player
	local name = Mutations.displayName(entry.def, entry.mutation)
	if reason == "bonk" then
		State.notify(owner, "good", ("Bonk! Your %s is coming back home."):format(name))
	elseif reason == "guard" then
		State.notify(owner, "good", ("Your Chowkidar caught the chor! Your %s is safe."):format(name))
	else
		State.notify(owner, "good", ("Your %s escaped from the chor and is walking home!"):format(name))
	end
	if thief.Parent then
		if reason == "guard" then
			State.notify(thief, "bad", "Seeti! The Chowkidar caught you and took it back!")
		else
			State.notify(thief, "bad", ("You dropped %s!"):format(name))
		end
	end
end

function Stealing.complete(thief: Player)
	local carry = carrying[thief]
	local thiefProfile = State.profiles[thief]
	if not carry or not thiefProfile then
		return
	end
	if not Havelis.hasFreePlot(thiefProfile) then
		State.notify(thief, "bad", "No empty plot for it, so it ran back home!")
		Stealing.returnToOwner(thief)
		return
	end
	carrying[thief] = nil
	cleanup(carry)
	unslow(thief)

	local entry = carry.entry
	local ownerProfile = entry.owner
	Models.detach(entry.model)
	Models.setPanic(entry.model, entry.def, false)
	Havelis.remove(ownerProfile, entry)
	Havelis.adopt(thiefProfile, entry.def, entry.mutation, entry.model)

	local name = Mutations.displayName(entry.def, entry.mutation)
	State.notify(thief, "good", ("You got away with %s!"):format(name))
	State.notify(ownerProfile.player, "bad", ("%s got away with your %s."):format(thief.DisplayName, name))
end

local function deny(player: Player, text: string)
	State.notify(player, "bad", text)
end

function Stealing.start(thief: Player, model: Model)
	local thiefProfile = State.profiles[thief]
	local entry = State.entries[model]
	if not thiefProfile or not thiefProfile.haveli or not entry then
		return
	end
	local owner = entry.owner
	if owner == thiefProfile or entry.carrier or not entry.arrived then
		return
	end
	if carrying[thief] then
		return deny(thief, "You are already carrying a brainrot!")
	end

	local now = workspace:GetServerTimeNow()
	if entry.def.questOnly then
		return deny(thief, "Quest brainrots cannot be stolen.")
	end
	if Havelis.isLocker(entry.plot) then
		return deny(thief, "Locker plots cannot be robbed.")
	end
	if now < owner.lockedUntil then
		return deny(thief, "This haveli has a taala on it!")
	end
	if now < owner.protectedUntil then
		return deny(thief, owner.player.DisplayName .. " is new here and is protected for a bit.")
	end
	local remaining = Config.STEAL_COOLDOWN - (now - (lastSteal[thief] or -math.huge))
	if remaining > 0 then
		return deny(thief, ("Catch your breath! You can steal again in %d seconds."):format(math.ceil(remaining)))
	end
	local target = lastTarget[thief]
	if target and target.ownerId == owner.player.UserId and now - target.time < Config.SAME_HAVELI_COOLDOWN then
		return deny(thief, "You just robbed this haveli. Try a different one!")
	end
	if Havelis.entryValue(entry) > Config.STEAL_PRICE_CAP and thiefProfile.data.rebirths < 1 then
		return deny(
			thief,
			("Do a Naya Safar first to steal brainrots worth more than %s."):format(
				Format.rupees(Config.STEAL_PRICE_CAP)
			)
		)
	end
	if not Havelis.hasFreePlot(thiefProfile) then
		return deny(thief, "You have no empty plot to keep it in!")
	end
	if not State.isNear(thief, Mover.pivot(model).Position, Config.PROMPT_DISTANCE + 4) then
		return
	end

	-- Everything else is fine, so now it costs a Chor Pass.
	local usedPass = false
	if Config.stealsCostRobux() then
		if thiefProfile.data.stealTokens < 1 then
			State.notify(thief, "info", "Stealing needs a Chor Pass. Get one, then hold E again!")
			Shop.prompt(thief, "steals", 1)
			return
		end
		thiefProfile.data.stealTokens -= 1
		State.syncTokens(thiefProfile)
		usedPass = true
	end

	local character = thief.Character :: Model
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = State.rootPart(thief) :: BasePart

	lastSteal[thief] = now
	lastTarget[thief] = { ownerId = owner.player.UserId, time = now }
	entry.carrier = thief
	Havelis.refreshPrompts(owner)
	Mover.stop(model)
	Models.attach(model, root, CARRY_OFFSET)
	Models.setPanic(model, entry.def, true)

	-- heavier (rarer) brainrots slow the thief down more
	local slow = (Config.CARRY_SPEED[entry.def.rarity] or 0.8)
		* (if entry.mutation then Config.CARRY_MUTATION_SPEED else 1)
		* (Themes.perk(owner.data.theme, "thiefSlow") or 1)
	thiefProfile.carrySpeed = slow
	Havelis.applyWalkSpeed(thiefProfile)

	local marker, tag = markThief(character)
	carrying[thief] = {
		entry = entry,
		marker = marker,
		tag = tag,
		usedPass = usedPass,
		guardSeen = 0,
		connections = {
			humanoid.Died:Connect(function()
				Stealing.returnToOwner(thief)
			end),
			thief.CharacterRemoving:Connect(function()
				Stealing.returnToOwner(thief)
			end),
		},
	}

	local name = Mutations.displayName(entry.def, entry.mutation)
	State.notify(
		owner.player,
		"alert",
		("Chor! Chor! %s stole your %s! Bonk them with your chappal!"):format(thief.DisplayName, name)
	)
	State.notify(thief, "info", "Run through your own haveli door to keep it! You are slower while carrying it.")
end

-- Swinging the chappal near a thief makes them drop what they are carrying.
function Stealing.bonk(player: Player)
	local now = os.clock()
	if (lastBonk[player] or 0) > now then
		return
	end
	lastBonk[player] = now + Config.BONK_COOLDOWN
	local root = State.rootPart(player)
	if not root then
		return
	end
	local profile = State.profiles[player]
	local range = Config.BONK_RANGE * (Themes.perk(profile and profile.data.theme, "bonkRange") or 1)
	for thief in carrying do
		local thiefRoot = State.rootPart(thief)
		if thief ~= player and thiefRoot and (thiefRoot.Position - root.Position).Magnitude <= range then
			State.notify(thief, "bad", player.DisplayName .. " bonked you with a chappal!")
			Stealing.returnToOwner(thief, "bonk")
			return
		end
	end
end

-- The Chowkidar (haveli Level 6+) catches thieves who stay near him too long.
local guardNaps: { [any]: number } = {}

local function guardStatus(h, text: string)
	local guard = h.guard
	local label = guard and guard:FindFirstChild("Label", true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

function Stealing.guardTick(dt: number)
	local now = os.clock()
	for h, wakeAt in guardNaps do
		if now >= wakeAt then
			guardNaps[h] = nil
			guardStatus(h, "Jaagte Raho!")
		end
	end
	for thief, carry in carrying do
		local owner = carry.entry.owner
		local h = owner.haveli
		local root = State.rootPart(thief)
		if not h or not h.guard or guardNaps[h] or not root or owner.data.level < Config.GUARD_LEVEL then
			carry.guardSeen = 0
			continue
		end
		if (root.Position - h.guardSpot.Position).Magnitude <= Config.GUARD_RANGE then
			carry.guardSeen += dt
			if carry.guardSeen >= Config.GUARD_SPOT_TIME then
				guardNaps[h] = now + Config.GUARD_COOLDOWN
				guardStatus(h, "Zzz...")
				Stealing.returnToOwner(thief, "guard")
			end
		else
			carry.guardSeen = 0
		end
	end
end

-- Call when a player leaves or rebirths.
function Stealing.releasePlayer(profile)
	local player = profile.player
	if carrying[player] then
		Stealing.returnToOwner(player)
	end
	for thief, carry in carrying do
		if carry.entry.owner == profile then
			carrying[thief] = nil
			cleanup(carry)
			refund(thief, carry)
			unslow(thief)
			carry.entry.carrier = nil
			Models.detach(carry.entry.model)
			State.notify(thief, "bad", ("The %s ran away!"):format(carry.entry.def.name))
		end
	end
end

function Stealing.forget(player: Player)
	lastSteal[player] = nil
	lastTarget[player] = nil
	lastBonk[player] = nil
end

function Stealing.isCarrying(player: Player): boolean
	return carrying[player] ~= nil
end

function Stealing.init(map)
	task.spawn(function()
		while true do
			Stealing.guardTick(task.wait(0.2))
		end
	end)
	for _, h in map.havelis do
		h.door.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and carrying[player] and h.owner and h.owner.player == player then
				Stealing.complete(player)
			end
		end)
	end
end

return Stealing
