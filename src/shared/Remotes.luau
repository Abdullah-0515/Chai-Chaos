-- RemoteEvents shared by the server and the client.
-- The server creates them; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "ChaiChaosRemotes"
local NAMES = {
	"Notify", -- server -> client: (kind, text)
	"LockHaveli", -- client -> server: lock your haveli (Taala)
	"Rebirth", -- client -> server: start a Naya Safar
}

local folder: Instance
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME) or Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for _, name in NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

return {
	Notify = folder:WaitForChild("Notify") :: RemoteEvent,
	LockHaveli = folder:WaitForChild("LockHaveli") :: RemoteEvent,
	Rebirth = folder:WaitForChild("Rebirth") :: RemoteEvent,
}
