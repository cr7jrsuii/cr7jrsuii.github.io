local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "MoneyGui"
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 400, 0, 64)
main.Position = UDim2.new(0.5, -200, 0.5, -60)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.Parent = gui

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "The Plaza Money Editor"
title.Parent = header

local amountBox = Instance.new("TextBox")
amountBox.Size = UDim2.new(1, -(100 + 12), 0, 25)
amountBox.Position = UDim2.new(0, 4, 0, 35)
amountBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
amountBox.TextColor3 = Color3.new(1, 1, 1)
amountBox.Font = Enum.Font.Code
amountBox.TextSize = 12
amountBox.Text = "10000"
amountBox.ClearTextOnFocus = false
amountBox.TextScaled = false
amountBox.TextXAlignment = Enum.TextXAlignment.Center
amountBox.TextYAlignment = Enum.TextYAlignment.Center
amountBox.ClipsDescendants = true
amountBox.Parent = main

local actionBtn = Instance.new("TextButton")
actionBtn.Size = UDim2.new(0, 100, 0, 25)
actionBtn.Position = UDim2.new(0, 296, 0, 35)
actionBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
actionBtn.TextColor3 = Color3.new(1, 1, 1)
actionBtn.Font = Enum.Font.GothamBold
actionBtn.TextSize = 12
actionBtn.Text = "Add"
actionBtn.Parent = main

actionBtn.MouseButton1Click:Connect(function()
    local amount = tonumber(amountBox.Text)
    if not amount then
        return
    end
    
    local currentID = game.ReplicatedStorage.ServerStats.CurrentID.Value
    local key = math.floor(math.sqrt(currentID)) + 1337
    
    game.ReplicatedStorage.ServerStats.ChangeMoney:FireServer(amount, key)
end)

amountBox:GetPropertyChangedSignal("Text"):Connect(updateButton)

local isVisible = true
local function toggleVisibility()
    isVisible = not isVisible
    main.Visible = isVisible
end

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Home then
        toggleVisibility()
    end
end)

local dragging, dragStart, startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
