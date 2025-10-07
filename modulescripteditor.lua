local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "ModuleEditor"
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 700, 0, 450)
main.Position = UDim2.new(0.5, -350, 0.5, -225)
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
title.Text = "ModuleScript Editor"
title.Parent = header

local pathBox = Instance.new("TextBox")
pathBox.Size = UDim2.new(1, -120, 0, 25)
pathBox.Position = UDim2.new(0, 10, 0, 40)
pathBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
pathBox.TextColor3 = Color3.new(1, 1, 1)
pathBox.Font = Enum.Font.Code
pathBox.TextSize = 12
pathBox.Text = "workspace.ModuleScript"
pathBox.ClearTextOnFocus = false
pathBox.Parent = main

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(0, 50, 0, 25)
loadBtn.Position = UDim2.new(1, -110, 0, 40)
loadBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
loadBtn.TextColor3 = Color3.new(1, 1, 1)
loadBtn.Text = "Load"
loadBtn.Parent = main

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0, 50, 0, 25)
saveBtn.Position = UDim2.new(1, -55, 0, 40)
saveBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
saveBtn.TextColor3 = Color3.new(1, 1, 1)
saveBtn.Text = "Save"
saveBtn.Parent = main

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -85)
scroll.Position = UDim2.new(0, 10, 0, 70)
scroll.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scroll.ScrollBarThickness = 6
scroll.Parent = main

local editor = Instance.new("TextBox")
editor.Size = UDim2.new(1, -6, 1, 0)
editor.BackgroundTransparency = 1
editor.TextColor3 = Color3.new(1, 1, 1)
editor.Font = Enum.Font.Code
editor.TextSize = 13
editor.MultiLine = true
editor.TextXAlignment = Enum.TextXAlignment.Left
editor.TextYAlignment = Enum.TextYAlignment.Top
editor.Text = "-- Load a module to edit"
editor.ClearTextOnFocus = false
editor.TextWrapped = false
editor.ClipsDescendants = false
editor.Parent = scroll

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 15)
status.Position = UDim2.new(0, 10, 1, -15)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(150, 150, 150)
status.Font = Enum.Font.Code
status.TextSize = 12
status.Text = "Ready"
status.Parent = main

local currentModule
local isVisible = true

local function updateScroll()
	local lines = #string.split(editor.Text, "\n")
	scroll.CanvasSize = UDim2.new(0, 0, 0, lines * 16)
end

local function toggleVisibility()
	isVisible = not isVisible
	main.Visible = isVisible
end

local function tableToString(t, depth)
	depth = depth or 0
	if type(t) ~= "table" then return tostring(t) end
	
	local indent = string.rep("  ", depth)
	local result = "{\n"
	
	for k, v in pairs(t) do
		local key = type(k) == "string" and '["'..k..'"]' or "["..k.."]"
		result = result .. indent .. "  " .. key .. " = "
		
		if type(v) == "table" then
			result = result .. tableToString(v, depth + 1)
		elseif type(v) == "string" then
			result = result .. '"' .. v .. '"'
		else
			result = result .. tostring(v)
		end
		result = result .. ",\n"
	end
	
	return result .. indent .. "}"
end

loadBtn.MouseButton1Click:Connect(function()
	local path = pathBox.Text
	local success, module = pcall(loadstring("return " .. path))
	
	if not success or not module or not module:IsA("ModuleScript") then
		status.Text = "Invalid module path"
		return
	end
	
	local data = require(module)
	if type(data) == "table" then
		editor.Text = tableToString(data)
		currentModule = module
		updateScroll()
		status.Text = "Loaded: " .. module.Name
	else
		status.Text = "Module doesn't return a table"
	end
end)

saveBtn.MouseButton1Click:Connect(function()
	if not currentModule then
		status.Text = "No module loaded"
		return
	end
	
	local success, newData = pcall(loadstring("return " .. editor.Text))
	if not success or type(newData) ~= "table" then
		status.Text = "Invalid table format"
		return
	end
	
	local moduleData = require(currentModule)
	if type(moduleData) == "table" then
		for k in pairs(moduleData) do
			moduleData[k] = nil
		end
		for k, v in pairs(newData) do
			moduleData[k] = v
		end
		status.Text = "Saved successfully"
	else
		status.Text = "Save failed"
	end
end)

editor:GetPropertyChangedSignal("Text"):Connect(updateScroll)

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
