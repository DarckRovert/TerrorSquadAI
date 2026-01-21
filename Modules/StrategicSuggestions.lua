-- TerrorSquadAI Strategic Suggestions Module
-- Dynamic strategic recommendations based on AI analysis
-- Author: DarckRovert (elnazzareno)

local StrategicSuggestions = {}
TerrorSquadAI:RegisterModule("StrategicSuggestions", StrategicSuggestions)

-- Suggestion queue
StrategicSuggestions.activesuggestions = {}
StrategicSuggestions.suggestionHistory = {}
StrategicSuggestions.maxActiveSuggestions = 3
StrategicSuggestions.suggestionCooldowns = {}

-- Suggestion priorities
StrategicSuggestions.PRIORITY_CRITICAL = 4
StrategicSuggestions.PRIORITY_HIGH = 3
StrategicSuggestions.PRIORITY_MEDIUM = 2
StrategicSuggestions.PRIORITY_LOW = 1

function StrategicSuggestions:Initialize()
    self.activeSuggestions = {}
    self.suggestionHistory = {}
    self.suggestionCooldowns = {}
    
    TerrorSquadAI:Debug("StrategicSuggestions initialized")
end

function StrategicSuggestions:ProcessSuggestions(suggestions)
    if not suggestions or table.getn(suggestions) == 0 then return end
    
    for _, suggestion in ipairs(suggestions) do
        self:AddSuggestion(suggestion)
    end
    
    -- Update UI
    self:UpdateSuggestionDisplay()
end

function StrategicSuggestions:AddSuggestion(suggestion)
    if not suggestion or not suggestion.message then return end
    
    -- Check cooldown
    local suggestionKey = suggestion.message
    if self.suggestionCooldowns[suggestionKey] then
        if GetTime() - self.suggestionCooldowns[suggestionKey] < 5 then
            return -- Still on cooldown
        end
    end
    
    -- Convert priority string to number
    local priorityValue = self.PRIORITY_MEDIUM
    if suggestion.priority == "critical" then
        priorityValue = self.PRIORITY_CRITICAL
    elseif suggestion.priority == "high" then
        priorityValue = self.PRIORITY_HIGH
    elseif suggestion.priority == "medium" then
        priorityValue = self.PRIORITY_MEDIUM
    elseif suggestion.priority == "low" then
        priorityValue = self.PRIORITY_LOW
    end
    
    -- Create suggestion object
    local newSuggestion = {
        id = GetTime(),
        type = suggestion.type or "general",
        priority = priorityValue,
        message = suggestion.message,
        icon = suggestion.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
        timestamp = GetTime(),
        duration = suggestion.duration or 5
    }
    
    -- Add to active suggestions
    table.insert(self.activeSuggestions, newSuggestion)
    
    -- Sort by priority
    table.sort(self.activeSuggestions, function(a, b)
        return a.priority > b.priority
    end)
    
    -- Limit active suggestions
    while table.getn(self.activeSuggestions) > self.maxActiveSuggestions do
        table.remove(self.activeSuggestions)
    end
    
    -- Set cooldown
    self.suggestionCooldowns[suggestionKey] = GetTime()
    
    -- Add to history
    table.insert(self.suggestionHistory, newSuggestion)
    if table.getn(self.suggestionHistory) > 50 then
        table.remove(self.suggestionHistory, 1)
    end
    
    -- Broadcast to squad if high priority
    if priorityValue >= self.PRIORITY_HIGH and TerrorSquadAI.DB.syncEnabled then
        if TerrorSquadAI.Modules.CommunicationSync then
            TerrorSquadAI.Modules.CommunicationSync:BroadcastSuggestion(newSuggestion)
        end
    end
    
    -- Show alert for critical and high priority suggestions
    if priorityValue >= self.PRIORITY_HIGH then
        if TerrorSquadAI.Modules.AlertSystem then
            local alertType = "critical"
            if priorityValue == self.PRIORITY_HIGH then
                alertType = "warning"
            end
            TerrorSquadAI.Modules.AlertSystem:ShowAlert({
                type = alertType,
                message = suggestion.message,
                duration = 3,
                sound = true
            })
        end
    end
end

function StrategicSuggestions:UpdateSuggestionDisplay()
    -- Remove expired suggestions
    local currentTime = GetTime()
    local i = 1
    while i <= table.getn(self.activeSuggestions) do
        local suggestion = self.activeSuggestions[i]
        if currentTime - suggestion.timestamp > suggestion.duration then
            table.remove(self.activeSuggestions, i)
        else
            i = i + 1
        end
    end
    
    -- Update UI module
    if TerrorSquadAI.Modules.UI then
        TerrorSquadAI.Modules.UI:UpdateSuggestions(self.activeSuggestions)
    end
end

