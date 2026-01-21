-- TerrorSquadAI Predictive System Module
-- Machine learning-inspired predictive combat analysis
-- Author: DarckRovert (elnazzareno)

local PredictiveSystem = {}
TerrorSquadAI:RegisterModule("PredictiveSystem", PredictiveSystem)

-- Prediction models
PredictiveSystem.combatPatterns = {}
PredictiveSystem.enemyBehaviors = {}
PredictiveSystem.outcomeHistory = {}
PredictiveSystem.predictions = {}

-- Learning parameters
PredictiveSystem.learningRate = 0.1
PredictiveSystem.confidenceThreshold = 0.6

function PredictiveSystem:Initialize()
    self.combatPatterns = {}
    self.enemyBehaviors = {}
    self.predictions = {}
    
    -- Load historical data
    if TerrorSquadAI.CharDB.combatStats then
        self:LearnFromHistory(TerrorSquadAI.CharDB.combatStats)
    end
    
    TerrorSquadAI:Debug("PredictiveSystem initialized")
end

function PredictiveSystem:LearnFromHistory(combatHistory)
    -- Analyze past combats to identify patterns
    for _, combat in ipairs(combatHistory) do
        self:AnalyzeCombatPattern(combat)
    end
    
    TerrorSquadAI:Debug("Learned from " .. table.getn(combatHistory) .. " combat records")
end

function PredictiveSystem:AnalyzeCombatPattern(combat)
    if not combat or not combat.scenario then return end
    
    local scenario = combat.scenario
    local duration = combat.duration or 0
    local threatLevel = combat.threatLevel or 0
    
    -- Create pattern signature
    local patternKey = scenario .. "_" .. math.floor(threatLevel)
    
    if not self.combatPatterns[patternKey] then
        self.combatPatterns[patternKey] = {
            count = 0,
            avgDuration = 0,
            avgThreat = 0,
            outcomes = {
                victory = 0,
                defeat = 0,
                retreat = 0
            }
        }
    end
    
    local pattern = self.combatPatterns[patternKey]
    pattern.count = pattern.count + 1
    
    -- Update averages
    pattern.avgDuration = ((pattern.avgDuration * (pattern.count - 1)) + duration) / pattern.count
    pattern.avgThreat = ((pattern.avgThreat * (pattern.count - 1)) + threatLevel) / pattern.count
    
    -- Determine outcome (simplified)
    if combat.data and combat.data.deaths then
        if combat.data.deaths > 0 then
            pattern.outcomes.defeat = pattern.outcomes.defeat + 1
        else
            pattern.outcomes.victory = pattern.outcomes.victory + 1
        end
    end
end

function PredictiveSystem:PredictCombatOutcome()
    if not TerrorSquadAI.Modules.AIEngine then return nil end
    
    local aiEngine = TerrorSquadAI.Modules.AIEngine
    if not aiEngine:IsInCombat() then return nil end
    
    local scenario = aiEngine:GetCurrentScenario()
    local threatLevel = aiEngine:GetThreatLevel()
    
    local patternKey = scenario .. "_" .. math.floor(threatLevel)
    local pattern = self.combatPatterns[patternKey]
    
    if not pattern or pattern.count < 3 then
        -- Not enough data
        return {
            outcome = "unknown",
            confidence = 0,
            estimatedDuration = 0
        }
    end
    
    -- Calculate win probability
    local totalOutcomes = pattern.outcomes.victory + pattern.outcomes.defeat + pattern.outcomes.retreat
    local winProbability = pattern.outcomes.victory / totalOutcomes
    
    local predictedOutcome
    if winProbability > 0.6 then
        predictedOutcome = "victory"
    elseif winProbability < 0.4 then
        predictedOutcome = "defeat"
    else
        predictedOutcome = "uncertain"
    end
    
    return {
        outcome = predictedOutcome,
        confidence = math.abs(winProbability - 0.5) * 2, -- 0 to 1 scale
        estimatedDuration = pattern.avgDuration,
        winProbability = winProbability
    }
end

