-- monitor_complete.lua - TRACK SEMUA PLAYER + AFK/DISCONNECT
local Monitor = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- ============================================
-- KONFIGURASI
-- ============================================
Monitor.Config = {
    FishWebhookURL = "",
    MonitorWebhookURL = "",
    DiscordUserID = "",
    UpdateInterval = 30,
    AFKThreshold = 300, -- 5 menit
    DebugMode = true,
    TrackAllPlayers = true, -- Track semua player di server
    SendAllFish = false, -- Kirim semua ikan (false = hanya secret/epic+)
    TrackLocations = true
}

-- Data storage untuk SEMUA PLAYER
Monitor.ServerData = {
    SessionStart = os.time(),
    Players = {}, -- {UserId: {player data}}
    PlayerStats = {}, -- {UserId: {stats}}
    FishLog = {}, -- Semua ikan yang didapat
    SecretFishLog = {},
    CastLog = {},
    
    -- Statistics
    TotalCasts = 0,
    TotalFish = 0,
    TotalSecrets = 0,
    TotalMutations = 0,
    
    -- AFK Tracking
    AFKPlayers = {},
    LastActivity = {}
}

-- TIER Data
Monitor.TIER_NAMES = {
    [1] = "Common",
    [2] = "Uncommon", 
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Mythic",
    [7] = "SECRET"
}

Monitor.TIER_COLORS = {
    [1] = 9807270,    -- Common: Grey
    [2] = 3066993,    -- Uncommon: Green
    [3] = 3447003,    -- Rare: Blue
    [4] = 10181046,   -- Epic: Purple
    [5] = 15844367,   -- Legendary: Gold
    [6] = 15548997,   -- Mythic: Pink
    [7] = 16711680    -- SECRET: Red
}

-- ============================================
-- HTTP REQUEST FUNCTION
-- ============================================
local function getHTTPRequest()
    local requestFunctions = {
        request,
        http_request,
        (syn and syn.request),
        (fluxus and fluxus.request),
        (http and http.request)
    }
    
    for _, func in ipairs(requestFunctions) do
        if func and type(func) == "function" then
            return func
        end
    end
    
    return nil
end

local httpRequest = getHTTPRequest()

-- ============================================
-- CONFIGURATION METHODS
-- ============================================
function Monitor:SetFishWebhookURL(url)
    self.Config.FishWebhookURL = url
    print("[Monitor] Fish webhook URL set")
end

function Monitor:SetMonitorWebhookURL(url)
    self.Config.MonitorWebhookURL = url
    print("[Monitor] Monitor webhook URL set")
end

function Monitor:SetDiscordUserID(id)
    self.Config.DiscordUserID = id
    print("[Monitor] Discord user ID set")
end

function Monitor:SetUpdateInterval(seconds)
    self.Config.UpdateInterval = seconds
    print("[Monitor] Update interval:", seconds, "seconds")
end

function Monitor:SetAFKThreshold(seconds)
    self.Config.AFKThreshold = seconds
    print("[Monitor] AFK threshold:", seconds, "seconds")
end

function Monitor:SetDebugMode(enabled)
    self.Config.DebugMode = enabled
    print("[Monitor] Debug mode:", enabled)
end

-- ============================================
-- PLAYER MANAGEMENT (SEMUA PLAYER)
-- ============================================
function Monitor:InitializePlayer(player)
    local userId = player.UserId
    
    self.ServerData.Players[userId] = {
        UserId = userId,
        Name = player.Name,
        DisplayName = player.DisplayName or player.Name,
        JoinedAt = os.time(),
        IsOnline = true,
        LastSeen = os.time(),
        
        -- Fishing Stats
        SessionCasts = 0,
        SessionFish = 0,
        SessionSecrets = 0,
        SessionMutations = 0,
        
        TotalCasts = 0,
        TotalFish = 0,
        TotalSecrets = 0,
        TotalMutations = 0,
        
        -- Location
        CurrentLocation = "Unknown",
        LastLocationUpdate = 0,
        
        -- AFK Tracking
        LastActivity = os.time(),
        IsAFK = false,
        AFKSince = nil
    }
    
    self.ServerData.PlayerStats[userId] = {
        LastCastTime = 0,
        LastFishTime = 0,
        LastSecretTime = 0,
        LastMutationTime = 0,
        FishLog = {}
    }
    
    self.ServerData.FishLog[userId] = {}
    self.ServerData.SecretFishLog[userId] = {}
    self.ServerData.CastLog[userId] = {}
    self.ServerData.LastActivity[userId] = os.time()
    
    print("[Monitor] Tracking player:", player.Name)
