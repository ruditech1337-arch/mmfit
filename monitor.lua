-- Lynxx Fishing GUI.lua
-- GUI yang benar-benar muncul dan bekerja

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Pastikan PlayerGui ada
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
print("[GUI] PlayerGui found:", playerGui)

-- ============================================
-- GUI MODULE
-- ============================================
local FishingGUI = {}

FishingGUI.Config = {
    Enabled = true,
    Position = UDim2.new(0.5, -200, 0.05, 0), -- Center atas
    NotificationDuration = 8, -- Detik
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
    AccentAFK = Color3.fromRGB(255, 165, 0), -- Orange
    AccentDisconnect = Color3.fromRGB(255, 80, 80), -- Red
    AccentInfo = Color3.fromRGB(100, 150, 255), -- Blue
    AccentSuccess = Color3.fromRGB(0, 200, 100), -- Green
    Online = Color3.fromRGB(0, 200, 100),
    Offline = Color3.fromRGB(200, 60, 60)
}

-- GUI Elements
local screenGui = nil
local mainContainer = nil
local isDragging = false
local dragStartPos = nil
local guiStartPos = nil

-- Debug function
local function debugPrint(msg)
    print("[GUI Debug] " .. msg)
end

-- Create element dengan error handling
local function createElement(className, properties)
    local success, element = pcall(function()
        local elem = Instance.new(className)
        
        for prop, value in pairs(properties) do
            if prop == "Parent" then
                elem.Parent = value
            else
                if pcall(function() return elem[prop] end) then
                    elem[prop] = value
                else
                    warn("[GUI] Property tidak valid:", prop, "untuk", className)
                end
            end
        end
        
        return elem
    end)
    
    if success then
        return element
    else
        warn("[GUI] Gagal membuat element:", className, element)
        return nil
    end
end

-- Initialize GUI
function FishingGUI:Init()
    debugPrint("Initializing GUI...")
    
    -- Hapus GUI lama jika ada
    if screenGui then
        screenGui:Destroy()
        screenGui = nil
    end
    
    -- Buat ScreenGui baru
    screenGui = createElement("ScreenGui", {
        Name = "FishingMonitorGUI",
        DisplayOrder = 999, -- Paling atas
        Enabled = true,
        Parent = playerGui
    })
    
    if not screenGui then
        warn("[GUI] Gagal membuat ScreenGui!")
        return false
    end
    
    debugPrint("ScreenGui created successfully")
    
    -- Main container untuk semua notifications
    mainContainer = createElement("Frame", {
        Name = "MainContainer",
        Size = UDim2.new(0, 420, 0, 500),
        Position = FishingGUI.Config.Position,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = screenGui
    })
    
    -- Drag handler
    if FishingGUI.Config.DragEnabled then
        local dragFrame = createElement("Frame", {
            Name = "DragFrame",
            Size = UDim2.new(1, 0, 0, 30),
            Position = UDim2.new(0, 0, 0, -30),
            BackgroundTransparency = 1,
            Active = true,
            Parent = mainContainer
        })
        
        dragFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = true
                dragStartPos = input.Position
                guiStartPos = mainContainer.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        isDragging = false
                    end
                end)
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStartPos
                mainContainer.Position = UDim2.new(
                    guiStartPos.X.Scale,
                    guiStartPos.X.Offset + delta.X,
                    guiStartPos.Y.Scale,
                    guiStartPos.Y.Offset + delta.Y
                )
            end
        end)
    end
    
    -- Tampilkan status GUI
    self:ShowStatusMessage("Fishing Monitor GUI Loaded!")
    
    debugPrint("GUI initialized successfully")
    return true
end

-- Show status message
function FishingGUI:ShowStatusMessage(message)
    if not screenGui then return end
    
    task.spawn(function()
        local frame = createElement("Frame", {
            Name = "StatusMessage",
            Size = UDim2.new(0, 300, 0, 60),
            Position = UDim2.new(0.5, -150, 0.3, 0),
            BackgroundColor3 = COLORS.Background,
            BorderColor3 = COLORS.Border,
            BorderSizePixel = 2,
            Parent = screenGui
        })
        
        createElement("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = frame
        })
        
        createElement("TextLabel", {
            Name = "Message",
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            Text = "🎣 " .. message,
            TextColor3 = COLORS.TextPrimary,
            TextSize = 16,
            Font = Enum.Font.GothamSemibold,
            TextWrapped = true,
            Parent = frame
        })
        
        -- Animate
        frame.Visible = true
        
        task.wait(3)
        
        -- Fade out
        local tween = TweenService:Create(frame, TweenInfo.new(0.5), {
            BackgroundTransparency = 1,
            Position = frame.Position + UDim2.new(0, 0, 0, -50)
        })
        
        tween:Play()
        tween.Completed:Wait()
        frame:Destroy()
    end)
