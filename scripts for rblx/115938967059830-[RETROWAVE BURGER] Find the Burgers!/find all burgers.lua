local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local burgersFolder = workspace:WaitForChild("Burgers")
local ownedFolder = player:WaitForChild("Burgers")

-- Collect owned burger names
local ownedNames = {}
for _, owned in pairs(ownedFolder:GetChildren()) do
	ownedNames[owned.Name] = true
end

-- Function to fire touch manually
local function fireTouch(part)
	local ti = part:FindFirstChildOfClass("TouchTransmitter") or part:FindFirstChild("TouchInterest")
	if ti then
		firetouchinterest(humanoidRootPart, part, 0) -- touch start
		wait(0.1)
		firetouchinterest(humanoidRootPart, part, 1) -- touch end
	end
end

-- Loop through burgers and interact with unowned ones
for _, part in pairs(burgersFolder:GetChildren()) do
	if part:IsA("BasePart") and not ownedNames[part.Name] then
		humanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 5, 0)
		wait(0.2)
		fireTouch(part)
		wait(1)
	end
end
