local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local assetIds = {}

local function extractIdsFromValue(value)
    local results = {}
    for id in tostring(value):gmatch("%f[%d](%d+)%f[%D]") do
        table.insert(results, id)
    end
    return results
end

-- Build a skip list of all player character models in workspace
local ignoreModels = {}
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character and player.Character:IsDescendantOf(workspace) then
        ignoreModels[player.Character] = true
    end
end

-- Expand check to children of character too
local function isDescendantOfCharacter(obj)
    for model in pairs(ignoreModels) do
        if obj:IsDescendantOf(model) then
            return true
        end
    end
    return false
end

-- Properties known to contain asset IDs
local assetProperties = {
    "Texture", "MeshId", "SoundId", "AnimationId",
    "Source", "Image", "LinkedSource", "Video", "TextureID",
    "DecalTexture", "Graphic", "URL"
}

-- Scan workspace, ignoring characters
for _, obj in ipairs(workspace:GetDescendants()) do
    if isDescendantOfCharacter(obj) then
        continue
    end

    for _, attrName in ipairs(obj:GetAttributes()) do
        local value = obj:GetAttribute(attrName)
        for _, id in ipairs(extractIdsFromValue(value)) do
            assetIds[id] = true
        end
    end

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

writefile("workspace_asset_ids_filtered.txt", table.concat(lines, "\n"))
print("Filtered Asset ID dump complete (characters excluded).")
-- to include character models use this version https://github.com/Im-sigma-lol/rblx/blob/b6483c38849dc64997ba1d90bdde7e19eb755a28/custominstances/dumpers/Workspace/assetids.lua
