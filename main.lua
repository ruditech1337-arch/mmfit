-- main.lua
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

repeat task.wait() until game:IsLoaded()
print("FishIt Complete Monitor Starting...")

-- Load modules
local FishingMonitor = loadstring(game:HttpGet("https://raw.githubusercontent.com/ruditech1337-arch/mmfit/refs/heads/main/monitor.lua"))()
local FishingGUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ruditech1337-arch/mmfit/refs/heads/main/gui.lua"))()

-- Configuration
FishingMonitor:SetFishWebhookURL("URL_DISCORD_FISH")
FishingMonitor:SetMonitorWebhookURL("URL_DISCORD_MONITOR")
FishingMonitor:SetUpdateInterval(30)
FishingMonitor:SetDebugMode(true)

-- Initialize GUI
if FishingGUI:Init() then
    print("✅ GUI Loaded!")
    FishingGUI:ShowStatusMessage("FishIt Monitor Active!")
    
    -- Test notifications
    task.wait(2)
    FishingGUI:Test()
    
    -- Bind ke monitor
    FishingGUI:BindToMonitor(FishingMonitor)
end

-- Start monitor
if FishingMonitor:Start() then
    print("✅ Monitor Started!")
end

print("Setup Complete! Press P to test notifications.")
