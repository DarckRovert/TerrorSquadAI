-- TerrorSquadAI Communication Sync Module
-- Synchronized communication between squad members
-- Author: DarckRovert (elnazzareno)

local CommunicationSync = {}
TerrorSquadAI:RegisterModule("CommunicationSync", CommunicationSync)

-- Network state
CommunicationSync.connectedMembers = {}
CommunicationSync.lastSync = 0
CommunicationSync.syncInterval = 5 -- seconds
CommunicationSync.messageQueue = {}

-- Message types
CommunicationSync.MSG_PRESENCE = "PRESENCE"
CommunicationSync.MSG_COMBAT_START = "COMBAT_START"
CommunicationSync.MSG_COMBAT_END = "COMBAT_END"
CommunicationSync.MSG_THREAT_UPDATE = "THREAT_UPDATE"
CommunicationSync.MSG_SUGGESTION = "SUGGESTION"
CommunicationSync.MSG_BOSS_TIMER = "BOSS_TIMER"
CommunicationSync.MSG_PRIORITY_TARGET = "PRIORITY_TARGET"
CommunicationSync.MSG_STRATEGY = "STRATEGY"
CommunicationSync.MSG_SYNC_REQUEST = "SYNC_REQUEST"
CommunicationSync.MSG_SYNC_RESPONSE = "SYNC_RESPONSE"

function CommunicationSync:Initialize()
    self.connectedMembers = {}
    self.messageQueue = {}
    
    -- Create update frame
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame:SetScript("OnUpdate", function()
        CommunicationSync:OnUpdate()
    end)
    
    -- Register events
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    self.eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    
    self.eventFrame:SetScript("OnEvent", function()
        if event == "CHAT_MSG_ADDON" then
            if arg1 == TerrorSquadAI.ADDON_PREFIX then
                CommunicationSync:OnMessageReceived(arg2, arg3, arg4)
            end
        elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
            CommunicationSync:OnGroupChanged()
        end
    end)
    
    TerrorSquadAI:Debug("CommunicationSync initialized")
end

function CommunicationSync:OnUpdate()
    if not TerrorSquadAI.DB.syncEnabled then return end
    
    local currentTime = GetTime()
    
    -- Periodic sync
    if currentTime - self.lastSync >= self.syncInterval then
        self:PeriodicSync()
        self.lastSync = currentTime
    end
    
    -- Process message queue
    self:ProcessMessageQueue()
end

function CommunicationSync:PeriodicSync()
    -- Send presence update
    self:BroadcastPresence()
    
    -- Clean up stale connections
    self:CleanupStaleConnections()
end

function CommunicationSync:CleanupStaleConnections()
    local currentTime = GetTime()
    local timeout = 30 -- seconds
    
    for member, data in pairs(self.connectedMembers) do
        if currentTime - data.lastSeen > timeout then
            self.connectedMembers[member] = nil
            TerrorSquadAI:Debug("Member disconnected: " .. member)
        end
    end
end

function CommunicationSync:SendMessage(messageType, data, target)
    if not TerrorSquadAI.DB.syncEnabled then return false end
    
    local message = {
        type = messageType,
        sender = UnitName("player"),
        timestamp = GetTime(),
        data = data
    }
    
    local serialized = self:SerializeMessage(message)
    if not serialized then return false end
    
    -- Determine channel
    local channel = "RAID"
    if GetNumRaidMembers() == 0 then
        if GetNumPartyMembers() > 0 then
            channel = "PARTY"
        else
            return false -- Solo, no one to send to
        end
    end
    
    -- Send message
    if target then
        SendAddonMessage(TerrorSquadAI.ADDON_PREFIX, serialized, "WHISPER", target)
    else
        SendAddonMessage(TerrorSquadAI.ADDON_PREFIX, serialized, channel)
    end
    
    return true
end

function CommunicationSync:OnMessageReceived(message, distribution, sender)
    if not TerrorSquadAI.DB.syncEnabled then return end
    if sender == UnitName("player") then return end -- Ignore own messages
    
    local deserialized = self:DeserializeMessage(message)
    if not deserialized then return end
    
    -- Update member info
    if not self.connectedMembers[sender] then
        self.connectedMembers[sender] = {
            name = sender,
            firstSeen = GetTime(),
            messagesReceived = 0
        }
        TerrorSquadAI:Debug("New member connected: " .. sender)
    end
    
    self.connectedMembers[sender].lastSeen = GetTime()
    self.connectedMembers[sender].messagesReceived = self.connectedMembers[sender].messagesReceived + 1
    
    -- Process message by type
    self:ProcessMessage(deserialized, sender)
