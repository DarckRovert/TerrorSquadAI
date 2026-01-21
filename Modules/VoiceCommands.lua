-- VoiceCommands.lua - Sistema de Comandos de Voz

local VC = {}
TerrorSquadAI:RegisterModule("VoiceCommands", VC)

-- Configuración
VC.config = {
    enabled = true,
    announceCommands = true,
}

-- Comandos disponibles
VC.commands = {}

function VC:Initialize()
    self:RegisterCommands()
    self:RegisterSlashCommands()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r VoiceCommands inicializado", 1, 0.84, 0)
end

function VC:RegisterCommands()
    self.commands = {
        ["atacar"] = {func = self.CommandAttack, desc = "Ordenar ataque concentrado"},
        ["defender"] = {func = self.CommandDefend, desc = "Ordenar posición defensiva"},
        ["retirada"] = {func = self.CommandRetreat, desc = "Ordenar retirada"},
        ["ayuda"] = {func = self.CommandHelp, desc = "Solicitar ayuda"},
        ["agrupar"] = {func = self.CommandGroup, desc = "Ordenar reagrupamiento"},
        ["dispersar"] = {func = self.CommandSpread, desc = "Ordenar dispersión"},
        ["interrumpir"] = {func = self.CommandInterrupt, desc = "Solicitar interrupción"},
        ["foco"] = {func = self.CommandFocus, desc = "Establecer fuego concentrado"},
        ["estado"] = {func = self.CommandStatus, desc = "Mostrar estado del escuadrón"},
        ["cooldowns"] = {func = self.CommandCooldowns, desc = "Mostrar cooldowns disponibles"},
    }
end

function VC:RegisterSlashCommands()
    SLASH_TSVOZ1 = "/voz"
    SlashCmdList["TSVOZ"] = function(msg)
        VC:HandleCommand(msg)
    end
end

function VC:HandleCommand(msg)
    if not self.config.enabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[VoiceCommands]|r Sistema desactivado", 1, 0.5, 0)
        return
    end
    
    local cmd = string.lower(msg or "")
    
    if cmd == "" then
        self:ShowHelp()
        return
    end
    
    local command = self.commands[cmd]
    if command then
        command.func(self)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[VoiceCommands]|r Comando desconocido: " .. cmd, 1, 0, 0)
        self:ShowHelp()
    end
end

function VC:ShowHelp()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Comandos de Voz Disponibles ===", 1, 0.84, 0)
    
    for cmd, data in pairs(self.commands) do
        DEFAULT_CHAT_FRAME:AddMessage("/voz " .. cmd .. " - " .. data.desc, 1, 1, 1)
    end
end

function VC:CommandAttack()
    self:BroadcastCommand("ATACAR", "¡Concentren fuego en el objetivo!")
    
    if UnitExists("target") then
        local targetName = UnitName("target")
        local message = "[Terror Squad] ¡ATACAR " .. targetName .. "!"
        
        if GetNumRaidMembers() > 0 then
            SendChatMessage(message, "RAID_WARNING")
        elseif GetNumPartyMembers() > 0 then
            SendChatMessage(message, "PARTY")
        end
        
        -- Marcar objetivo si AutoMarker está disponible
        if TerrorSquadAI.Modules.AutoMarker then
            TerrorSquadAI.Modules.AutoMarker:MarkManual("target", "Skull")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[VoiceCommands]|r Necesitas un objetivo", 1, 0, 0)
    end
end

