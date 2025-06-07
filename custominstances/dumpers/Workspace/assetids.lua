local HttpService = game:GetService("HttpService")
local assetIds = {}

local function extractIdsFromValue(value)
    local results = {}
    -- Find all number-only substrings (likely asset IDs)
    for id in tostring(value):gmatch("%f[%d](%d+)%f[%D]") do
        table.insert(results, id)
    end
    return results
end

-- Include more asset-related properties for better coverage
local assetProperties = {
    "Texture", "MeshId", "SoundId", "AnimationId",
    "Source", "Image", "LinkedSource", "Video", "TextureID",
    "DecalTexture", "Graphic", "URL"
}

for _, obj in ipairs(workspace:GetDescendants()) do
    -- Check attributes
    for _, attrName in ipairs(obj:GetAttributes()) do
        local value = obj:GetAttribute(attrName)
        for _, id in ipairs(extractIdsFromValue(value)) do
            assetIds[id] = true
        end
    end

    -- Check properties via pcall in case of read errors
    for _, prop in ipairs(assetProperties) do
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

writefile("workspace_asset_ids.txt", table.concat(lines, "\n"))
print("Asset ID dump complete.")
