local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local boxesEnabled = false
local boxColor = Color3.new(1, 0, 0)
local tracersEnabled = false
local savedWeaponStats = {}
local aimbotEnabled = false
local targetBodyPart = "HumanoidRootPart"
local fieldOfView = 100
local showCircle = false
local circleColor = Color3.new(1, 0, 0)
local wallCheck = false
local isAiming = false
local lockedTarget = nil
local playerBoxes = {}
local playerTracers = {}
local cameraFOV = 70
local fovChangerEnabled = false
local fullbrightEnabled = false
local timeChangerEnabled = false
local customTime = 12
local skyColorEnabled = false
local skyColor = Color3.new(0.5, 0.8, 1)
local savedLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows
}

local function isEnemyPlayer(plr)
    return plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team
end

local function getCharacter(plr)
    local charFolder = Workspace:FindFirstChild("Instantials") and Workspace.Instantials:FindFirstChild("Characters")
    if charFolder then
        return charFolder:FindFirstChild(plr.Name)
    end
    return nil
end

local function makeBox()
    local newBox = Drawing.new("Square")
    newBox.Visible = false
    newBox.Thickness = 2
    newBox.Transparency = 1
    newBox.Color = boxColor
    newBox.Filled = false
    return newBox
end

local function makeTracer()
    local newLine = Drawing.new("Line")
    newLine.Visible = false
    newLine.Thickness = 2
    newLine.Transparency = 1
    newLine.Color = boxColor
    return newLine
end

local function setupPlayerVisuals(plr)
    if playerBoxes[plr] then
        playerBoxes[plr].box:Remove()
        if playerBoxes[plr].line then
            playerBoxes[plr].line:Remove()
        end
        if playerBoxes[plr].connection then
            playerBoxes[plr].connection:Disconnect()
        end
    end
    
    local box = makeBox()
    local line = makeTracer()
    
    local renderConnection = RunService.RenderStepped:Connect(function()
        if not isEnemyPlayer(plr) then
            box.Visible = false
            line.Visible = false
            return
        end
        
        local character = getCharacter(plr)
        if not character then
            box.Visible = false
            line.Visible = false
            return
        end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            box.Visible = false
            line.Visible = false
            return
        end
        
        local cam = Workspace.CurrentCamera
        local screenPos, onScreen = cam:WorldToViewportPoint(rootPart.Position)
        
        if onScreen then
            if boxesEnabled then
                local topPosition = cam:WorldToViewportPoint((rootPart.CFrame * CFrame.new(0, 3, 0)).Position)
                local bottomPosition = cam:WorldToViewportPoint((rootPart.CFrame * CFrame.new(0, -3, 0)).Position)
                
                local boxHeight = math.abs(topPosition.Y - bottomPosition.Y)
                local boxWidth = boxHeight / 2
                
                box.Size = Vector2.new(boxWidth, boxHeight)
                box.Position = Vector2.new(screenPos.X - boxWidth / 2, screenPos.Y - boxHeight / 2)
                box.Color = boxColor
                box.Visible = true
            else
                box.Visible = false
            end
            
            if tracersEnabled then
                local viewport = cam.ViewportSize
                line.From = Vector2.new(viewport.X / 2, viewport.Y)
                line.To = Vector2.new(screenPos.X, screenPos.Y)
                line.Color = boxColor
                line.Visible = true
            else
                line.Visible = false
            end
        else
            box.Visible = false
            line.Visible = false
        end
    end)
    
    playerBoxes[plr] = {box = box, line = line, connection = renderConnection}
end

local function clearPlayerVisuals(plr)
    if playerBoxes[plr] then
        playerBoxes[plr].box:Remove()
        if playerBoxes[plr].line then
            playerBoxes[plr].line:Remove()
        end
        if playerBoxes[plr].connection then
            playerBoxes[plr].connection:Disconnect()
        end
        playerBoxes[plr] = nil
    end
end

local function refreshColors()
    for plr, data in pairs(playerBoxes) do
        if data.box then
            data.box.Color = boxColor
        end
        if data.line then
            data.line.Color = boxColor
        end
    end
end

local aimCircle = Drawing.new("Circle")
aimCircle.Thickness = 2
aimCircle.NumSides = 64
aimCircle.Radius = fieldOfView
aimCircle.Color = circleColor
aimCircle.Visible = false
aimCircle.Filled = false
aimCircle.Transparency = 1

local function refreshCircle()
    local cam = Workspace.CurrentCamera
    local viewport = cam.ViewportSize
    aimCircle.Position = Vector2.new(viewport.X / 2, viewport.Y / 2)
    aimCircle.Radius = fieldOfView
    aimCircle.Color = circleColor
    aimCircle.Visible = showCircle and aimbotEnabled
end

