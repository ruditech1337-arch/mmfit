-- Main Script.lua
-- Copy ini ke executor Anda

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Pastikan game sudah load
repeat task.wait() until game:IsLoaded()

print("================================")
print("FishIt Complete Monitor")
print("Starting...")
print("================================")

-- Tunggu beberapa saat untuk memastikan semua services ready
task.wait(2)

-- Load modules (sesuaikan path)
local success, FishingMonitor = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/.../FishingMonitor.lua"))()
    -- ATAU jika Anda simpan di workspace:
    -- return require(game:GetService("ReplicatedStorage"):WaitForChild("FishingMonitor"))
end)

local success2, FishingGUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/.../FishingGUI.lua"))()
    -- ATAU:
    -- return require(game:GetService("ReplicatedStorage"):WaitForChild("FishingGUI"))
end)

if not success then
    warn("Failed to load FishingMonitor!")
    FishingMonitor = nil
end

if not success2 then
    warn("Failed to load FishingGUI!")
    FishingGUI = nil
end

-- Configuration
if FishingMonitor then
    -- SET WEBHOOK URL ANDA DI SINI!
    FishingMonitor:SetFishWebhookURL("") -- Webhook untuk fish caught
    FishingMonitor:SetMonitorWebhookURL("") -- Webhook untuk server monitor
    FishingMonitor:SetDiscordUserID("") -- Discord ID Anda
    FishingMonitor:SetUpdateInterval(30)
    FishingMonitor:SetDebugMode(true)
end

-- Initialize GUI terlebih dahulu
if FishingGUI then
    local guiLoaded = FishingGUI:Init()
    
    if guiLoaded then
        print("✅ GUI successfully loaded!")
        
        -- Show welcome message
        FishingGUI:ShowStatusMessage("FishIt Monitor Active!")
        
        -- Bind GUI ke monitor jika ada
        if FishingMonitor then
            FishingGUI:BindToMonitor(FishingMonitor)
        end
        
        -- Test notifications (opsional)
        task.wait(3)
        FishingGUI:Test()
    else
        warn("❌ Failed to load GUI!")
    end
end

-- Start monitor
if FishingMonitor then
    local monitorStarted = FishingMonitor:Start()
    
    if monitorStarted then
        print("✅ Monitor successfully started!")
        
        -- Update GUI dengan data awal
        if FishingGUI then
            task.wait(5)
            local data = FishingMonitor:GetServerData()
            if data then
                FishingGUI:ShowServerStats({
                    players = data.OnlinePlayers or 0,
                    casts = data.TotalCasts or 0,
                    fish = data.TotalFish or 0,
                    secrets = data.TotalSecrets or 0,
                    mutations = data.TotalMutations or 0
                })
            end
        end
    else
        warn("❌ Failed to start monitor!")
    end
end

-- Keybind untuk toggle GUI
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.RightControl then -- CTRL + P
            if FishingGUI then
                local currentState = FishingGUI.Toggle
                FishingGUI:Toggle(not currentState)
                print("GUI toggled:", not currentState and "ON" or "OFF")
            end
        elseif input.KeyCode == Enum.KeyCode.P then -- P saja untuk test
            if FishingGUI then
                FishingGUI:Test()
                print("Test notifications triggered")
            end
        end
    end
end)

print("================================")
print("Setup Complete!")
print("Controls:")
print("- Right Ctrl: Toggle GUI")
print("- P: Test notifications")
print("================================")

-- Keep script running
while true do
    task.wait(1)
end