end

-- Show AFK notification (seperti di gambar)
function FishingGUI:ShowAFKNotification(playerData)
    if not FishingGUI.Config.ShowAFK or not screenGui then return end
    
    debugPrint("Showing AFK notification for: " .. (playerData.Name or "Unknown"))
    
    local notification = self:CreateBaseNotification("AFK", COLORS.AccentAFK)
    if not notification then return end
    
    -- Content
    self:AddNotificationContent(notification, {
        Title = "USER AFK",
        Subtitle = "No catch in last 5 minutes",
        User = playerData.Name or "Unknown Player",
        DisplayName = playerData.DisplayName or playerData.Name,
        Location = playerData.Location or "Unknown",
        Caught = playerData.Caught or 0,
        LastTime = playerData.LastTime or "Just now"
    })
    
    self:ShowNotification(notification)
end

-- Show Disconnect notification
function FishingGUI:ShowDisconnectNotification(playerData)
    if not FishingGUI.Config.ShowDisconnect or not screenGui then return end
    
    debugPrint("Showing Disconnect notification for: " .. (playerData.Name or "Unknown"))
    
    local notification = self:CreateBaseNotification("DISCONNECT", COLORS.AccentDisconnect)
    if not notification then return end
    
    -- Content
    self:AddNotificationContent(notification, {
        Title = "USER DISCONNECT",
        Subtitle = "Player left the game",
        User = playerData.Name or "Unknown Player",
        DisplayName = playerData.DisplayName or playerData.Name,
        Location = playerData.Location or "Unknown",
        Caught = playerData.Caught or 0,
        LastTime = playerData.LastTime or "Just now"
    })
    
    self:ShowNotification(notification)
end

-- Show Fish Caught notification
function FishingGUI:ShowFishCaughtNotification(fishData)
    if not FishingGUI.Config.ShowFish or not screenGui then return end
    
    debugPrint("Showing Fish caught: " .. (fishData.Name or "Unknown"))
    
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
    
    local notification = self:CreateBaseNotification("FISH", color)
    if not notification then return end
    
    -- Content khusus fish
    local contentFrame = createElement("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -20, 1, -80),
        Position = UDim2.new(0, 10, 0, 70),
        BackgroundTransparency = 1,
        Parent = notification
    })
    
    -- Fish icon
    createElement("ImageLabel", {
        Name = "FishIcon",
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://7072720899", -- Fishing icon
        Parent = contentFrame
    })
    
    -- Fish info
    createElement("TextLabel", {
        Name = "FishName",
        Size = UDim2.new(1, -60, 0, 30),
        Position = UDim2.new(0, 60, 0, 0),
        BackgroundTransparency = 1,
        Text = fishData.Name or "Fish Caught!",
        TextColor3 = color,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = contentFrame
    })
    
    createElement("TextLabel", {
        Name = "FishDetails",
        Size = UDim2.new(1, -60, 0, 40),
        Position = UDim2.new(0, 60, 0, 30),
        BackgroundTransparency = 1,
        Text = string.format("Tier: %s\nWeight: %.2f kg", 
            fishData.Tier or "Unknown", 
            fishData.Weight or 0),
        TextColor3 = COLORS.TextSecondary,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = contentFrame
    })
    
    -- Mutation badge jika ada
    if fishData.Mutation and fishData.Mutation ~= "None" then
        local mutationBadge = createElement("Frame", {
            Name = "MutationBadge",
            Size = UDim2.new(0, 100, 0, 25),
            Position = UDim2.new(0, 0, 1, -25),
            BackgroundColor3 = Color3.fromRGB(100, 50, 200),
            BorderSizePixel = 0,
            Parent = contentFrame
        })
        
        createElement("UICorner", {
            CornerRadius = UDim.new(0, 12),
            Parent = mutationBadge
        })
        
        createElement("TextLabel", {
            Name = "MutationText",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "✨ " .. fishData.Mutation,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 12,
            Font = Enum.Font.GothamSemibold,
            Parent = mutationBadge
        })
    end
    
    self:ShowNotification(notification)
end

