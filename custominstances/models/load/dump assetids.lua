local path = "5.rbxm"

-- Make a temp container for loaded objects
local container = Instance.new("Folder")
container.Name = "Temp_" .. tick()
container.Parent = workspace

-- Load objects into container
local objects = game:GetObjects(getcustomasset(path))
for _, obj in ipairs(objects) do
    obj.Parent = container
end

-- Get all LuaSourceContainer descendants
local function getAllScripts(root)
    local found = {}
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("LuaSourceContainer") then
            table.insert(found, obj)
        end
    end
    return found
end

-- Clean filename characters
local function sanitize(str)
    return str:gsub("[^%w%-%._]", "_")
end

-- Retry getting Source up to 3 times
local function safeGetSource(script)
    for i = 1, 3 do
        local success, result = pcall(function() return script.Source end)
        if success and result and #result > 0 then
            return result
        end
        wait(0.05)
    end
    return nil
end

-- Get place id folder
local placeFolder = "dumped_scripts/" .. tostring(game.PlaceId or "UnknownPlaceId")
if not isfolder(placeFolder) then
    makefolder(placeFolder)
end

-- Track used filenames to avoid collisions
local usedNames = {}

-- Dump scripts
local scripts = getAllScripts(container)
local totalDumped = 0
local totalFailed = 0

for _, script in ipairs(scripts) do
    local source = safeGetSource(script)
    if source then
        local baseName = sanitize(script:GetFullName())
        local name = baseName
        local index = 1
        while usedNames[name] do
            name = baseName .. "_" .. tostring(index)
            index += 1
        end
        usedNames[name] = true

        local filePath = placeFolder .. "/" .. name .. ".lua"
        pcall(function()
            writefile(filePath, source)
        end)
        totalDumped += 1
    else
        warn("Failed to dump script:", script:GetFullName())
        totalFailed += 1
    end
end

print("Done. Scripts dumped:", totalDumped, "| Failed:", totalFailed)
