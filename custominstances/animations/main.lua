local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Step 1: Load main.rbxm and parent it to Workspace
local mainPath = "main.rbxm"
local mainModel = game:GetObjects(getcustomasset(mainPath))[1]
if mainModel then
    mainModel.Parent = workspace
else
    warn("Failed to load main.rbxm")
    return
end

-- Step 2: Locate the animation instance inside workspace.freespirit
local animInstance = workspace:FindFirstChild("freespirit")
if not animInstance or not animInstance:IsA("Animation") then
    warn("workspace.freespirit is missing or not an Animation")
    return
end

-- Step 3: Replace AnimationId with path to local anim.rbxm
local animAssetPath = getcustomasset("anim.rbxm")
animInstance.AnimationId = animAssetPath -- This simulates a fake AnimationId for client-side use

-- Step 4: Load and play the animation on the local humanoid
local animTrack = humanoid:LoadAnimation(animInstance)
animTrack:Play()