end

function Monitor:TrackPlayerLeave(player)
    local userId = player.UserId
    
    if self.ServerData.Players[userId] then
        local playerData = self.ServerData.Players[userId]
        playerData.IsOnline = false
        playerData.LeftAt = os.time()
        playerData.LastSeen = os.time()
        
        -- Kirim DISCONNECT notification
        self:SendPlayerDisconnectWebhook(playerData)
        
        if self.Config.DebugMode then
            print("[Monitor] Player left:", player.Name)
        end
    end
end

-- ============================================
-- FISHING TRACKING (SEMUA PLAYER)
-- ============================================
function Monitor:TrackCast(player)
    if not self.Config.TrackAllPlayers then return end
    
    local userId = player.UserId
    local currentTime = os.time()
    
    -- Initialize jika belum ada
    if not self.ServerData.Players[userId] then
        self:InitializePlayer(player)
    end
    
    local playerData = self.ServerData.Players[userId]
    
    -- Update stats
    playerData.SessionCasts = playerData.SessionCasts + 1
    playerData.TotalCasts = playerData.TotalCasts + 1
    playerData.LastSeen = currentTime
    playerData.LastActivity = currentTime
    playerData.IsAFK = false
    playerData.AFKSince = nil
    
    local stats = self.ServerData.PlayerStats[userId]
    stats.LastCastTime = currentTime
    
    -- Update global
    self.ServerData.TotalCasts = self.ServerData.TotalCasts + 1
    self.ServerData.LastActivity[userId] = currentTime
    
    -- Log cast
    table.insert(self.ServerData.CastLog[userId], {
        Time = currentTime,
        TimeFormatted = os.date("%H:%M:%S"),
        Location = playerData.CurrentLocation or "Unknown"
    })
    
    if self.Config.DebugMode then
        print(string.format("[Monitor] %s cast #%d at %s",
            playerData.Name, playerData.SessionCasts, playerData.CurrentLocation))
    end
end

function Monitor:TrackFish(player, fishData, weight, mutation, isShiny)
    if not self.Config.TrackAllPlayers then return end
    
    local userId = player.UserId
    local currentTime = os.time()
    
    -- Initialize jika belum ada
    if not self.ServerData.Players[userId] then
        self:InitializePlayer(player)
    end
    
    local playerData = self.ServerData.Players[userId]
    local stats = self.ServerData.PlayerStats[userId]
    
    local tier = fishData.Tier or 1
    local tierName = self.TIER_NAMES[tier] or "Common"
    local mutationName = mutation or "None"
    
    if isShiny then
        mutationName = "Shiny"
    end
    
    -- Update player stats
    playerData.SessionFish = playerData.SessionFish + 1
    playerData.TotalFish = playerData.TotalFish + 1
    
    if tier == 7 then -- SECRET
        playerData.SessionSecrets = playerData.SessionSecrets + 1
        playerData.TotalSecrets = playerData.TotalSecrets + 1
        stats.LastSecretTime = currentTime
    end
    
    if mutationName ~= "None" then
        playerData.SessionMutations = playerData.SessionMutations + 1
        playerData.TotalMutations = playerData.TotalMutations + 1
        stats.LastMutationTime = currentTime
    end
    
    playerData.LastSeen = currentTime
    playerData.LastActivity = currentTime
    playerData.IsAFK = false
    stats.LastFishTime = currentTime
    
    -- Update global stats
    self.ServerData.TotalFish = self.ServerData.TotalFish + 1
    
    if tier == 7 then
        self.ServerData.TotalSecrets = self.ServerData.TotalSecrets + 1
    end
    
    if mutationName ~= "None" then
        self.ServerData.TotalMutations = self.ServerData.TotalMutations + 1
    end
    
    -- Log fish
    local fishLog = {
        FishName = fishData.Name,
        Tier = tier,
        TierName = tierName,
        Weight = weight or 0,
        Mutation = mutationName,
        IsShiny = isShiny or false,
        Time = currentTime,
        TimeFormatted = os.date("%H:%M:%S"),
        Location = playerData.CurrentLocation or "Unknown",
        PlayerName = playerData.DisplayName
    }
    
    table.insert(self.ServerData.FishLog[userId], fishLog)
    table.insert(stats.FishLog, fishLog)
    
    if tier == 7 then
        table.insert(self.ServerData.SecretFishLog[userId], fishLog)
    end
    
    -- Kirim webhook berdasarkan tier
    if tier >= 4 or mutationName ~= "None" or isShiny then -- Epic+ atau ada mutation/shiny
        self:SendFishWebhook(player, fishLog)
    end
    
    if self.Config.DebugMode then
        print(string.format("[Monitor] %s caught %s (%s) %s at %s",
            playerData.Name, fishData.Name, tierName,
            mutationName ~= "None" and "["..mutationName.."]" or "",
            playerData.CurrentLocation))
    end
