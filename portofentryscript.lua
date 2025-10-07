local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Window = Library:CreateWindow({Title = "Port of Entry: Border Roleplay Script", Center = true, AutoShow = true})
local GeneralTab = Window:AddTab("General")
local ActionBox = GeneralTab:AddLeftTabbox("Main")
local MainTab = ActionBox:AddTab("Main")

local SpawnBox = GeneralTab:AddLeftTabbox("Spawn")
local SpawnTab = SpawnBox:AddTab("Character")

local skinColor = Color3.new(0.8627451062202454, 0.7882353067398071, 0.6039215922355652)
local gender = "Female"
local nationality = "American"
local hairId = 32278814
local faceId = 277950647
local firstName = "Abigail"
local lastName = "Alexander"

local defaultHairId = 32278814
local defaultFaceId = 277950647

local nameModules = {
    American = require(game:GetService("ReplicatedStorage").Assets.Character.NameModules.American),
    Mexican = require(game:GetService("ReplicatedStorage").Assets.Character.NameModules.Mexican)
}

local function getAllNames()
    local allNames = {}
    for nat, module in pairs(nameModules) do
        for gend, names in pairs(module) do
            if gend ~= "LastNames" then
                for _, name in pairs(names) do
                    table.insert(allNames, nat .. " - " .. gend .. " - " .. name)
                end
            end
        end
    end
    table.sort(allNames)
    return allNames
end

local function getAllLastNames()
    local allLastNames = {}
    for nat, module in pairs(nameModules) do
        for _, name in pairs(module.LastNames) do
            table.insert(allLastNames, nat .. " - " .. name)
        end
    end
    table.sort(allLastNames)
    return allLastNames
end

SpawnTab:AddDropdown('FirstName', {Values = getAllNames(), Default = 1, Multi = false, Text = 'First Name', Callback = function(value)
    local parts = string.split(value, " - ")
    nationality = parts[1]
    gender = parts[2]
    firstName = parts[3]
end})

SpawnTab:AddDropdown('LastName', {Values = getAllLastNames(), Default = 1, Multi = false, Text = 'Last Name', Callback = function(value)
    local parts = string.split(value, " - ")
    lastName = parts[2]
end})

SpawnTab:AddLabel('Skin Tone'):AddColorPicker('SkinTone', {Default = skinColor, Title = 'Skin Tone', Callback = function(value)
    skinColor = value
end})

SpawnTab:AddInput('HairId', {Default = tostring(hairId), Numeric = true, Text = 'Hair ID', Placeholder = 'Enter Hair ID', Callback = function(value)
    if value == "" or value == nil then
        hairId = defaultHairId
    else
        hairId = tonumber(value) or defaultHairId
    end
end})

SpawnTab:AddInput('FaceId', {Default = tostring(faceId), Numeric = true, Text = 'Face ID', Placeholder = 'Enter Face ID', Callback = function(value)
    if value == "" or value == nil then
        faceId = defaultFaceId
    else
        faceId = tonumber(value) or defaultFaceId
    end
end})

SpawnTab:AddButton({Text = 'Spawn Character', Func = function()
    local finalHairId = (hairId and hairId ~= 0) and hairId or defaultHairId
    local finalFaceId = (faceId and faceId ~= 0) and faceId or defaultFaceId
    
    local args = {{
        Nationality = nationality,
        HairId = finalHairId,
        Forename = firstName,
        SkinColor = skinColor,
        Gender = gender,
        FaceId = finalFaceId,
        Surname = lastName
    }}
    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_knit@1.7.0"):WaitForChild("knit"):WaitForChild("Services"):WaitForChild("Character"):WaitForChild("RF"):WaitForChild("SpawnCharacter"):InvokeServer(unpack(args))
end})

local autoFarmEnabled = false

