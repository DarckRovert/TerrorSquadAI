-- FocusFireCoordinator.lua - Coordinador de Fuego Concentrado

local function GetUnitID(unit)
    if not UnitExists(unit) then return nil end
    local name = UnitName(unit)
    local level = UnitLevel(unit)
    return name .. ":" .. level
end

local FFC = {}
TerrorSquadAI:RegisterModule("FocusFireCoordinator", FFC)

-- Estado
FFC.currentTarget = nil
FFC.targetUnitID = nil
FFC.targetPriority = 0
FFC.lastUpdate = 0
FFC.updateInterval = 1
FFC.squadTargets = {}

-- Configuración
FFC.config = {
    enabled = true,
    autoTarget = false,        -- No auto-target, muy intrusivo
    announceTargets = false,   -- Sin anuncios visuales
    markTargets = true,
    syncWithSquad = true,
}

-- Prioridades de objetivo
local TARGET_PRIORITIES = {
    -- PvP
    ["PRIEST"] = 10,
    ["PALADIN"] = 9,
    ["DRUID"] = 8,
    ["SHAMAN"] = 8,
    ["MAGE"] = 7,
    ["WARLOCK"] = 7,
    ["HUNTER"] = 6,
    ["ROGUE"] = 6,
    ["WARRIOR"] = 5,
    
    -- PvE (por clasificación)
    ["worldboss"] = 10,
    ["rareelite"] = 9,
    ["elite"] = 7,
    ["rare"] = 6,
    ["normal"] = 5,
}

function FFC:Initialize()
    self:RegisterEvents()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r FocusFireCoordinator inicializado", 1, 0.84, 0)
end

function FFC:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_TARGET_CHANGED" then
            FFC:OnTargetChanged()
        elseif event == "CHAT_MSG_ADDON" then
            FFC:OnAddonMessage(arg1, arg2, arg3, arg4)
        elseif event == "PLAYER_REGEN_DISABLED" then
            FFC:OnEnterCombat()
        elseif event == "UNIT_HEALTH" then
            FFC:OnUnitHealth(arg1)
        end
    end)
    
    -- Timer de actualización
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        local now = GetTime()
        if now - FFC.lastUpdate >= FFC.updateInterval then
            FFC:Update()
            FFC.lastUpdate = now
        end
    end)
end

function FFC:OnTargetChanged()
    if not self.config.enabled then return end
    if not UnitExists("target") then return end
    if not UnitCanAttack("player", "target") then return end
    
    local unitID = GetUnitID("target")
    local priority = self:CalculatePriority("target")
    
    -- Si es un objetivo de mayor prioridad, actualizar
    if priority and (not self.targetPriority or priority > self.targetPriority) then
        self:SetFocusTarget("target", priority)
    end
end

function FFC:OnEnterCombat()
    if not self.config.enabled then return end
    self:ScanForPriorityTargets()
end

function FFC:OnUnitHealth(unit)
    if not self.config.enabled then return end
    if not self.currentTarget then return end
    
    -- Si el objetivo actual está bajo de salud, buscar siguiente
    if GetUnitID(unit) == self.targetUnitID then
        local healthPct = (UnitHealth(unit) / UnitHealthMax(unit)) * 100
        if healthPct < 10 then
            self:FindNextTarget()
        end
    end
end

function FFC:Update()
    if not self.config.enabled then return end
    if not UnitAffectingCombat("player") then return end
    
    -- Verificar si el objetivo actual sigue siendo válido
    if self.currentTarget then
        if not UnitExists(self.currentTarget) or UnitIsDead(self.currentTarget) then
            self:FindNextTarget()
        end
    else
        self:ScanForPriorityTargets()
    end
end

