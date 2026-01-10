-- main.lua - Script utama yang benar
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Tunggu game load
repeat task.wait() until game:IsLoaded()
print("========================================")
print("FishIt Complete Monitor v2.0")
print("Loading modules...")
print("========================================")

-- Load monitor module
local FishingMonitor = nil
local success1, err1 = pcall(function()
    local monitorCode = game:HttpGet("https://raw.githubusercontent.com/ruditech1337-arch/mmfit/refs/heads/main/monitor.lua")
    FishingMonitor = loadstring(monitorCode)()
    print("✅ FishingMonitor loaded successfully")
end)

if not success1 then
    warn("❌ Failed to load FishingMonitor:", err1)
    return
end

-- Load GUI module
local FishingGUI = nil
local success2, err2 = pcall(function()
    local guiCode = game:HttpGet("https://raw.githubusercontent.com/ruditech1337-arch/mmfit/refs/heads/main/gui.lua")
    -- HAPUS bagian yang memuat ulang gui.lua dari dalam gui.lua itu sendiri
    -- Ganti dengan modul GUI yang benar
    FishingGUI = loadstring(guiCode)()
    print("✅ FishingGUI loaded successfully")
end)

if not success2 then
    warn("❌ Failed to load FishingGUI:", err2)
    FishingGUI = nil
end

-- ============================================
-- CONFIGURASI
-- ============================================
print("\n[Config] Setting up configuration...")

-- Ganti dengan webhook Discord kamu
local FISH_WEBHOOK = "https://discord.com/api/webhooks/1441282008360816672/CmvOOKuQnX3a90emvGSrvrhWml52_LbujYKTmQs1hnf2zLmKs2EpkUnljs6q13K_bEr5"
local MONITOR_WEBHOOK = "https://discord.com/api/webhooks/1441282008360816672/CmvOOKuQnX3a90emvGSrvrhWml52_LbujYKTmQs1hnf2zLmKs2EpkUnljs6q13K_bEr5"

-- Konfigurasi FishingMonitor
if FishingMonitor then
    FishingMonitor:SetFishWebhookURL(FISH_WEBHOOK)
    FishingMonitor:SetMonitorWebhookURL(MONITOR_WEBHOOK)
    FishingMonitor:SetDiscordUserID("") -- Isi dengan Discord ID kamu
    FishingMonitor:SetUpdateInterval(30) -- Update setiap 30 detik
    FishingMonitor:SetDebugMode(true)
    print("✅ FishingMonitor configured")
end

-- ============================================
-- INISIALISASI GUI
-- ============================================
if FishingGUI then
    print("\n[GUI] Initializing GUI...")
    
    -- Coba init GUI
    local guiSuccess, guiErr = pcall(function()
        return FishingGUI:Init()
    end)
    
    if guiSuccess then
        print("✅ GUI initialized successfully!")
        
        -- Show welcome message
        FishingGUI:ShowStatusMessage("🎣 FishIt Monitor Active!")
        
        -- Test notifications setelah beberapa detik
        task.spawn(function()
            task.wait(3)
            print("[GUI] Running test notifications...")
            FishingGUI:Test()
        end)
        
        -- Bind ke monitor jika ada
        if FishingMonitor then
            task.spawn(function()
                task.wait(2)
                FishingGUI:BindToMonitor(FishingMonitor)
                print("✅ GUI bound to Monitor")
            end)
        end
    else
        warn("❌ GUI initialization failed:", guiErr)
    end
end

-- ============================================
-- START MONITORING
-- ============================================
if FishingMonitor then
    print("\n[Monitor] Starting monitoring system...")
    
    task.spawn(function()
        task.wait(2) -- Tunggu GUI selesai init
        
        local monitorSuccess, monitorErr = pcall(function()
            return FishingMonitor:Start()
        end)
        
        if monitorSuccess then
            print("✅ Monitoring system started successfully!")
            
            -- Update GUI dengan data awal
            if FishingGUI then
                task.wait(5)
                
                -- Coba dapatkan data server
                local dataSuccess, serverData = pcall(function()
                    return FishingMonitor:GetServerData()
                end)
                
                if dataSuccess and serverData then
                    FishingGUI:ShowServerStats({
                        players = serverData.OnlinePlayers or #Players:GetPlayers(),
                        casts = serverData.TotalCasts or 0,
                        fish = serverData.TotalFish or 0,
                        secrets = serverData.TotalSecrets or 0,
                        mutations = serverData.TotalMutations or 0
                    })
                    print("✅ Server stats updated in GUI")
                end
            end
        else
            warn("❌ Failed to start monitor:", monitorErr)
        end
    end)
end

-- ============================================
-- KEYBINDS & CONTROLS
-- ============================================
local UserInputService = game:GetService("UserInputService")
local guiEnabled = true

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Toggle GUI dengan Right Control
    if input.KeyCode == Enum.KeyCode.RightControl then
        if FishingGUI then
            guiEnabled = not guiEnabled
            FishingGUI:Toggle(guiEnabled)
            print("GUI toggled:", guiEnabled and "ON" or "OFF")
        end
    end
    
    -- Test notifications dengan P
    if input.KeyCode == Enum.KeyCode.P then
        if FishingGUI then
            print("Manual test triggered")
            FishingGUI:Test()
        end
    end
end)

print("\n========================================")
print("SETUP COMPLETE!")
print("Controls:")
print("- Right Ctrl: Toggle GUI")
print("- P: Test notifications")
print("========================================")

-- Debug: Cek apakah GUI terlihat
task.spawn(function()
    task.wait(5)
    
    if FishingGUI then
        print("\n[Debug] Checking GUI status...")
        
        -- Cek apakah ScreenGui ada
        local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local screenGui = playerGui:FindFirstChild("FishingMonitorGUI")
            if screenGui then
                print("✅ ScreenGui found in PlayerGui")
                print("   ScreenGui.Enabled:", screenGui.Enabled)
                print("   Children count:", #screenGui:GetChildren())
            else
                warn("❌ ScreenGui not found in PlayerGui")
                
                -- Buat test frame
                local testGui = Instance.new("ScreenGui")
                testGui.Name = "TestGUI"
                testGui.Parent = playerGui
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0, 200, 0, 100)
                frame.Position = UDim2.new(0.5, -100, 0.5, -50)
                frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                frame.Parent = testGui
                
                local text = Instance.new("TextLabel")
                text.Size = UDim2.new(1, 0, 1, 0)
                text.Text = "TEST GUI - CAN YOU SEE THIS?"
                text.TextColor3 = Color3.new(1, 1, 1)
                text.BackgroundTransparency = 1
                text.Parent = frame
                
                print("✅ Test GUI created - Check if green box appears")
            end
        end
    end
end)

-- Keep script alive
while true do
    task.wait(1)
end
