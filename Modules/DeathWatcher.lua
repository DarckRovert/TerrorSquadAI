-- DeathWatcher.lua - Auto-Target al Morir el Objetivo
-- TerrorSquadAI v3.0 - Phase 1
-- Detecta cuando el target muere y automáticamente busca el siguiente objetivo

local DW = {}
TerrorSquadAI:RegisterModule("DeathWatcher", DW)

-- Configuración
DW.config = {
    enabled = true,
    autoRetarget = true,
    retargetDelay = 0.3, -- Segundos antes de cambiar target
    announceKill = true,
    onlyInCombat = true,
}

-- Estado
DW.lastTargetName = nil
DW.lastTargetHealth = 100
DW.pendingRetarget = false

function DW:Initialize()
    self:RegisterEvents()
    -- Mensaje silencioso (solo en debug)
    if TerrorSquadAI.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r DeathWatcher inicializado", 1, 0.84, 0)
    end
end

function DW:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_TARGET_CHANGED" then
            DW:OnTargetChanged()
        elseif event == "UNIT_HEALTH" then
            if arg1 == "target" then
                DW:OnTargetHealthChanged()
            end
        elseif event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
            DW:OnHostileDeath(arg1)
        elseif event == "PLAYER_REGEN_ENABLED" then
            DW.inCombat = false
        elseif event == "PLAYER_REGEN_DISABLED" then
            DW.inCombat = true
        end
    end)
end

function DW:OnTargetChanged()
    if UnitExists("target") then
        self.lastTargetName = UnitName("target")
        local maxHP = UnitHealthMax("target")
        if maxHP and maxHP > 0 then
            self.lastTargetHealth = (UnitHealth("target") / maxHP) * 100
        else
            self.lastTargetHealth = 100
        end
    else
        self.lastTargetName = nil
        self.lastTargetHealth = 0
    end
end

function DW:OnTargetHealthChanged()
    if not self.config.enabled then return end
    if not UnitExists("target") then return end
    
    local maxHP = UnitHealthMax("target")
    if not maxHP or maxHP == 0 then return end
    
    local healthPct = (UnitHealth("target") / maxHP) * 100
    
    -- Detectar si el target acaba de morir (salud pasó a 0)
    if healthPct <= 0 and self.lastTargetHealth > 0 then
        self:OnTargetDied()
    end
    
    self.lastTargetHealth = healthPct
end

function DW:OnHostileDeath(message)
    if not self.config.enabled then return end
    if not message then return end
    
    -- Si el mensaje contiene el nombre de nuestro target, está muerto
    if self.lastTargetName and string.find(message, self.lastTargetName) then
        self:OnTargetDied()
    end
end

function DW:OnTargetDied()
    if not self.config.autoRetarget then return end
    if self.config.onlyInCombat and not self.inCombat then return end
    if self.pendingRetarget then return end
    
    local deadTargetName = self.lastTargetName or "objetivo"
    
    -- Anunciar kill si está habilitado
    if self.config.announceKill and TerrorSquadAI.Modules.GnomoFury then
        -- GnomoFury maneja los anuncios de kills
    end
    
    -- Programar retarget con delay
    self.pendingRetarget = true
    
    local delayFrame = CreateFrame("Frame")
    local elapsed = 0
    delayFrame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= DW.config.retargetDelay then
            DW:FindNextTarget()
            DW.pendingRetarget = false
            delayFrame:SetScript("OnUpdate", nil)
        end
    end)
end

function DW:FindNextTarget()
    -- Primero intentar con SmartTargeting si está disponible
    if TerrorSquadAI.Modules.SmartTargeting then
        TerrorSquadAI.Modules.SmartTargeting:FindBestTarget()
        
        if UnitExists("target") and not UnitIsDead("target") then
            -- Encontró un target válido
            local newTargetName = UnitName("target")
            
            -- Alerta visual
            if TerrorSquadAI.Modules.AlertSystem then
                TerrorSquadAI.Modules.AlertSystem:ShowAlert("AUTO-TARGET: " .. newTargetName, "INFO")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AutoTarget]|r → " .. newTargetName, 0, 1, 0)
            end
            return true
        end
    end
    
    -- Fallback: usar TargetNearestEnemy
    TargetNearestEnemy()
    
    if UnitExists("target") and not UnitIsDead("target") then
        local newTargetName = UnitName("target")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[AutoTarget]|r → " .. newTargetName, 0, 1, 0)
        return true
    end
    
    return false
end

-- Comandos
function DW:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[DeathWatcher]|r " .. status, 1, 0.84, 0)
end

function DW:ToggleAutoRetarget()
    self.config.autoRetarget = not self.config.autoRetarget
    local status = self.config.autoRetarget and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[DeathWatcher]|r Auto-retarget: " .. status, 1, 0.84, 0)
end

function DW:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== DeathWatcher Status ===|r", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage("Habilitado: " .. (self.config.enabled and "Sí" or "No"), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Auto-retarget: " .. (self.config.autoRetarget and "Sí" or "No"), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Delay: " .. self.config.retargetDelay .. "s", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Solo en combate: " .. (self.config.onlyInCombat and "Sí" or "No"), 1, 1, 1)
    
    if self.lastTargetName then
        DEFAULT_CHAT_FRAME:AddMessage("Último target: " .. self.lastTargetName .. " (" .. math.floor(self.lastTargetHealth) .. "%)", 1, 1, 1)
    end
end
