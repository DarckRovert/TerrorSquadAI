-- WipePredictor.lua - Predictor de Wipes
-- TerrorSquadAI v3.0 - Phase 3
-- Analiza el estado del raid para predecir wipes

local WP = {}
TerrorSquadAI:RegisterModule("WipePredictor", WP)

-- Configuración
WP.config = {
    enabled = true,
    alertThreshold = 70, -- Porcentaje de riesgo para alertar
    criticalThreshold = 90, -- Porcentaje para alerta crítica
    checkInterval = 1, -- Segundos entre checks
}

-- Estado
WP.inCombat = false
WP.combatStartTime = 0
WP.lastWipeRisk = 0
WP.lastAlertTime = 0
WP.recentDeaths = {} -- {timestamp, ...}

function WP:Initialize()
    self:RegisterEvents()
    self:StartMonitor()
    
    if TerrorSquadAI.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r WipePredictor inicializado", 1, 0.84, 0)
    end
end

function WP:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH")
    
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_REGEN_DISABLED" then
            WP.inCombat = true
            WP.combatStartTime = GetTime()
            WP.recentDeaths = {}
            WP.lastWipeRisk = 0
        elseif event == "PLAYER_REGEN_ENABLED" then
            WP.inCombat = false
            WP.recentDeaths = {}
        elseif event == "CHAT_MSG_COMBAT_FRIENDLY_DEATH" then
            WP:OnFriendlyDeath(arg1)
        end
    end)
end

function WP:OnFriendlyDeath(message)
    if not self.inCombat then return end
    
    table.insert(self.recentDeaths, GetTime())
    
    -- Limpiar muertes viejas (más de 30 segundos)
    local now = GetTime()
    local cleaned = {}
    for _, deathTime in ipairs(self.recentDeaths) do
        if now - deathTime < 30 then
            table.insert(cleaned, deathTime)
        end
    end
    self.recentDeaths = cleaned
end

function WP:StartMonitor()
    local frame = CreateFrame("Frame")
    local elapsed = 0
    
    frame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= WP.config.checkInterval then
            elapsed = 0
            if WP.config.enabled and WP.inCombat then
                WP:CalculateWipeRisk()
            end
        end
    end)
end

function WP:CalculateWipeRisk()
    local risk = 0
    local factors = {}
    
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid == 0 and numParty == 0 then return 0 end
    
    -- Factor 1: Salud promedio del raid (0-30 puntos)
    local avgHealth, tankHealth, healerHealth = self:GetGroupHealthStats()
    
    if avgHealth < 30 then
        risk = risk + 30
        table.insert(factors, "Salud raid crítica")
    elseif avgHealth < 50 then
        risk = risk + 15
        table.insert(factors, "Salud raid baja")
    elseif avgHealth < 70 then
        risk = risk + 5
    end
    
    -- Factor 2: Muertes recientes (0-30 puntos)
    local deathCount = table.getn(self.recentDeaths)
    if deathCount >= 5 then
        risk = risk + 30
        table.insert(factors, deathCount .. " muertes recientes")
    elseif deathCount >= 3 then
        risk = risk + 20
        table.insert(factors, deathCount .. " muertes recientes")
    elseif deathCount >= 1 then
        risk = risk + 10
    end
    
    -- Factor 3: Tank bajo de vida (0-20 puntos)
    if tankHealth and tankHealth < 30 then
        risk = risk + 20
        table.insert(factors, "Tank crítico")
    elseif tankHealth and tankHealth < 50 then
        risk = risk + 10
        table.insert(factors, "Tank bajo HP")
    end
    
    -- Factor 4: Healers muertos o bajos (0-20 puntos)
    local healerStatus = self:GetHealerStatus()
    if healerStatus.dead > 0 then
        risk = risk + 20
        table.insert(factors, healerStatus.dead .. " healer(s) muerto(s)")
    elseif healerStatus.critical > 0 then
        risk = risk + 10
        table.insert(factors, healerStatus.critical .. " healer(s) crítico(s)")
    end
    
    -- Guardar riesgo
    self.lastWipeRisk = math.min(100, risk)
    
    -- Alertar si es necesario
    self:CheckAlert(risk, factors)
    
    return risk
end

