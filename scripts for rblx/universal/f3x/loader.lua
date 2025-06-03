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

-- Correct file path and download URL
local file = "F3X.rbxm"
local url = "https://raw.githubusercontent.com/Im-sigma-lol/rblx/main/scripts%20for%20rblx/universal/f3x/F3X.rbxm"

-- Download if missing
if not isfile(file) then
    writefile(file, game:HttpGet(url))
end

-- Load the .rbxm as a single object
local scriptObject = LoadCustomInstance(file)
if not scriptObject then
    return warn("Failed to load " .. file)
end

-- Make sure it's a script (ModuleScript or LocalScript)
if not scriptObject.Source then
    return warn("Loaded object has no .Source (not a script-like object?)")
end

-- Execute the script
loadstring(scriptObject.Source)()
