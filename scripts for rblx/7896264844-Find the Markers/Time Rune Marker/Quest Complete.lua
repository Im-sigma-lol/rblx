local TweenService = game:GetService("TweenService")

-- Helper to tween transparency
local function tweenTransparency(inst, target)
    if inst then
        TweenService:Create(inst, TweenInfo.new(0.3), { Transparency = target }):Play()
    end
end

-- Spoof relic visuals
local function spoofRelics()
    local Relics = workspace:WaitForChild("Relics")
    for _, relic in ipairs(Relics:GetChildren()) do
        local part = relic:FindFirstChild("Part")
        local union = relic:FindFirstChild("Union")
        if part and union and part:FindFirstChild("Attachment") then
            tweenTransparency(part, 0)
            tweenTransparency(union, 0)

            local emitter = part.Attachment:FindFirstChildOfClass("ParticleEmitter")
            if emitter then emitter.Enabled = true end

            local T3 = script:FindFirstChild("T3") or relic:FindFirstChild("T3")
            if T3 and T3:IsA("Sound") then T3:Play() end
        end
    end
end

-- Spoof pedestal visuals
local function spoofPedestal()
    local pedestal = workspace:FindFirstChild("Pedestal")
    if pedestal then
        local glow = pedestal:FindFirstChild("PedestalGlow")
        if glow then
            tweenTransparency(glow, 0)
        end
    end
end

-- Spoof bridge visuals
local function spoofBridge()
    local bridge = workspace:FindFirstChild("TimeBridge")
    if bridge then
        for _, part in ipairs(bridge:GetDescendants()) do
            if part:IsA("BasePart") then
                tweenTransparency(part, 0)
            end
        end
    end
end

-- Spoof glowball visuals
local function spoofGlowball()
    local glowball = workspace:FindFirstChild("TimeGlowball")
    if glowball then
        for _, v in ipairs(glowball:GetDescendants()) do
            if v:IsA("BasePart") then
                tweenTransparency(v, 0)
            elseif v:IsA("ParticleEmitter") then
                v.Enabled = true
            end
        end
    end
end

-- Run all spoofs
spoofRelics()
spoofPedestal()
spoofBridge()
spoofGlowball()