MainTab:AddToggle("DisableTrespass", {Text = "Disable Trespass", Default = false, Callback = function(value)
    if not autoFarmEnabled then
        for _, trigger in pairs(workspace.Triggers:GetChildren()) do
            if trigger.Name == "TrespassingTrigger" then
                trigger.CanTouch = not value
            end
        end
    end
end})

MainTab:AddToggle("DisableBorder", {Text = "Disable Border", Default = false, Callback = function(value)
    if not autoFarmEnabled then
        local borderTrigger = workspace.Triggers:FindFirstChild("BorderTrigger")
        if borderTrigger then
            borderTrigger.CanTouch = not value
        end
    end
end})

MainTab:AddToggle("AutoFarm", {Text = "Auto Farm", Default = false, Callback = function(value)
    autoFarmEnabled = value
end})

MainTab:AddButton({Text = 'Get Dufflebag', Func = function()
    if not autoFarmEnabled then
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character
        if character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            local proximityPrompt = workspace.ContrabandDealers.DuffleBagShop.ProximityPrompt
            if humanoidRootPart and proximityPrompt then
                local originalPos = humanoidRootPart.CFrame
                humanoidRootPart.CFrame = proximityPrompt.Parent.CFrame
                task.wait(0.5)
                fireproximityprompt(proximityPrompt)
                humanoidRootPart.CFrame = originalPos
            end
        end
    end
end})

local ActionsBox = GeneralTab:AddLeftTabbox("Actions")
local ActionsTab = ActionsBox:AddTab("Triggers")

ActionsTab:AddButton({Text = 'Cross Border', Func = function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local borderTrigger = workspace.Triggers:FindFirstChild("BorderTrigger")
        if humanoidRootPart and borderTrigger then
            firetouchinterest(borderTrigger, humanoidRootPart, true)
            firetouchinterest(borderTrigger, humanoidRootPart, false)
        end
    end
end})

ActionsTab:AddButton({Text = 'Trespass', Func = function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        for _, trigger in pairs(workspace.Triggers:GetChildren()) do
            if trigger.Name == "TrespassingTrigger" then
                firetouchinterest(trigger, humanoidRootPart, true)
                firetouchinterest(trigger, humanoidRootPart, false)
                break
            end
        end
    end
end})

local CreditsBox = GeneralTab:AddLeftTabbox("Credits")
local CreditsTab = CreditsBox:AddTab("Credits")
CreditsTab:AddButton({Text = 'Subscribe to MeatBoxing', Func = function() 
    setclipboard('https://www.youtube.com/@meatboxing')
    Library:Notify('Copied Link') 
end, Tooltip = 'For creating this script'})

local ShopBox = GeneralTab:AddRightTabbox("Shop")
local ShopTab = ShopBox:AddTab("Items")

ShopTab:AddButton({Text = 'Valid Passport ($50)', Func = function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local proximityPrompt = workspace.PassportDealers.PassportShopValid.ProximityPrompt
        if humanoidRootPart and proximityPrompt then
            local originalPos = humanoidRootPart.CFrame
            humanoidRootPart.CFrame = proximityPrompt.Parent.CFrame
            task.wait(0.5)
            fireproximityprompt(proximityPrompt)
            humanoidRootPart.CFrame = originalPos
        end
    end
end})

ShopTab:AddButton({Text = 'Invalid Passport ($10)', Func = function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local proximityPrompt = workspace.PassportDealers.PassportShopInvalid.ProximityPrompt
        if humanoidRootPart and proximityPrompt then
            local originalPos = humanoidRootPart.CFrame
            humanoidRootPart.CFrame = proximityPrompt.Parent.CFrame
            task.wait(0.5)
            fireproximityprompt(proximityPrompt)
            humanoidRootPart.CFrame = originalPos
        end
    end
end})

ShopTab:AddButton({Text = 'AK74 ($300)', Func = function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local proximityPrompt = workspace.ItemShops.ItemShop.ProximityPrompt
        if humanoidRootPart and proximityPrompt then
            local originalPos = humanoidRootPart.CFrame
            humanoidRootPart.CFrame = proximityPrompt.Parent.CFrame
            task.wait(0.5)
            fireproximityprompt(proximityPrompt)
            humanoidRootPart.CFrame = originalPos
        end
    end
end})

