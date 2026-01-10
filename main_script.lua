-- main_script.lua - SCRIPT UTAMA UNTUK DIEXEKUSI
local Players = game:GetService("Players")

-- Tunggu game load
repeat task.wait() until game:IsLoaded()
print("========================================")
print("🎣 FishIt Complete Monitor")
print("Starting...")
print("========================================")

-- Load modules
local FishingMonitor, FishingGUI

-- Load monitor module
local success1, err1 = pcall(function()
    local code = game:HttpGet("https://raw.githubusercontent.com/ruditech1337-arch/mmfit/refs/heads/main/monitor.lua")
    FishingMonitor = loadstring(code)()
    print("✅ FishingMonitor loaded")
end)

if not success1 then
    warn("❌ Failed to load monitor:", err1)
end

-- Load GUI module
local success2, err2 = pcall(function()
    local code = game:HttpGet("https://raw.githubusercontent.com/ruditech1337-arch/mmfit/refs/heads/main/gui_module.lua")
    FishingGUI = loadstring(code)()
    print("✅ FishingGUI loaded")
end)

if not success2 then
    warn("❌ Failed to load GUI:", err2)
    FishingGUI = nil
end

-- ============================================
-- KONFIGURASI
-- ============================================
if FishingMonitor then
    -- GANTI DENGAN WEBHOOK KAMU
    FishingMonitor:SetFishWebhookURL("https://discord.com/api/webhooks/1441282008360816672/CmvOOKuQnX3a90emvGSrvrhWml52_LbujYKTmQs1hnf2zLmKs2EpkUnljs6q13K_bEr5")
    FishingMonitor:SetMonitorWebhookURL("https://discord.com/api/webhooks/1441282008360816672/CmvOOKuQnX3a90emvGSrvrhWml52_LbujYKTmQs1hnf2zLmKs2EpkUnljs6q13K_bEr5")
    FishingMonitor:SetUpdateInterval(30)
    FishingMonitor:SetDebugMode(true)
    print("✅ Monitor configured")
end

-- ============================================
-- INISIALISASI GUI
-- ============================================
if FishingGUI then
    local guiSuccess = FishingGUI:Init()
    if guiSuccess then
        print("✅ GUI initialized")
        
        -- Welcome message
        FishingGUI:ShowStatusMessage("FishIt Monitor Active!")
        
        -- Test setelah 3 detik
        task.delay(3, function()
            FishingGUI:Test()
        end)
        
        -- Bind ke monitor
        if FishingMonitor then
            FishingGUI:BindToMonitor(FishingMonitor)
        end
    else
        warn("❌ GUI init failed")
    end
end

-- ============================================
-- START MONITOR
-- ============================================
if FishingMonitor then
    task.delay(2, function()
        local monitorSuccess = FishingMonitor:Start()
        if monitorSuccess then
            print("✅ Monitor started")
            
            -- Update GUI stats setelah 5 detik
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
                    end
                end)
            end
        else
            warn("❌ Monitor start failed")
        end
    end)
end

-- ============================================
-- CONTROLS
-- ============================================
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.P then
        if FishingGUI then
            print("Manual test triggered")
            FishingGUI:Test()
        end
    end
    
    if input.KeyCode == Enum.KeyCode.RightControl then
        if FishingGUI then
            local currentState = true
            FishingGUI:Toggle(not currentState)
            print("GUI toggled")
        end
    end
end)

print("\n========================================")
print("✅ SETUP COMPLETE!")
print("Controls:")
print("- P: Test notifications")
print("- Right Ctrl: Toggle GUI")
print("========================================")

-- Keep alive
while true do
    task.wait(10)
    print("🎣 Monitor still running...")
end
