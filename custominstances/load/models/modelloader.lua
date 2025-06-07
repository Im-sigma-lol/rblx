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

-- Now call LoadCustomInstance on "5.rbxmx"
local model = LoadCustomInstance("5.rbxmx")
if model then
    model.Parent = workspace
else
    warn("Failed to load model from 5.rbxmx")
end
