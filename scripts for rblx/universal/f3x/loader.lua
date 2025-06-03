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

local file = "F3X.rbxm"
local url = "https://github.com/Im-sigma-lol/rblx/raw/refs/heads/main/scripts%20for%20rblx/universal/F3X/F3X.rbxm"

-- Download if missing
if not isfile(path) then
    writefile(path, game:HttpGet(url))
end

-- Load the .rbxm as a single object (script-like)
local scriptObject = LoadCustomInstance(file)
if not scriptObject then
    return warn("Failed to load " .. file)
end

-- Ensure it's a script with .Source
if not scriptObject.Source then
    return warn("Loaded object has no .Source (not a Script/ModuleScript?)")
end

-- Run it just like game:GetObjects("rbxassetid://...")[1].Source
loadstring(scriptObject.Source)()
