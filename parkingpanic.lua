local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local Window = Library:CreateWindow({Title = "Parking Panic Script", Center = true, AutoShow = true})
local GeneralTab = Window:AddTab("General")
local ActionBox = GeneralTab:AddLeftTabbox("Main")
local MainTab = ActionBox:AddTab("Actions")
MainTab:AddButton("Unlock All Levels", function() for i = 1, 50 do game.ReplicatedStorage.CompleteLevel:FireServer(i) end Library:Notify("Unlocked All Levels") end)
local CreditsBox = GeneralTab:AddRightTabbox("Credits") do
    local Main = CreditsBox:AddTab("Credits")
    Main:AddButton({Text = 'Subscrube to MeatBoxing', Func = function() setclipboard('https://www.youtube.com/@meatboxing'); Library:Notify('Copied Link') end, Tooltip = 'For creating this script'})
end
