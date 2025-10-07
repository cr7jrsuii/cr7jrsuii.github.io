local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Window = Library:CreateWindow({Title = "Fading Blocks Script", Center = true, AutoShow = true})
local GeneralTab = Window:AddTab("General")
local ActionBox = GeneralTab:AddLeftTabbox("Main")
local MainTab = ActionBox:AddTab("Main")

local playtimeToggle = false
MainTab:AddToggle("PlaytimeToggle", {
    Text = "Add Money",
    Default = false,
    Callback = function(value)
        playtimeToggle = value
    end
})

local infiniteJumpEnabled = false
MainTab:AddToggle("InfiniteJumpToggle", {
    Text = "Infinite Jump",
    Default = false,
    Callback = function(value)
        infiniteJumpEnabled = value
    end
})

MainTab:AddButton({
    Text = "Remove all Blocks",
    Func = function()
        for _, n in ipairs({"Fading Shapes","Fading Hexagons","Fading Blocks Spinner [NEW]","Fading Blocks","Fading Balls"}) do
            if workspace:FindFirstChild(n) then
                for _, d in ipairs(workspace[n]:GetDescendants()) do
                    if d:IsA("TouchTransmitter") then
                        firetouchinterest(d.Parent, game.Players.LocalPlayer.Character.HumanoidRootPart, true)
                        firetouchinterest(d.Parent, game.Players.LocalPlayer.Character.HumanoidRootPart, false)
                    end
                end
                break
            end
        end
    end
})

game:GetService("UserInputService").JumpRequest:Connect(function()
    if infiniteJumpEnabled and game.Players.LocalPlayer.Character then
        local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
    if playtimeToggle then
        game:GetService("ReplicatedStorage"):WaitForChild("GivePlaytimeReward"):FireServer(8)
    end
end)

local PetBox = GeneralTab:AddLeftTabbox("Pets")
local PetTab = PetBox:AddTab("Pets")

local selectedPet = nil
local petDropdownOptions = {}
local petModelNames = {}

local PetData = require(game:GetService("ReplicatedStorage"):WaitForChild("PetData"))
for modelName, petInfo in pairs(PetData) do
    local displayName = petInfo.Name .. " - " .. petInfo.Rarity
    table.insert(petDropdownOptions, displayName)
    petModelNames[displayName] = modelName
end

table.sort(petDropdownOptions)

if #petDropdownOptions > 0 then
    selectedPet = petModelNames[petDropdownOptions[1]]
end

PetTab:AddDropdown("PetDropdown", {
    Values = petDropdownOptions,
    Default = 1,
    Multi = false,
    Text = "Select Pet",
    Callback = function(value)
        selectedPet = petModelNames[value]
    end
})

PetTab:AddButton({
    Text = "Give Pet",
    Func = function()
        if selectedPet then
            local args = {selectedPet}
            game:GetService("ReplicatedStorage"):WaitForChild("AddPetToOwned"):FireServer(unpack(args))
        end
    end
})

local TrailBox = GeneralTab:AddRightTabbox("Trails")
local TrailTab = TrailBox:AddTab("Trails")

local selectedTrail = nil
local trailDropdownOptions = {}

local TrailsFolder = game:GetService("ReplicatedStorage"):WaitForChild("Trails")
for _, trail in ipairs(TrailsFolder:GetChildren()) do
    table.insert(trailDropdownOptions, trail.Name)
end

table.sort(trailDropdownOptions)

if #trailDropdownOptions > 0 then
    selectedTrail = trailDropdownOptions[1]
end

TrailTab:AddDropdown("TrailDropdown", {
    Values = trailDropdownOptions,
    Default = 1,
    Multi = false,
    Text = "Select Trail",
    Callback = function(value)
        selectedTrail = value
    end
})

TrailTab:AddButton({
    Text = "Give Trail",
    Func = function()
        if selectedTrail then
            local args = {true, selectedTrail}
            game:GetService("ReplicatedStorage"):WaitForChild("TrailSelectedRE"):FireServer(unpack(args))
        end
    end
})

local CreditsBox = GeneralTab:AddRightTabbox("Credits") do
    local Main = CreditsBox:AddTab("Credits")
    Main:AddButton({Text = 'Subscribe to MeatBoxing', Func = function() setclipboard('https://www.youtube.com/@meatboxing'); Library:Notify('Copied Link') end, Tooltip = 'For creating this script'})
end

game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.End then
        Library:Toggle()
    end
end)
