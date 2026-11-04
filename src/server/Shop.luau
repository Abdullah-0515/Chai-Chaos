-- Robux purchases (Developer Products) for Kismat Rolls and Chor Passes.
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
}

function Shop.give(profile, field: string, amount: number)
	profile.data[field] += amount
	State.syncTokens(profile)
end

-- Shows the Robux purchase prompt for pack `index` of `kindName`.
function Shop.prompt(player: Player, kindName: any, index: any): boolean
	local kind = Shop.KINDS[kindName]
	if not kind or type(index) ~= "number" then
		return false
	end
	local pack = kind.packs[index]
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
		Shop.give(profile, kind.field, -pack.amount)
		local index = table.find(data.receipts, purchaseId)
		if index then
			table.remove(data.receipts, index)
		end
	end

	Shop.give(profile, kind.field, pack.amount)
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

	State.notify(
		player,
		"good",
		("Shukriya! You got %d %s."):format(pack.amount, if pack.amount == 1 then kind.one else kind.many)
	)
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
