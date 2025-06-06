local path = "5.rbxm"
local model = game:GetObjects(getcustomasset(path))[1]

if not model then
    warn("Failed to load model")
    return
end

model.Parent = workspace

local HttpService = game:GetService("HttpService")
local assetIds = {}

local function extractIdsFromValue(value)
    local results = {}
    -- Find all number-only strings
    for id in tostring(value):gmatch("%f[%d](%d+)%f[%D]") do
        table.insert(results, id)
    end
    return results
end

for _, obj in ipairs(model:GetDescendants()) do
    for _, prop in ipairs(obj:GetAttributes()) do
        local value = obj:GetAttribute(prop)
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

-- Convert set to sorted list
local idList = {}
for id in pairs(assetIds) do
    table.insert(idList, id)
end
table.sort(idList)

-- Write to file
local lines = {}
for _, id in ipairs(idList) do
    table.insert(lines, "rbxassetid://" .. id)
end

writefile("dumped_asset_ids.txt", table.concat(lines, "\n"))

print("Asset ID dump complete.")
