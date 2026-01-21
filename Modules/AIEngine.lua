-- TerrorSquadAI AI Engine Module
-- Advanced decision-making and combat analysis
-- Author: DarckRovert (elnazzareno)

local AIEngine = {}
TerrorSquadAI:RegisterModule("AIEngine", AIEngine)

-- AI State
AIEngine.inCombat = false
AIEngine.currentScenario = nil
AIEngine.threatLevel = 0
AIEngine.lastAnalysis = 0
AIEngine.analysisInterval = 0.5 -- seconds
AIEngine.combatData = {}

-- Threat levels
AIEngine.THREAT_CRITICAL = 4
AIEngine.THREAT_HIGH = 3
AIEngine.THREAT_MEDIUM = 2
AIEngine.THREAT_LOW = 1
AIEngine.THREAT_NONE = 0

-- Combat scenarios
AIEngine.SCENARIO_UNKNOWN = 0
AIEngine.SCENARIO_BOSS_FIGHT = 1
AIEngine.SCENARIO_PVP_SKIRMISH = 2
AIEngine.SCENARIO_PVP_BATTLEGROUND = 3
AIEngine.SCENARIO_DUNGEON_TRASH = 4
AIEngine.SCENARIO_WORLD_PVP = 5

function AIEngine:Initialize()
    self.combatData = {
        startTime = 0,
        enemiesEngaged = {},
        alliesPresent = {},
        damageDealt = 0,
        damageTaken = 0,
        healingDone = 0,
        deaths = 0,
        kills = 0
    }
    
    -- Create update frame
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame:SetScript("OnUpdate", function()
        AIEngine:OnUpdate()
    end)
    
    TerrorSquadAI:Debug("AIEngine initialized")
end

function AIEngine:OnUpdate()
    if not TerrorSquadAI.DB.aiEnabled then return end
    if not self.inCombat then return end
    
    local currentTime = GetTime()
    if currentTime - self.lastAnalysis >= self.analysisInterval then
        self:AnalyzeCombatSituation()
        self.lastAnalysis = currentTime
    end
end

function AIEngine:OnCombatStart()
    self.inCombat = true
    self.combatData.startTime = GetTime()
    self.combatData.enemiesEngaged = {}
    self.combatData.alliesPresent = {}
    
    -- Detect scenario type
    self:DetectScenario()
    
    -- Notify other modules
    if TerrorSquadAI.Modules.CommunicationSync then
        TerrorSquadAI.Modules.CommunicationSync:BroadcastCombatStart()
    end
    
    TerrorSquadAI:Debug("Combat started - Scenario: " .. self.currentScenario)
end

function AIEngine:OnCombatEnd()
    self.inCombat = false
    local duration = GetTime() - self.combatData.startTime
    
    -- Store combat statistics
    if not TerrorSquadAI.CharDB.combatStats then
        TerrorSquadAI.CharDB.combatStats = {}
    end
    
    table.insert(TerrorSquadAI.CharDB.combatStats, {
        timestamp = time(),
        duration = duration,
        scenario = self.currentScenario,
        threatLevel = self.threatLevel,
        data = self.combatData
    })
    
    -- Keep only last 100 combat records
    if table.getn(TerrorSquadAI.CharDB.combatStats) > 100 then
        table.remove(TerrorSquadAI.CharDB.combatStats, 1)
    end
    
    -- Notify other modules
    if TerrorSquadAI.Modules.CommunicationSync then
        TerrorSquadAI.Modules.CommunicationSync:BroadcastCombatEnd()
    end
    
    TerrorSquadAI:Debug("Combat ended - Duration: " .. string.format("%.1f", duration) .. "s")
end

function AIEngine:DetectScenario()
    -- Check if in battleground
    local inBattleground = false
    for i = 1, MAX_BATTLEFIELD_QUEUES do
        local status = GetBattlefieldStatus(i)
        if status == "active" then
            inBattleground = true
            break
        end
    end
    
    if inBattleground then
        self.currentScenario = self.SCENARIO_PVP_BATTLEGROUND
        return
    end
    
    -- Check if in instance
    local inInstance, instanceType = IsInInstance()
    if inInstance then
        if instanceType == "pvp" then
            self.currentScenario = self.SCENARIO_PVP_BATTLEGROUND
        elseif instanceType == "party" or instanceType == "raid" then
            -- Check if fighting boss (has raid icon or high level)
            if self:IsBossFight() then
                self.currentScenario = self.SCENARIO_BOSS_FIGHT
            else
                self.currentScenario = self.SCENARIO_DUNGEON_TRASH
            end
        end
        return
    end
    
    -- Check if PvP flagged and enemies nearby
    if UnitIsPVP("player") then
        local enemyPlayers = self:CountNearbyEnemyPlayers()
        if enemyPlayers > 0 then
            if enemyPlayers >= 3 then
                self.currentScenario = self.SCENARIO_WORLD_PVP
            else
                self.currentScenario = self.SCENARIO_PVP_SKIRMISH
            end
            return
        end
    end
    
    self.currentScenario = self.SCENARIO_UNKNOWN
end

function AIEngine:IsBossFight()
    -- Check target
    if UnitExists("target") and UnitIsEnemy("player", "target") then
        local level = UnitLevel("target")
        local classification = UnitClassification("target")
        
        -- Boss classification or skull level
        if classification == "worldboss" or classification == "rareelite" or classification == "elite" then
            if level == -1 or level >= UnitLevel("player") + 3 then
                return true
            end
        end
    end
    
    return false
end

