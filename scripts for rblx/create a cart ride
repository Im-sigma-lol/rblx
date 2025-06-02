local targetName = "TargetPlayer" -- change this to the player you want to target
local outputName = "Create a Cart ride" -- name of the output .txt file (with special chars)

local Players = game:GetService("Players")
local target = Players:FindFirstChild(targetName)

if not target then
    warn("Target player not found.")
    return
end

-- List of all Roblox ValueBase classes
local valueTypes = {
    "StringValue", "BoolValue", "IntValue", "NumberValue",
    "Vector3Value", "ObjectValue", "CFrameValue", "BrickColorValue",
    "Color3Value", "FloatValue", "DoubleConstrainedValue"
}

-- Turn list into a lookup table
local valueTypeMap = {}
for _, v in ipairs(valueTypes) do
    valueTypeMap[v] = true
end

-- Helper: Get full path
local function getFullPath(obj)
    local path = {}
    while obj and obj ~= game do
        table.insert(path, 1, obj.Name)
        obj = obj.Parent
    end
    return "/" .. table.concat(path, "/")
end

-- Container for results
local results = {}

-- Search inside target (Character or Backpack, etc.)
for _, inst in ipairs(target:GetDescendants()) do
    if valueTypeMap[inst.ClassName] then
        local value = tostring(inst.Value)
        local fullPath = getFullPath(inst)
        table.insert(results, fullPath .. " = " .. value)
    end
end

-- Save result to file
if #results > 0 then
    local content = table.concat(results, "\n")
    writefile(outputName .. ".txt", content)
    print("Saved value data to " .. outputName .. ".txt")
else
    print("No value instances found under " .. targetName)
end
