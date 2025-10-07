local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaKeyHelper"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 200, 0, 120)
container.Position = UDim2.new(1, -210, 0.5, -60)
container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
container.BorderSizePixel = 0
container.Active = true
container.Draggable = true
container.Parent = screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 10)
containerCorner.Parent = container

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.BorderSizePixel = 0
titleBar.Parent = container

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Delta Keys"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 25, 0, 25)
closeButton.Position = UDim2.new(1, -28, 0, 2.5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 12
closeButton.Font = Enum.Font.GothamBold
closeButton.BorderSizePixel = 0
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 5)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local homeButton = Instance.new("TextButton")
homeButton.Name = "HomeButton"
homeButton.Size = UDim2.new(1, -20, 0, 35)
homeButton.Position = UDim2.new(0, 10, 0, 40)
homeButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
homeButton.Text = "HOME"
homeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
homeButton.TextSize = 16
homeButton.Font = Enum.Font.GothamBold
homeButton.BorderSizePixel = 0
homeButton.Parent = container

local homeCorner = Instance.new("UICorner")
homeCorner.CornerRadius = UDim.new(0, 8)
homeCorner.Parent = homeButton

local endButton = Instance.new("TextButton")
endButton.Name = "EndButton"
endButton.Size = UDim2.new(1, -20, 0, 35)
endButton.Position = UDim2.new(0, 10, 0, 80)
endButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
endButton.Text = "END"
endButton.TextColor3 = Color3.fromRGB(255, 255, 255)
endButton.TextSize = 16
endButton.Font = Enum.Font.GothamBold
endButton.BorderSizePixel = 0
endButton.Parent = container

local endCorner = Instance.new("UICorner")
endCorner.CornerRadius = UDim.new(0, 8)
endCorner.Parent = endButton

local function flashButton(button)
    local originalColor = button.BackgroundColor3
    button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    task.wait(0.1)
    button.BackgroundColor3 = originalColor
end

homeButton.MouseButton1Click:Connect(function()
    flashButton(homeButton)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Home, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Home, false, game)
    end)
    print("HOME key pressed")
end)

endButton.MouseButton1Click:Connect(function()
    flashButton(endButton)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.End, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.End, false, game)
    end)
    print("END key pressed")
end)

print("Delta Key Helper Loaded - Use HOME/END buttons to control executor GUI")
