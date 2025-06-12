-- Simple client-side spawn of the Potion Marker
local potion = game.ReplicatedStorage:FindFirstChild("Potion Marker")
if potion then
    potion.Parent = workspace
end
