-- TerrorTactics.lua - Sistema de Tácticas Coordinadas
-- TerrorSquadAI v3.0 - Phase 4
-- Tácticas predefinidas que coordinan múltiples módulos

local TT = {}
TerrorSquadAI:RegisterModule("TerrorTactics", TT)

-- Configuración
TT.config = {
    enabled = true,
    announceToGroup = false, -- No spam por defecto
    visualAlerts = true,
}

-- Estado
TT.activeTactic = nil
TT.tacticStartTime = 0

-- Definición de tácticas
TT.tactics = {
    -- Alpha Focus: Todos al target marcado
    alpha = {
        name = "Alpha Focus",
        description = "Todos concentran fuego en el objetivo marcado con Skull",
        color = "|cFFFF0000",
        onActivate = function()
            -- Marcar target actual con Skull
            if TerrorSquadAI.Modules.AutoMarker then
                TerrorSquadAI.Modules.AutoMarker:MarkManual("target", "Skull")
            end
            -- Activar FocusFireCoordinator
            if TerrorSquadAI.Modules.FocusFireCoordinator then
                TerrorSquadAI.Modules.FocusFireCoordinator:SetFocusTarget("target", 100)
            end
            -- Enviar ping de ataque
            if TerrorSquadAI.Modules.TacticalPings then
                TerrorSquadAI.Modules.TacticalPings:SendPing("atacar")
            end
        end,
        onDeactivate = function()
            if TerrorSquadAI.Modules.FocusFireCoordinator then
                TerrorSquadAI.Modules.FocusFireCoordinator:ClearTarget()
            end
        end,
    },
    
    -- Healer Hunt: Priorizar healers
    healer = {
        name = "Healer Hunt",
        description = "Prioridad máxima a healers enemigos",
        color = "|cFFFFFF00",
        onActivate = function()
            -- Configurar SmartTargeting para priorizar healers
            if TerrorSquadAI.Modules.SmartTargeting then
                TerrorSquadAI.Modules.SmartTargeting.config.preferHealers = true
                TerrorSquadAI.Modules.SmartTargeting.config.preferCasters = true
            end
            -- Buscar healer cercano
            TT:FindNearestHealer()
        end,
        onDeactivate = function()
            -- Restaurar configuración
        end,
    },
    
    -- Scatter: Dispersión para evitar AoE
    scatter = {
        name = "Scatter",
        description = "Dispersarse para evitar AoE - cada uno elige su target",
        color = "|cFF00FFFF",
        onActivate = function()
            -- Formación dispersa
            if TerrorSquadAI.Modules.PositionOptimizer then
                TerrorSquadAI.Modules.PositionOptimizer:SuggestFormation("dispersion")
            end
            -- Limpiar focus compartido
            if TerrorSquadAI.Modules.FocusFireCoordinator then
                TerrorSquadAI.Modules.FocusFireCoordinator:ClearTarget()
            end
            -- Ping de dispersión
            if TerrorSquadAI.Modules.TacticalPings then
                TerrorSquadAI.Modules.TacticalPings:SendPing("dispersion")
            end
        end,
        onDeactivate = function() end,
    },
    
    -- Retreat: Retirada táctica
    retreat = {
        name = "Retreat",
        description = "Retirada táctica - reagrupar y curar",
        color = "|cFFFF8800",
        onActivate = function()
            -- Formación compacta para retreat
            if TerrorSquadAI.Modules.PositionOptimizer then
                TerrorSquadAI.Modules.PositionOptimizer:SuggestFormation("compacta")
            end
            -- Ping de retirada
            if TerrorSquadAI.Modules.TacticalPings then
                TerrorSquadAI.Modules.TacticalPings:SendPing("retirada")
            end
            -- Alerta visual fuerte
            if TerrorSquadAI.Modules.AlertSystem then
                TerrorSquadAI.Modules.AlertSystem:ShowAlert("¡RETIRADA! Reagrupar y curar", "CRITICAL")
            end
            PlaySound("RaidWarning")
        end,
        onDeactivate = function() end,
    },
    
    -- Defensive: Postura defensiva
    defensive = {
        name = "Defensive",
        description = "Postura defensiva - proteger healers y tank",
        color = "|cFF00FF00",
        onActivate = function()
            -- Formación defensiva
            if TerrorSquadAI.Modules.PositionOptimizer then
                TerrorSquadAI.Modules.PositionOptimizer:SuggestFormation("compacta")
            end
            -- Ping de defensa
            if TerrorSquadAI.Modules.TacticalPings then
                TerrorSquadAI.Modules.TacticalPings:SendPing("defender")
            end
        end,
        onDeactivate = function() end,
    },
    
    -- Burst: Ventana de burst DPS
    burst = {
        name = "Burst",
        description = "¡Usar todos los cooldowns ofensivos ahora!",
        color = "|cFFFF00FF",
        onActivate = function()
            -- Alerta de cooldowns
            if TerrorSquadAI.Modules.AlertSystem then
                TerrorSquadAI.Modules.AlertSystem:ShowAlert("¡BURST! Usar cooldowns ofensivos", "WARNING")
            end
            PlaySound("ReadyCheck")
        end,
        onDeactivate = function() end,
    },
}

