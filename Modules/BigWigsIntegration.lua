-- TerrorSquadAI BigWigs Integration Module
-- Bidirectional integration with BigWigs for real-time boss data
-- Author: DarckRovert (elnazzareno)

local BigWigsIntegration = {}
TerrorSquadAI:RegisterModule("BigWigsIntegration", BigWigsIntegration)

-- BigWigs state
BigWigsIntegration.bigWigsLoaded = false
BigWigsIntegration.activeModule = nil
BigWigsIntegration.bossAbilities = {}
BigWigsIntegration.timers = {}
BigWigsIntegration.bars = {}

function BigWigsIntegration:Initialize()
    -- Check if BigWigs is loaded
    if BigWigs then
        self.bigWigsLoaded = true
        TerrorSquadAI:Debug("BigWigs detected - initializing integration")
        self:SetupHooks()
    else
        TerrorSquadAI:Debug("BigWigs not detected - integration disabled")
        self.bigWigsLoaded = false
    end
    
    -- Register for BigWigs events
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("ADDON_LOADED")
    
    self.eventFrame:SetScript("OnEvent", function()
        if event == "ADDON_LOADED" and arg1 == "BigWigs" then
            BigWigsIntegration.bigWigsLoaded = true
            BigWigsIntegration:SetupHooks()
            TerrorSquadAI:Debug("BigWigs loaded - integration active")
        end
    end)
end

function BigWigsIntegration:SetupHooks()
    if not self.bigWigsLoaded or not BigWigs then return end
    
    -- Hook into BigWigs message system
    if BigWigs.RegisterMessage then
        -- BigWigs 2.0 style
        BigWigs:RegisterMessage("BigWigs_Message", function(...)
            BigWigsIntegration:OnBigWigsMessage(arg1, arg2, arg3, arg4)
        end)
        
        BigWigs:RegisterMessage("BigWigs_StartBar", function(...)
            BigWigsIntegration:OnBigWigsStartBar(arg1, arg2, arg3, arg4)
        end)
        
        BigWigs:RegisterMessage("BigWigs_StopBar", function(...)
            BigWigsIntegration:OnBigWigsStopBar(arg1, arg2)
        end)
    end
    
    TerrorSquadAI:Debug("BigWigs hooks established")
end

-- Method called by TerrorLink plugin
function BigWigsIntegration:ReceiveExternalData(data)
    if not data then return end
    
    -- Handle message types
    if data.type == "message" then
        self:OnBigWigsMessage(nil, nil, data.text, data.priority == "critical" and "Urgent" or "Attention")
    elseif data.type == "timer_start" then
        self:OnBigWigsStartBar(nil, nil, data.text, data.duration)
    elseif data.type == "timer_stop" then
        self:OnBigWigsStopBar(nil, nil, data.text)
    elseif data.type == "boss_death" then
        -- Handle boss death logic if needed
    end
end

function BigWigsIntegration:OnBigWigsMessage(module, key, text, color)
    if not TerrorSquadAI.DB.bigWigsIntegration then return end
    
    -- Process BigWigs message
    local messageData = {
        module = module,
        key = key,
        text = text,
        color = color,
        timestamp = GetTime()
    }
    
    -- Analyze message for AI
    self:AnalyzeBossAbility(messageData)
    
    -- Send to alert system if critical
    if self:IsCriticalAbility(key) then
        if TerrorSquadAI.Modules.AlertSystem then
            TerrorSquadAI.Modules.AlertSystem:ShowAlert({
                type = "critical",
                message = text,
                duration = 4,
                sound = true,
                source = "BigWigs"
            })
        end
    end
    
    -- Generate strategic suggestions
    local suggestions = self:GenerateSuggestionsFromAbility(key, text)
    if suggestions and TerrorSquadAI.Modules.StrategicSuggestions then
        TerrorSquadAI.Modules.StrategicSuggestions:ProcessSuggestions(suggestions)
    end
end

function BigWigsIntegration:OnBigWigsStartBar(module, key, text, time)
    if not TerrorSquadAI.DB.bigWigsIntegration then return end
    
    -- Track timer
    local timerData = {
        module = module,
        key = key,
        text = text,
        duration = time,
        startTime = GetTime(),
        endTime = GetTime() + time
    }
    
    self.timers[key] = timerData
    self.bars[key] = timerData
    
    -- Notify predictive system
    if TerrorSquadAI.Modules.PredictiveSystem then
        TerrorSquadAI.Modules.PredictiveSystem:TrackEnemyAbility("boss", key)
    end
    
    -- Sync with squad
    if TerrorSquadAI.Modules.CommunicationSync and TerrorSquadAI.DB.syncEnabled then
        TerrorSquadAI.Modules.CommunicationSync:BroadcastBossTimer(timerData)
    end
end

function BigWigsIntegration:OnBigWigsStopBar(module, key)
    if not TerrorSquadAI.DB.bigWigsIntegration then return end
    if not key then return end
    
    -- Remove timer
    self.timers[key] = nil
    self.bars[key] = nil
