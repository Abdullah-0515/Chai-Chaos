-- Robux purchases (Developer Products) for Kismat Rolls, Chor Passes and
-- vehicle paint jobs (looks only).
--
-- Roblox calls ProcessReceipt for every purchase, and calls it again later if
-- we return NotProcessedYet. We only say PurchaseGranted once the item is given
-- and saved, and we never give the same purchase twice.
--
-- Kismat Rolls are paid random items, so they are never offered to players
-- where PolicyService says paid random items are restricted.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local PlayerData = require(script.Parent.PlayerData)
local Havelis = require(script.Parent.Havelis)

local Shop = {}

local MAX_RECEIPTS = 50

-- Set by Main: gives a bought paint job (see Garage.onPaintBought).
Shop.paintHook = nil :: ((any, string) -> ())?

local paintPacks = {}
for paintId, productId in Config.PAINT_PRODUCTS do
	table.insert(paintPacks, { id = productId, amount = 1, paint = paintId })
end

-- What each kind of pack gives and which save field it adds to.
Shop.KINDS = {
	rolls = {
		field = "rollTokens",
		packs = Config.ROLL_PRODUCTS,
		one = "Kismat Roll",
		many = "Kismat Rolls",
		random = true,
	},
	steals = {
		field = "stealTokens",
		packs = Config.STEAL_PRODUCTS,
		one = "Chor Pass",
		many = "Chor Passes",
		random = false,
	},
	paint = {
		packs = paintPacks,
		one = "paint job",
		many = "paint jobs",
		random = false,
	},
}

function Shop.give(profile, field: string, amount: number)
	profile.data[field] += amount
	State.syncTokens(profile)
end

-- Gives (or takes back, if saving failed) what a pack is worth.
local function grant(profile, kind, pack, undo: boolean?)
	if kind.field then
		Shop.give(profile, kind.field, if undo then -pack.amount else pack.amount)
	elseif undo then
		profile.data.paints[pack.paint] = nil
		if profile.data.paint == pack.paint then
			profile.data.paint = "Factory"
		end
	elseif Shop.paintHook then
		Shop.paintHook(profile, pack.paint)
	else
		profile.data.paints[pack.paint] = true
	end
end

-- Shows the Robux purchase prompt for pack `index` of `kindName`.
function Shop.prompt(player: Player, kindName: any, index: any): boolean
	local kind = Shop.KINDS[kindName]
	if not kind then
		return false
	end
	local pack = nil
	if kindName == "paint" then
		for _, p in kind.packs do
			if p.paint == index then
				pack = p
			end
		end
		local profile = State.profiles[player]
		if pack and profile and profile.data.paints[pack.paint] then
			State.notify(player, "info", "You already have that paint job!")
			return false
		end
	elseif type(index) == "number" then
		pack = kind.packs[index]
	end
	if not pack or pack.id == 0 then
		return false
	end
	if kind.random and player:GetAttribute("PaidRollsAllowed") ~= true then
		State.notify(player, "bad", "Robux rolls are not available for your account. You can still roll with rupees!")
		return false
	end
	MarketplaceService:PromptProductPurchase(player, pack.id)
	return true
end

local function find(productId: number)
	for _, kind in Shop.KINDS do
		for _, pack in kind.packs do
			if pack.id ~= 0 and pack.id == productId then
				return kind, pack
			end
		end
	end
	return nil, nil
end

function Shop.processReceipt(receipt)
	local kind, pack = find(receipt.ProductId)
	if not kind then
		warn("[ChaiChaos] Unknown Developer Product " .. tostring(receipt.ProductId) .. ", add it to Config")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local profile = player and State.profiles[player]
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- not loaded yet, Roblox will retry
	end

	local data = profile.data
	local purchaseId = tostring(receipt.PurchaseId)
	if table.find(data.receipts, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local function undo()
		grant(profile, kind, pack, true)
		local index = table.find(data.receipts, purchaseId)
		if index then
			table.remove(data.receipts, index)
		end
	end

	grant(profile, kind, pack)
	table.insert(data.receipts, purchaseId)
	while #data.receipts > MAX_RECEIPTS do
		table.remove(data.receipts, 1)
	end

	if profile.canSave then
		Havelis.syncData(profile)
		if not PlayerData.save(player.UserId, data) then
			undo()
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	elseif not RunService:IsStudio() then
		-- their data did not load, so we cannot save this yet; Roblox will retry
		undo()
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if pack.paint then
		State.notify(player, "good", ("Shukriya! Your vehicles now have the %s paint job."):format(pack.paint))
	else
		State.notify(
			player,
			"good",
			("Shukriya! You got %d %s."):format(pack.amount, if pack.amount == 1 then kind.one else kind.many)
		)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Call when a player joins (it waits on Roblox, so run it in its own thread).
function Shop.setup(profile)
	State.syncTokens(profile)
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(profile.player)
	end)
	-- If Roblox cannot tell us, play it safe and do not offer paid rolls.
	local allowed = ok and type(info) == "table" and info.ArePaidRandomItemsRestricted == false
	profile.player:SetAttribute("PaidRollsAllowed", allowed)
end

function Shop.init()
	Remotes.BuyProduct.OnServerEvent:Connect(Shop.prompt)
	MarketplaceService.ProcessReceipt = Shop.processReceipt

	for _, kind in Shop.KINDS do
		local configured = false
		for _, pack in kind.packs do
			if pack.id ~= 0 then
				configured = true
			end
		end
		if not configured then
			print(
				("[ChaiChaos] %s Robux packs are hidden until you add Developer Product ids to Config."):format(
					kind.one
				)
			)
		end
	end
	if not Config.stealsCostRobux() then
		print("[ChaiChaos] Stealing is free until Config.STEAL_PRODUCTS has a Developer Product id.")
	end
end

return Shop
