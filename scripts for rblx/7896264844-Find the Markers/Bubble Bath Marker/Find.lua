-- Enable quest progression states
local panelopen = game.ReplicatedStorage:FindFirstChild("panelopen")
if panelopen then panelopen.Parent = workspace end

local pumpIndicator = workspace:FindFirstChild("PumpIndicator")
if pumpIndicator then
    pumpIndicator.Color = Color3.fromRGB(108, 255, 17)
end

-- Parent bathbubble and marker
local bathbubble = game.ReplicatedStorage:FindFirstChild("bathbubble")
if bathbubble then bathbubble.Parent = workspace end

local marker = game.ReplicatedStorage:FindFirstChild("Bubble Bath Marker")
if marker then marker.Parent = workspace end

-- Set transparency of water
local water = workspace:FindFirstChild("otherwater")
if water then water.Transparency = 0.6 end

-- Destroy wrench, leaks, soap, and set up teleporter
local wrench = workspace:FindFirstChild("bubblebathwrench")
if wrench then wrench:Destroy() end

local leaks = workspace:FindFirstChild("bathleaks")
if leaks then leaks:Destroy() end

local soap = workspace:FindFirstChild("soap")
if soap then soap:Destroy() end

-- Enable and fake the grate interaction
local grate = workspace:FindFirstChild("Quagmire Grate")
if grate and grate:FindFirstChild("Interact") then
    local prompt = grate.Interact:FindFirstChild("ProximityPrompt")
    if prompt then
        prompt.ObjectText = "Pipe"
        prompt.ActionText = "Enter"
        prompt.Enabled = true
        prompt.HoldDuration = 0
    end
end
-- Fire touch on all Parts in Bubble Bath Marker
for _, child in pairs(workspace["Bubble Bath Marker"]:GetChildren()) do
    if child:IsA("BasePart") and child.Name == "Part" then
        local ti = child:FindFirstChildOfClass("TouchTransmitter")
        if ti then
            firetouchinterest(hrp, child, 0)
            wait(0.05)
            firetouchinterest(hrp, child, 1)
        end
    end
end

-- Return to original position
wait(0.05)
hrp.CFrame = original
