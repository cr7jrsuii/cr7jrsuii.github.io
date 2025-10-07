local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local function isMobile()
    return GuiService:IsTenFootInterface() == false and UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

if isMobile() then
    print("Mobile detected")
else
    print("Not mobile")
end