-- Show Server Stats
function FishingGUI:ShowServerStats(stats)
    if not FishingGUI.Config.ShowServerStats or not screenGui then return end
    
    -- Update atau buat stats panel
    local statsPanel = screenGui:FindFirstChild("ServerStatsPanel")
    
    if not statsPanel then
        statsPanel = self:CreateStatsPanel()
    end
    
    -- Update data
    self:UpdateStatsPanel(statsPanel, stats)
end

-- Create base notification
function FishingGUI:CreateBaseNotification(type, accentColor)
    if not screenGui or not mainContainer then return nil end
    
    local notification = createElement("Frame", {
        Name = "Notification_" .. type .. "_" .. tick(),
        Size = UDim2.new(0, 400, 0, 200),
        Position = UDim2.new(0, 0, 1, 0), -- Mulai dari bawah
        BackgroundColor3 = COLORS.Background,
        BorderColor3 = COLORS.Border,
        BorderSizePixel = 2,
        ClipsDescendants = true,
        Parent = mainContainer
    })
    
    if not notification then return nil end
    
    createElement("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = notification
    })
    
    -- Title bar
    local titleBar = createElement("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Parent = notification
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(0, 12, 0, 0),
        Parent = titleBar
    })
    
    -- Close button
    local closeBtn = createElement("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 5),
        BackgroundColor3 = Color3.fromRGB(40, 40, 45),
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = COLORS.TextSecondary,
        TextSize = 24,
        Font = Enum.Font.GothamBold,
        Parent = titleBar
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(0, 15),
        Parent = closeBtn
    })
    
    closeBtn.MouseButton1Click:Connect(function()
        self:HideNotification(notification)
    end)
    
    return notification
end

-- Add content to notification
function FishingGUI:AddNotificationContent(notification, data)
    -- Title
    createElement("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -50, 0, 40),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = data.Title,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification.TitleBar
    })
    
    -- Subtitle
    createElement("TextLabel", {
        Name = "Subtitle",
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundTransparency = 1,
        Text = data.Subtitle,
        TextColor3 = COLORS.TextSecondary,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    -- Separator
    createElement("Frame", {
        Name = "Separator",
        Size = UDim2.new(1, -20, 0, 1),
        Position = UDim2.new(0, 10, 0, 75),
        BackgroundColor3 = COLORS.Border,
        BorderSizePixel = 0,
        Parent = notification
    })
    
    -- User info
    createElement("TextLabel", {
        Name = "UserLabel",
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 85),
        BackgroundTransparency = 1,
        Text = "Roblox User:",
        TextColor3 = COLORS.AccentInfo,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    createElement("TextLabel", {
        Name = "Username",
        Size = UDim2.new(1, -20, 0, 25),
        Position = UDim2.new(0, 10, 0, 105),
        BackgroundTransparency = 1,
        Text = "  " .. (data.DisplayName or data.User),
        TextColor3 = COLORS.TextPrimary,
        TextSize = 16,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    -- Location
    createElement("TextLabel", {
        Name = "Location",
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 135),
        BackgroundTransparency = 1,
        Text = "Current Location: " .. data.Location,
        TextColor3 = COLORS.TextPrimary,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notification
    })
    
    -- Stats row
    local statsRow = createElement("Frame", {
        Name = "StatsRow",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 160),
        BackgroundTransparency = 1,
        Parent = notification
    })
    
    -- Caught count
    local caughtFrame = createElement("Frame", {
        Name = "CaughtStat",
        Size = UDim2.new(0.4, 0, 1, 0),
        BackgroundColor3 = COLORS.BackgroundLight,
        BorderColor3 = COLORS.Border,
        BorderSizePixel = 1,
        Parent = statsRow
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = caughtFrame
    })
    
    createElement("TextLabel", {
        Name = "CaughtLabel",
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = "CAUGHT",
        TextColor3 = COLORS.TextSecondary,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = caughtFrame
    })
    
    createElement("TextLabel", {
        Name = "CaughtValue",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = tostring(data.Caught),
        TextColor3 = COLORS.AccentInfo,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = caughtFrame
    })
    
    -- Time info
    local timeFrame = createElement("Frame", {
        Name = "TimeStat",
        Size = UDim2.new(0.55, 0, 1, 0),
        Position = UDim2.new(0.45, 0, 0, 0),
        BackgroundColor3 = COLORS.BackgroundLight,
        BorderColor3 = COLORS.Border,
        BorderSizePixel = 1,
        Parent = statsRow
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = timeFrame
    })
    
    createElement("TextLabel", {
        Name = "TimeLabel",
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = "LAST FISHING",
        TextColor3 = COLORS.TextSecondary,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = timeFrame
    })
    
    createElement("TextLabel", {
        Name = "TimeValue",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = data.LastTime,
        TextColor3 = COLORS.AccentInfo,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = timeFrame
    })
end

-- Show notification dengan animasi
function FishingGUI:ShowNotification(notification)
    if not notification then return end
    
    -- Hitung posisi baru (stacking)
    local notificationCount = 0
    for _, child in ipairs(mainContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("Notification_") then
            notificationCount = notificationCount + 1
        end
    end
    
    local yOffset = (notificationCount - 1) * 210 -- Spacing antar notifications
    notification.Position = UDim2.new(0, 0, 1, yOffset)
    
    -- Animate slide up
    local targetY = notificationCount * -210
    local targetPos = UDim2.new(0, 0, 0, targetY)
    
    notification.Visible = true
    
    local slideTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = targetPos
    })
    
    slideTween:Play()
    
    -- Progress bar untuk auto-hide
    if FishingGUI.Config.AutoHide then
        local progressBar = createElement("Frame", {
            Name = "ProgressBar",
            Size = UDim2.new(1, 0, 0, 3),
            Position = UDim2.new(0, 0, 1, -3),
            BackgroundColor3 = notification.TitleBar.BackgroundColor3,
            BorderSizePixel = 0,
            Parent = notification
        })
        
        createElement("UICorner", {
            CornerRadius = UDim.new(0, 0, 0, 12),
            Parent = progressBar
        })
        
        -- Animate progress bar
        local progressTween = TweenService:Create(
            progressBar, 
            TweenInfo.new(FishingGUI.Config.NotificationDuration, Enum.EasingStyle.Linear),
            {Size = UDim2.new(0, 0, 0, 3)}
        )
        
        progressTween:Play()
        
        -- Auto hide setelah durasi
        task.delay(FishingGUI.Config.NotificationDuration, function()
            if notification and notification.Parent then
                self:HideNotification(notification)
            end
        end)
    end
end

-- Hide notification dengan animasi
function FishingGUI:HideNotification(notification)
    if not notification then return end
    
    local slideTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = notification.Position + UDim2.new(0, 0, 0, 50),
        BackgroundTransparency = 1
    })
    
    slideTween:Play()
    slideTween.Completed:Wait()
    
    if notification.Parent then
        notification:Destroy()
    end
