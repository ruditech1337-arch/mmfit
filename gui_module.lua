-- gui_module.lua - MODUL GUI MURNI (tanpa script utama)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local FishingGUI = {}

-- ============================================
-- KONFIGURASI
-- ============================================
FishingGUI.Config = {
    Enabled = true,
    Position = UDim2.new(0.5, -200, 0.05, 0),
    NotificationDuration = 8,
    ShowAFK = true,
    ShowDisconnect = true,
    ShowFish = true,
    ShowServerStats = true,
    AutoHide = true,
    DragEnabled = true
}

-- Warna theme
local COLORS = {
    Background = Color3.fromRGB(30, 30, 35),
    BackgroundLight = Color3.fromRGB(40, 40, 45),
    Border = Color3.fromRGB(70, 70, 80),
    TextPrimary = Color3.fromRGB(240, 240, 245),
    TextSecondary = Color3.fromRGB(180, 180, 190),
    AccentAFK = Color3.fromRGB(255, 165, 0),
    AccentDisconnect = Color3.fromRGB(255, 80, 80),
    AccentInfo = Color3.fromRGB(100, 150, 255),
    AccentSuccess = Color3.fromRGB(0, 200, 100),
    Online = Color3.fromRGB(0, 200, 100),
    Offline = Color3.fromRGB(200, 60, 60)
}

-- GUI Elements
local screenGui = nil
local mainContainer = nil

-- ============================================
-- FUNGSI UTAMA MODULE
-- ============================================
function FishingGUI:Init()
    print("[GUI Module] Initializing...")
    
    -- Hapus GUI lama
    if screenGui then
        screenGui:Destroy()
    end
    
    -- Buat ScreenGui baru
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FishingMonitorGUI"
    screenGui.DisplayOrder = 999
    screenGui.Parent = playerGui
    
    -- Main container
    mainContainer = Instance.new("Frame")
    mainContainer.Name = "MainContainer"
    mainContainer.Size = UDim2.new(0, 420, 0, 500)
    mainContainer.Position = self.Config.Position
    mainContainer.BackgroundTransparency = 1
    mainContainer.BorderSizePixel = 0
    mainContainer.Parent = screenGui
    
    print("[GUI Module] Initialized successfully")
    return true
end

function FishingGUI:ShowStatusMessage(message)
    if not screenGui then return end
    
    local frame = Instance.new("Frame")
    frame.Name = "StatusMessage"
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(0.5, -150, 0.3, 0)
    frame.BackgroundColor3 = COLORS.Background
    frame.BorderColor3 = COLORS.Border
    frame.BorderSizePixel = 2
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local text = Instance.new("TextLabel")
    text.Name = "Message"
    text.Size = UDim2.new(1, -20, 1, -20)
    text.Position = UDim2.new(0, 10, 0, 10)
    text.BackgroundTransparency = 1
    text.Text = "🎣 " .. message
    text.TextColor3 = COLORS.TextPrimary
    text.TextSize = 16
    text.Font = Enum.Font.GothamSemibold
    text.TextWrapped = true
    text.Parent = frame
    
    -- Auto hide setelah 3 detik
    task.delay(3, function()
        if frame and frame.Parent then
            local tween = TweenService:Create(frame, TweenInfo.new(0.5), {
                BackgroundTransparency = 1,
                Position = frame.Position + UDim2.new(0, 0, 0, -50)
            })
            tween:Play()
            tween.Completed:Wait()
            frame:Destroy()
        end
    end)
end

function FishingGUI:ShowAFKNotification(playerData)
    if not screenGui then return end
    print("[GUI] Showing AFK notification:", playerData.Name)
    -- Implementasi notifikasi AFK
    self:ShowSimpleNotification("USER AFK", "No catch in last 5 minutes", COLORS.AccentAFK, playerData)
end

function FishingGUI:ShowDisconnectNotification(playerData)
    if not screenGui then return end
    print("[GUI] Showing Disconnect notification:", playerData.Name)
    self:ShowSimpleNotification("USER DISCONNECT", "Player left the game", COLORS.AccentDisconnect, playerData)
end

function FishingGUI:ShowFishCaughtNotification(fishData)
    if not screenGui then return end
    print("[GUI] Showing Fish caught:", fishData.Name)
    
    local tierColors = {
        Common = COLORS.TextSecondary,
        Uncommon = Color3.fromRGB(0, 180, 255),
        Rare = Color3.fromRGB(150, 0, 255),
        Epic = Color3.fromRGB(255, 100, 0),
        Legendary = Color3.fromRGB(255, 215, 0),
        Mythic = Color3.fromRGB(255, 0, 200),
        SECRET = Color3.fromRGB(255, 50, 50)
    }
    
    local color = tierColors[fishData.Tier] or COLORS.AccentSuccess
    
    self:ShowSimpleNotification("FISH CAUGHT", fishData.Name, color, {
        Name = fishData.Name,
        Location = fishData.Location or "Unknown",
        Caught = fishData.Weight or 0,
        LastTime = "Just now"
    })
end

