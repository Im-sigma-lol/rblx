-- Check and load vynixuModules.lua
local modulePath = "vynixuModules.lua"
if not isfile(modulePath) then
    writefile(modulePath, game:HttpGet("https://pastebin.com/raw/iwRG2M9S"))
end

-- Load the module
local success, module = pcall(loadfile, modulePath)
if not success then
    error("Failed to load vynixuModules.lua:\n" .. tostring(module))
end

-- Run the module to register functions in getgenv()
module()

-- Get LocalPlayer's Backpack
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Load the tool model
local tool = LoadCustomInstance("BT-Tool-2.2.0.rbxmx")
if tool and tool:IsA("Tool") then
    -- Parent to Backpack
    tool.Parent = LocalPlayer:WaitForChild("Backpack")

    -- Enable all scripts inside
    for _, descendant in ipairs(tool:GetDescendants()) do
        if descendant:IsA("Script") or descendant:IsA("LocalScript") then
            descendant.Disabled = false
        end
    end
else
    warn("Failed to load tool from BT-Tool-2.2.0.rbxmx or it is not a Tool")
end