function FFC:CalculatePriority(unit)
    if not UnitExists(unit) then return 0 end
    
    local priority = 0
    
    -- PvP: Prioridad por clase
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        priority = TARGET_PRIORITIES[class] or 5
        
        -- Bonus por bajo HP
        local healthPct = (UnitHealth(unit) / UnitHealthMax(unit)) * 100
        if healthPct < 30 then
            priority = priority + 3
        elseif healthPct < 50 then
            priority = priority + 1
        end
        
        -- Bonus si está casteando
        -- Vanilla WoW no tiene UnitCastingInfo/UnitChannelInfo
        if false then -- UnitCastingInfo(unit) or UnitChannelInfo(unit) then
            priority = priority + 2
        end
    else
        -- PvE: Prioridad por clasificación
        local classification = UnitClassification(unit)
        priority = TARGET_PRIORITIES[classification] or 5
        
        -- Bonus por tipo de criatura
        local creatureType = UnitCreatureType(unit)
        if creatureType == "Humanoid" then
            priority = priority + 1
        end
    end
    
    -- Penalización por distancia
    local distance = self:GetDistance(unit)
    if distance > 30 then
        priority = priority - 2
    end
    
    return math.max(0, priority)
end

function FFC:GetDistance(unit)
    if not UnitExists(unit) then return 999 end
    
    -- Aproximación de distancia usando CheckInteractDistance
    if CheckInteractDistance(unit, 1) then
        return 5 -- Muy cerca
    elseif CheckInteractDistance(unit, 2) then
        return 10 -- Cerca
    elseif CheckInteractDistance(unit, 3) then
        return 20 -- Media
    elseif CheckInteractDistance(unit, 4) then
        return 30 -- Lejos
    else
        return 40 -- Muy lejos
    end
end

function FFC:SetFocusTarget(unit, priority)
    if not UnitExists(unit) then return end
    
    local unitID = GetUnitID(unit)
    local name = UnitName(unit)
    
    self.currentTarget = unit
    self.targetUnitID = unitID
    self.targetPriority = priority
    
    -- Anunciar
    if self.config.announceTargets then
        self:AnnounceTarget(name, priority)
    end
    
    -- Marcar
    if self.config.markTargets and TerrorSquadAI.Modules.AutoMarker then
        TerrorSquadAI.Modules.AutoMarker:MarkTarget(unit, 1) -- Skull
    end
    
    -- Sincronizar con escuadrón
    if self.config.syncWithSquad then
        self:BroadcastTarget(unitID, name, priority)
    end
    
    -- Auto-target
    if self.config.autoTarget and GetUnitID("target") ~= unitID then
        TargetByName(name)
    end
end

function FFC:AnnounceTarget(name, priority)
    local priorityText = priority and tostring(priority) or "0"
    
    -- Usar AlertSystem para mostrar alerta visual en pantalla
    if TerrorSquadAI.Modules.AlertSystem then
        TerrorSquadAI.Modules.AlertSystem:ShowAlert({
            type = "critical",
            message = "FOCO: " .. name .. " (Prioridad: " .. priorityText .. ")",
            icon = "Interface\\Icons\\Ability_Hunter_SniperShot",
            duration = 4,
            sound = true,
            source = "FocusFire"
        })
    end
    
    -- Solo enviar al chat del grupo si está habilitado
    if TerrorSquadAI.DB.chatMessagesEnabled then
        local message = "[Terror Squad] FOCO: " .. name
        if GetNumRaidMembers() > 0 then
            SendChatMessage(message, "RAID_WARNING")
        elseif GetNumPartyMembers() > 0 then
            SendChatMessage(message, "PARTY")
        end
    end
end

function FFC:BroadcastTarget(unitID, name, priority)
    if not TerrorSquadAI.Modules.CommunicationSync then return end
    
    local data = string.format("FOCUS:%s:%s:%d", unitID, name, priority)
    TerrorSquadAI.Modules.CommunicationSync:SendMessage("FOCUSFIRE", data)
end

function FFC:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= "TerrorSquadAI" then return end
    
    local _, _, msgType, data = string.find(message, "^(%w+):(.+)$")
    if msgType == "FOCUS" then
        self:ReceiveFocusTarget(data, sender)
    end
