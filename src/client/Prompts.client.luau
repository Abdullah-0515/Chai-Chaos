-- Shows each ProximityPrompt only to the right players:
-- "Sell" and "Unlock plot" only to the owner, "Steal" only to everyone else.
-- The server marks prompts with attributes: ShowFor ("owner"/"others"),
-- OwnerId and Active. The server still checks everything when a prompt is used.

local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function update(prompt: ProximityPrompt)
	local showFor = prompt:GetAttribute("ShowFor")
	if showFor == nil then
		return
	end
	local mine = prompt:GetAttribute("OwnerId") == player.UserId
	local active = prompt:GetAttribute("Active") ~= false
	if showFor == "owner" then
		prompt.Enabled = active and mine
	else
		prompt.Enabled = active and not mine and (prompt:GetAttribute("OwnerId") or 0) ~= 0
	end
end

local function watch(instance: Instance)
	if instance:IsA("ProximityPrompt") then
		update(instance)
		instance.AttributeChanged:Connect(function()
			update(instance)
		end)
	end
end

workspace.DescendantAdded:Connect(watch)
for _, descendant in workspace:GetDescendants() do
	watch(descendant)
end
