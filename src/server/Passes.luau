-- Game passes: bought once with Robux and kept forever.
--   2x Cash     : your brainrots earn twice as much
--   Extra Plots : Config.EXTRA_PLOTS more plots
-- Their ids are in Config.GAME_PASSES; a pass with id 0 is hidden.
--
-- Roblox is asked which passes a player owns when they join. What it says is
-- also kept in their save, so a hiccup at Roblox never takes plots away.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local Havelis = require(script.Parent.Havelis)

local Passes = {}

function Passes.sync(profile)
	local list = {}
	for id in profile.data.passes do
		table.insert(list, id)
	end
	table.sort(list)
	profile.player:SetAttribute("Passes", table.concat(list, ","))
end

local function infoOf(id: string)
	for _, info in Config.PASS_INFO do
		if info.id == id then
			return info
		end
	end
	return nil
end

-- Gives a pass (used when Roblox says the player owns it).
function Passes.grant(profile, id: string, announce: boolean?)
	if profile.data.passes[id] then
		return
	end
	profile.data.passes[id] = true
	Passes.sync(profile)
	if profile.haveli then
		Havelis.restyle(profile)
		Havelis.arrange(profile)
		Havelis.refreshPrompts(profile)
	end
	local info = infoOf(id)
	if announce and info then
		State.sound(profile.player, "Purchase")
		State.notify(profile.player, "rare", ("Shukriya! %s is yours forever. %s"):format(info.name, info.text))
	end
end

-- Asks Roblox which passes the player owns. It waits, so call it before the
-- player's brainrots are put on their plots.
function Passes.check(profile)
	for id, passId in Config.GAME_PASSES do
		if passId ~= 0 and not profile.data.passes[id] then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(profile.player.UserId, passId)
			end)
			if ok and owns == true then
				profile.data.passes[id] = true
			end
		end
	end
	Passes.sync(profile)
end

function Passes.prompt(player: Player, id: any)
	local profile = State.profiles[player]
	local passId = type(id) == "string" and Config.GAME_PASSES[id]
	if not profile or not passId or passId == 0 then
		return
	end
	if profile.data.passes[id] then
		State.notify(player, "info", "You already have that pass!")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, passId)
end

function Passes.init()
	Remotes.BuyProduct.OnServerEvent:Connect(function(player: Player, kind: any, id: any)
		if kind == "pass" then
			Passes.prompt(player, id)
		end
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, bought: boolean)
		local profile = State.profiles[player]
		if not bought or not profile then
			return
		end
		for id, configured in Config.GAME_PASSES do
			if configured ~= 0 and configured == passId then
				Passes.grant(profile, id, true)
			end
		end
	end)
	local any = false
	for _, passId in Config.GAME_PASSES do
		any = any or passId ~= 0
	end
	if not any then
		print("[ChaiChaos] Game passes are hidden until you add their ids to Config.GAME_PASSES.")
	end
end

return Passes
