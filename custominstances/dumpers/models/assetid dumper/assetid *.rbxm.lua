local HttpService = game:GetService("HttpService")
local AssetService = game:GetService("InsertService")
local Files = listfiles(".")

local function extractIdsFromValue(value)
    local results = {}
    for id in tostring(value):gmatch("%f[%d](%d+)%f[%D]") do
        table.insert(results, id)
    end
    return results
end

local function processRBXM(rbxmFile)
    local name = rbxmFile:match("([^/\\]+)%.rbxm$")
    local idFolder = "placeid/" .. name
    local tempFolderName = "temp_model" .. name

    -- Load the model
    local success, model = pcall(function()
        return game:GetObjects(getcustomasset(rbxmFile))[1]
    end)

    if not success or not model then
        warn("Failed to load model from", rbxmFile)
        return
    end

    -- Parent to a temp folder in workspace
    local tempFolder = Instance.new("Folder")
    tempFolder.Name = tempFolderName
    tempFolder.Parent = workspace
    model.Parent = tempFolder

    -- Collect asset IDs
    local assetIds = {}

    for _, obj in ipairs(tempFolder:GetDescendants()) do
        for _, attr in ipairs(obj:GetAttributes()) do
            local value = obj:GetAttribute(attr)
            for _, id in ipairs(extractIdsFromValue(value)) do
                assetIds[id] = true
            end
        end

        for _, prop in ipairs({"Texture", "MeshId", "SoundId", "AnimationId", "Source", "Image", "LinkedSource"}) do
            pcall(function()
                if obj[prop] then
                    for _, id in ipairs(extractIdsFromValue(obj[prop])) do
                        assetIds[id] = true
                    end
                end
            end)
        end
    end

    -- Write to file
    makefolder(idFolder)
    local idList = {}
    for id in pairs(assetIds) do
        table.insert(idList, id)
    end
    table.sort(idList)

    local lines = {}
    for _, id in ipairs(idList) do
        table.insert(lines, "rbxassetid://" .. id)
    end
    writefile(idFolder .. "/dumped_asset_ids.txt", table.concat(lines, "\n"))
    print("Finished dumping", rbxmFile, "→", #lines, "IDs")

    -- Cleanup
    tempFolder:Destroy()
end

for _, file in ipairs(Files) do
    if file:match("%.rbxm$") then
        processRBXM(file)
    end
end

print("All RBXM files processed.")
