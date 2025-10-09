local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Window = Library:CreateWindow({Title = "Plane Crash Physics Script", Center = true, AutoShow = true})
local GeneralTab = Window:AddTab("General")
local ActionBox = GeneralTab:AddLeftTabbox("Main")
local MainTab = ActionBox:AddTab("Main")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local planeList = {
    ["A360"] = "A360",
    ["A370"] = "A370",
    ["A380"] = "A380",
    ["AE Stunt"] = "AE Stunt",
    ["Airborne280"] = "Airborne280",
    ["Airborne290"] = "Airborne290",
    ["Bomber"] = "Bomber",
    ["Bomber Helicopter"] = "Bomber helicopter",
    ["Cargo Plane"] = "Cargo plane",
    ["Fuel Carrier"] = "Fuel carrier",
    ["Helicopter"] = "Helicopter",
    ["III-T1"] = "III-T1",
    ["III-V1"] = "III-V1",
    ["Little Boy"] = "Little boy",
    ["Passenger Plane"] = "Passenger plane",
    ["Plane"] = "Plane",
    ["Plane2"] = "Plane2",
    ["Speed Plane"] = "Speed plane",
    ["Stunt Plane"] = "Stunt plane",
    ["Tactical Helicopter"] = "Tactical helicopter",
    ["Starfly"] = "[FAST] Starfly",
    ["Tactical Jet"] = "[FAST] Tactical Jet",
    ["Cargo Bomber"] = "[MILITARY] Cargo bomber",
    ["Fighter Jet"] = "[MILITARY] Fighter Jet",
    ["Ray Bomber"] = "[MILITARY] Ray bomber",
    ["Ray Helicopter"] = "[MILITARY] Ray helicopter"
}

local selectedPlane = "A360"

local function getPlayerVehicle()
    for _, vehicle in ipairs(workspace.Vehicles:GetChildren()) do
        local seat = vehicle:FindFirstChild("Seat")
        if seat and seat.Occupant and seat.Occupant.Parent == LocalPlayer.Character then
            return vehicle
        end
    end
    return nil
end

local function removeTouchInterests(parent)
    for _, descendant in ipairs(parent:GetDescendants()) do
        if descendant:IsA("TouchTransmitter") then
            descendant:Destroy()
        end
    end
end

local invincibleEnabled = false
local currentVehicle = nil
local descendantConnection = nil

local speedHackEnabled = false
local speedValue = 100
local turnSpeedEnabled = false
local turnSpeedValue = 10
local noCooldownEnabled = false
local infiniteMoneyEnabled = false
local moneyConnection = nil
local cameraShakeDisabled = false
local cameraShakeConnection = nil

local function setupInvincibility(vehicle)
    if not vehicle then return end
    
    removeTouchInterests(vehicle)
    
    if descendantConnection then
        descendantConnection:Disconnect()
    end
    
    descendantConnection = vehicle.DescendantAdded:Connect(function(descendant)
        if invincibleEnabled and descendant:IsA("TouchTransmitter") then
            descendant:Destroy()
        end
    end)
end

local function applySpeedHack(vehicle)
    if not vehicle then return end
    local config = vehicle:FindFirstChild("Configurations")
    if config then
        local speed = config:FindFirstChild("Speed")
        if speed and speed:IsA("NumberValue") then
            speed.Value = speedValue
        end
    end
end

local function applyTurnSpeed(vehicle)
    if not vehicle then return end
    local config = vehicle:FindFirstChild("Configurations")
    if config then
        local turnSpeed = config:FindFirstChild("TurnSpeed")
        if turnSpeed and turnSpeed:IsA("NumberValue") then
            turnSpeed.Value = turnSpeedValue
        end
    end
end

local function removeCooldown()
    local targetScript = LocalPlayer.PlayerGui.PlaneSpawner.OpenStats.LocalScript
    for _, func in pairs(getgc()) do
        if type(func) == "function" and getfenv(func).script == targetScript then
            debug.setupvalue(func, 1, -1)
        end
    end
end

local function disableCameraShake()
    local cameraShaker = LocalPlayer.Backpack:FindFirstChild("CameraShakerMain")
    if cameraShaker then
        cameraShaker.Disabled = true
    end
    local characterShaker = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("CameraShakerMain")
    if characterShaker then
        characterShaker.Disabled = true
    end
end

local function checkVehicle()
    local vehicle = getPlayerVehicle()
    if vehicle ~= currentVehicle then
        currentVehicle = vehicle
        if vehicle then
            if invincibleEnabled then
                setupInvincibility(vehicle)
            end
            if speedHackEnabled then
                applySpeedHack(vehicle)
            end
            if turnSpeedEnabled then
                applyTurnSpeed(vehicle)
            end
        end
    end
end

MainTab:AddToggle("InfiniteMoney", {
    Text = "Infinite Money",
    Default = false,
    Callback = function(value)
        infiniteMoneyEnabled = value
        
        if value then
            moneyConnection = game:GetService("RunService").RenderStepped:Connect(function()
                game.ReplicatedStorage.GetCash:FireServer()
            end)
        else
            if moneyConnection then
                moneyConnection:Disconnect()
                moneyConnection = nil
            end
        end
    end
})

