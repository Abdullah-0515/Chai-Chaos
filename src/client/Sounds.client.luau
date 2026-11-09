-- Sounds on this player's screen:
-- * sounds the server asks for (eggs, coins, bonks, treasure...)
-- * a click for every button in the HUD
-- * music for where you are (bazaar, biomes, events) once you add music ids
--   to Sounds.luau, and wind up in the mountains and the desert

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("ChaiChaos")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Biomes = require(Shared:WaitForChild("Biomes"))
local Events = require(Shared:WaitForChild("Events"))
local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ChaiChaosHud")

Remotes.PlaySound.OnClientEvent:Connect(function(name: any, position: any)
	if type(name) == "string" then
		SoundPlayer.play(name, if typeof(position) == "Vector3" then position else nil)
	end
end)

-- a click for every HUD button, including ones made later
local function hook(instance: Instance)
	if instance:IsA("GuiButton") then
		instance.Activated:Connect(function()
			SoundPlayer.play("Click")
		end)
	end
end
gui.DescendantAdded:Connect(hook)
for _, descendant in gui:GetDescendants() do
	hook(descendant)
end

local function update()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local biome = if root and root:IsA("BasePart") then Biomes.at(root.Position) else nil
	local music = if Events.current() then "MusicEvent" elseif biome then "MusicBiome" else "MusicBazaar"
	for _, name in { "MusicBazaar", "MusicBiome", "MusicEvent" } do
		SoundPlayer.loop(name, name == music)
	end
	-- windy in the snowy mountains, and in the desert during a sandstorm
	local windy = biome ~= nil
		and (
			table.find(biome.hazards, "snowballs") ~= nil
			or (table.find(biome.hazards, "sandstorm") ~= nil and workspace:GetAttribute("Sandstorm") == true)
		)
	SoundPlayer.loop("Wind", windy)
end

task.spawn(function()
	while gui.Parent do
		update()
		task.wait(1)
	end
end)