function VC:CommandDefend()
    self:BroadcastCommand("DEFENDER", "Adopten posición defensiva")
    
    local message = "[Terror Squad] ¡DEFENDER! Posición defensiva"
    if GetNumRaidMembers() > 0 then
        SendChatMessage(message, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(message, "PARTY")
    end
    
    -- Sugerir formación defensiva
    if TerrorSquadAI.Modules.PositionOptimizer then
        TerrorSquadAI.Modules.PositionOptimizer:CommandTight()
    end
end

function VC:CommandRetreat()
    self:BroadcastCommand("RETIRADA", "¡Retirada inmediata!")
    
    local message = "[Terror Squad] ¡RETIRADA! Salgan ahora"
    if GetNumRaidMembers() > 0 then
        SendChatMessage(message, "RAID_WARNING")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(message, "PARTY")
    end
end

function VC:CommandHelp()
    self:BroadcastCommand("AYUDA", "Solicitud de ayuda")
    
    local playerName = UnitName("player")
    local x, y = GetPlayerMapPosition("player")
    local zone = GetRealZoneText()
    
    local message = string.format("[Terror Squad] %s necesita AYUDA en %s!", playerName, zone or "ubicación actual")
    if GetNumRaidMembers() > 0 then
        SendChatMessage(message, "RAID_WARNING")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(message, "PARTY")
    end
    
    -- Ping de ayuda
    if TerrorSquadAI.Modules.TacticalPings then
        TerrorSquadAI.Modules.TacticalPings:PingHelp()
    end
end

function VC:CommandGroup()
    self:BroadcastCommand("AGRUPAR", "Reagruparse")
    
    local message = "[Terror Squad] ¡AGRUPARSE! Todos a mí"
    if GetNumRaidMembers() > 0 then
        SendChatMessage(message, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(message, "PARTY")
    end
    
    -- Sugerir formación agrupada
    if TerrorSquadAI.Modules.PositionOptimizer then
        TerrorSquadAI.Modules.PositionOptimizer:CommandTight()
    end
    
    -- Ping de reagrupamiento
    if TerrorSquadAI.Modules.TacticalPings then
        TerrorSquadAI.Modules.TacticalPings:PingGather()
    end
end

function VC:CommandSpread()
    self:BroadcastCommand("DISPERSAR", "Dispersarse")
    
    local message = "[Terror Squad] ¡DISPERSARSE! Separen posiciones"
    if GetNumRaidMembers() > 0 then
        SendChatMessage(message, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(message, "PARTY")
    end
    
    -- Sugerir formación dispersa
    if TerrorSquadAI.Modules.PositionOptimizer then
        TerrorSquadAI.Modules.PositionOptimizer:CommandSpread()
    end
end

function VC:CommandInterrupt()
    self:BroadcastCommand("INTERRUMPIR", "Interrumpir casteo")
    
    if UnitExists("target") then
        local targetName = UnitName("target")
        -- NOTA: UnitCastingInfo/UnitChannelInfo NO existen en WoW 1.12
        -- No podemos detectar si el enemigo está casteando
        -- Simplemente enviamos el comando de interrupt
        
        local message = "[Terror Squad] ¡INTERRUMPIR a " .. targetName .. "!"
        if GetNumRaidMembers() > 0 then
            SendChatMessage(message, "RAID")
        elseif GetNumPartyMembers() > 0 then
            SendChatMessage(message, "PARTY")
        end
        
        -- Intentar interrupción manual
        if TerrorSquadAI.Modules.InterruptCoordinator then
            TerrorSquadAI.Modules.InterruptCoordinator:ManualInterrupt()
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[VoiceCommands]|r Necesitas un objetivo", 1, 0, 0)
    end
end

function VC:CommandFocus()
    self:BroadcastCommand("FOCO", "Establecer foco")
    
    if UnitExists("target") then
        local targetName = UnitName("target")
        local message = "[Terror Squad] FOCO en " .. targetName .. " - Todos a ese objetivo"
        
        if GetNumRaidMembers() > 0 then
            SendChatMessage(message, "RAID_WARNING")
        elseif GetNumPartyMembers() > 0 then
            SendChatMessage(message, "PARTY")
        end
        
        -- Establecer objetivo de foco
        if TerrorSquadAI.Modules.FocusFireCoordinator then
            local priority = TerrorSquadAI.Modules.FocusFireCoordinator:CalculatePriority("target")
            TerrorSquadAI.Modules.FocusFireCoordinator:SetFocusTarget("target", priority)
        end
        
        -- Marcar objetivo
        if TerrorSquadAI.Modules.AutoMarker then
            TerrorSquadAI.Modules.AutoMarker:MarkManual("target", "Skull")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[VoiceCommands]|r Necesitas un objetivo", 1, 0, 0)
    end
end

function VC:CommandStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Estado del Escuadrón ===", 1, 0.84, 0)
    
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Miembros en raid: " .. numRaid, 1, 1, 1)
        
        local alive = 0
        local dead = 0
        local inCombat = 0
        
        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitIsDeadOrGhost(unit) then
                dead = dead + 1
            else
                alive = alive + 1
                if UnitAffectingCombat(unit) then
                    inCombat = inCombat + 1
                end
            end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("Vivos: " .. alive .. " | Muertos: " .. dead, 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("En combate: " .. inCombat, 1, 1, 1)
    elseif numParty > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Miembros en grupo: " .. (numParty + 1), 1, 1, 1)
    else
        DEFAULT_CHAT_FRAME:AddMessage("No estás en un grupo", 1, 0.5, 0.5)
    end
    
    -- Mostrar recursos si ResourceMonitor está disponible
    if TerrorSquadAI.Modules.ResourceMonitor then
        local avgHealth = TerrorSquadAI.Modules.ResourceMonitor:GetAverageHealth()
        local avgMana = TerrorSquadAI.Modules.ResourceMonitor:GetAverageMana()
        DEFAULT_CHAT_FRAME:AddMessage(string.format("HP Promedio: %.0f%%", avgHealth), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Mana Promedio: %.0f%%", avgMana), 1, 1, 1)
    end
    
    -- Mostrar amenaza si ThreatPredictor está disponible
    if TerrorSquadAI.Modules.ThreatPredictor then
        local threat = TerrorSquadAI.Modules.ThreatPredictor:GetCurrentThreat()
        local level, color = TerrorSquadAI.Modules.ThreatPredictor:GetThreatLevel()
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Amenaza: %.0f%% (%s)", threat, level), unpack(color))
    end
end

function VC:CommandCooldowns()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Cooldowns Disponibles ===", 1, 0.84, 0)
    
    if TerrorSquadAI.Modules.CooldownTracker then
        TerrorSquadAI.Modules.CooldownTracker:PrintCooldowns()
    else
        DEFAULT_CHAT_FRAME:AddMessage("CooldownTracker no disponible", 1, 0.5, 0.5)
    end
end

function VC:BroadcastCommand(command, message)
    if TerrorSquadAI.Modules.CommunicationSync then
        local data = string.format("VCMD:%s:%s", command, UnitName("player"))
        TerrorSquadAI.Modules.CommunicationSync:SendMessage("VOICECMD", data)
    end
    
    if self.config.announceCommands then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Comando de Voz]|r " .. message, 1, 0.84, 0)
    end
end

function VC:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[VoiceCommands]|r " .. status, 1, 0.84, 0)
end

function VC:ToggleAnnounce()
    self.config.announceCommands = not self.config.announceCommands
    local status = self.config.announceCommands and "activados" or "desactivados"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[VoiceCommands]|r Anuncios " .. status, 1, 0.84, 0)
end
