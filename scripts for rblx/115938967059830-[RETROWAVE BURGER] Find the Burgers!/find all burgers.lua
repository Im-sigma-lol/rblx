local player = game:GetService("Players").LocalPlayer
local ownedFolder = player:WaitForChild("Burgers")
local burgersFolder = workspace:WaitForChild("Burgers")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Lookup table of owned burger names
local ownedNames = {}
for _, burger in ipairs(ownedFolder:GetChildren()) do
	ownedNames[burger.Name] = true
end

-- Loop through burgers in Workspace and fire remote for unowned ones
for _, burger in ipairs(burgersFolder:GetChildren()) do
	if burger:IsA("BasePart") and not ownedNames[burger.Name] then
		ReplicatedStorage.Remotes.AwardRobloxian:FireServer(burger)
		wait(0.1) -- slight delay to avoid spam detection
	end
end
