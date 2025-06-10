-- Settings
local modelsFolder = "Models" -- Folder containing 1.rbxm, 2.rbxm, ...
local files = listfiles(modelsFolder)

-- Create tmp folder in Workspace if it doesn't exist
local tmp = workspace:FindFirstChild("tmp")
if not tmp then
    tmp = Instance.new("Folder")
    tmp.Name = "tmp"
    tmp.Parent = workspace
end

-- Load each .rbxm file and parent its model into workspace.tmp
for _, file in ipairs(files) do
    if file:match("%.rbxm$") then
        local success, model = pcall(function()
            return game:GetObjects(getcustomasset(file))[1]
        end)

        if success and model then
            model.Parent = tmp
            print("Loaded:", file)
        else
            warn("Failed to load:", file)
        end
    end
end

print("Finished loading all models into workspace.tmp")
