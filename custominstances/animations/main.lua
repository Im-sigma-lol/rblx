-- GUI button (you need to define or insert this somewhere in your UI)
local HeadThrow = yourButtonReferenceHere -- replace with actual TextButton
local loc = Color3.fromRGB(255, 0, 0) -- example toggle color

-- Load local .rbxm animation
local AnimModel = game:GetObjects(getcustomasset("anim.rbxm"))[1]

-- Try to extract Animation instance
local Anim
if AnimModel:IsA("Animation") then
    Anim = AnimModel
else
    Anim = AnimModel:FindFirstChildOfClass("Animation")
end

if not Anim then
    warn("No Animation found in anim.rbxm!")
    return
end

-- Load animation onto humanoid
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local track = Humanoid:LoadAnimation(Anim)

-- Toggle animation
local HeadThrowACTIVE = false

HeadThrow.MouseButton1Click:Connect(function()
    HeadThrowACTIVE = not HeadThrowACTIVE
    if HeadThrowACTIVE then
        HeadThrow.BackgroundColor3 = loc
        task.spawn(function()
            while HeadThrowACTIVE do
                if not track.IsPlaying then
                    track:Play(0.1, 1, 1)
                end
                task.wait()
            end
        end)
    else
        track:Stop()
    end
end)