end

function CommunicationSync:ProcessMessage(message, sender)
    if not message or not message.type then return end
    
    if message.type == self.MSG_PRESENCE then
        self:OnPresenceReceived(message, sender)
    elseif message.type == self.MSG_COMBAT_START then
        self:OnCombatStartReceived(message, sender)
    elseif message.type == self.MSG_COMBAT_END then
        self:OnCombatEndReceived(message, sender)
    elseif message.type == self.MSG_THREAT_UPDATE then
        self:OnThreatUpdateReceived(message, sender)
    elseif message.type == self.MSG_SUGGESTION then
        self:OnSuggestionReceived(message, sender)
    elseif message.type == self.MSG_BOSS_TIMER then
        self:OnBossTimerReceived(message, sender)
    elseif message.type == self.MSG_PRIORITY_TARGET then
        self:OnPriorityTargetReceived(message, sender)
    elseif message.type == self.MSG_STRATEGY then
        self:OnStrategyReceived(message, sender)
    elseif message.type == self.MSG_SYNC_REQUEST then
        self:OnSyncRequestReceived(message, sender)
    elseif message.type == self.MSG_SYNC_RESPONSE then
        self:OnSyncResponseReceived(message, sender)
    end
end

function CommunicationSync:OnPresenceReceived(message, sender)
    -- Update member data
    if self.connectedMembers[sender] and message.data then
        self.connectedMembers[sender].version = message.data.version
        self.connectedMembers[sender].aiEnabled = message.data.aiEnabled
    end
end

function CommunicationSync:OnCombatStartReceived(message, sender)
    TerrorSquadAI:Debug(sender .. " entered combat")
    
    if self.connectedMembers[sender] then
        self.connectedMembers[sender].inCombat = true
    end
end

function CommunicationSync:OnCombatEndReceived(message, sender)
    TerrorSquadAI:Debug(sender .. " left combat")
    
    if self.connectedMembers[sender] then
        self.connectedMembers[sender].inCombat = false
    end
end

function CommunicationSync:OnThreatUpdateReceived(message, sender)
    if not message.data or not message.data.threatLevel then return end
    
    if self.connectedMembers[sender] then
        self.connectedMembers[sender].threatLevel = message.data.threatLevel
    end
end

function CommunicationSync:OnSuggestionReceived(message, sender)
    if not message.data then return end
    
    -- Display received suggestion if high priority
    if message.data.priority and message.data.priority >= 3 then
        if TerrorSquadAI.Modules.AlertSystem then
            TerrorSquadAI.Modules.AlertSystem:ShowAlert({
                type = "info",
                message = "[" .. sender .. "] " .. (message.data.message or "Suggestion"),
                duration = 3,
                icon = message.data.icon
            })
        end
    end
end

function CommunicationSync:OnBossTimerReceived(message, sender)
    if not message.data then return end
    
    -- Sync boss timer with local tracking
    TerrorSquadAI:Debug("Boss timer received from " .. sender .. ": " .. (message.data.text or "Unknown"))
end

function CommunicationSync:OnPriorityTargetReceived(message, sender)
    if not message.data then return end
    
    -- Update shared priority targets
    TerrorSquadAI:Debug("Priority target from " .. sender)
end

function CommunicationSync:OnStrategyReceived(message, sender)
    if not message.data then return end
    
    -- Receive strategy recommendation from squad leader
    if message.data.approach then
        TerrorSquadAI:Debug("Strategy update from " .. sender .. ": " .. message.data.approach)
    end
end

function CommunicationSync:OnSyncRequestReceived(message, sender)
    -- Respond with current state
    self:SendSyncResponse(sender)
end

function CommunicationSync:OnSyncResponseReceived(message, sender)
    if not message.data then return end
    
    -- Update member with full state
    if self.connectedMembers[sender] then
        for key, value in pairs(message.data) do
            self.connectedMembers[sender][key] = value
        end
    end
end

function CommunicationSync:BroadcastPresence()
    self:SendMessage(self.MSG_PRESENCE, {
        version = TerrorSquadAI.Version,
        aiEnabled = TerrorSquadAI.DB.aiEnabled,
        clan = TerrorSquadAI.Clan
    })
end

function CommunicationSync:AnnouncePresence()
    self:BroadcastPresence()
    TerrorSquadAI:Print("Announcing presence to El Sequito del Terror...")
end