end

-- ============================================
-- WEBHOOK FUNCTIONS (SEMUA NOTIFIKASI)
-- ============================================
function Monitor:SendFishWebhook(player, fishLog)
    if not self.Config.FishWebhookURL or self.Config.FishWebhookURL == "" then
        return
    end
    
    if not httpRequest then return end
    
    local playerData = self.ServerData.Players[player.UserId]
    if not playerData then return end
    
    local tier = fishLog.Tier
    local tierName = fishLog.TierName
    local color = self.TIER_COLORS[tier] or 3447003
    
    if fishLog.Mutation == "Shiny" then
        color = 16776960 -- Yellow
    elseif fishLog.Mutation ~= "None" then
        color = 10181046 -- Purple
    end
    
    local title = ""
    local description = ""
    
    if tier == 7 then
        title = "🔥 SECRET FISH CAUGHT!"
        description = string.format("**%s** caught a **SECRET** fish!", playerData.DisplayName)
    elseif fishLog.IsShiny then
        title = "✨ SHINY FISH CAUGHT!"
        description = string.format("**%s** caught a **Shiny** fish!", playerData.DisplayName)
    elseif fishLog.Mutation ~= "None" then
        title = "🌟 MUTATED FISH CAUGHT!"
        description = string.format("**%s** caught a **%s** fish!", playerData.DisplayName, fishLog.Mutation)
    else
        title = string.format("🎣 %s FISH CAUGHT", tierName:upper())
        description = string.format("**%s** caught a **%s** fish!", playerData.DisplayName, tierName)
    end
    
    local embed = {
        embeds = {{
            title = title,
            description = description,
            color = color,
            fields = {
                {
                    name = "Fish Details",
                    value = string.format(
                        "**Name:** %s\n**Tier:** %s\n**Weight:** %.2f kg\n**Location:** %s",
                        fishLog.FishName,
                        tierName,
                        fishLog.Weight,
                        fishLog.Location
                    ),
                    inline = true
                },
                {
                    name = "Player Info",
                    value = string.format(
                        "**User:** %s\n**Total Fish:** %d\n**Total SECRETs:** %d",
                        playerData.DisplayName,
                        playerData.TotalFish,
                        playerData.TotalSecrets
                    ),
                    inline = true
                }
            },
            footer = {
                text = "FishIt Monitor • " .. os.date("%H:%M:%S"),
                icon_url = "https://i.imgur.com/8yZqFqM.png"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    pcall(function()
        httpRequest({
            Url = self.Config.FishWebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(embed)
        })
        if self.Config.DebugMode then
            print("[Monitor] Fish webhook sent for:", playerData.Name)
        end
    end)
end

function Monitor:SendPlayerAFKWebhook(playerData)
    if not self.Config.MonitorWebhookURL or self.Config.MonitorWebhookURL == "" then
        return
    end
    
    local embed = {
        embeds = {{
            title = "⏸️ USER AFK",
            description = "No catch in last 5 minutes",
            color = 16753920, -- Orange
            fields = {
                {
                    name = "Roblox User:",
                    value = string.format("**%s**\n(%s)", 
                        playerData.DisplayName, 
                        playerData.Name),
                    inline = false
                },
                {
                    name = "Current Location:",
                    value = playerData.CurrentLocation or "Unknown",
                    inline = true
                },
                {
                    name = "Current Caught:",
                    value = tostring(playerData.SessionCasts),
                    inline = true
                },
                {
                    name = "Last Fishing Time:",
                    value = os.date("%B %d, %Y %H:%M", playerData.LastActivity),
                    inline = false
                }
            },
            footer = {
                text = "X8 Notification • AFK Detection",
                icon_url = "https://i.imgur.com/shnNZuT.png"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    pcall(function()
        httpRequest({
            Url = self.Config.MonitorWebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(embed)
        })
        print("[Monitor] AFK notification sent for:", playerData.Name)
    end)
end

function Monitor:SendPlayerDisconnectWebhook(playerData)
    if not self.Config.MonitorWebhookURL or self.Config.MonitorWebhookURL == "" then
        return
    end
    
    local embed = {
        embeds = {{
            title = "🚪 USER DISCONNECT",
            description = "Player left the game",
            color = 16711680, -- Red
            fields = {
                {
                    name = "Roblox User:",
                    value = string.format("**%s**\n(%s)", 
                        playerData.DisplayName, 
                        playerData.Name),
                    inline = false
                },
                {
                    name = "Current Location:",
                    value = playerData.CurrentLocation or "Unknown",
                    inline = true
                },
                {
                    name = "Current Caught:",
                    value = tostring(playerData.SessionCasts),
                    inline = true
                },
                {
                    name = "Last Fishing Time:",
                    value = os.date("%B %d, %Y %H:%M"),
                    inline = false
                }
            },
            footer = {
                text = "X8 Notification • Player Left",
                icon_url = "https://i.imgur.com/shnNZuT.png"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    pcall(function()
        httpRequest({
            Url = self.Config.MonitorWebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(embed)
        })
        print("[Monitor] Disconnect notification sent for:", playerData.Name)
    end)
end

function Monitor:SendServerMonitorWebhook()
    if not self.Config.MonitorWebhookURL or self.Config.MonitorWebhookURL == "" then
        return
    end
    
    if not httpRequest then return end
    
    -- Collect data dari SEMUA PLAYER
    local onlinePlayers = {}
    local totalCasts = 0
    local totalFish = 0
    local totalSecrets = 0
    
    for userId, playerData in pairs(self.ServerData.Players) do
        if playerData.IsOnline then
            table.insert(onlinePlayers, {
                Name = playerData.DisplayName,
                Casts = playerData.SessionCasts,
                Fish = playerData.SessionFish,
                Secrets = playerData.SessionSecrets,
                Location = playerData.CurrentLocation,
                IsAFK = playerData.IsAFK
            })
            
            totalCasts = totalCasts + playerData.SessionCasts
            totalFish = totalFish + playerData.SessionFish
            totalSecrets = totalSecrets + playerData.SessionSecrets
        end
    end
    
    local embed = {
        embeds = {{
            title = "📊 REAL-TIME SERVER MONITOR",
            description = string.format(
                "**Online Players:** %d\n**Session Duration:** %s",
                #onlinePlayers,
                self:FormatDuration(os.time() - self.ServerData.SessionStart)
            ),
            color = 3447003,
            fields = {
                {
                    name = "📈 SERVER STATISTICS",
                    value = string.format(
                        "**Total Casts:** %d\n**Total Fish:** %d\n**Total SECRETs:** %d\n**Total Mutations:** %d",
                        totalCasts, totalFish, totalSecrets, self.ServerData.TotalMutations
                    ),
                    inline = true
                },
                {
                    name = "🔥 RECENT SECRET CATCHES",
                    value = self:GetRecentSecretsText() or "No recent SECRETs",
                    inline = true
                }
            },
            footer = {
                text = "FishIt Complete Monitor • Update every " .. self.Config.UpdateInterval .. "s",
                icon_url = "https://i.imgur.com/shnNZuT.png"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    pcall(function()
        httpRequest({
            Url = self.Config.MonitorWebhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(embed)
        })
    end)
end

-- ============================================
-- AFK DETECTION SYSTEM
-- ============================================
function Monitor:CheckAFKPlayers()
    local currentTime = os.time()
    local afkDetected = false
    
    for userId, playerData in pairs(self.ServerData.Players) do
        if playerData.IsOnline then
            local timeSinceActivity = currentTime - playerData.LastActivity
            
            if timeSinceActivity > self.Config.AFKThreshold then
                -- Player is AFK
                if not playerData.IsAFK then
                    playerData.IsAFK = true
                    playerData.AFKSince = playerData.LastActivity
                    
                    -- Kirim AFK notification
                    self:SendPlayerAFKWebhook(playerData)
                    afkDetected = true
                end
            else
                -- Player is active
                if playerData.IsAFK then
                    playerData.IsAFK = false
                    playerData.AFKSince = nil
                end
            end
        end
    end
    
    return afkDetected
end

-- ============================================
-- EVENT HOOKING (SEMUA PLAYER)
-- ============================================
function Monitor:HookFishingEvents()
    print("[Monitor] Hooking fishing events for ALL players...")
    
    -- Load game modules
    local Items, Variants
    local success = pcall(function()
        Items = require(ReplicatedStorage:WaitForChild("Items"))
        Variants = require(ReplicatedStorage:WaitForChild("Variants"))
        print("[Monitor] Game modules loaded")
    end)
    
    if not success then
        warn("[Monitor] Failed to load game modules")
        return
    end
    
    -- Get net folder
    local netFolder = ReplicatedStorage.Packages
        ._Index["sleitnick_net@0.2.0"]
        .net
    
    -- Hook fishing casts (untuk SEMUA player)
    local RE_MinigameChanged = netFolder:WaitForChild("RE/MinigameChanged")
    RE_MinigameChanged.OnClientEvent:Connect(function(state, player)
        if state == "Casting" or state == "Fishing" then
            local targetPlayer = player or LocalPlayer
            self:TrackCast(targetPlayer)
        end
    end)
    
    -- Hook fish caught (untuk SEMUA player)
    local RE_ObtainedNewFish = netFolder:WaitForChild("RE/ObtainedNewFishNotification")
    RE_ObtainedNewFish.OnClientEvent:Connect(function(itemId, metadata, extraData, player)
        local targetPlayer = player or LocalPlayer
        
        -- Find fish data
        local fishData = nil
        for _, fish in pairs(Items) do
            if fish.Data and fish.Data.Id == itemId then
                fishData = fish.Data
                break
            end
        end
        
        if fishData then
            local weight = metadata and metadata.Weight or 0
            local mutation = "None"
            local isShiny = (metadata and metadata.Shiny) or (extraData and extraData.Shiny)
            
            if extraData then
                mutation = extraData.Variant or extraData.Mutation or "None"
            end
            
            if isShiny then
                mutation = "Shiny"
            end
            
            -- Track fish untuk player ini
            self:TrackFish(targetPlayer, fishData, weight, mutation, isShiny)
        end
    end)
    
    print("[Monitor] Fishing events hooked for ALL players")
end

-- ============================================
-- MAIN FUNCTIONS
-- ============================================
function Monitor:Start()
    print("[Monitor] Starting COMPLETE monitoring system...")
    
    -- Initialize SEMUA player yang sudah online
    for _, player in pairs(Players:GetPlayers()) do
        self:InitializePlayer(player)
    end
    
    -- Player join event
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayer(player)
        print("[Monitor] New player joined:", player.Name)
    end)
    
    -- Player leave event
    Players.PlayerRemoving:Connect(function(player)
        self:TrackPlayerLeave(player)
    end)
    
    -- Hook fishing events
    task.spawn(function()
        task.wait(2) -- Tunggu game load
        self:HookFishingEvents()
    end)
    
    -- AFK checking loop
    task.spawn(function()
        while true do
            self:CheckAFKPlayers()
            task.wait(10) -- Check setiap 10 detik
        end
    end)
    
    -- Webhook updates
    task.spawn(function()
        while true do
            self:SendServerMonitorWebhook()
            task.wait(self.Config.UpdateInterval)
        end
    end)
    
    print("[Monitor] COMPLETE monitoring system started!")
    print("[Monitor] Tracking", #Players:GetPlayers(), "players")
    return true
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================
function Monitor:GetRecentSecretsText()
    local recentSecrets = ""
    local count = 0
    
    for userId, logs in pairs(self.ServerData.SecretFishLog) do
        if #logs > 0 then
            local playerData = self.ServerData.Players[userId]
            local latestSecret = logs[#logs]
            
            if latestSecret and count < 3 then
                recentSecrets = recentSecrets .. string.format(
                    "• **%s** - %s (%.2f kg) @ %s\n",
                    playerData.DisplayName,
                    latestSecret.FishName,
                    latestSecret.Weight,
                    os.date("%H:%M", latestSecret.Time)
                )
                count = count + 1
            end
        end
    end
    
    return recentSecrets ~= "" and recentSecrets or nil
end

function Monitor:FormatDuration(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    
    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, secs)
    else
        return string.format("%ds", secs)
    end
end

function Monitor:GetServerData()
    local onlineCount = 0
    for _, playerData in pairs(self.ServerData.Players) do
        if playerData.IsOnline then
            onlineCount = onlineCount + 1
        end
    end
    
    return {
        OnlinePlayers = onlineCount,
        TotalCasts = self.ServerData.TotalCasts,
        TotalFish = self.ServerData.TotalFish,
        TotalSecrets = self.ServerData.TotalSecrets,
        TotalMutations = self.ServerData.TotalMutations,
        SessionDuration = os.time() - self.ServerData.SessionStart
    }
end

-- ============================================
-- RETURN MODULE
-- ============================================
return Monitor
