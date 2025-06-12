local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local burgersFolder = workspace:WaitForChild("Burgers")
local ownedFolder = player:WaitForChild("Burgers")

-- Store owned burger names
local ownedNames = {}
for _, owned in pairs(ownedFolder:GetChildren()) do
	ownedNames[owned.Name] = true
end

-- Fire touch interest
local function fireTouch(part)
	local ti = part:FindFirstChildOfClass("TouchTransmitter") or part:FindFirstChild("TouchInterest")
	if ti then
		firetouchinterest(humanoidRootPart, part, 0)
		wait(0.1)
		firetouchinterest(humanoidRootPart, part, 1)
	end
end

-- Fire click detector
local function fireClick(part)
	local cd = part:FindFirstChildOfClass("ClickDetector")
	if cd then
		fireclickdetector(cd)
	end
end

-- Main loop through unowned burgers
for _, part in pairs(burgersFolder:GetChildren()) do
	if part:IsA("BasePart") and not ownedNames[part.Name] then
		humanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 5, 0)
		wait(0.2)
		fireTouch(part)
		fireClick(part)
		wait(1)
	end
end
