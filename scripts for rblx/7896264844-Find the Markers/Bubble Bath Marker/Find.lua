-- Simple client-side spawn of the Bubble Bath Marker
local marker = game.ReplicatedStorage:FindFirstChild("Bubble Bath Marker")
if marker then
    marker.Parent = workspace
end
local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
local original = hrp.CFrame

-- Go to  position
hrp.CFrame = CFrame.new(-40, 28, -197)

-- Fire touch on all Parts in Bubble Bath Marker
for _, child in pairs(workspace["Bubble Bath Marker"]:GetChildren()) do
    if child:IsA("BasePart") and child.Name == "Part" then
        local ti = child:FindFirstChildOfClass("TouchTransmitter")
        if ti then
            firetouchinterest(hrp, child, 0)
            wait(0.1)
            firetouchinterest(hrp, child, 1)
        end
    end
end

-- Return to original position
wait(0.5)
hrp.CFrame = original
