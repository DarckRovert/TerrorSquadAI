-- TerrorSquadAI TerrorNet Module
-- Phase 7: Total Integration
-- Zone-wide logistic network sharing enemy positions and squad status

local TerrorNet = {}
TerrorSquadAI:RegisterModule("TerrorNet", TerrorNet)

TerrorNet.PREFIX = "TSNET"
TerrorNet.BROADCAST_INTERVAL = 3.0 -- Seconds

TerrorNet.networkData = {} -- { [SenderName] = { x=, y=, map=, time= } }

function TerrorNet:Initialize()
    self:RegisterEvents()
    self.lastBroadcast = 0
    TerrorSquadAI:Debug("TerrorNet (Logistics Grid) online")
end

function TerrorNet:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    f:SetScript("OnUpdate", function() TerrorNet:OnUpdate() end)
    f:SetScript("OnEvent", function()
        if event == "CHAT_MSG_ADDON" and arg1 == TerrorNet.PREFIX then
            TerrorNet:OnMessageReceived(arg2, arg4) -- msg, sender
        end
    end)
end

function TerrorNet:OnUpdate()
    local now = GetTime()
    if now - self.lastBroadcast > self.BROADCAST_INTERVAL then
        self:BroadcastPosition()
        self.lastBroadcast = now
    end
end

function TerrorNet:BroadcastPosition()
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then return end
    
    local x, y = GetPlayerMapPosition("player")
    if x == 0 and y == 0 then return end
    
    -- Format: POS:MapID:X:Y
    -- In 1.12 map ID is tricky. using ZoneText as proxy or just relying on checking zone match on receiver.
    local msg = string.format("POS:%.3f:%.3f", x, y)
    
    -- Broadcast to RAID or PARTY
    local channel = "PARTY"
    if GetNumRaidMembers() > 0 then channel = "RAID" end
    
    SendAddonMessage(self.PREFIX, msg, channel)
    
    -- Also broadcast target if hostile player
    if UnitExists("target") and UnitIsPlayer("target") and UnitIsEnemy("player", "target") then
        local tx, ty = GetPlayerMapPosition("target")
        if tx and (tx ~= 0 or ty ~= 0) then
            -- TGT:Name:X:Y
            local tMsg = string.format("TGT:%s:%.3f:%.3f", UnitName("target"), tx, ty)
            SendAddonMessage(self.PREFIX, tMsg, channel)
        end
    end
end

function TerrorNet:OnMessageReceived(msg, sender)
    if sender == UnitName("player") then return end
    
    -- Parse Message
    -- POS:X:Y
    local s, e, x, y = string.find(msg, "^POS:(%d+.%d+):(%d+.%d+)")
    if s then
        self:UpdateNetworkData(sender, tonumber(x), tonumber(y), "ALLY")
        return
    end
    
    -- TGT:Name:X:Y
    local s, e, name, tx, ty = string.find(msg, "^TGT:(.+):(%d+.%d+):(%d+.%d+)")
    if s then
        -- This is an enemy spotted by an ally
        self:UpdateNetworkData(name, tonumber(tx), tonumber(ty), "ENEMY_NET")
        return
    end
end

function TerrorNet:UpdateNetworkData(name, x, y, type)
    self.networkData[name] = {
        x = x,
        y = y,
        type = type,
        time = GetTime()
    }
    
    -- Feed into Tactical Radar if available
    if TerrorSquadAI.Modules.TacticalRadar and TerrorSquadAI.Modules.TacticalRadar.RegisterExternalTarget then
        TerrorSquadAI.Modules.TacticalRadar:RegisterExternalTarget(name, x, y, type)
    end
end