end

function FFC:ReceiveFocusTarget(data, sender)
    local _, _, unitID, name, priority = string.find(data, "^([^:]+):([^:]+):(%d+)$")
    if not unitID or not name or not priority then return end
    
    priority = tonumber(priority)
    
    -- Guardar objetivo del escuadrón
    self.squadTargets[sender] = {
        unitID = unitID,
        name = name,
        priority = priority,
        time = GetTime()
    }
    
    -- Si es de mayor prioridad que el nuestro, considerar cambiar
    if priority > self.targetPriority and self.config.autoTarget then
        -- Buscar el objetivo por nombre
        TargetByName(name)
        if UnitExists("target") and GetUnitID("target") == unitID then
            self:SetFocusTarget("target", priority)
        end
    end
end

function FFC:ScanForPriorityTargets()
    local bestTarget = nil
    local bestPriority = 0
    
    -- Escanear targets de raid/party
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            local unit = "raid" .. i .. "target"
            if UnitExists(unit) and UnitCanAttack("player", unit) then
                local priority = self:CalculatePriority(unit)
                if priority > bestPriority then
                    bestTarget = unit
                    bestPriority = priority
                end
            end
        end
    else
        local numParty = GetNumPartyMembers()
        for i = 1, numParty do
            local unit = "party" .. i .. "target"
            if UnitExists(unit) and UnitCanAttack("player", unit) then
                local priority = self:CalculatePriority(unit)
                if priority > bestPriority then
                    bestTarget = unit
                    bestPriority = priority
                end
            end
        end
    end
    
    -- Considerar objetivo actual del jugador
    if UnitExists("target") and UnitCanAttack("player", "target") then
        local priority = self:CalculatePriority("target")
        if priority > bestPriority then
            bestTarget = "target"
            bestPriority = priority
        end
    end
    
    if bestTarget and bestPriority > 0 then
        self:SetFocusTarget(bestTarget, bestPriority)
    end
end

function FFC:FindNextTarget()
    self.currentTarget = nil
    self.targetUnitID = nil
    self.targetPriority = 0
    
    self:ScanForPriorityTargets()
end

function FFC:ClearTarget()
    self.currentTarget = nil
    self.targetUnitID = nil
    self.targetPriority = 0
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Focus Fire]|r Objetivo limpiado", 1, 0.84, 0)
end

function FFC:GetCurrentTarget()
    return {
        unit = self.currentTarget,
        unitID = self.targetUnitID,
        priority = self.targetPriority
    }
end

function FFC:GetSquadTargets()
    return self.squadTargets
end

function FFC:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Focus Fire Status ===", 1, 0.84, 0)
    
    if self.currentTarget and UnitExists(self.currentTarget) then
        local name = UnitName(self.currentTarget)
        local healthPct = (UnitHealth(self.currentTarget) / UnitHealthMax(self.currentTarget)) * 100
        DEFAULT_CHAT_FRAME:AddMessage("Objetivo Actual: " .. name, 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("Prioridad: " .. self.targetPriority, 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Salud: %.0f%%", healthPct), 1, 1, 1)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Sin objetivo de foco", 1, 0.5, 0.5)
    end
    
    -- Mostrar objetivos del escuadrón
    local count = 0
    for player, target in pairs(self.squadTargets) do
        count = count + 1
    end
    
    if count > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("\nObjetivos del Escuadrón:", 1, 0.84, 0)
        for player, target in pairs(self.squadTargets) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s: %s (P:%d)", player, target.name, target.priority), 1, 1, 1)
        end
    end
end

function FFC:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Focus Fire]|r " .. status, 1, 0.84, 0)
end

function FFC:ToggleAutoTarget()
    self.config.autoTarget = not self.config.autoTarget
    local status = self.config.autoTarget and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Focus Fire]|r Auto-target " .. status, 1, 0.84, 0)
end