function WP:GetGroupHealthStats()
    local totalHealth = 0
    local count = 0
    local tankHealth = nil
    local healerHealth = 100
    
    local numRaid = GetNumRaidMembers()
    
    if numRaid > 0 then
        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitExists(unit) and not UnitIsDead(unit) then
                local maxHP = UnitHealthMax(unit)
                if maxHP and maxHP > 0 then
                    local healthPct = (UnitHealth(unit) / maxHP) * 100
                    totalHealth = totalHealth + healthPct
                    count = count + 1
                    
                    -- Detectar tank (warrior primeros en raid)
                    local _, class = UnitClass(unit)
                    if class == "WARRIOR" and not tankHealth then
                        tankHealth = healthPct
                    end
                    
                    -- Detectar healer con menos vida
                    if class == "PRIEST" or class == "PALADIN" or class == "DRUID" or class == "SHAMAN" then
                        if healthPct < healerHealth then
                            healerHealth = healthPct
                        end
                    end
                end
            end
        end
    else
        -- Grupo pequeño
        local numParty = GetNumPartyMembers()
        for i = 1, numParty do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDead(unit) then
                local maxHP = UnitHealthMax(unit)
                if maxHP and maxHP > 0 then
                    local healthPct = (UnitHealth(unit) / maxHP) * 100
                    totalHealth = totalHealth + healthPct
                    count = count + 1
                end
            end
        end
        -- Incluir player
        local maxHP = UnitHealthMax("player")
        if maxHP and maxHP > 0 then
            totalHealth = totalHealth + (UnitHealth("player") / maxHP) * 100
            count = count + 1
        end
    end
    
    local avgHealth = count > 0 and (totalHealth / count) or 100
    return avgHealth, tankHealth, healerHealth
end

function WP:GetHealerStatus()
    local status = {total = 0, dead = 0, critical = 0}
    
    local numRaid = GetNumRaidMembers()
    if numRaid == 0 then return status end
    
    local healerClasses = {PRIEST = true, PALADIN = true, DRUID = true, SHAMAN = true}
    
    for i = 1, numRaid do
        local unit = "raid" .. i
        if UnitExists(unit) then
            local _, class = UnitClass(unit)
            if healerClasses[class] then
                status.total = status.total + 1
                
                if UnitIsDead(unit) then
                    status.dead = status.dead + 1
                else
                    local maxHP = UnitHealthMax(unit)
                    if maxHP and maxHP > 0 then
                        local healthPct = (UnitHealth(unit) / maxHP) * 100
                        if healthPct < 30 then
                            status.critical = status.critical + 1
                        end
                    end
                end
            end
        end
    end
    
    return status
end

function WP:CheckAlert(risk, factors)
    local now = GetTime()
    
    -- Cooldown de alertas
    if now - self.lastAlertTime < 10 then return end
    
    if risk >= self.config.criticalThreshold then
        self.lastAlertTime = now
        local message = string.format("|cFFFF0000¡RIESGO DE WIPE: %d%%!|r", risk)
        
        if TerrorSquadAI.Modules.AlertSystem then
            TerrorSquadAI.Modules.AlertSystem:ShowAlert(message, "CRITICAL")
        else
            DEFAULT_CHAT_FRAME:AddMessage(message, 1, 0, 0)
        end
        
        -- Mostrar factores
        for _, factor in ipairs(factors) do
            DEFAULT_CHAT_FRAME:AddMessage("  - " .. factor, 1, 0.5, 0.5)
        end
        
        PlaySound("RaidWarning")
        
    elseif risk >= self.config.alertThreshold then
        self.lastAlertTime = now
        local message = string.format("|cFFFFFF00Riesgo de wipe elevado: %d%%|r", risk)
        
        if TerrorSquadAI.Modules.AlertSystem then
            TerrorSquadAI.Modules.AlertSystem:ShowAlert(message, "WARNING")
        else
            DEFAULT_CHAT_FRAME:AddMessage(message, 1, 1, 0)
        end
    end
end

function WP:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Wipe Predictor ===|r", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage("En combate: " .. (self.inCombat and "Sí" or "No"), 1, 1, 1)
    
    if self.inCombat then
        local duration = GetTime() - self.combatStartTime
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Duración: %.0f segundos", duration), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Riesgo actual: %d%%", self.lastWipeRisk), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("Muertes recientes: " .. table.getn(self.recentDeaths), 1, 1, 1)
    end
end

function WP:GetWipeRisk()
    return self.lastWipeRisk
end

function WP:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[WipePredictor]|r " .. status, 1, 0.84, 0)
end