local function findNearestEnemy()
    local nearestPlayer = nil
    local smallestDistance = fieldOfView
    local closestWorldDist = math.huge
    
    local cam = Workspace.CurrentCamera
    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    
    for _, plr in pairs(Players:GetPlayers()) do
        if isEnemyPlayer(plr) then
            local character = getCharacter(plr)
            if character then
                local targetPart = character:FindFirstChild(targetBodyPart)
                if targetPart then
                    local viewportPos, visible = cam:WorldToViewportPoint(targetPart.Position)
                    if visible then
                        local distanceFromCenter = (Vector2.new(viewportPos.X, viewportPos.Y) - screenCenter).Magnitude
                        if distanceFromCenter < smallestDistance then
                            local worldDist = (targetPart.Position - cam.CFrame.Position).Magnitude
                            
                            if wallCheck then
                                local castRay = Ray.new(cam.CFrame.Position, (targetPart.Position - cam.CFrame.Position).Unit * 1000)
                                local hitPart, hitPos = Workspace:FindPartOnRayWithIgnoreList(castRay, {LocalPlayer.Character, cam})
                                if hitPart and hitPart:IsDescendantOf(character) then
                                    if distanceFromCenter < smallestDistance or (distanceFromCenter == smallestDistance and worldDist < closestWorldDist) then
                                        nearestPlayer = targetPart
                                        smallestDistance = distanceFromCenter
                                        closestWorldDist = worldDist
                                    end
                                end
                            else
                                if distanceFromCenter < smallestDistance or (distanceFromCenter == smallestDistance and worldDist < closestWorldDist) then
                                    nearestPlayer = targetPart
                                    smallestDistance = distanceFromCenter
                                    closestWorldDist = worldDist
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return nearestPlayer
end

RunService.RenderStepped:Connect(function()
    refreshCircle()
    
    if fovChangerEnabled then
        local cam = Workspace.CurrentCamera
        cam.FieldOfView = cameraFOV
    end
    
    if fullbrightEnabled then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.FogEnd = 1e9
        Lighting.GlobalShadows = false
    end
    
    if timeChangerEnabled then
        Lighting.TimeOfDay = string.format("%02d:00:00", customTime)
    end
    
    if skyColorEnabled then
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky then
            sky.SkyboxBk = ""
            sky.SkyboxDn = ""
            sky.SkyboxFt = ""
            sky.SkyboxLf = ""
            sky.SkyboxRt = ""
            sky.SkyboxUp = ""
            sky.StarCount = 0
            sky.SunAngularSize = 0
            sky.MoonAngularSize = 0
        else
            local newSky = Instance.new("Sky")
            newSky.Parent = Lighting
            newSky.SkyboxBk = ""
            newSky.SkyboxDn = ""
            newSky.SkyboxFt = ""
            newSky.SkyboxLf = ""
            newSky.SkyboxRt = ""
            newSky.SkyboxUp = ""
            newSky.StarCount = 0
            newSky.SunAngularSize = 0
            newSky.MoonAngularSize = 0
        end
        Lighting.Ambient = skyColor
        Lighting.OutdoorAmbient = skyColor
        Lighting.FogColor = skyColor
    end
    
    if isAiming and aimbotEnabled then
        local cam = Workspace.CurrentCamera
        
        if not lockedTarget or not lockedTarget.Parent then
            lockedTarget = findNearestEnemy()
        end
        
        if lockedTarget and lockedTarget.Parent then
            cam.CFrame = CFrame.new(cam.CFrame.Position, lockedTarget.Position)
        else
            lockedTarget = nil
        end
    end
end)

local LinoriaLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Window = LinoriaLib:CreateWindow({Title = "Paintball Wars! Script", Center = true, AutoShow = true})
local Tabs = {
    General = Window:AddTab("General")
}

local MainBox = Tabs.General:AddLeftTabbox("Main")
local Main = MainBox:AddTab("Main")

Main:AddToggle("WeaponMods", {Text = "Weapon Mods", Default = false, Callback = function(val)
    if val then
        for i,v in pairs(game:GetService("ReplicatedStorage").Shared.Databases.Weapons:GetChildren()) do
            local weaponModule = require(game:GetService("ReplicatedStorage").Shared.Databases.Weapons[v.Name])
            if not savedWeaponStats[v.Name] then
                savedWeaponStats[v.Name] = {
                    FullAuto = weaponModule.FullAuto,
                    BulletDelay = weaponModule.BulletDelay,
                    Acceleration = weaponModule.Acceleration,
                    Velocity = weaponModule.Velocity
                }
            end
            weaponModule.FullAuto = true
            weaponModule.BulletDelay = 0
            weaponModule.Acceleration = Vector3.new(0,0,0)
            weaponModule.Velocity = -100000
        end
    else
        for i,v in pairs(game:GetService("ReplicatedStorage").Shared.Databases.Weapons:GetChildren()) do
            local weaponModule = require(game:GetService("ReplicatedStorage").Shared.Databases.Weapons[v.Name])
            if savedWeaponStats[v.Name] then
                weaponModule.FullAuto = savedWeaponStats[v.Name].FullAuto
                weaponModule.BulletDelay = savedWeaponStats[v.Name].BulletDelay
                weaponModule.Acceleration = savedWeaponStats[v.Name].Acceleration
                weaponModule.Velocity = savedWeaponStats[v.Name].Velocity
            end
        end
    end
end})

