local path = "5.rbxm"
local model = game:GetObjects(getcustomasset(path))[1]

if not model then
    warn("Failed to load model")
    return
end

model.Parent = workspace

if not isfolder("dumped_scripts") then
    makefolder("dumped_scripts")
end

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
print("Found", #scripts, "scripts to dump")

for _, script in ipairs(scripts) do
    print("Dumping:", script:GetFullName())
    local success, source = pcall(function()
        return script.Source
    end)

    if success and source then
        local name = sanitizeName(script:GetFullName())
        local filename = "dumped_scripts/" .. name .. ".lua"
        local ok, err = pcall(function()
            writefile(filename, source)
        end)
        if ok then
            print("Wrote to:", filename)
        else
            warn("Failed to write to file:", filename, err)
        end
    else
        warn("Failed to access source of", script:GetFullName())
    end
end

print("Script dumping complete.")
