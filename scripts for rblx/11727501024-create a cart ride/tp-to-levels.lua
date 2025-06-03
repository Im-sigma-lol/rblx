local CoreGui = game:GetService("CoreGui")

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "DebugTextViewer"
gui.Parent = CoreGui

local frame = Instance.new("ScrollingFrame")
frame.Size = UDim2.new(0.4, 0, 0.6, 0)
frame.Position = UDim2.new(0.3, 0, 0.2, 0)
frame.Parent = gui
frame.CanvasSize = UDim2.new(0, 0, 0, 0)
frame.ScrollBarThickness = 10

local layout = Instance.new("UIListLayout", frame)
layout.Padding = UDim.new(0, 4)

local function addText(msg)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -8, 0, 24)
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 16
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Text = msg
	lbl.Parent = frame
end

-- Start Debug Scan
local root = workspace:FindFirstChild("CartRideWorkspace")
if not root then
	addText("CartRideWorkspace not found.")
	return
end

addText("Found CartRideWorkspace.")

for _, model in ipairs(root:GetChildren()) do
	if model:IsA("Model") and model.Name == "LevelSpawn" then
		addText("Model: " .. model:GetFullName())

		local part = model:FindFirstChild("LevelSpawn")
		if part and part:IsA("BasePart") then
			addText("  Found part: " .. part:GetFullName())

			local bbg = part:FindFirstChild("BBG")
			if bbg and bbg:IsA("BillboardGui") then
				addText("    Found BBG")

				local textLabel = bbg:FindFirstChild("TextLabel")
				if textLabel and textLabel:IsA("TextLabel") then
					addText("      Text: " .. textLabel.Text)
				else
					addText("      TextLabel missing or wrong class")
				end
			else
				addText("    BBG missing or wrong type")
			end
		else
			addText("  Part LevelSpawn missing or not a BasePart")
		end
	end
end

-- Resize canvas
task.wait(0.1)
frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
