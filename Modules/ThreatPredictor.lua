-- ThreatPredictor.lua - Predictor de Amenaza

local TP = {}
TerrorSquadAI:RegisterModule("ThreatPredictor", TP)

-- Helper para identificar unidades (WoW 1.12 no tiene UnitGUID)
local function GetUnitID(unit)
    if not UnitExists(unit) then return nil end
    local name = UnitName(unit)
    local level = UnitLevel(unit)
    return name .. ":" .. level
end

-- Estado
TP.threatHistory = {}
TP.currentThreat = 0
TP.predictedThreat = 0
TP.lastUpdate = 0
TP.updateInterval = 1
TP.maxHistorySize = 30

-- Configuración
TP.config = {
    enabled = true,
    showPredictions = true,
    warnHighThreat = true,
    threatThreshold = 80,
}

-- Factores de amenaza
local THREAT_FACTORS = {
    -- Enemigos
    enemyCount = 10,
    enemyElite = 15,
    enemyBoss = 25,
    enemyPlayer = 20,
    
    -- Salud
    lowHealth = 15,
    criticalHealth = 25,
    
    -- Situación
    outnumbered = 20,
    surrounded = 15,
    noHealer = 10,
    
    -- Buffs/Debuffs
    dangerousDebuff = 10,
    lostBuff = 5,
}

function TP:Initialize()
    self:RegisterEvents()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r ThreatPredictor inicializado", 1, 0.84, 0)
end

function TP:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_REGEN_DISABLED" then
            TP:OnEnterCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            TP:OnLeaveCombat()
        elseif event == "UNIT_HEALTH" then
            TP:OnHealthChange(arg1)
        elseif event == "PLAYER_TARGET_CHANGED" then
            TP:OnTargetChanged()
        end
    end)
    
    -- Timer de actualización
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        local now = GetTime()
        if now - TP.lastUpdate >= TP.updateInterval then
            TP:Update()
            TP.lastUpdate = now
        end
    end)
end

function TP:Update()
    if not self.config.enabled then return end
    if not UnitAffectingCombat("player") then return end
    
    self:CalculateThreat()
    self:PredictThreat()
    self:RecordHistory()
    self:CheckThreatLevel()
end

function TP:CalculateThreat()
    local threat = 0
    
    -- Factor 1: Salud del jugador
    local maxHP = UnitHealthMax("player")
    local healthPct = 100
    if maxHP and maxHP > 0 then
        healthPct = (UnitHealth("player") / maxHP) * 100
    end
    if healthPct < 20 then
        threat = threat + THREAT_FACTORS.criticalHealth
    elseif healthPct < 40 then
        threat = threat + THREAT_FACTORS.lowHealth
    end
    
    -- Factor 2: Enemigos cercanos (aproximación)
    local enemyCount = self:EstimateNearbyEnemies()
    threat = threat + (enemyCount * THREAT_FACTORS.enemyCount)
    
    -- Factor 3: Tipo de objetivo
    if UnitExists("target") and UnitCanAttack("player", "target") then
        if UnitIsPlayer("target") then
            threat = threat + THREAT_FACTORS.enemyPlayer
        else
            local classification = UnitClassification("target")
            if classification == "worldboss" then
                threat = threat + THREAT_FACTORS.enemyBoss
            elseif classification == "elite" or classification == "rareelite" then
                threat = threat + THREAT_FACTORS.enemyElite
            end
        end
    end
    
    -- Factor 4: Salud del grupo
    if TerrorSquadAI.Modules.ResourceMonitor then
        local avgHealth = TerrorSquadAI.Modules.ResourceMonitor:GetAverageHealth()
        if avgHealth < 40 then
            threat = threat + 15
        elseif avgHealth < 60 then
            threat = threat + 8
        end
    end
    
    -- Factor 5: Mana del grupo (healers)
    if TerrorSquadAI.Modules.ResourceMonitor then
        local avgMana = TerrorSquadAI.Modules.ResourceMonitor:GetAverageMana()
        if avgMana < 20 then
            threat = threat + THREAT_FACTORS.noHealer
        end
    end
    
    -- Normalizar a 0-100
    self.currentThreat = math.min(100, threat)
end

function TP:EstimateNearbyEnemies()
    -- En Vanilla no hay forma directa de contar enemigos
    -- Usamos heurísticas basadas en targets del grupo
    local enemies = {}
    
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            local unit = "raid" .. i .. "target"
            if UnitExists(unit) and UnitCanAttack("player", unit) then
                local unitID = GetUnitID(unit)
                if unitID and not enemies[unitID] then
                    enemies[unitID] = true
                end
            end
        end
    else
        local numParty = GetNumPartyMembers()
        for i = 1, numParty do
            local unit = "party" .. i .. "target"
            if UnitExists(unit) and UnitCanAttack("player", unit) then
                local unitID = GetUnitID(unit)
                if unitID and not enemies[unitID] then
                    enemies[unitID] = true
                end
            end
        end
    end
    
    -- Contar enemigos únicos
    local count = 0
    for _ in pairs(enemies) do
        count = count + 1
    end
    
    return count
end

function TP:PredictThreat()
    if table.getn(self.threatHistory) < 3 then
        self.predictedThreat = self.currentThreat
        return
    end
    
    -- Calcular tendencia usando los últimos 5 puntos
    local recentHistory = {}
    local startIdx = math.max(1, table.getn(self.threatHistory) - 4)
    for i = startIdx, table.getn(self.threatHistory) do
        table.insert(recentHistory, self.threatHistory[i].threat)
    end
    
    -- Calcular promedio de cambio
    local totalChange = 0
    for i = 2, table.getn(recentHistory) do
        totalChange = totalChange + (recentHistory[i] - recentHistory[i-1])
    end
    
    local avgChange = totalChange / (table.getn(recentHistory) - 1)
    
    -- Predecir amenaza en los próximos 5 segundos
    self.predictedThreat = math.max(0, math.min(100, self.currentThreat + (avgChange * 5)))