MainTab:AddToggle("NoSpawnCooldown", {
    Text = "No Spawn Cooldown",
    Default = false,
    Callback = function(value)
        noCooldownEnabled = value
        if value then
            removeCooldown()
        end
    end
})

MainTab:AddToggle("DisableCameraShake", {
    Text = "Disable Camera Shake",
    Default = false,
    Callback = function(value)
        cameraShakeDisabled = value
        
        if value then
            disableCameraShake()
            
            cameraShakeConnection = LocalPlayer.Backpack.ChildAdded:Connect(function(child)
                if cameraShakeDisabled and child.Name == "CameraShakerMain" then
                    child.Disabled = true
                end
            end)
            
            if LocalPlayer.Character then
                LocalPlayer.Character.ChildAdded:Connect(function(child)
                    if cameraShakeDisabled and child.Name == "CameraShakerMain" then
                        child.Disabled = true
                    end
                end)
            end
        else
            if cameraShakeConnection then
                cameraShakeConnection:Disconnect()
                cameraShakeConnection = nil
            end
            
            local cameraShaker = LocalPlayer.Backpack:FindFirstChild("CameraShakerMain")
            if cameraShaker then
                cameraShaker.Disabled = false
            end
            local characterShaker = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("CameraShakerMain")
            if characterShaker then
                characterShaker.Disabled = false
            end
        end
    end
})

local VehicleBox = GeneralTab:AddLeftTabbox("Vehicle")
local VehicleTab = VehicleBox:AddTab("Vehicle")

VehicleTab:AddToggle("Invincible", {
    Text = "Invincible",
    Default = false,
    Callback = function(value)
        invincibleEnabled = value
        
        if value then
            local vehicle = getPlayerVehicle()
            if vehicle then
                currentVehicle = vehicle
                setupInvincibility(vehicle)
            end
        else
            if descendantConnection then
                descendantConnection:Disconnect()
                descendantConnection = nil
            end
            currentVehicle = nil
        end
    end
})

VehicleTab:AddToggle("SpeedHack", {
    Text = "Enable Speed Hack",
    Default = false,
    Callback = function(value)
        speedHackEnabled = value
        if value then
            local vehicle = getPlayerVehicle()
            if vehicle then
                applySpeedHack(vehicle)
            end
        end
    end
})

VehicleTab:AddSlider("SpeedValue", {
    Text = "Speed Value",
    Default = 100,
    Min = 100,
    Max = 1000,
    Rounding = 0,
    Callback = function(value)
        speedValue = value
        if speedHackEnabled then
            local vehicle = getPlayerVehicle()
            if vehicle then
                applySpeedHack(vehicle)
            end
        end
    end
})

VehicleTab:AddToggle("TurnSpeedHack", {
    Text = "Enable Turnspeed Hack",
    Default = false,
    Callback = function(value)
        turnSpeedEnabled = value
        if value then
            local vehicle = getPlayerVehicle()
            if vehicle then
                applyTurnSpeed(vehicle)
            end
        end
    end
})

VehicleTab:AddSlider("TurnSpeedValue", {
    Text = "Turn Speed Value",
    Default = 10,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        turnSpeedValue = value
        if turnSpeedEnabled then
            local vehicle = getPlayerVehicle()
            if vehicle then
                applyTurnSpeed(vehicle)
            end
        end
    end
})

local SpawnBox = GeneralTab:AddRightTabbox("Spawn Plane")
local SpawnTab = SpawnBox:AddTab("Spawn Plane")

local planeNames = {}
for displayName, _ in pairs(planeList) do
    table.insert(planeNames, displayName)
end
table.sort(planeNames)

SpawnTab:AddDropdown("PlaneDropdown", {
    Text = "Select Plane",
    Values = planeNames,
    Default = 1,
    Multi = false,
    Callback = function(value)
        selectedPlane = planeList[value]
    end
})

SpawnTab:AddButton({
    Text = "Spawn",
    Func = function()
        local args = {selectedPlane}
        game:GetService("ReplicatedStorage"):WaitForChild("SpawnCar"):FireServer(unpack(args))
    end
})

game:GetService("RunService").Heartbeat:Connect(function()
    if invincibleEnabled or speedHackEnabled or turnSpeedEnabled then
        checkVehicle()
    end
    if noCooldownEnabled then
        removeCooldown()
    end
    if cameraShakeDisabled then
        disableCameraShake()
    end
end)

local CreditsBox = GeneralTab:AddRightTabbox("Credits")
local CreditsTab = CreditsBox:AddTab("Credits")

CreditsTab:AddButton({
    Text = 'Subscrube to MeatBoxing',
    Func = function()
        setclipboard('https://www.youtube.com/@meatboxing')
        Library:Notify('Copied Link')
    end,
    Tooltip = 'For creating this script'
})

game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.End then
        Library:Toggle()
    end
end)