function PredictiveSystem:PredictEnemyAction(enemyGUID)
    if not self.enemyBehaviors[enemyGUID] then
        return nil
    end
    
    local behavior = self.enemyBehaviors[enemyGUID]
    local currentTime = GetTime()
    
    -- Predict next ability based on patterns
    if behavior.abilitySequence and table.getn(behavior.abilitySequence) > 0 then
        local lastAbility = behavior.abilitySequence[table.getn(behavior.abilitySequence)]
        local timeSinceLast = currentTime - lastAbility.time
        
        -- Find common follow-up abilities
        local predictions = {}
        for i = 1, table.getn(behavior.abilitySequence) - 1 do
            if behavior.abilitySequence[i].name == lastAbility.name then
                local nextAbility = behavior.abilitySequence[i + 1]
                if not predictions[nextAbility.name] then
                    predictions[nextAbility.name] = {
                        count = 0,
                        avgDelay = 0
                    }
                end
                predictions[nextAbility.name].count = predictions[nextAbility.name].count + 1
            end
        end
        
        -- Return most likely prediction
        local bestPrediction = nil
        local maxCount = 0
        for abilityName, data in pairs(predictions) do
            if data.count > maxCount then
                maxCount = data.count
                bestPrediction = abilityName
            end
        end
        
        if bestPrediction then
            return {
                ability = bestPrediction,
                confidence = maxCount / table.getn(behavior.abilitySequence)
            }
        end
    end
    
    return nil
end

function PredictiveSystem:TrackEnemyAbility(enemyGUID, abilityName)
    if not self.enemyBehaviors[enemyGUID] then
        self.enemyBehaviors[enemyGUID] = {
            abilitySequence = {},
            abilityCounts = {}
        }
    end
    
    local behavior = self.enemyBehaviors[enemyGUID]
    
    -- Add to sequence
    table.insert(behavior.abilitySequence, {
        name = abilityName,
        time = GetTime()
    })
    
    -- Update counts
    if not behavior.abilityCounts[abilityName] then
        behavior.abilityCounts[abilityName] = 0
    end
    behavior.abilityCounts[abilityName] = behavior.abilityCounts[abilityName] + 1
    
    -- COOLDOWN TRACKING (New in Phase 6)
    if not behavior.abilityCooldowns then behavior.abilityCooldowns = {} end
    
    if behavior.abilityCooldowns[abilityName] then
        local lastTime = behavior.abilityCooldowns[abilityName].lastTime
        local interval = GetTime() - lastTime
        
        -- Filter out spam (< 2s)
        if interval > 2 then
            local data = behavior.abilityCooldowns[abilityName]
            -- Weighted moving average for cooldown estimation
            if data.detectedCD == 0 then
                data.detectedCD = interval
            else
                data.detectedCD = (data.detectedCD * 0.7) + (interval * 0.3)
            end
        end
        behavior.abilityCooldowns[abilityName].lastTime = GetTime()
    else
        behavior.abilityCooldowns[abilityName] = {
            lastTime = GetTime(),
            detectedCD = 0
        }
    end

    -- Limit sequence size
    if table.getn(behavior.abilitySequence) > 50 then
        table.remove(behavior.abilitySequence, 1)
    end
end

-- New function: Get Probability of Ability coming soon (0-1)
function PredictiveSystem:GetAbilityLikelihood(enemyGUID, abilityName)
    if not self.enemyBehaviors[enemyGUID] or not self.enemyBehaviors[enemyGUID].abilityCooldowns then return 0 end
    
    local data = self.enemyBehaviors[enemyGUID].abilityCooldowns[abilityName]
    if not data or data.detectedCD == 0 then return 0 end
    
    local timeSince = GetTime() - data.lastTime
    
    -- If time since last usage is close to detected CD, likelihood increases
    if timeSince >= data.detectedCD then
        return 1.0 -- Ready!
    elseif timeSince >= (data.detectedCD * 0.8) then
        return 0.8 -- Coming soon
    else
        return 0.1 -- On CD
    end

end