function TT:Initialize()
    self:RegisterSlashCommands()
    
    if TerrorSquadAI.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r TerrorTactics inicializado", 1, 0.84, 0)
    end
end

function TT:RegisterSlashCommands()
    -- Ya se maneja desde Commands.lua
end

function TT:ActivateTactic(tacticName)
    if not self.config.enabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Tactics]|r Sistema desactivado", 1, 0.5, 0)
        return
    end
    
    tacticName = string.lower(tacticName or "")
    local tactic = self.tactics[tacticName]
    
    if not tactic then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Tactics]|r Táctica no encontrada: " .. tacticName, 1, 0, 0)
        self:PrintAvailable()
        return
    end
    
    -- Desactivar táctica anterior
    if self.activeTactic then
        self:DeactivateTactic()
    end
    
    -- Activar nueva táctica
    self.activeTactic = tacticName
    self.tacticStartTime = GetTime()
    
    -- Ejecutar función de activación
    if tactic.onActivate then
        tactic.onActivate()
    end
    
    -- Anunciar
    local message = string.format("%s%s|r activada", tactic.color, tactic.name)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Tactics]|r " .. message, 1, 0.84, 0)
    
    -- Anunciar al grupo si está habilitado
    if self.config.announceToGroup then
        local groupMessage = "[Terror Tactics] " .. tactic.name .. " - " .. tactic.description
        if GetNumRaidMembers() > 0 then
            SendChatMessage(groupMessage, "RAID")
        elseif GetNumPartyMembers() > 0 then
            SendChatMessage(groupMessage, "PARTY")
        end
    end
    
    -- Sincronizar con otros usuarios del addon
    if TerrorSquadAI.Modules.CommunicationSync then
        TerrorSquadAI.Modules.CommunicationSync:SendMessage("TACTIC", tacticName)
    end
end

function TT:DeactivateTactic()
    if not self.activeTactic then return end
    
    local tactic = self.tactics[self.activeTactic]
    if tactic and tactic.onDeactivate then
        tactic.onDeactivate()
    end
    
    local duration = GetTime() - self.tacticStartTime
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD700[Tactics]|r %s desactivada (%.0fs)", 
        tactic.name, duration), 1, 0.84, 0)
    
    self.activeTactic = nil
end

function TT:FindNearestHealer()
    local healerClasses = {PRIEST = true, PALADIN = true, DRUID = true, SHAMAN = true}
    
    -- Buscar en targets del raid
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            local unit = "raid" .. i .. "target"
            if UnitExists(unit) and UnitCanAttack("player", unit) and UnitIsPlayer(unit) then
                local _, class = UnitClass(unit)
                if healerClasses[class] then
                    TargetUnit(unit)
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Healer Hunt]|r Encontrado: " .. UnitName(unit) .. " (" .. class .. ")", 1, 0.84, 0)
                    return true
                end
            end
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Healer Hunt]|r No se encontró healer enemigo visible", 1, 0.5, 0)
    return false
end

function TT:PrintAvailable()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Tácticas Disponibles ===|r", 1, 0.84, 0)
    
    for name, tactic in pairs(self.tactics) do
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s/tsa tactic %s|r - %s", 
            tactic.color, name, tactic.description), 1, 1, 1)
    end
end

function TT:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Terror Tactics Status ===|r", 1, 0.84, 0)
    
    if self.activeTactic then
        local tactic = self.tactics[self.activeTactic]
        local duration = GetTime() - self.tacticStartTime
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Táctica activa: %s%s|r (%.0fs)", 
            tactic.color, tactic.name, duration), 1, 1, 1)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Sin táctica activa", 1, 1, 1)
    end
end

function TT:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorTactics]|r " .. status, 1, 0.84, 0)
end

function TT:GetActiveTactic()
    return self.activeTactic
end