function FishingGUI:ShowSimpleNotification(title, subtitle, color, data)
    if not screenGui or not mainContainer then return end
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification_" .. title .. "_" .. tick()
    notification.Size = UDim2.new(0, 400, 0, 200)
    notification.Position = UDim2.new(0, 0, 1, 0)
    notification.BackgroundColor3 = COLORS.Background
    notification.BorderColor3 = COLORS.Border
    notification.BorderSizePixel = 2
    notification.ClipsDescendants = true
    notification.Parent = mainContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = notification
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = color
    titleBar.BorderSizePixel = 0
    titleBar.Parent = notification
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12, 0, 0)
    titleCorner.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -50, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = title
    titleText.TextColor3 = Color3.new(1, 1, 1)
    titleText.TextSize = 18
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Subtitle
    local subtitleText = Instance.new("TextLabel")
    subtitleText.Name = "Subtitle"
    subtitleText.Size = UDim2.new(1, -20, 0, 25)
    subtitleText.Position = UDim2.new(0, 10, 0, 45)
    subtitleText.BackgroundTransparency = 1
    subtitleText.Text = subtitle
    subtitleText.TextColor3 = COLORS.TextSecondary
    subtitleText.TextSize = 14
    subtitleText.Font = Enum.Font.Gotham
    subtitleText.TextXAlignment = Enum.TextXAlignment.Left
    subtitleText.Parent = notification
    
    -- Data info
    local infoText = Instance.new("TextLabel")
    infoText.Name = "Info"
    infoText.Size = UDim2.new(1, -20, 0, 100)
    infoText.Position = UDim2.new(0, 10, 0, 75)
    infoText.BackgroundTransparency = 1
    infoText.Text = string.format("User: %s\nLocation: %s\nCaught: %s\nTime: %s",
        data.Name or "Unknown",
        data.Location or "Unknown",
        data.Caught or "0",
        data.LastTime or "Just now")
    infoText.TextColor3 = COLORS.TextPrimary
    infoText.TextSize = 14
    infoText.Font = Enum.Font.Gotham
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.Parent = notification
    
    -- Animate in
    notification.Visible = true
    local slideTween = TweenService:Create(notification, TweenInfo.new(0.3), {
        Position = UDim2.new(0, 0, 0, 0)
    })
    slideTween:Play()
    
    -- Auto hide
    task.delay(self.Config.NotificationDuration, function()
        if notification and notification.Parent then
            local fadeTween = TweenService:Create(notification, TweenInfo.new(0.5), {
                BackgroundTransparency = 1,
                Position = notification.Position + UDim2.new(0, 0, 0, -50)
            })
            fadeTween:Play()
            fadeTween.Completed:Wait()
            notification:Destroy()
        end
    end)
end

function FishingGUI:ShowServerStats(stats)
    if not screenGui then return end
    
    -- Hapus stats panel lama
    local oldPanel = screenGui:FindFirstChild("ServerStatsPanel")
    if oldPanel then oldPanel:Destroy() end
    
    -- Buat panel baru
    local statsPanel = Instance.new("Frame")
    statsPanel.Name = "ServerStatsPanel"
    statsPanel.Size = UDim2.new(0, 250, 0, 180)
    statsPanel.Position = UDim2.new(1, -260, 0.05, 0)
    statsPanel.BackgroundColor3 = COLORS.Background
    statsPanel.BorderColor3 = COLORS.Border
    statsPanel.BorderSizePixel = 2
    statsPanel.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = statsPanel
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -10, 0, 30)
    title.Position = UDim2.new(0, 5, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "📊 SERVER STATS"
    title.TextColor3 = COLORS.TextPrimary
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = statsPanel
    
    -- Stats
    local statLabels = {
        {name = "Players:", value = tostring(stats.players or 0), y = 40},
        {name = "Total Casts:", value = tostring(stats.casts or 0), y = 70},
        {name = "Total Fish:", value = tostring(stats.fish or 0), y = 100},
        {name = "SECRET Fish:", value = tostring(stats.secrets or 0), y = 130},
        {name = "Mutations:", value = tostring(stats.mutations or 0), y = 160}
    }
    
    for _, label in ipairs(statLabels) do
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.6, 0, 0, 20)
        nameLabel.Position = UDim2.new(0, 10, 0, label.y)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = label.name
        nameLabel.TextColor3 = COLORS.TextSecondary
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = statsPanel
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.35, 0, 0, 20)
        valueLabel.Position = UDim2.new(0.6, 0, 0, label.y)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = label.value
        valueLabel.TextColor3 = COLORS.AccentSuccess
        valueLabel.TextSize = 14
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = statsPanel
    end
end

function FishingGUI:Test()
    print("[GUI] Running test...")
    
    -- Test AFK
    self:ShowAFKNotification({
        Name = "TestPlayer123",
        DisplayName = "Test Player",
        Location = "Fisherman Island",
        Caught = 82145,
        LastTime = "January 2, 2026 18:56"
    })
    
    task.wait(2)
    
    -- Test Disconnect
    self:ShowDisconnectNotification({
        Name = "TestAngler456",
        DisplayName = "Test Angler",
        Location = "Deep Ocean",
        Caught = 125000,
        LastTime = "January 2, 2026 19:02"
    })
    
    task.wait(2)
    
    -- Test Fish
    self:ShowFishCaughtNotification({
        Name = "Golden Tuna",
        Tier = "Legendary",
        Weight = 45.67,
        Location = "Fisherman Island"
    })
    
    -- Test Stats
    self:ShowServerStats({
        players = 8,
        casts = 1245,
        fish = 892,
        secrets = 23,
        mutations = 45
    })
    
    print("[GUI] Test completed!")
end

function FishingGUI:BindToMonitor(monitorModule)
    print("[GUI] Binding to monitor module...")
    -- Implementasi binding nanti
end

function FishingGUI:Toggle(enabled)
    if screenGui then
        screenGui.Enabled = enabled
        print("[GUI] Toggled:", enabled and "ON" or "OFF")
    end
end

function FishingGUI:ClearAll()
    if mainContainer then
        for _, child in ipairs(mainContainer:GetChildren()) do
            if child:IsA("Frame") and child.Name:match("Notification_") then
                child:Destroy()
            end
        end
    end
end

-- Return module
return FishingGUI
