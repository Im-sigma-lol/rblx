-- Place this in a LocalScript
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local rightShoulder = char:FindFirstChild("Right Shoulder", true) -- Motor6D for R6
if not rightShoulder then
    warn("Right Shoulder not found")
    return
end

-- Save the original joint C0 to blend from
local originalC0 = rightShoulder.C0

-- Define a very simple hardcoded animation
local keyframes = {
    {Time = 0.0, Angle =  math.rad(0)},
    {Time = 0.25, Angle = math.rad(-45)},
    {Time = 0.5, Angle =  math.rad(45)},
    {Time = 0.75, Angle = math.rad(-45)},
    {Time = 1.0, Angle =  math.rad(0)},
}

-- Simple animation loop logic
local time = 0
local duration = keyframes[#keyframes].Time

RunService.RenderStepped:Connect(function(dt)
    time = (time + dt) % duration

    -- Find the two keyframes we are between
    local kfA, kfB
    for i = 1, #keyframes - 1 do
        if time >= keyframes[i].Time and time <= keyframes[i+1].Time then
            kfA = keyframes[i]
            kfB = keyframes[i+1]
            break
        end
    end

    if not (kfA and kfB) then return end

    -- Lerp the angle
    local alpha = (time - kfA.Time) / (kfB.Time - kfA.Time)
    local angle = kfA.Angle + (kfB.Angle - kfA.Angle) * alpha

    -- Apply rotation to the right arm (local Z axis wave)
    rightShoulder.C0 = originalC0 * CFrame.Angles(0, 0, angle)
end)