end

-- Create stats panel
function FishingGUI:CreateStatsPanel()
    local statsPanel = createElement("Frame", {
        Name = "ServerStatsPanel",
        Size = UDim2.new(0, 250, 0, 180),
        Position = UDim2.new(1, -260, 0.05, 0),
        BackgroundColor3 = COLORS.Background,
        BorderColor3 = COLORS.Border,
        BorderSizePixel = 2,
        Parent = screenGui
    })
    
    createElement("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = statsPanel
    })
    
    -- Title
    createElement("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -10, 0, 30),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        Text = "📊 SERVER STATS",
        TextColor3 = COLORS.TextPrimary,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = statsPanel
    })
    
    -- Stats labels
    local labels = {
        {Name = "Players", Key = "players", Y = 40},
        {Name = "Total Casts", Key = "casts", Y = 70},
        {Name = "Total Fish", Key = "fish", Y = 100},
        {Name = "SECRET Fish", Key = "secrets", Y = 130},
        {Name = "Mutations", Key = "mutations", Y = 160}
    }
    
    for _, labelInfo in ipairs(labels) do
        createElement("TextLabel", {
            Name = labelInfo.Name .. "Label",
            Size = UDim2.new(0.6, 0, 0, 20),
            Position = UDim2.new(0, 10, 0, labelInfo.Y),
            BackgroundTransparency = 1,
            Text = labelInfo.Name .. ":",
            TextColor3 = COLORS.TextSecondary,
            TextSize = 14,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = statsPanel
        })
        
        createElement("TextLabel", {
            Name = labelInfo.Name .. "Value",
            Size = UDim2.new(0.35, 0, 0, 20),
            Position = UDim2.new(0.6, 0, 0, labelInfo.Y),
            BackgroundTransparency = 1,
            Text = "0",
            TextColor3 = COLORS.AccentSuccess,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = statsPanel
        })
    end
    
    return statsPanel
end