function CommunicationSync:BroadcastCombatStart()
    self:SendMessage(self.MSG_COMBAT_START, {
        timestamp = GetTime()
    })
end

function CommunicationSync:BroadcastCombatEnd()
    self:SendMessage(self.MSG_COMBAT_END, {
        timestamp = GetTime()
    })
end

function CommunicationSync:BroadcastThreatUpdate(threatLevel)
    self:SendMessage(self.MSG_THREAT_UPDATE, {
        threatLevel = threatLevel
    })
end

function CommunicationSync:BroadcastSuggestion(suggestion)
    self:SendMessage(self.MSG_SUGGESTION, suggestion)
end

function CommunicationSync:BroadcastBossTimer(timerData)
    self:SendMessage(self.MSG_BOSS_TIMER, timerData)
end

function CommunicationSync:BroadcastPriorityTarget(targetData)
    self:SendMessage(self.MSG_PRIORITY_TARGET, targetData)
end

function CommunicationSync:BroadcastStrategy(strategy)
    self:SendMessage(self.MSG_STRATEGY, strategy)
end

function CommunicationSync:SendSyncRequest(target)
    self:SendMessage(self.MSG_SYNC_REQUEST, {}, target)
end

function CommunicationSync:SendSyncResponse(target)
    local aiEngine = TerrorSquadAI.Modules.AIEngine
    local threatAnalysis = TerrorSquadAI.Modules.ThreatAnalysis
    
    local state = {
        version = TerrorSquadAI.Version,
        aiEnabled = TerrorSquadAI.DB.aiEnabled,
        inCombat = aiEngine and aiEngine:IsInCombat() or false,
        threatLevel = threatAnalysis and threatAnalysis:GetCurrentThreat() or 0,
        scenario = aiEngine and aiEngine:GetCurrentScenario() or 0
    }
    
    self:SendMessage(self.MSG_SYNC_RESPONSE, state, target)
end

function CommunicationSync:ForceSyncAll()
    -- Request sync from all members
    for member, _ in pairs(self.connectedMembers) do
        self:SendSyncRequest(member)
    end
    
    -- Broadcast own state
    self:BroadcastPresence()
end

function CommunicationSync:OnGroupChanged()
    -- Group composition changed
    TerrorSquadAI:Debug("Group composition changed")
    
    -- Announce presence to new members
    self:BroadcastPresence()
end

function CommunicationSync:ProcessMessageQueue()
    -- Process any queued messages
    while table.getn(self.messageQueue) > 0 do
        local msg = table.remove(self.messageQueue, 1)
        if msg then
            self:SendMessage(msg.type, msg.data, msg.target)
        end
    end
end

function CommunicationSync:SerializeMessage(message)
    -- Simple serialization using safe delimiters
    if not message then return nil end
    
    local serialized = ""
    serialized = serialized .. message.type .. "~"
    serialized = serialized .. message.sender .. "~"
    serialized = serialized .. tostring(message.timestamp) .. "~"
    
    -- Serialize data (simplified)
    if message.data then
        if type(message.data) == "table" then
            for key, value in pairs(message.data) do
                -- Escape special characters
                local safeKey = tostring(key)
                local safeValue = tostring(value)
                serialized = serialized .. safeKey .. "=" .. safeValue .. ";"
            end
        else
            serialized = serialized .. tostring(message.data)
        end
    end
    
    return serialized
end

function CommunicationSync:DeserializeMessage(serialized)
    if not serialized or serialized == "" then return nil end
    
    -- Simple deserialization using safe delimiters
    local parts = {}
    for part in string.gfind(serialized, "[^~]+") do
        table.insert(parts, part)
    end
    
    if table.getn(parts) < 3 then return nil end
    
    local message = {
        type = parts[1],
        sender = parts[2],
        timestamp = tonumber(parts[3]) or 0,
        data = {}
    }
    
    -- Deserialize data
    if parts[4] then
        for pair in string.gfind(parts[4], "[^;]+") do
            local _, _, key, value = string.find(pair, "([^=]+)=([^=]+)")
            if key and value then
                -- Try to convert to number
                local numValue = tonumber(value)
                message.data[key] = numValue or value
            end
        end
    end
    
    return message
end

function CommunicationSync:GetConnectedMembers()
    return self.connectedMembers
end

function CommunicationSync:GetMemberCount()
    local count = 0
    for _ in pairs(self.connectedMembers) do
        count = count + 1
    end
    return count
end

function CommunicationSync:IsMemberConnected(memberName)
    return self.connectedMembers[memberName] ~= nil
end
