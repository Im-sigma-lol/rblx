-- Function to award unowned burgers
local function awardUnownedBurgers()
	-- Get the local player and necessary services
	local player = game:GetService("Players").LocalPlayer
	local ownedBurgers = player:WaitForChild("Burgers")
	local allBurgers = workspace:WaitForChild("Burgers")
	local remotes = game:GetService("ReplicatedStorage").Remotes

	-- Create a table to store the names of owned burgers
	local ownedBurgerNames = {}
	for _, burger in ipairs(ownedBurgers:GetChildren()) do
		ownedBurgerNames[burger.Name] = true
	end

	-- Loop through all burgers in the workspace
	for _, burger in ipairs(allBurgers:GetChildren()) do
		-- Check if the burger is a BasePart and not already owned
		if burger:IsA("BasePart") and not ownedBurgerNames[burger.Name] then
			-- Fire the remote event to award the burger
			remotes.AwardRobloxian:FireServer(burger)
			-- Wait briefly to avoid spam detection
			wait(0.1)
		end
	end
end

-- Execute the function
awardUnownedBurgers()
