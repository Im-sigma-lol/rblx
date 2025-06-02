-- Create GUI in CoreGui
local player = game:GetService("Players").LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Remove old GUI if exists
if CoreGui:FindFirstChild("ValueDumperGui") then
    CoreGui:FindFirstChild("ValueDumperGui"):Destroy()
end

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "ValueDumperGui"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 100)
Frame.Position = UDim2.new(0.5, -150, 0.3, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0

local TextBox = Instance.new("TextBox", Frame)
TextBox.Size = UDim2.new(1, -20, 0, 40)
TextBox.Position = UDim2.new(0, 10, 0, 10)
TextBox.PlaceholderText = "Enter Target Username"
TextBox.Text = ""
TextBox.TextSize = 18
TextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.BorderSizePixel = 0

local InfoLabel = Instance.new("TextLabel", Frame)
InfoLabel.Size = UDim2.new(1, -20, 0, 40)
InfoLabel.Position = UDim2.new(0, 10, 0, 55)
InfoLabel.BackgroundTransparency = 1
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoLabel.TextSize = 16
InfoLabel.Text = ""

-- Value types
local valueTypes = {
    StringValue = true, BoolValue = true, IntValue = true,
    NumberValue = true, Vector3Value = true, ObjectValue = true,
    CFrameValue = true, BrickColorValue = true, Color3Value = true,
    FloatValue = true, DoubleConstrainedValue = true
}

-- Helper
local function getFullPath(obj)
    local path = {}
    while obj and obj ~= game do
        table.insert(path, 1, obj.Name)
        obj = obj.Parent
    end
    return "/" .. table.concat(path, "/")
end

-- Dump values
local function dumpValuesFor(targetName)
    local Players = game:GetService("Players")
    local target = Players:FindFirstChild(targetName)
    if not target then
        return false, "Player not found."
    end

    local results = {}
    for _, inst in ipairs(target:GetDescendants()) do
        if valueTypes[inst.ClassName] then
            local value = tostring(inst.Value)
            local fullPath = getFullPath(inst)
            table.insert(results, fullPath .. " = " .. value)
        end
    end

    if #results > 0 then
        local filename = targetName .. "_Values.txt"
        writefile(filename, table.concat(results, "\n"))
        return true, "Saved to: " .. filename
    else
        return false, "No values found."
    end
end

-- Bind enter key
TextBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local inputName = TextBox.Text:match("^%s*(.-)%s*$")
        if inputName ~= "" then
            local success, msg = dumpValuesFor(inputName)
            InfoLabel.Text = msg
        else
            InfoLabel.Text = "Please enter a username."
        end
    end
end)