ShopTab:AddButton({Text = 'MicroDraco ($750)', Func = function()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if character then
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local itemShops = workspace.ItemShops:GetChildren()
        if #itemShops >= 2 then
            local proximityPrompt = itemShops[2].ProximityPrompt
            if humanoidRootPart and proximityPrompt then
                local originalPos = humanoidRootPart.CFrame
                humanoidRootPart.CFrame = proximityPrompt.Parent.CFrame
                task.wait(0.5)
                fireproximityprompt(proximityPrompt)
                humanoidRootPart.CFrame = originalPos
            end
        end
    end
end})

local TeleportBox = GeneralTab:AddRightTabbox("Teleport")
local TeleportTab = TeleportBox:AddTab("Locations")

local teleportLocations = {
    {"Sheriff's Office", Vector3.new(-196, 53, -588)},
    {"Border Patrol", Vector3.new(-177, 53, -523)},
    {"Port Bank", Vector3.new(30, 53, -640)},
    {"Melon Cafe", Vector3.new(121, 53, -617)},
    {"Duck Mart", Vector3.new(125, 53, -668)},
    {"Jack's Steakhouse", Vector3.new(27, 53, -883)},
    {"Immigration and Customs Enforcement", Vector3.new(161, 53, -955)},
    {"Department of Justice", Vector3.new(20, 53, -954)},
    {"Maple Flowers", Vector3.new(21, 53, -915)},
    {"CorPo Gas", Vector3.new(27, 53, -790)},
    {"Mecanica Martinez 2", Vector3.new(-221, 65, -53)},
    {"Mecanica Martinez 1", Vector3.new(237, 66, -6)},
    {"Pablo's Workshop", Vector3.new(229, 66, -32)},
    {"Cantina", Vector3.new(304, 66, -6)},
    {"Abandoned House", Vector3.new(111, 49, -168)},
    {"Port of Entry", Vector3.new(329, 68, -448)},
    {"Department of Homeland Security", Vector3.new(356, 68, -628)}
}

for _, location in pairs(teleportLocations) do
    TeleportTab:AddButton({Text = location[1], Func = function()
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character
        if character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                humanoidRootPart.CFrame = CFrame.new(location[2])
            end
        end
    end})
end

task.spawn(function()
    while true do
        if autoFarmEnabled then
            local finalHairId = (hairId and hairId ~= 0) and hairId or defaultHairId
            local finalFaceId = (faceId and faceId ~= 0) and faceId or defaultFaceId
            
            local args = {{
                Nationality = nationality,
                HairId = finalHairId,
                Forename = firstName,
                SkinColor = skinColor,
                Gender = gender,
                FaceId = finalFaceId,
                Surname = lastName
            }}
            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_knit@1.7.0"):WaitForChild("knit"):WaitForChild("Services"):WaitForChild("Character"):WaitForChild("RF"):WaitForChild("SpawnCharacter"):InvokeServer(unpack(args))
            
            local player = game:GetService("Players").LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            local proximityPrompt = game:GetService("Workspace"):WaitForChild("ContrabandDealers"):WaitForChild("DuffleBagShop"):WaitForChild("ProximityPrompt")
            
            humanoidRootPart.CFrame = proximityPrompt.Parent.CFrame
            task.wait(0.5)
            fireproximityprompt(proximityPrompt)
            local borderTrigger = game:GetService("Workspace"):WaitForChild("Triggers"):WaitForChild("BorderTrigger")
            firetouchinterest(borderTrigger, humanoidRootPart, true)
            firetouchinterest(borderTrigger, humanoidRootPart, false)
            task.wait(0.25)
        else
            task.wait(1)
        end
    end
end)

game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.End then
        Library:Toggle()
    end
end)