function StrategicSuggestions:GeneratePvPSuggestions()
    local suggestions = {}
    
    if not TerrorSquadAI.Modules.AIEngine then return suggestions end
    local aiEngine = TerrorSquadAI.Modules.AIEngine
    
    if not aiEngine:IsInCombat() then return suggestions end
    
    -- Analyze target
    if UnitExists("target") and UnitIsEnemy("player", "target") and UnitIsPlayer("target") then
        local targetHealth = UnitHealth("target") / UnitHealthMax("target")
        local targetClass = UnitClass("target")
        
        -- Low health target
        if targetHealth < 0.3 then
            table.insert(suggestions, {
                type = "tactical",
                priority = "high",
                message = "¡Rango de ejecución - remata al objetivo!",
                icon = "Interface\\Icons\\Ability_Warrior_Execute"
            })
        end
        
        -- Class-specific suggestions
        if targetClass == "PRIEST" or targetClass == "MAGE" or targetClass == "WARLOCK" then
            table.insert(suggestions, {
                type = "tactical",
                priority = "medium",
                message = "Objetivo caster prioritario - interrumpe hechizos",
                icon = "Interface\\Icons\\Spell_Frost_IceShock"
            })
        end
    end
    
    -- Check for nearby enemies
    local threatAnalysis = TerrorSquadAI.Modules.ThreatAnalysis
    if threatAnalysis then
        local priorityTargets = threatAnalysis:GetPriorityTargets()
        if priorityTargets and table.getn(priorityTargets) >= 3 then
            table.insert(suggestions, {
                type = "tactical",
                priority = "high",
                message = "Múltiples enemigos - usa habilidades de área",
                icon = "Interface\\Icons\\Spell_Fire_SelfDestruct"
            })
        end
    end
    
    -- Check player resources
    local playerHealth = UnitHealth("player") / UnitHealthMax("player")
    if playerHealth < 0.4 then
        table.insert(suggestions, {
            type = "defensive",
            priority = "critical",
            message = "Vida baja - usa defensivas o retírate",
            icon = "Interface\\Icons\\Spell_Holy_PowerWordShield"
        })
    end
    
    return suggestions
end

function StrategicSuggestions:GeneratePvESuggestions()
    local suggestions = {}
    
    if not TerrorSquadAI.Modules.AIEngine then return suggestions end
    local aiEngine = TerrorSquadAI.Modules.AIEngine
    
    if not aiEngine:IsInCombat() then return suggestions end
    
    -- Check for boss mechanics (simplified)
    if UnitExists("target") and UnitIsEnemy("player", "target") then
        local classification = UnitClassification("target")
        
        if classification == "worldboss" or classification == "rareelite" then
            -- Boss fight suggestions
            table.insert(suggestions, {
                type = "tactical",
                priority = "high",
                message = "Encuentro con jefe - sigue las mecánicas",
                icon = "Interface\\Icons\\Spell_Shadow_Skull"
            })
        end
    end
    
    -- Check group health
    local lowHealthAllies = 0
    if GetNumRaidMembers() > 0 then
        for i = 1, 40 do
            local unit = "raid" .. i
            if UnitExists(unit) and not UnitIsDead(unit) then
                local health = UnitHealth(unit) / UnitHealthMax(unit)
                if health < 0.4 then
                    lowHealthAllies = lowHealthAllies + 1
                end
            end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) then
                local health = UnitHealth(unit) / UnitHealthMax(unit)
                if health < 0.4 then
                    lowHealthAllies = lowHealthAllies + 1
                end
            end
        end
    end
    
    if lowHealthAllies >= 2 then
        table.insert(suggestions, {
            type = "support",
            priority = "high",
            message = "Múltiples aliados heridos - se necesita curación de grupo",
            icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing"
        })
    end
    
    return suggestions
end

function StrategicSuggestions:GenerateCoordinationSuggestions()
    local suggestions = {}
    
    -- Check if in group
    local inGroup = GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0
    if not inGroup then return suggestions end
    
    -- Get predictive analysis
    if TerrorSquadAI.Modules.PredictiveSystem then
        local predictions = TerrorSquadAI.Modules.PredictiveSystem:GetPredictions()
        
        if predictions and predictions.optimalStrategy then
            local strategy = predictions.optimalStrategy
            
            if strategy.approach == "aggressive" then
                table.insert(suggestions, {
                    type = "coordination",
                    priority = "medium",
                    message = "Ventana óptima - coordina daño explosivo",
                    icon = "Interface\\Icons\\Ability_Warrior_BattleShout"
                })
            elseif strategy.approach == "defensive" then
                table.insert(suggestions, {
                    type = "coordination",
                    priority = "high",
                    message = "Postura defensiva - coordina enfriamientos",
                    icon = "Interface\\Icons\\Ability_Defend"
                })
            end
        end
        
        if predictions and predictions.squadSynergy then
            local synergy = predictions.squadSynergy
            if synergy.synergyScore < 0.5 then
                table.insert(suggestions, {
                    type = "coordination",
                    priority = "low",
                    message = "Composición subóptima - adapta estrategia",
                    icon = "Interface\\Icons\\INV_Misc_GroupLooking"
                })
            end
        end
    end
    
    return suggestions
end

function StrategicSuggestions:GetActiveSuggestions()
    return self.activeSuggestions
end

function StrategicSuggestions:GetSuggestionHistory()
    return self.suggestionHistory
end

function StrategicSuggestions:ClearSuggestions()
    self.activeSuggestions = {}
    self:UpdateSuggestionDisplay()
end
