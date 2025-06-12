local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local burgersFolder = workspace:WaitForChild("Burgers")

for _, part in pairs(burgersFolder:GetChildren()) do
	if part:IsA("BasePart") then
		humanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 5, 0) -- teleport above the part
		wait(1) -- wait 1 second before teleporting to the next part
	end
end
