-- Cleanup old GUI
local rUuJQbg9hAvQ = game:GetService("CoreGui")
if CoreGui:FindFirstChild("MDExMDAxMTAgMDEwMTAwMDAgMDEwMTAxMDEgMDEwMDAxMTEgMDEwMTExMDEgMDExMTAxMTEgMDEwMDAwMTAgMDEwMTEwMDEgMDEwMDAxMTAgMDEwMTAwMDAgMDEwMTExMTEgMDExMTExMTEgMDEwMDAxMTAgMDEwMTEwMDE=") then
    CoreGui:FindFirstChild("MDExMDAxMTAgMDEwMTAwMDAgMDEwMTAxMDEgMDEwMDAxMTEgMDEwMTExMDEgMDExMTAxMTEgMDEwMDAwMTAgMDEwMTEwMDEgMDEwMDAxMTAgMDEwMTAwMDAgMDEwMTExMTEgMDExMTExMTEgMDEwMDAxMTAgMDEwMTEwMDE="):Destroy()
end

-- Services
local dhFFcPyZXuyg = game:GetService("Players")
local 7XtxhG5VT2JP = Players.LocalPlayer

-- Create GUI
local puD3LoTp2xnz = Instance.new("ScreenGui", CoreGui)
gui.Name = "MDExMDAxMTAgMDEwMTAwMDAgMDEwMTAxMDEgMDEwMDAxMTEgMDEwMTExMDEgMDExMTAxMTEgMDEwMDAwMTAgMDEwMTEwMDEgMDEwMDAxMTAgMDEwMTAwMDAgMDEwMTExMTEgMDExMTExMTEgMDEwMDAxMTAgMDEwMTEwMDE="
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false

-- Main Frame
local ATQuvGBmDYiU = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 100)
frame.Position = UDim2.new(0.5, -150, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

-- TextBox
local cPYHVGE4u4nC = Instance.new("TextBox", frame)
textbox.Size = UDim2.new(1, -20, 0, 40)
textbox.Position = UDim2.new(0, 10, 0, 10)
textbox.PlaceholderText = "Enter Target Username"
textbox.Text = ""
textbox.TextSize = 18
textbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
textbox.BorderSizePixel = 0

-- Info Label
local ER2j8Vo3J7uT = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, -20, 0, 40)
label.Position = UDim2.new(0, 10, 0, 55)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(200, 200, 200)
label.TextSize = 16
label.Text = ""

-- Minimize Button
local I95UvwzTfNwy = Instance.new("TextButton", frame)
miniBtn.Size = UDim2.new(0, 20, 0, 20)
miniBtn.Position = UDim2.new(1, -25, 0, 5)
miniBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
miniBtn.Text = "-"
miniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
miniBtn.TextSize = 14
miniBtn.BorderSizePixel = 0

-- Minimized Icon
local HS37vQ9LRDRm = Instance.new("TextButton", gui)
icon.Size = UDim2.new(0, 20, 0, 20)
icon.Position = frame.Position + UDim2.new(0, 280, 0, 0) -- right side of frame
icon.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
icon.Text = "+"
icon.TextColor3 = Color3.fromRGB(255, 255, 255)
icon.TextSize = 14
icon.Visible = false
icon.BorderSizePixel = 0

-- Track last position
local Wavd8lBnJPeQ = frame.Position

-- Toggle minimize
miniBtn.MouseButton1Click:Connect(function()
    lastPos = frame.Position
    frame.Visible = false
    icon.Position = lastPos + UDim2.new(0, 280, 0, 0)
    icon.Visible = true
end)

-- Restore GUI
icon.MouseButton1Click:Connect(function()
    frame.Position = lastPos
    frame.Visible = true
    icon.Visible = false
end)

-- Value Types
local A5i83PkhCQrQ = {
    StringValue = true, BoolValue = true, IntValue = true,
    NumberValue = true, Vector3Value = true, ObjectValue = true,
    CFrameValue = true, BrickColorValue = true, Color3Value = true,
    FloatValue = true, DoubleConstrainedValue = true
}

-- Helper: Get full path
local function getFullPath(obj)
    local sd9qgrnnJ1st = {}
    while obj and obj ~= game do
        table.insert(path, 1, obj.Name)
        obj = obj.Parent
    end
    return "/" .. table.concat(path, "/")
end

-- Dump values
local function dumpValuesFor(targetName)
    local PEKLScEoOmjS = Players:FindFirstChild(targetName)
    if not target then
        return false, "Player not found."
    end

    local xxjGS1msfjgb = {}
    for _, inst in ipairs(target:GetDescendants()) do
        if valueTypes[inst.ClassName] then
            local qZz5BA3YzEAZ = tostring(inst.Value)
            local YdXaxaimtDsN = getFullPath(inst)
            table.insert(results, fullPath .. " = " .. value)
        end
    end

    if #results > 0 then
        local ouGg9vFGItJk = targetName .. "_Values.txt"
        writefile(filename, table.concat(results, "\n"))
        return true, "Saved to: " .. filename
    else
        return false, "No values found."
    end
end

-- Run on Enter
textbox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local IvMHq4rok5p0 = textbox.Text:match("^%s*(.-)%s*$")
        if inputName ~= "" then
            local success, msg = dumpValuesFor(inputName)
            label.Text = msg
        else
            label.Text = "Please enter a username."
        end
    end
end)
