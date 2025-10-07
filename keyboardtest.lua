local UserInputService = game:GetService("UserInputService")

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

if isMobile then
    print("Player is on mobile")
else
    print("Player is on PC")
end

local isMobile2 = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local GuiService = game:GetService("GuiService")

local isMobile3 = GuiService:IsTenFootInterface() == false and UserInputService.TouchEnabled

local function getPlatform()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        return "Mobile"
    elseif UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        return "PC"
    elseif UserInputService.GamepadEnabled then
        return "Console"
    else
        return "Unknown"
    end
end

print("Platform:", getPlatform())

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

if isMobile then
    print("Mobile controls enabled")
else
    print("PC controls")
end
