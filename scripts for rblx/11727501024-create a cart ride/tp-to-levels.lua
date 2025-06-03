local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Create GUI
local gui = Instance.new("ScreenGui")
gui.Name = "LevelSpawnTextTeleporter"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("ScrollingFrame")
frame.Size = UDim2.new(0.4, 0, 0.6, 0)
frame.Position = UDim2.new(0.3, 0, 0.2, 0)
frame.CanvasSize = UDim2.new(0, 0, 0, 0)
frame.ScrollBarThickness = 8
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = gui

local layout = Instance.new("UIListLayout", frame)
layout.Padding = UDim.new(0, 6)

-- Create a teleport button
local function createButton(text, model)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -10, 0, 36)
	btn.Text = text
	btn.Font = Enum.Font.SourceSansBold
	btn.TextScaled = true
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Parent = frame

	btn.MouseButton1Click:Connect(function()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local tpPosition
		if model.PrimaryPart then
			tpPosition = model.PrimaryPart.Position + Vector3.new(0, 5, 0)
		else
			-- fallback: center of model
			local total = Vector3.new()
			local parts = 0
			for _, obj in ipairs(model:GetDescendants()) do
				if obj:IsA("BasePart") then
					total += obj.Position
					parts += 1
				end
			end
			if parts > 0 then
				tpPosition = (total / parts) + Vector3.new(0, 5, 0)
			end
		end

		if tpPosition then
			hrp.CFrame = CFrame.new(tpPosition)
		end
	end)
end

-- Search models
local folder = workspace:FindFirstChild("CartRideWorkspace")
if folder then
	local objects = folder:FindFirstChild("Objects")
	if objects then
		for _, model in ipairs(objects:GetChildren()) do
			if model:IsA("Model") and model.Name == "LevelSpawn" then
				for _, descendant in ipairs(model:GetDescendants()) do
					if descendant:IsA("TextLabel") then
						createButton(descendant.Text, model)
					end
				end
			end
		end
	end
end

-- Resize scroll area
task.wait(0.1)
frame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
