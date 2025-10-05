local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Window = Library:CreateWindow({Title = "Don't leave the circle Script", Center = true, AutoShow = true})
local GeneralTab = Window:AddTab("General")
local ActionBox = GeneralTab:AddLeftTabbox("Main")
local MainTab = ActionBox:AddTab("Main")

local autoCollectCoins = false
MainTab:AddToggle("AutoCollectCoins", {Text = "Auto Collect Coins", Default = false, Callback = function(value)
    autoCollectCoins = value
end})

task.spawn(function()
    local h = game.Players.LocalPlayer.Character.HumanoidRootPart
    while true do
        if autoCollectCoins then
            for _, v in workspace.Coins:GetChildren() do
                if v.Name == "Coin" then
                    firetouchinterest(v, h, true)
                    firetouchinterest(v, h, false)
                end
            end
        end
        task.wait()
    end
end)

local CreditsBox = GeneralTab:AddRightTabbox("Credits") do
    local Main = CreditsBox:AddTab("Credits")
    Main:AddButton({Text = 'Subscrube to MeatBoxing', Func = function() setclipboard('https://www.youtube.com/@meatboxing'); Library:Notify('Copied Link') end, Tooltip = 'For creating this script'})
end

game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.End then
        Library:Toggle()
    end
end)