end

function TP:RecordHistory()
    table.insert(self.threatHistory, {
        time = GetTime(),
        threat = self.currentThreat,
    })
    
    -- Mantener tamaño máximo
    while table.getn(self.threatHistory) > self.maxHistorySize do
        table.remove(self.threatHistory, 1)
    end
end

function TP:CheckThreatLevel()
    if not self.config.warnHighThreat then return end
    
    if self.currentThreat >= self.config.threatThreshold then
        self:WarnHighThreat()
    end
    
    -- Advertir si la amenaza está aumentando rápidamente
    if self.predictedThreat > self.currentThreat + 20 then
        self:WarnIncreasingThreat()
    end
end

function TP:WarnHighThreat()
    local now = GetTime()
    local lastWarn = self.lastHighThreatWarn or 0
    
    if now - lastWarn < 10 then return end
    
    self.lastHighThreatWarn = now
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Amenaza]|r ¡NIVEL DE AMENAZA ALTO! (" .. math.floor(self.currentThreat) .. "%)", 1, 0, 0)
    
    -- Sugerir acción
    if self.currentThreat >= 90 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Amenaza]|r Sugerencia: Considerar retirada", 1, 0, 0)
    elseif self.currentThreat >= 80 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[Amenaza]|r Sugerencia: Jugar defensivo", 1, 0.5, 0)
    end
end

function TP:WarnIncreasingThreat()
    local now = GetTime()
    local lastWarn = self.lastIncreasingWarn or 0
    
    if now - lastWarn < 15 then return end
    
    self.lastIncreasingWarn = now
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[Amenaza]|r La amenaza está aumentando rápidamente", 1, 0.5, 0)
end

function TP:OnEnterCombat()
    self.threatHistory = {}
    self:CalculateThreat()
end

function TP:OnLeaveCombat()
    self.currentThreat = 0
    self.predictedThreat = 0
end

function TP:OnHealthChange(unit)
    if unit == "player" then
        -- Recalcular amenaza cuando cambia la salud
        if UnitAffectingCombat("player") then
            self:CalculateThreat()
        end
    end
end

function TP:OnTargetChanged()
    if UnitAffectingCombat("player") then
        self:CalculateThreat()
    end
end

function TP:GetCurrentThreat()
    return self.currentThreat
end

function TP:GetPredictedThreat()
    return self.predictedThreat
end

function TP:GetThreatLevel()
    if self.currentThreat < 30 then
        return "BAJO", {0, 1, 0}
    elseif self.currentThreat < 60 then
        return "MEDIO", {1, 1, 0}
    elseif self.currentThreat < 80 then
        return "ALTO", {1, 0.5, 0}
    else
        return "CRÍTICO", {1, 0, 0}
    end
end

function TP:GetThreatTrend()
    if table.getn(self.threatHistory) < 2 then
        return "ESTABLE"
    end
    
    local recent = self.threatHistory[table.getn(self.threatHistory)].threat
    local previous = self.threatHistory[table.getn(self.threatHistory) - 1].threat
    local diff = recent - previous
    
    if diff > 5 then
        return "AUMENTANDO"
    elseif diff < -5 then
        return "DISMINUYENDO"
    else
        return "ESTABLE"
    end
end

function TP:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Threat Predictor Status ===", 1, 0.84, 0)
    
    local level, color = self:GetThreatLevel()
    local trend = self:GetThreatTrend()
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Amenaza Actual: %.0f%%", self.currentThreat), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Nivel: " .. level, unpack(color))
    DEFAULT_CHAT_FRAME:AddMessage("Tendencia: " .. trend, 1, 1, 1)
    
    if self.config.showPredictions then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Predicción (5s): %.0f%%", self.predictedThreat), 1, 1, 1)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("\nHistorial: " .. table.getn(self.threatHistory) .. " puntos", 1, 1, 1)
end

function TP:PrintHistory()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Historial de Amenaza ===", 1, 0.84, 0)
    
    if table.getn(self.threatHistory) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Sin datos", 1, 0.5, 0.5)
        return
    end
    
    local now = GetTime()
    local count = math.min(10, table.getn(self.threatHistory))
    local startIdx = table.getn(self.threatHistory) - count + 1
    
    for i = startIdx, table.getn(self.threatHistory) do
        local entry = self.threatHistory[i]
        local elapsed = now - entry.time
        DEFAULT_CHAT_FRAME:AddMessage(string.format("%.0fs atrás: %.0f%%", elapsed, entry.threat), 1, 1, 1)
    end
end

function TP:ClearHistory()
    self.threatHistory = {}
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Amenaza]|r Historial limpiado", 1, 0.84, 0)
end

function TP:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Amenaza]|r " .. status, 1, 0.84, 0)
end

function TP:TogglePredictions()
    self.config.showPredictions = not self.config.showPredictions
    local status = self.config.showPredictions and "activadas" or "desactivadas"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Amenaza]|r Predicciones " .. status, 1, 0.84, 0)
end

function TP:ToggleWarnings()
    self.config.warnHighThreat = not self.config.warnHighThreat
    local status = self.config.warnHighThreat and "activadas" or "desactivadas"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Amenaza]|r Advertencias " .. status, 1, 0.84, 0)
end

function TP:SetThreshold(value)
    value = math.max(50, math.min(95, value))
    self.config.threatThreshold = value
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Amenaza]|r Umbral: " .. value .. "%", 1, 0.84, 0)
end
