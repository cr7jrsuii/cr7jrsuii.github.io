local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Root = Character:WaitForChild("HumanoidRootPart")
local ENABLED = false

local Window = Library:CreateWindow({
    Title = 'NYC CHAOS Script',
    Center = true,
    AutoShow = true,
})

local Tabs = {
    General = Window:AddTab('General'),
}

local MainTabbox = Tabs.General:AddLeftTabbox()
local MainTab = MainTabbox:AddTab('Main')

MainTab:AddToggle('AutoCombat', {
    Text = 'Enabled',
    Default = false,
    Tooltip = 'Automatically punch nearby players',
    Callback = function(Value)
        ENABLED = Value
    end
}):AddKeyPicker('AutoCombat_KeyPicker', {Default = 'K', SyncToggleState = true, Mode = 'Toggle', Text = 'Enabled', NoUI = false})

MainTab:AddSlider('CombatRange', {
    Text = 'Combat Range',
    Default = 20,
    Min = 5,
    Max = 50,
    Rounding = 0,
    Compact = false,
})

local CreditsBox = Tabs.General:AddRightTabbox("Credits")
local CreditsTab = CreditsBox:AddTab("Credits")
CreditsTab:AddButton({Text = 'Subscrube to MeatBoxing', Func = function() setclipboard('https://www.youtube.com/@meatboxing'); Library:Notify('Copied Link') end, Tooltip = 'For creating this script'})

local function getNearbyPlayers()
    local nearby = {}
    local range = Options.CombatRange.Value
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local proot = player.Character:FindFirstChild("HumanoidRootPart")
            if proot and Root then
                local distance = (Root.Position - proot.Position).Magnitude
                if distance <= range then
                    table.insert(nearby, player)
                end
            end
        end
    end
    return nearby
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end  
    if input.KeyCode == Enum.KeyCode.End then
        Library:Toggle()
    end
end)

RunService.Heartbeat:Connect(function()
    if ENABLED then
        if not Character or not Character.Parent then
            Character = LocalPlayer.Character
            if Character then
                Root = Character:WaitForChild("HumanoidRootPart")
            end
        end
        
        if Root then
            local nearbyPlayers = getNearbyPlayers()
            for _, player in ipairs(nearbyPlayers) do
                local targetChar = player.Character
                if targetChar then
                    local humanoid = targetChar:FindFirstChild("Humanoid")
                    if humanoid then
                        local args = {
                            humanoid,
                            "Punch",
                            false
                        }
                        ReplicatedStorage:FindFirstChild("Remote").Events.CombatUsed:FireServer(unpack(args))
                    end
                end
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Root = newChar:WaitForChild("HumanoidRootPart")
end)