function AIEngine:CountNearbyEnemyPlayers()
    local count = 0
    -- This is a simplified version - in real implementation would scan nearby units
    -- For vanilla WoW, we'd need to check raid/party targets and visible nameplates
    return count
end

function AIEngine:AnalyzeCombatSituation()
    -- Calculate threat level
    self.threatLevel = self:CalculateThreatLevel()
    
    -- Get strategic suggestions
    local suggestions = self:GenerateStrategicSuggestions()
    
    -- Send to strategic suggestions module
    if TerrorSquadAI.Modules.StrategicSuggestions and suggestions then
        TerrorSquadAI.Modules.StrategicSuggestions:ProcessSuggestions(suggestions)
    end
    
    -- Update threat analysis module
    if TerrorSquadAI.Modules.ThreatAnalysis then
        TerrorSquadAI.Modules.ThreatAnalysis:UpdateThreat(self.threatLevel)
    end
end

function AIEngine:CalculateThreatLevel()
    local threat = self.THREAT_NONE
    
    if not self.inCombat then
        return threat
    end
    
    -- Base threat on health percentage
    local maxHealth = UnitHealthMax("player")
    if not maxHealth or maxHealth == 0 then return threat end
    local healthPercent = UnitHealth("player") / maxHealth
    if healthPercent < 0.3 then
        threat = self.THREAT_HIGH
    elseif healthPercent < 0.5 then
        threat = self.THREAT_MEDIUM
    else
        threat = self.THREAT_LOW
    end
    
    -- Increase threat if multiple enemies
    local enemyCount = self:CountNearbyEnemies()
    if enemyCount >= 5 then
        threat = threat + 2
    elseif enemyCount >= 3 then
        threat = threat + 1
    end
    
    -- Increase threat if allies are low
    local lowAllies = self:CountLowHealthAllies()
    if lowAllies >= 3 then
        threat = threat + 1
    end
    
    -- Cap at critical
    if threat > self.THREAT_CRITICAL then
        threat = self.THREAT_CRITICAL
    end
    
    return threat
end

function AIEngine:CountNearbyEnemies()
    local count = 0
    
    -- Count target
    if UnitExists("target") and UnitIsEnemy("player", "target") and not UnitIsDead("target") then
        count = count + 1
    end
    
    -- Count party/raid targets
    if GetNumRaidMembers() > 0 then
        for i = 1, 40 do
            local unit = "raid" .. i .. "target"
            if UnitExists(unit) and UnitIsEnemy("player", unit) and not UnitIsDead(unit) then
                count = count + 1
            end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, 4 do
            local unit = "party" .. i .. "target"
            if UnitExists(unit) and UnitIsEnemy("player", unit) and not UnitIsDead(unit) then
                count = count + 1
            end
        end
    end
    
    return count
end

function AIEngine:CountLowHealthAllies()
    local count = 0
    local threshold = 0.4
    
    -- Check party
    if GetNumPartyMembers() > 0 then
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) then
                local healthPercent = UnitHealth(unit) / UnitHealthMax(unit)
                if healthPercent < threshold then
                    count = count + 1
                end
            end
        end
    end
    
    -- Check raid
    if GetNumRaidMembers() > 0 then
        for i = 1, 40 do
            local unit = "raid" .. i
            if UnitExists(unit) and not UnitIsDead(unit) then
                local healthPercent = UnitHealth(unit) / UnitHealthMax(unit)
                if healthPercent < threshold then
                    count = count + 1
                end
            end
        end
    end
    
    return count
end

function AIEngine:GenerateStrategicSuggestions()
    local suggestions = {}
    
    -- Analyze current situation
    local maxHealth = UnitHealthMax("player")
    local maxMana = UnitManaMax("player")
    local playerHealth = (maxHealth and maxHealth > 0) and (UnitHealth("player") / maxHealth) or 1
    local playerMana = (maxMana and maxMana > 0) and (UnitMana("player") / maxMana) or 1
    local enemyCount = self:CountNearbyEnemies()
    
    -- Health-based suggestions
    if playerHealth < 0.3 then
        table.insert(suggestions, {
            type = "defensive",
            priority = "critical",
            message = "¡CRÍTICO! Vida baja - Usa defensivas",
            icon = "Interface\\Icons\\Spell_Holy_PowerWordShield"
        })
    end
    
    -- Enemy count suggestions
    if enemyCount >= 3 then
        table.insert(suggestions, {
            type = "tactical",
            priority = "high",
            message = "Múltiples enemigos - Concentra fuego en uno",
            icon = "Interface\\Icons\\Ability_Hunter_MarkedForDeath"
        })
    end
    
    -- Mana management for casters
    if UnitPowerType("player") == 0 and playerMana < 0.2 then
        table.insert(suggestions, {
            type = "resource",
            priority = "medium",
            message = "Maná bajo - Conserva recursos",
            icon = "Interface\\Icons\\Inv_Drink_05"
        })
    end
    
    -- PvP specific suggestions
    if self.currentScenario == self.SCENARIO_PVP_SKIRMISH or 
       self.currentScenario == self.SCENARIO_WORLD_PVP then
        
        local lowAllies = self:CountLowHealthAllies()
        if lowAllies >= 2 then
            table.insert(suggestions, {
                type = "tactical",
                priority = "high",
                message = "Aliados heridos - Considera retirarte",
                icon = "Interface\\Icons\\Ability_Rogue_Sprint"
            })
        end
    end
    
    return suggestions
end

function AIEngine:GetThreatLevel()
    return self.threatLevel
end

function AIEngine:GetCurrentScenario()
    return self.currentScenario
end

function AIEngine:IsInCombat()
    return self.inCombat
end
