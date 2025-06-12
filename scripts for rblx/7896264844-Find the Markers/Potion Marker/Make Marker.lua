-- Simple client-side spawn of the Potion Marker
local marker = game.ReplicatedStorage:FindFirstChild("Potion Marker")
if marker then
    marker.Parent = workspace
end