local EspBox = Tabs.General:AddLeftTabbox("Esp")
local Esp = EspBox:AddTab("Esp")

Esp:AddToggle("ESPBoxes", {Text = "Boxes", Default = false}):AddColorPicker("ESPColor", {Default = Color3.new(1, 0, 0)})

Toggles.ESPBoxes:OnChanged(function()
    boxesEnabled = Toggles.ESPBoxes.Value
    
    if boxesEnabled or tracersEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if isEnemyPlayer(plr) then
                setupPlayerVisuals(plr)
            end
        end
    else
        for plr, _ in pairs(playerBoxes) do
            clearPlayerVisuals(plr)
        end
    end
end)

Options.ESPColor:OnChanged(function()
    boxColor = Options.ESPColor.Value
    refreshColors()
end)

Esp:AddToggle("Tracers", {Text = "Tracers", Default = false, Callback = function(val)
    tracersEnabled = val
    
    if boxesEnabled or tracersEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if isEnemyPlayer(plr) then
                setupPlayerVisuals(plr)
            end
        end
    else
        for plr, _ in pairs(playerBoxes) do
            clearPlayerVisuals(plr)
        end
    end
end})

local MiscBox = Tabs.General:AddLeftTabbox("Misc")
local Misc = MiscBox:AddTab("Misc")

Misc:AddToggle("FOVEnabled", {Text = "FOV Changer", Default = false, Callback = function(val)
    fovChangerEnabled = val
    if not val then
        Workspace.CurrentCamera.FieldOfView = 70
    end
end})

Misc:AddSlider("CustomFOV", {Text = "FOV", Default = 70, Min = 60, Max = 120, Rounding = 0, Callback = function(val)
    cameraFOV = val
end})

Misc:AddToggle("Fullbright", {Text = "Fullbright", Default = false, Callback = function(val)
    fullbrightEnabled = val
    if not val then
        Lighting.Ambient = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
        Lighting.Brightness = savedLighting.Brightness
        Lighting.FogEnd = savedLighting.FogEnd
        Lighting.GlobalShadows = savedLighting.GlobalShadows
    end
end})

Misc:AddToggle("TimeEnabled", {Text = "Time Changer", Default = false, Callback = function(val)
    timeChangerEnabled = val
end})

Misc:AddSlider("CustomTime", {Text = "Time (Hour)", Default = 12, Min = 0, Max = 23, Rounding = 0, Callback = function(val)
    customTime = val
end})

Misc:AddToggle("SkyColorEnabled", {Text = "Sky Color", Default = false}):AddColorPicker("SkyColor", {Default = Color3.new(0.5, 0.8, 1)})

Toggles.SkyColorEnabled:OnChanged(function()
    skyColorEnabled = Toggles.SkyColorEnabled.Value
    if not skyColorEnabled then
        Lighting.Ambient = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
        Lighting.FogColor = Color3.fromRGB(191, 191, 191)
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky and sky.SkyboxBk == "" then
            sky:Destroy()
        end
    end
end)

Options.SkyColor:OnChanged(function()
    skyColor = Options.SkyColor.Value
end)

local AimbotBox = Tabs.General:AddRightTabbox("Aimbot")
local Aimbot = AimbotBox:AddTab("Aimbot")

Aimbot:AddToggle("AimbotEnabled", {Text = "Enabled", Default = false, Callback = function(val)
    aimbotEnabled = val
    if not val then
        isAiming = false
        lockedTarget = nil
        aimCircle.Visible = false
    end
end})

Aimbot:AddDropdown("AimbotPart", {
    Values = {"HumanoidRootPart", "Head"},
    Default = 1,
    Multi = false,
    Text = "Target Part",
    Callback = function(val)
        targetBodyPart = val
    end
})

Aimbot:AddSlider("AimbotFOV", {Text = "FOV", Default = 100, Min = 20, Max = 500, Rounding = 0, Callback = function(val)
    fieldOfView = val
end})

Aimbot:AddToggle("ShowFOVCircle", {Text = "Show FOV Circle", Default = false}):AddColorPicker("FOVCircleColor", {Default = Color3.new(1, 0, 0)})

