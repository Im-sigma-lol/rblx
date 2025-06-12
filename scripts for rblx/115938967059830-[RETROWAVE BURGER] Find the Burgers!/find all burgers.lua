local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local burgersFolder = workspace:WaitForChild("Burgers")
local ownedFolder = player:WaitForChild("Burgers")

-- Create a lookup table of owned burger names
local ownedNames = {}
for _, owned in pairs(ownedFolder:GetChildren()) do
	ownedNames[owned.Name] = true
end

-- Teleport to each unowned burger
for _, part in pairs(burgersFolder:GetChildren()) do
	if part:IsA("BasePart") and not ownedNames[part.Name] then
		humanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 5, 0)
		wait(1)
	end
end
