local path = "5.rbxm"
local model = game:GetObjects(getcustomasset(path))[1]

if not model then
    warn("Failed to load model")
    return
end

model.Parent = workspace

local function sanitizeName(name)
    return name:gsub("[^%w_%-]", "_")
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

local scripts = getAllScripts(model)

for _, script in ipairs(scripts) do
    local success, source = pcall(function()
        return script.Source
    end)

    if success and source then
        local name = sanitizeName(script:GetFullName())
        local filename = "dumped_scripts/" .. name .. ".lua"
        pcall(function()
            writefile(filename, source)
        end)
    else
        warn("Failed to access source of", script:GetFullName())
    end
end

print("Script dumping complete.")
