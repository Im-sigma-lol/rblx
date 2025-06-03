local lp = game.Players.LocalPlayer
local pdf = lp:WaitForChild("PDF")

-- Helper function to create or get a child
local function getOrCreate(name, class)
	local val = pdf:FindFirstChild(name)
	if not val then
		val = Instance.new(class)
		val.Name = name
		val.Parent = pdf
	end
	return val
end

-- Set upgrade values
getOrCreate("BrakeUpgrade", "IntValue").Value = 2
getOrCreate("BrakeUpgradeScale", "NumberValue").Value = 1
getOrCreate("SpeedUpgrade", "IntValue").Value = 3
getOrCreate("SpeedUpgradeScale", "NumberValue").Value = 1

-- Set magnet booleans
getOrCreate("TrackMagnets", "BoolValue").Value = true
getOrCreate("TrackMagnetsOn", "BoolValue").Value = true
