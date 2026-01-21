-- CriticalHealthMonitor.lua - Avisos de Salud Crítica
-- TerrorSquadAI v3.0 - Phase 1
-- Alerta cuando miembros importantes del grupo están en HP crítico

local CHM = {}
TerrorSquadAI:RegisterModule("CriticalHealthMonitor", CHM)

-- Configuración
CHM.config = {
    enabled = false,  -- DESACTIVADO por defecto, muy intrusivo
    criticalThreshold = 30, -- Porcentaje para alerta crítica
    warningThreshold = 50,  -- Porcentaje para advertencia
    alertCooldown = 5,      -- Segundos entre alertas del mismo jugador
    prioritizeHealers = true,
    prioritizeTanks = true,
    showVisualAlert = false, -- Sin alertas visuales por defecto
    playSound = false,       -- Sin sonido por defecto
}

-- Estado
CHM.lastAlerts = {} -- {playerName = lastAlertTime}
CHM.inCombat = false

-- Clases healer
local HEALER_CLASSES = {
    PRIEST = true,
    PALADIN = true,
    DRUID = true,
    SHAMAN = true,
}

function CHM:Initialize()
    self:RegisterEvents()
    self:StartMonitor()
    
    if TerrorSquadAI.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r CriticalHealthMonitor inicializado", 1, 0.84, 0)
    end
end

function CHM:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_REGEN_DISABLED" then
            CHM.inCombat = true
        elseif event == "PLAYER_REGEN_ENABLED" then
            CHM.inCombat = false
            CHM.lastAlerts = {} -- Limpiar cooldowns al salir de combate
        end
    end)
end

function CHM:StartMonitor()
    local frame = CreateFrame("Frame")
    local elapsed = 0
    
    frame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= 0.5 then -- Check cada 0.5 segundos
            elapsed = 0
            if CHM.config.enabled and CHM.inCombat then
                CHM:ScanGroupHealth()
            end
        end
    end)
end

function CHM:ScanGroupHealth()
    local now = GetTime()
    
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            self:CheckUnitHealth("raid" .. i, now)
        end
    else
        local numParty = GetNumPartyMembers()
        for i = 1, numParty do
            self:CheckUnitHealth("party" .. i, now)
        end
        -- También verificar al jugador
        self:CheckUnitHealth("player", now)
    end
end

function CHM:CheckUnitHealth(unit, now)
    if not UnitExists(unit) then return end
    if UnitIsDead(unit) then return end
    if not UnitIsConnected(unit) then return end
    
    local name = UnitName(unit)
    if not name then return end
    
    local maxHP = UnitHealthMax(unit)
    if not maxHP or maxHP == 0 then return end
    
    local healthPct = (UnitHealth(unit) / maxHP) * 100
    local priority = self:GetUnitPriority(unit)
    
    -- Verificar cooldown de alertas
    if self.lastAlerts[name] and (now - self.lastAlerts[name]) < self.config.alertCooldown then
        return
    end
    
    -- Determinar nivel de alerta
    local alertLevel = nil
    if healthPct <= self.config.criticalThreshold then
        alertLevel = "CRITICAL"
    elseif healthPct <= self.config.warningThreshold and priority >= 2 then
        alertLevel = "WARNING"
    end
    
    if alertLevel then
        self:TriggerAlert(name, healthPct, alertLevel, priority)
        self.lastAlerts[name] = now
    end
end

function CHM:GetUnitPriority(unit)
    -- 3 = Alta (Tank/Healer), 2 = Media (DPS crítico), 1 = Normal
    local _, class = UnitClass(unit)
    
    -- Detectar si es healer por clase
    if self.config.prioritizeHealers and HEALER_CLASSES[class] then
        return 3
    end
    
    -- Detectar tank por rol (en raid, usualmente los primeros)
    if self.config.prioritizeTanks then
        local numRaid = GetNumRaidMembers()
        if numRaid > 0 then
            -- En Vanilla, detectar tank es difícil - asumimos warrior/druid en bear
            if class == "WARRIOR" then
                return 3
            end
        end
    end
    
    return 1
end

function CHM:TriggerAlert(playerName, healthPct, alertLevel, priority)
    local color, sound, prefix
    
    if alertLevel == "CRITICAL" then
        color = "|cFFFF0000"
        sound = "RaidWarning"
        prefix = "¡CRÍTICO!"
    else
        color = "|cFFFFFF00"
        sound = "igQuestFailed"
        prefix = "¡Bajo HP!"
    end
    
    -- Mensaje visual
    if self.config.showVisualAlert then
        local priorityText = ""
        if priority >= 3 then
            priorityText = " [HEALER/TANK]"
        end
        
        local message = string.format("%s%s|r %s: %.0f%%%s", color, prefix, playerName, healthPct, priorityText)
        
        -- Usar AlertSystem si está disponible
        if TerrorSquadAI.Modules.AlertSystem then
            TerrorSquadAI.Modules.AlertSystem:ShowAlert(message, alertLevel)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[HealthAlert]|r " .. message, 1, 1, 1)
        end
    end
    
    -- Sonido
    if self.config.playSound and alertLevel == "CRITICAL" then
        PlaySound(sound)
    end
end

-- Comandos
function CHM:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[CriticalHealth]|r " .. status, 1, 0.84, 0)
end

function CHM:SetThreshold(threshold)
    threshold = tonumber(threshold)
    if threshold and threshold > 0 and threshold <= 100 then
        self.config.criticalThreshold = threshold
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[CriticalHealth]|r Umbral crítico: " .. threshold .. "%", 1, 0.84, 0)
    end
end

function CHM:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Critical Health Monitor ===|r", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage("Habilitado: " .. (self.config.enabled and "Sí" or "No"), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Umbral crítico: " .. self.config.criticalThreshold .. "%", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Umbral advertencia: " .. self.config.warningThreshold .. "%", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Priorizar healers: " .. (self.config.prioritizeHealers and "Sí" or "No"), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Priorizar tanks: " .. (self.config.prioritizeTanks and "Sí" or "No"), 1, 1, 1)
end

-- API para otros módulos
function CHM:GetCriticalMembers()
    local critical = {}
    local numRaid = GetNumRaidMembers()
    
    if numRaid > 0 then
        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitExists(unit) and not UnitIsDead(unit) then
                local maxHP = UnitHealthMax(unit)
                if maxHP and maxHP > 0 then
                    local healthPct = (UnitHealth(unit) / maxHP) * 100
                    if healthPct <= self.config.criticalThreshold then
                        table.insert(critical, {
                            name = UnitName(unit),
                            health = healthPct,
                            priority = self:GetUnitPriority(unit),
                        })
                    end
                end
            end
        end
    end
    
    return critical
end
