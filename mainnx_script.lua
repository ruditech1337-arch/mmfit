-- main_script.lua - SCRIPT UTAMA YANG DIUPDATE
local Players = game:GetService("Players")

-- Tunggu game load
repeat task.wait() until game:IsLoaded()
print("========================================")
print("🎣 FishIt Complete Monitor v2.0")
print("Starting...")
print("========================================")

-- Load modules
local FishingMonitor, FishingGUI

-- Load monitor module
local success1, err1 = pcall(function()
    local code = game:HttpGet("https://raw.githubusercontent.com/ruditech1337-arch/mmfit/refs/heads/main/monitor_complete.lua")
    FishingMonitor = loadstring(code)()
    print("✅ FishingMonitor module loaded")
end)

if not success1 then
    warn("❌ Failed to load monitor module:", err1)
    FishingMonitor = nil
end

-- Load GUI module
local success2, err2 = pcall(function()
    local code = game:HttpGet("https://raw.githubusercontent.com/ruditech1337-arch/mmfit/refs/heads/main/gui_module.lua")
    FishingGUI = loadstring(code)()
    print("✅ FishingGUI module loaded")
end)

if not success2 then
    warn("❌ Failed to load GUI module:", err2)
    FishingGUI = nil
end

-- ============================================
-- KONFIGURASI MONITOR
-- ============================================
if FishingMonitor then
    -- SET YOUR DISCORD WEBHOOKS HERE!
    local FISH_WEBHOOK = "https://discord.com/api/webhooks/1459313509761548510/mA3k8M_gEgfZtnhTpCfODjF-MjN-oDEbmhehw1qxVUBxBgFVKq6aSqSRbI3F20i60G53"
    local MONITOR_WEBHOOK = "https://discord.com/api/webhooks/1441282008360816672/CmvOOKuQnX3a90emvGSrvrhWml52_LbujYKTmQs1hnf2zLmKs2EpkUnljs6q13K_bEr5"
    
    -- Configure monitor
    FishingMonitor:SetFishWebhookURL(FISH_WEBHOOK)
    FishingMonitor:SetMonitorWebhookURL(MONITOR_WEBHOOK)
    FishingMonitor:SetDiscordUserID("") -- Your Discord ID
    FishingMonitor:SetUpdateInterval(30) -- Update every 30 seconds
    FishingMonitor:SetDebugMode(true)
    
    print("✅ Monitor configuration complete")
else
    warn("⚠️ Cannot configure monitor - module not loaded")
end

-- ============================================
-- INISIALISASI GUI
-- ============================================
if FishingGUI then
    print("\n[GUI] Initializing GUI system...")
    
    local guiSuccess, guiErr = pcall(function()
        return FishingGUI:Init()
    end)
    
    if guiSuccess then
        print("✅ GUI system initialized")
        
        -- Show welcome message
        FishingGUI:ShowStatusMessage("🎣 FishIt Monitor Active!")
        
        -- Run test after 3 seconds
        task.delay(3, function()
            print("[GUI] Running test notifications...")
            FishingGUI:Test()
        end)
        
        -- Bind to monitor if available
        if FishingMonitor then
            FishingGUI:BindToMonitor(FishingMonitor)
            print("✅ GUI bound to Monitor")
        end
    else
        warn("❌ GUI initialization failed:", guiErr)
    end
else
    warn("⚠️ GUI module not available")
end

-- ============================================
-- START MONITORING SYSTEM
-- ============================================
if FishingMonitor then
    print("\n[Monitor] Starting monitoring system...")
    
    task.delay(2, function()
        local monitorSuccess, monitorErr = pcall(function()
            return FishingMonitor:Start()
        end)
        
        if monitorSuccess then
            print("✅ Monitoring system started successfully!")
            
            -- Update GUI with initial data
            if FishingGUI then
                task.delay(5, function()
                    local data = FishingMonitor:GetServerData()
                    if data then
                        FishingGUI:ShowServerStats({
                            players = data.OnlinePlayers or #Players:GetPlayers(),
                            casts = data.TotalCasts or 0,
                            fish = data.TotalFish or 0,
                            secrets = data.TotalSecrets or 0,
                            mutations = data.TotalMutations or 0
                        })
                        print("✅ Server stats displayed in GUI")
                    end
                end)
            end
        else
            warn("❌ Failed to start monitor:", monitorErr)
        end
    end)
else
    warn("⚠️ Cannot start monitor - module not loaded")
end

-- ============================================
-- KEYBIND CONTROLS
-- ============================================
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- P key: Test notifications
    if input.KeyCode == Enum.KeyCode.P then
        if FishingGUI then
            print("[Manual] Test triggered")
            FishingGUI:Test()
        end
    end
    
    -- Right Control: Toggle GUI
    if input.KeyCode == Enum.KeyCode.RightControl then
        if FishingGUI then
            FishingGUI:Toggle()
            print("[Manual] GUI toggled")
        end
    end
end)

print("\n========================================")
print("✅ SETUP COMPLETE!")
print("========================================")
print("Controls:")
print("- P: Test notifications")
print("- Right Ctrl: Toggle GUI")
print("========================================")
print("Waiting for fishing activity...")
print("========================================")

-- Keep script alive
while true do
    task.wait(10)
end
