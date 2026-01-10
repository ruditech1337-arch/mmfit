-- monitor_fixed.lua - MODULE MONITORING LENGKAP DENGAN SEMUA METHOD
local Monitor = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- ============================================
-- KONFIGURASI
-- ============================================
Monitor.Config = {
    FishWebhookURL = "",
    MonitorWebhookURL = "",
    DiscordUserID = "",
    UpdateInterval = 30,
    AFKThreshold = 300,
    DebugMode = true
}

-- Data storage
Monitor.ServerData = {
    SessionStart = os.time(),
    Players = {},
    PlayerStats = {},
    TotalCasts = 0,
    TotalFish = 0,
    TotalSecrets = 0,
    TotalMutations = 0
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
-- CONFIGURATION METHODS (YANG DIPERLUKAN)
-- ============================================
function Monitor:SetFishWebhookURL(url)
    self.Config.FishWebhookURL = url
    print("[Monitor] Fish webhook URL set:", url)
end

function Monitor:SetMonitorWebhookURL(url)
    self.Config.MonitorWebhookURL = url
    print("[Monitor] Monitor webhook URL set:", url)
end

function Monitor:SetDiscordUserID(id)
    self.Config.DiscordUserID = id
    print("[Monitor] Discord user ID set:", id)
end

function Monitor:SetUpdateInterval(seconds)
    self.Config.UpdateInterval = seconds
    print("[Monitor] Update interval set to", seconds, "seconds")
end

function Monitor:SetAFKThreshold(seconds)
    self.Config.AFKThreshold = seconds
    print("[Monitor] AFK threshold set to", seconds, "seconds")
end

function Monitor:SetDebugMode(enabled)
    self.Config.DebugMode = enabled
    print("[Monitor] Debug mode", enabled and "enabled" or "disabled")
end

-- ============================================
-- WEBHOOK SEND FUNCTIONS
-- ============================================
function Monitor:SendFishWebhook(fishData, weight, mutation, playerName)
    if not self.Config.FishWebhookURL or self.Config.FishWebhookURL == "" then
        return
    end
    
    if not httpRequest then
        warn("[Monitor] HTTP request not available")
        return
    end
    
    local embed = {
        embeds = {{
            title = "🎣 FISH CAUGHT",
            description = string.format("**%s** caught a fish!", playerName or LocalPlayer.Name),
            color = 3066993, -- Green
            fields = {
                {
                    name = "Fish Details",
                    value = string.format("**Name:** %s\n**Weight:** %.2f kg\n**Mutation:** %s",
                        fishData.Name or "Unknown",
                        weight or 0,
                        mutation or "None"),
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
        print("[Monitor] Fish webhook sent")
    end)
end

function Monitor:SendServerMonitorWebhook()
    if not self.Config.MonitorWebhookURL or self.Config.MonitorWebhookURL == "" then
        return
    end
    
    if not httpRequest then return end
    
    local embed = {
        embeds = {{
            title = "📊 SERVER MONITOR",
            description = string.format("**Players Online:** %d\n**Server Time:** %s",
                #Players:GetPlayers(),
                os.date("%H:%M:%S")),
            color = 3447003, -- Blue
            fields = {
                {
                    name = "Statistics",
                    value = string.format("**Total Casts:** %d\n**Total Fish:** %d\n**Total SECRETs:** %d\n**Total Mutations:** %d",
                        self.ServerData.TotalCasts or 0,
                        self.ServerData.TotalFish or 0,
                        self.ServerData.TotalSecrets or 0,
                        self.ServerData.TotalMutations or 0),
                    inline = false
                }
            },
            footer = {
                text = "FishIt Complete Monitor • Real-time",
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
        print("[Monitor] Server monitor webhook sent")
    end)
end

-- ============================================
-- MONITORING FUNCTIONS
-- ============================================
function Monitor:TrackFish(player, fishName, weight, mutation)
    local userId = player.UserId
    
    if not self.ServerData.Players[userId] then
        self.ServerData.Players[userId] = {
            Name = player.Name,
            DisplayName = player.DisplayName or player.Name,
            TotalFish = 0,
            TotalSecrets = 0
        }
    end
    
    local playerData = self.ServerData.Players[userId]
    playerData.TotalFish = (playerData.TotalFish or 0) + 1
    self.ServerData.TotalFish = self.ServerData.TotalFish + 1
    
    -- Kirim webhook untuk fish tier tinggi
    if fishName:find("SECRET") or fishName:find("Legendary") or fishName:find("Mythic") then
        self:SendFishWebhook({
            Name = fishName,
            Tier = fishName:find("SECRET") and "SECRET" or 
                  fishName:find("Legendary") and "Legendary" or "Mythic"
        }, weight, mutation, player.Name)
    end
    
    if self.Config.DebugMode then
        print(string.format("[Monitor] %s caught %s (%.2f kg) %s",
            player.Name, fishName, weight, mutation and "["..mutation.."]" or ""))
    end
end

function Monitor:TrackCast(player)
    self.ServerData.TotalCasts = self.ServerData.TotalCasts + 1
    
    if self.Config.DebugMode then
        print("[Monitor] Cast tracked for:", player.Name)
    end
end

-- ============================================
-- EVENT HOOKING
-- ============================================
function Monitor:HookFishingEvents()
    print("[Monitor] Hooking fishing events...")
    
    -- Try to load game modules
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
    
    -- Hook fishing events
    local netFolder = ReplicatedStorage.Packages
        ._Index["sleitnick_net@0.2.0"]
        .net
    
    -- Fish caught event
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
            
            if extraData then
                mutation = extraData.Variant or extraData.Mutation or "None"
            end
            
            -- Track the fish
            self:TrackFish(targetPlayer, fishData.Name, weight, mutation)
        end
    end)
    
    -- Cast event
    local RE_MinigameChanged = netFolder:WaitForChild("RE/MinigameChanged")
    RE_MinigameChanged.OnClientEvent:Connect(function(state, player)
        if state == "Casting" or state == "Fishing" then
            local targetPlayer = player or LocalPlayer
            self:TrackCast(targetPlayer)
        end
    end)
    
    print("[Monitor] Fishing events hooked successfully")
end

-- ============================================
-- MAIN FUNCTIONS
-- ============================================
function Monitor:Start()
    print("[Monitor] Starting monitoring system...")
    
    -- Initialize player tracking
    for _, player in pairs(Players:GetPlayers()) do
        self.ServerData.Players[player.UserId] = {
            Name = player.Name,
            DisplayName = player.DisplayName or player.Name,
            TotalFish = 0,
            TotalSecrets = 0
        }
    end
    
    -- Hook events
    task.spawn(function()
        task.wait(2) -- Wait for game to load
        self:HookFishingEvents()
    end)
    
    -- Start webhook updates
    task.spawn(function()
        while true do
            self:SendServerMonitorWebhook()
            task.wait(self.Config.UpdateInterval)
        end
    end)
    
    print("[Monitor] Monitoring system started successfully!")
    return true
end

function Monitor:GetServerData()
    return {
        OnlinePlayers = #Players:GetPlayers(),
        TotalCasts = self.ServerData.TotalCasts,
        TotalFish = self.ServerData.TotalFish,
        TotalSecrets = self.ServerData.TotalSecrets,
        TotalMutations = self.ServerData.TotalMutations,
        SessionDuration = os.time() - self.ServerData.SessionStart
    }
end

function Monitor:Stop()
    print("[Monitor] Stopping monitoring...")
    return true
end

-- ============================================
-- RETURN MODULE
-- ============================================
return Monitor
