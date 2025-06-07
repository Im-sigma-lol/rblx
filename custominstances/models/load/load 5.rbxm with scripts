local path = "5.rbxm"

-- Generate random string for folder name
local function randomName(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local str = ""
    for i = 1, len do
        local r = math.random(1, #chars)
        str = str .. chars:sub(r, r)
    end
    return str
end

-- Load objects
local objects = game:GetObjects(getcustomasset(path))
if not objects or #objects == 0 then
    warn("Nothing loaded from", path)
    return
end

-- Main container
local container = nil
if #objects == 1 and objects[1]:IsA("Model") then
    container = objects[1]
    container.Parent = workspace
else
    container = Instance.new("Folder")
    container.Name = "Imported_" .. randomName(8)
    container.Parent = workspace
    for _, obj in ipairs(objects) do
        obj.Parent = container
    end
end

-- Execute LuaSourceContainers (Script, LocalScript)
local function executeScript(original)
    local class = original.ClassName
    if class == "Script" or class == "LocalScript" then
        local clone = Instance.new(class)
        clone.Name = original.Name
        pcall(function()
            clone.Source = original.Source
        end)
        clone.Parent = original.Parent
    end
end

-- Find and run all scripts
for _, obj in ipairs(container:GetDescendants()) do
    if obj:IsA("LuaSourceContainer") then
        executeScript(obj)
    end
end

print("Imported model and executed scripts (client-side only).")
