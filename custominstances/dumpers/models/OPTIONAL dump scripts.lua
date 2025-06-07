local placeFolder = "dumped_scripts/" .. tostring(game.PlaceId or "UnknownPlaceId")
if not isfolder(placeFolder) then
    makefolder(placeFolder)
end

-- Sanitize function to make safe filenames
local function sanitize(str)
    return str:gsub("[^%w%-%._]", "_")
end

-- Try to get the source safely
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

-- Start dumping loop
local index = 1
local totalDumpedGlobal = 0
local totalFailedGlobal = 0

while true do
    local path = tostring(index) .. ".rbxm"
    local success, objects = pcall(function()
        return game:GetObjects(getcustomasset(path))
    end)

    if not success or not objects or #objects == 0 then
        print("No more .rbxm files at index", index)
        break
    end

    -- Temporary container
    local container = Instance.new("Folder")
    container.Name = "Temp_" .. tick()
    container.Parent = workspace

    for _, obj in ipairs(objects) do
        obj.Parent = container
    end

    -- Create subfolder for this file
    local subFolder = placeFolder .. "/" .. tostring(index)
    if not isfolder(subFolder) then
        makefolder(subFolder)
    end

    -- Prepare used name tracker
    local usedNames = {}

    local scripts = getAllScripts(container)
    local totalDumped = 0
    local totalFailed = 0

    for _, script in ipairs(scripts) do
        local source = safeGetSource(script)
        if source then
            local baseName = sanitize(script:GetFullName())
            local name = baseName
            local i = 1
            while usedNames[name] do
                name = baseName .. "_" .. tostring(i)
                i += 1
            end
            usedNames[name] = true

            local filePath = subFolder .. "/" .. name .. ".lua"
            pcall(function()
                writefile(filePath, source)
            end)
            totalDumped += 1
        else
            warn("Failed to dump script:", script:GetFullName())
            totalFailed += 1
        end
    end

    totalDumpedGlobal += totalDumped
    totalFailedGlobal += totalFailed

    print("Dumped", totalDumped, "scripts from", path, "| Failed:", totalFailed)

    -- Clean up
    container:Destroy()

    index += 1
end

print("Done. Total scripts dumped:", totalDumpedGlobal, "| Total failed:", totalFailedGlobal)
