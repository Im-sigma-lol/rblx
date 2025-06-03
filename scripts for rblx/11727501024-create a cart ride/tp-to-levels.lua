local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LevelSpawnTextViewer"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(0.4, 0, 0.6, 0)
ScrollingFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.ScrollBarThickness = 10
ScrollingFrame.BackgroundTransparency = 0.2
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ScrollingFrame.Parent = ScreenGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ScrollingFrame

-- Add a label
local function addTextLabel(text, path)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -10, 0, 30)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextScaled = true
	label.Font = Enum.Font.Code
	label.Text = text .. "  [" .. path .. "]"
	label.Parent = ScrollingFrame
end

-- Find all LevelSpawn -> BBG -> TextLabel
local root = workspace:FindFirstChild("CartRideWorkspace")
if root then
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("Model") and descendant.Name == "LevelSpawn" then
			local bbg = descendant:FindFirstChild("BBG")
			if bbg and bbg:IsA("SurfaceGui") then
				local textLabel = bbg:FindFirstChild("TextLabel")
				if textLabel and textLabel:IsA("TextLabel") then
					addTextLabel(textLabel.Text, descendant:GetFullName())
				end
			end
		end
	end
end

-- Auto-resize canvas
task.wait(0.1)
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20)