function PredictiveSystem:PredictOptimalStrategy()
    if not TerrorSquadAI.Modules.AIEngine then return nil end
    
    local aiEngine = TerrorSquadAI.Modules.AIEngine
    local scenario = aiEngine:GetCurrentScenario()
    local threatLevel = aiEngine:GetThreatLevel()
    
    -- Get combat outcome prediction
    local outcomePrediction = self:PredictCombatOutcome()
    
    if not outcomePrediction then return nil end
    
    local strategy = {
        approach = "balanced",
        priority = "damage",
        formation = "spread",
        confidence = outcomePrediction.confidence
    }
    
    -- Adjust strategy based on prediction
    if outcomePrediction.outcome == "defeat" and outcomePrediction.confidence > self.confidenceThreshold then
        strategy.approach = "defensive"
        strategy.priority = "survival"
        strategy.formation = "tight"
    elseif outcomePrediction.outcome == "victory" and outcomePrediction.confidence > self.confidenceThreshold then
        strategy.approach = "aggressive"
        strategy.priority = "damage"
        strategy.formation = "spread"
    end
    
    -- Adjust for scenario type
    if scenario == aiEngine.SCENARIO_PVP_SKIRMISH or scenario == aiEngine.SCENARIO_WORLD_PVP then
        strategy.priority = "control"
        strategy.formation = "mobile"
    elseif scenario == aiEngine.SCENARIO_BOSS_FIGHT then
        strategy.priority = "mechanics"
        strategy.formation = "organized"
    end
    
    -- Factor in user preferences
    if TerrorSquadAI.DB.strategicPreferences then
        local prefs = TerrorSquadAI.DB.strategicPreferences
        if prefs.aggressiveness > 0.7 then
            strategy.approach = "aggressive"
        elseif prefs.defensiveness > 0.7 then
            strategy.approach = "defensive"
        end
    end
    
    return strategy
end

function PredictiveSystem:AnalyzeSquadSynergy()
    -- Analyze party/raid composition for synergy predictions
    local composition = {
        tanks = 0,
        healers = 0,
        dps = 0,
        classes = {}
    }
    
    local groupSize = GetNumRaidMembers()
    local isRaid = groupSize > 0
    
    if not isRaid then
        groupSize = GetNumPartyMembers()
    end
    
    if groupSize == 0 then
        return nil -- Solo
    end
    
    -- Analyze group composition
    for i = 1, groupSize do
        local unit = isRaid and ("raid" .. i) or ("party" .. i)
        if UnitExists(unit) then
            local _, class = UnitClass(unit)
            
            if not composition.classes[class] then
                composition.classes[class] = 0
            end
            composition.classes[class] = composition.classes[class] + 1
            
            -- Simplified role detection
            if class == "WARRIOR" or class == "DRUID" then
                composition.tanks = composition.tanks + 0.5
            end
            if class == "PRIEST" or class == "DRUID" or class == "PALADIN" or class == "SHAMAN" then
                composition.healers = composition.healers + 0.5
            end
            composition.dps = composition.dps + 1
        end
    end
    
    -- Calculate synergy score (0-1)
    local synergyScore = 0.5
    
    -- Balanced composition bonus
    if composition.tanks >= 1 and composition.healers >= 1 and composition.dps >= 2 then
        synergyScore = synergyScore + 0.2
    end
    
    -- Class diversity bonus
    local classCount = 0
    for _ in pairs(composition.classes) do
        classCount = classCount + 1
    end
    synergyScore = synergyScore + (classCount * 0.05)
    
    -- Cap at 1.0
    if synergyScore > 1.0 then
        synergyScore = 1.0
    end
    
    return {
        composition = composition,
        synergyScore = synergyScore,
        recommendation = synergyScore > 0.7 and "excellent" or (synergyScore > 0.5 and "good" or "suboptimal")
    }
end

function PredictiveSystem:GetPredictions()
    return {
        combatOutcome = self:PredictCombatOutcome(),
        optimalStrategy = self:PredictOptimalStrategy(),
        squadSynergy = self:AnalyzeSquadSynergy()
    }
end