-- Update stats panel
function FishingGUI:UpdateStatsPanel(statsPanel, stats)
    if not statsPanel then return end
    
    local values = {
        players = stats.players or "0",
        casts = stats.casts or "0",
        fish = stats.fish or "0",
        secrets = stats.secrets or "0",
        mutations = stats.mutations or "0"
    }
    
    for name, value in pairs(values) do
        local label = statsPanel:FindFirstChild(name:gsub("^%l", string.upper) .. "Value")
        if label then
            label.Text = tostring(value)
        end
    end
end

-- Clear semua notifications
function FishingGUI:ClearAll()
    if not mainContainer then return end
    
    for _, child in ipairs(mainContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("Notification_") then
            child:Destroy()
        end
    end
end

-- Toggle GUI visibility
function FishingGUI:Toggle(visible)
    if screenGui then
        screenGui.Enabled = visible
    end
end

-- Test function untuk demo
function FishingGUI:Test()
    if not screenGui then
        self:Init()
    end
    
    debugPrint("Running GUI test...")
    
    -- Test AFK notification
    task.wait(1)
    self:ShowAFKNotification({
        Name = "TestPlayer123",
        DisplayName = "Test Player",
        Location = "Fisherman Island",
        Caught = 82145,
        LastTime = "January 2, 2026 18:56"
    })
    
    -- Test Disconnect notification
    task.wait(3)
    self:ShowDisconnectNotification({
        Name = "TestAngler456",
        DisplayName = "Test Angler",
        Location = "Deep Ocean",
        Caught = 125000,
        LastTime = "January 2, 2026 19:02"
    })
    
    -- Test Fish caught notification
    task.wait(3)
    self:ShowFishCaughtNotification({
        Name = "Golden Tuna",
        Tier = "Legendary",
        Weight = 45.67,
        Mutation = "Shiny"
    })
    
    -- Test Server stats
    task.wait(2)
    self:ShowServerStats({
        players = 8,
        casts = 1245,
        fish = 892,
        secrets = 23,
        mutations = 45
    })
    
    debugPrint("GUI test completed!")
end

-- Bind dengan FishingMonitor
function FishingGUI:BindToMonitor(monitorModule)
    if not monitorModule then return end
    
    debugPrint("Binding to monitor module...")
    
    -- Listen untuk player data updates
    task.spawn(function()
        while FishingGUI.Config.Enabled do
            if monitorModule.GetServerData then
                local serverData = monitorModule:GetServerData()
                if serverData then
                    self:ShowServerStats({
                        players = serverData.OnlinePlayers or 0,
                        casts = serverData.TotalCasts or 0,
                        fish = serverData.TotalFish or 0,
                        secrets = serverData.TotalSecrets or 0,
                        mutations = serverData.TotalMutations or 0
                    })
                end
            end
            task.wait(5) -- Update setiap 5 detik
        end
    end)
    
    -- Listen untuk fish caught events
    if monitorModule.HookFishingEvents then
        local originalHook = monitorModule.HookFishingEvents
        monitorModule.HookFishingEvents = function(...)
            local result = originalHook(...)
            
            -- Tambahkan hook untuk GUI
            local netFolder = ReplicatedStorage.Packages
                ._Index["sleitnick_net@0.2.0"]
                .net
            
            local RE_ObtainedNewFish = netFolder:WaitForChild("RE/ObtainedNewFishNotification")
            RE_ObtainedNewFish.OnClientEvent:Connect(function(itemId, metadata, extraData, player)
                local targetPlayer = player or LocalPlayer
                
                -- Load fish data
                local Items = require(ReplicatedStorage:WaitForChild("Items"))
                local fish = nil
                
                for _, f in pairs(Items) do
                    if f.Data and f.Data.Id == itemId then
                        fish = f.Data
                        break
                    end
                end
                
                if fish and FishingGUI.Config.ShowFish then
                    local weight = metadata and metadata.Weight or 0
                    local mutation = "None"
                    local isShiny = (metadata and metadata.Shiny) or (extraData and extraData.Shiny)
                    
                    if extraData then
                        mutation = extraData.Variant or extraData.Mutation or "None"
                    end
                    
                    if isShiny then
                        mutation = "Shiny"
                    end
                    
                    self:ShowFishCaughtNotification({
                        Name = fish.Name,
                        Tier = FishingGUI.TIER_NAMES[fish.Tier] or "Unknown",
                        Weight = weight,
                        Mutation = mutation
                    })
                end
            end)
            
            return result
        end
    end
    
    debugPrint("Successfully bound to monitor module")
end

-- Export module
return FishingGUI
