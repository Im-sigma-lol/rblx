-- Make sure the file is in your executor's working directory
local model = LoadCustomInstance("5.rbxmx")

if model then
    model.Parent = game.Workspace
else
    warn("Failed to load model from 5.rbxmx")
end
