-- TerrorSquadAI Threat Analysis Module
-- Real-time threat assessment and tracking
-- Author: DarckRovert (elnazzareno)

local ThreatAnalysis = {}
TerrorSquadAI:RegisterModule("ThreatAnalysis", ThreatAnalysis)

-- Vanilla WoW 1.12 doesn't have UnitGUID, so we create a unique identifier
local function GetUnitID(unit)
    if not UnitExists(unit) then return nil end
    local name = UnitName(unit)
    local level = UnitLevel(unit)
    return name .. "-" .. (level or "??")
end

-- Helper: Division segura para porcentajes de salud
local function SafeHealthPercent(unit)
    if not UnitExists(unit) then return 1 end
    local max = UnitHealthMax(unit)
    if not max or max == 0 then return 1 end
    return UnitHealth(unit) / max
end

-- Threat tracking
ThreatAnalysis.threatHistory = {}
ThreatAnalysis.maxHistorySize = 100
ThreatAnalysis.currentThreat = 0
ThreatAnalysis.threatTrend = 0 -- -1 decreasing, 0 stable, 1 increasing

-- Enemy tracking
ThreatAnalysis.trackedEnemies = {}
ThreatAnalysis.priorityTargets = {}

function ThreatAnalysis:Initialize()
    self.threatHistory = {}
    self.trackedEnemies = {}
    self.priorityTargets = {}
    
    -- Register events
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.eventFrame:RegisterEvent("UNIT_HEALTH")
    self.eventFrame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
    
    self.eventFrame:SetScript("OnEvent", function()
        if event == "PLAYER_TARGET_CHANGED" then
            ThreatAnalysis:OnTargetChanged()
        elseif event == "UNIT_HEALTH" then
            ThreatAnalysis:OnUnitHealth(arg1)
        elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
            ThreatAnalysis:OnEnemyDeath(arg1)
        end
    end)
    
    TerrorSquadAI:Debug("ThreatAnalysis initialized")
end

function ThreatAnalysis:UpdateThreat(threatLevel)
    self.currentThreat = threatLevel
    
    -- Add to history
    table.insert(self.threatHistory, {
        time = GetTime(),
        level = threatLevel
    })
    
    -- Trim history
    if table.getn(self.threatHistory) > self.maxHistorySize then
        table.remove(self.threatHistory, 1)
    end
    
    -- Calculate trend
    self:CalculateThreatTrend()
    
    -- Trigger alerts if needed
    if threatLevel >= TerrorSquadAI.Modules.AIEngine.THREAT_HIGH then
        self:TriggerHighThreatAlert()
    end
end

function ThreatAnalysis:CalculateThreatTrend()
    local historySize = table.getn(self.threatHistory)
    if historySize < 5 then
        self.threatTrend = 0
        return
    end
    
    -- Compare recent average to older average
    local recentSum = 0
    local olderSum = 0
    local halfSize = math.floor(historySize / 2)
    
    for i = halfSize + 1, historySize do
        recentSum = recentSum + self.threatHistory[i].level
    end
    
    for i = 1, halfSize do
        olderSum = olderSum + self.threatHistory[i].level
    end
    
    local recentAvg = recentSum / (historySize - halfSize)
    local olderAvg = olderSum / halfSize
    
    if recentAvg > olderAvg + 0.5 then
        self.threatTrend = 1
    elseif recentAvg < olderAvg - 0.5 then
        self.threatTrend = -1
    else
        self.threatTrend = 0
    end
end

function ThreatAnalysis:OnTargetChanged()
    if not UnitExists("target") then return end
    if not UnitIsEnemy("player", "target") then return end
    
    local targetID = GetUnitID("target")
    if not targetID then return end
    
    -- Track new enemy
    if not self.trackedEnemies[targetID] then
        self.trackedEnemies[targetID] = {
            name = UnitName("target"),
            level = UnitLevel("target"),
            classification = UnitClassification("target"),
            firstSeen = GetTime(),
            healthPercent = SafeHealthPercent("target"),
            threat = self:CalculateEnemyThreat("target")
        }
    end
    
    -- Update priority targets
    self:UpdatePriorityTargets()
end

function ThreatAnalysis:OnUnitHealth(unit)
    if not UnitExists(unit) then return end
    if not UnitIsEnemy("player", unit) then return end
    
    local targetID = GetUnitID(unit)
    if targetID and self.trackedEnemies[targetID] then
        self.trackedEnemies[targetID].healthPercent = SafeHealthPercent(unit)
        self.trackedEnemies[targetID].threat = self:CalculateEnemyThreat(unit)
    end
end

function ThreatAnalysis:OnEnemyDeath(message)
    -- Parse death message and remove from tracked enemies
    -- This is simplified - would need proper parsing
    for unitID, enemy in pairs(self.trackedEnemies) do
        if string.find(message, enemy.name) then
            self.trackedEnemies[unitID] = nil
            break
        end
    end
    
    self:UpdatePriorityTargets()
end

function ThreatAnalysis:CalculateEnemyThreat(unit)
    local threat = 0
    
    -- Base threat on classification
    local classification = UnitClassification(unit)
    if classification == "worldboss" then
        threat = threat + 100
    elseif classification == "rareelite" then
        threat = threat + 50
    elseif classification == "elite" then
        threat = threat + 30
    elseif classification == "rare" then
        threat = threat + 20
    else
        threat = threat + 10
    end
    
    -- Level difference
    local levelDiff = UnitLevel(unit) - UnitLevel("player")
    if levelDiff == -1 then -- Skull level
        threat = threat + 50
    else
        threat = threat + (levelDiff * 5)
    end
    
    -- Health percentage (low health = lower threat)
    local healthPercent = SafeHealthPercent(unit)
    threat = threat * healthPercent
    
    -- Vanilla WoW 1.12 doesn't have UnitCastingInfo/UnitChannelInfo
    -- Skip casting check for now
    
    return threat
end

function ThreatAnalysis:UpdatePriorityTargets()
    -- Sort enemies by threat
    local sortedEnemies = {}
    
    for unitID, enemy in pairs(self.trackedEnemies) do
        table.insert(sortedEnemies, {
            unitID = unitID,
            data = enemy
        })
    end
    
    table.sort(sortedEnemies, function(a, b)
        return (a.data.threat or 0) > (b.data.threat or 0)
    end)
    
    -- Update priority list (top 5)
    self.priorityTargets = {}
    for i = 1, math.min(5, table.getn(sortedEnemies)) do
        table.insert(self.priorityTargets, sortedEnemies[i])
    end
    
    -- Notify squad coordination
    if TerrorSquadAI.Modules.SquadCoordination then
        TerrorSquadAI.Modules.SquadCoordination:UpdatePriorityTargets(self.priorityTargets)
    end
end

function ThreatAnalysis:TriggerHighThreatAlert()
    if not TerrorSquadAI.DB.alertsEnabled then return end
    
    if TerrorSquadAI.Modules.AlertSystem then
        TerrorSquadAI.Modules.AlertSystem:ShowAlert({
            type = "critical",
            message = "¡AMENAZA ALTA DETECTADA!",
            duration = 3,
            sound = true
        })
    end
end

function ThreatAnalysis:GetCurrentThreat()
    return self.currentThreat
end

function ThreatAnalysis:GetThreatTrend()
    return self.threatTrend
end

function ThreatAnalysis:GetPriorityTargets()
    return self.priorityTargets
end

function ThreatAnalysis:GetTrackedEnemies()
    return self.trackedEnemies
end
