local path = "5.rbxm"

-- Create a temporary folder to hold all loaded objects
local tmpFolder = Instance.new("Folder")
tmpFolder.Name = "TempLoadedRBXM_" .. tostring(tick()):gsub("%.", "_")
tmpFolder.Parent = workspace

-- Load all objects from the RBXM file
local objs = game:GetObjects(getcustomasset(path))
print("Loaded", #objs, "objects")

for i, obj in ipairs(objs) do
    obj.Parent = tmpFolder
end

local function getAllScripts(parent)
    local scripts = {}
    for _, v in ipairs(parent:GetDescendants()) do
        if v:IsA("LuaSourceContainer") then
            table.insert(scripts, v)
        end
    end
    return scripts
end

local allScripts = getAllScripts(tmpFolder)
print("Found", #allScripts, "scripts in temp folder")

local function sanitizeName(name)
    return name:gsub("[^%w_%-]", "_")
end

for _, script in ipairs(allScripts) do
    local success, source = pcall(function() return script.Source end)
    if success and source then
        local name = sanitizeName(script:GetFullName())
        local filename = "dumped_scripts/" .. name .. ".lua"
        pcall(function()
            writefile(filename, source)
        end)
        print("Dumped:", filename)
    else
        warn("Failed to get source of", script:GetFullName())
    end
end

print("Script dumping complete.")