Toggles.ShowFOVCircle:OnChanged(function()
    showCircle = Toggles.ShowFOVCircle.Value
    if not showCircle then
        aimCircle.Visible = false
    end
end)

Options.FOVCircleColor:OnChanged(function()
    circleColor = Options.FOVCircleColor.Value
end)

Aimbot:AddToggle("VisibleCheck", {Text = "Visible Check", Default = false, Callback = function(val)
    wallCheck = val
end})

local CreditsBox = Tabs.General:AddRightTabbox("Credits")
local Credits = CreditsBox:AddTab("Credits")
Credits:AddButton({Text = 'Subscrube to MeatBoxing', Func = function() setclipboard('https://www.youtube.com/@meatboxing'); LinoriaLib:Notify('Copied Link') end, Tooltip = 'For creating this script'})

local ConfigBox = Tabs.General:AddRightTabbox("Config")
local Config = ConfigBox:AddTab("Config")

local configPath = "paintballwarsconfig.json"

local function saveConfig()
    local configData = {
        weaponMods = Toggles.WeaponMods.Value,
        boxes = Toggles.ESPBoxes.Value,
        boxColorR = boxColor.R,
        boxColorG = boxColor.G,
        boxColorB = boxColor.B,
        tracers = Toggles.Tracers.Value,
        fovChanger = Toggles.FOVEnabled.Value,
        customFOV = cameraFOV,
        fullbright = Toggles.Fullbright.Value,
        timeChanger = Toggles.TimeEnabled.Value,
        customTime = customTime,
        skyColor = Toggles.SkyColorEnabled.Value,
        skyColorR = skyColor.R,
        skyColorG = skyColor.G,
        skyColorB = skyColor.B,
        aimbot = Toggles.AimbotEnabled.Value,
        aimbotPart = targetBodyPart,
        aimbotFOV = fieldOfView,
        showFOVCircle = Toggles.ShowFOVCircle.Value,
        fovCircleColorR = circleColor.R,
        fovCircleColorG = circleColor.G,
        fovCircleColorB = circleColor.B,
        visibleCheck = Toggles.VisibleCheck.Value
    }
    writefile(configPath, game:GetService("HttpService"):JSONEncode(configData))
    LinoriaLib:Notify('Config saved!')
end

local function loadConfig()
    if not isfile(configPath) then LinoriaLib:Notify('No config found!') return end
    local configData = game:GetService("HttpService"):JSONDecode(readfile(configPath))
    Toggles.WeaponMods:SetValue(configData.weaponMods or false)
    Toggles.ESPBoxes:SetValue(configData.boxes or false)
    Options.ESPColor:SetValue(Color3.new(configData.boxColorR, configData.boxColorG, configData.boxColorB))
    Toggles.Tracers:SetValue(configData.tracers or false)
    Toggles.FOVEnabled:SetValue(configData.fovChanger or false)
    Options.CustomFOV:SetValue(configData.customFOV)
    Toggles.Fullbright:SetValue(configData.fullbright or false)
    Toggles.TimeEnabled:SetValue(configData.timeChanger or false)
    Options.CustomTime:SetValue(configData.customTime)
    Toggles.SkyColorEnabled:SetValue(configData.skyColor or false)
    Options.SkyColor:SetValue(Color3.new(configData.skyColorR, configData.skyColorG, configData.skyColorB))
    Toggles.AimbotEnabled:SetValue(configData.aimbot or false)
    Options.AimbotPart:SetValue(configData.aimbotPart)
    Options.AimbotFOV:SetValue(configData.aimbotFOV)
    Toggles.ShowFOVCircle:SetValue(configData.showFOVCircle or false)
    Options.FOVCircleColor:SetValue(Color3.new(configData.fovCircleColorR, configData.fovCircleColorG, configData.fovCircleColorB))
    Toggles.VisibleCheck:SetValue(configData.visibleCheck or false)
    LinoriaLib:Notify('Config loaded!')
end

Config:AddButton({Text = 'Save Config', Func = saveConfig})
Config:AddButton({Text = 'Load Config', Func = loadConfig})
Config:AddButton({Text = 'Delete Config', Func = function()
    if isfile(configPath) then delfile(configPath) LinoriaLib:Notify('Config deleted!') else LinoriaLib:Notify('No config to delete!') end
end})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 and aimbotEnabled then
        isAiming = true
        lockedTarget = findNearestEnemy()
    end
    
    if input.KeyCode == Enum.KeyCode.End then
        LinoriaLib:Toggle()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isAiming = false
        lockedTarget = nil
    end
end)

Players.PlayerAdded:Connect(function(plr)
    if (boxesEnabled or tracersEnabled) and isEnemyPlayer(plr) then
        setupPlayerVisuals(plr)
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    clearPlayerVisuals(plr)
end)