end

function BigWigsIntegration:AnalyzeBossAbility(messageData)
    if not messageData or not messageData.key then return end
    
    -- Store ability data
    if not self.bossAbilities[messageData.key] then
        self.bossAbilities[messageData.key] = {
            count = 0,
            lastSeen = 0,
            avgInterval = 0,
            occurrences = {}
        }
    end
    
    local ability = self.bossAbilities[messageData.key]
    ability.count = ability.count + 1
    
    -- Calculate interval
    if ability.lastSeen > 0 then
        local interval = GetTime() - ability.lastSeen
        ability.avgInterval = ((ability.avgInterval * (ability.count - 1)) + interval) / ability.count
    end
    
    ability.lastSeen = GetTime()
    table.insert(ability.occurrences, GetTime())
    
    -- Limit occurrence history
    if table.getn(ability.occurrences) > 20 then
        table.remove(ability.occurrences, 1)
    end
end

function BigWigsIntegration:IsCriticalAbility(key)
    if not key then return false end
    
    local criticalKeywords = {
        "enrage", "wipe", "death", "bomb", "explosion",
        "meteor", "flame", "frost", "shadow", "arcane",
        "charge", "fear", "stun", "silence", "interrupt"
    }
    
    local lowerKey = string.lower(key)
    for _, keyword in ipairs(criticalKeywords) do
        if string.find(lowerKey, keyword) then
            return true
        end
    end
    
    return false
end

function BigWigsIntegration:GenerateSuggestionsFromAbility(key, text)
    if not key then return nil end
    
    local suggestions = {}
    local lowerKey = string.lower(key)
    local lowerText = string.lower(text or "")
    
    -- AoE abilities
    if string.find(lowerKey, "aoe") or string.find(lowerText, "spread") then
        table.insert(suggestions, {
            type = "tactical",
            priority = "high",
            message = "¡DISPERSÁRENSE! - Habilidad de área",
            icon = "Interface\\Icons\\Spell_Fire_SelfDestruct"
        })
    end
    
    -- Stack mechanics
    if string.find(lowerText, "stack") or string.find(lowerText, "group") then
        table.insert(suggestions, {
            type = "tactical",
            priority = "high",
            message = "¡AGRÚPENSE! - Mecánica de grupo",
            icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing"
        })
    end
    
    -- Interrupt mechanics
    if string.find(lowerKey, "cast") or string.find(lowerKey, "channel") then
        table.insert(suggestions, {
            type = "tactical",
            priority = "high",
            message = "¡INTERRUMPIR! - Casteo importante",
            icon = "Interface\\Icons\\Spell_Frost_IceShock"
        })
    end
    
    -- Defensive mechanics
    if string.find(lowerKey, "enrage") or string.find(lowerKey, "damage") then
        table.insert(suggestions, {
            type = "defensive",
            priority = "high",
            message = "¡DEFENSIVAS! - Daño alto entrante",
            icon = "Interface\\Icons\\Spell_Holy_PowerWordShield"
        })
    end
    
    -- Burst window
    if string.find(lowerKey, "vulnerable") or string.find(lowerText, "burn") then
        table.insert(suggestions, {
            type = "offensive",
            priority = "medium",
            message = "¡ATAQUEN! - Jefe vulnerable",
            icon = "Interface\\Icons\\Ability_Warrior_BattleShout"
        })
    end
    
    return table.getn(suggestions) > 0 and suggestions or nil
end

function BigWigsIntegration:GetActiveTimers()
    return self.timers
end

function BigWigsIntegration:GetActiveBars()
    return self.bars
end

function BigWigsIntegration:GetBossAbilities()
    return self.bossAbilities
end

function BigWigsIntegration:PredictNextAbility()
    -- Predict next boss ability based on patterns
    local predictions = {}
    
    for key, ability in pairs(self.bossAbilities) do
        if ability.avgInterval > 0 and ability.lastSeen > 0 then
            local timeSinceLast = GetTime() - ability.lastSeen
            local expectedIn = ability.avgInterval - timeSinceLast
            
            if expectedIn > 0 and expectedIn < 10 then
                table.insert(predictions, {
                    ability = key,
                    expectedIn = expectedIn,
                    confidence = math.min(ability.count / 10, 1.0)
                })
            end
        end
    end
    
    -- Sort by expected time
    table.sort(predictions, function(a, b)
        return a.expectedIn < b.expectedIn
    end)
    
    return predictions
end

function BigWigsIntegration:SendDataToBigWigs(data)
    -- Send data back to BigWigs (if API allows)
    if not self.bigWigsLoaded or not BigWigs then return false end
    
    -- This would require BigWigs API support
    -- Placeholder for bidirectional communication
    
    return true
end

function BigWigsIntegration:IsActive()
    return self.bigWigsLoaded and TerrorSquadAI.DB.bigWigsIntegration
end
