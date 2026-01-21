-- AutoMarker.lua - Sistema Automático de Marcado de Objetivos

local AM = {}
TerrorSquadAI:RegisterModule("AutoMarker", AM)

-- Helper: Generar ID único para unidades (WoW 1.12 no tiene UnitGUID)
local function GetUnitID(unit)
    if not UnitExists(unit) then return nil end
    local name = UnitName(unit)
    local level = UnitLevel(unit)
    return name .. ":" .. level
end

-- Símbolos de raid disponibles
local RAID_ICONS = {
    {name = "Skull", id = 8, priority = 1},
    {name = "Cross", id = 7, priority = 2},
    {name = "Square", id = 6, priority = 3},
    {name = "Moon", id = 5, priority = 4},
    {name = "Triangle", id = 4, priority = 5},
    {name = "Diamond", id = 3, priority = 6},
    {name = "Circle", id = 2, priority = 7},
    {name = "Star", id = 1, priority = 8},
}

-- Configuración
AM.config = {
    enabled = true,
    autoMarkPriority = true,
    markCCs = true,
    markHealers = true,
    markTanks = false,
}

-- Estado
AM.markedTargets = {}
AM.lastMarkTime = 0
AM.markCooldown = 1 -- segundos entre marcados

function AM:Initialize()
    self:RegisterEvents()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r AutoMarker inicializado", 1, 0.84, 0)
end

function AM:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entrar en combate
    frame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Salir de combate
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_TARGET_CHANGED" then
            AM:OnTargetChanged()
        elseif event == "PLAYER_REGEN_DISABLED" then
            AM:OnEnterCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            AM:OnLeaveCombat()
        elseif event == "CHAT_MSG_ADDON" then
            AM:OnAddonMessage(arg1, arg2, arg3, arg4)
        end
    end)
end

function AM:OnTargetChanged()
    if not self.config.enabled then return end
    if not UnitExists("target") then return end
    if not UnitCanAttack("player", "target") then return end
    
    local now = GetTime()
    if now - self.lastMarkTime < self.markCooldown then return end
    
    self:ConsiderMarking("target")
end

function AM:OnEnterCombat()
    if not self.config.enabled then return end
    self:ScanForPriorityTargets()
end

function AM:OnLeaveCombat()
    -- Limpiar marcas después de combate
    self.markedTargets = {}
end

function AM:ConsiderMarking(unit)
    if not UnitExists(unit) then return end
    if GetRaidTargetIndex(unit) then return end -- Ya está marcado
    
    local unitID = GetUnitID(unit)
    if not unitID then return end
    if self.markedTargets[unitID] then return end
    
    local priority = self:GetTargetPriority(unit)
    if priority > 0 then
        self:MarkTarget(unit, priority)
    end
end

function AM:GetTargetPriority(unit)
    if not UnitExists(unit) then return 0 end
    
    local priority = 0
    local class = UnitClass(unit)
    local creatureType = UnitCreatureType(unit)
    
    -- Prioridad por clase (PvP)
    if UnitIsPlayer(unit) then
        if self.config.markHealers then
            if class == "Priest" or class == "Paladin" or class == "Druid" or class == "Shaman" then
                priority = 1 -- Máxima prioridad para healers
            end
        end
        
        -- Clases con CC peligroso
        if self.config.markCCs then
            if class == "Mage" or class == "Warlock" then
                priority = math.max(priority, 2)
            end
        end
        
        -- DPS de alto burst
        if class == "Rogue" or class == "Warrior" then
            priority = math.max(priority, 3)
        end
    else
        -- PvE: Marcar elites y jefes
        local classification = UnitClassification(unit)
        if classification == "worldboss" or classification == "rareelite" then
            priority = 1
        elseif classification == "elite" or classification == "rare" then
            priority = 2
        end
        
        -- Tipos de criaturas peligrosas
        if creatureType == "Humanoid" then
            priority = math.max(priority, 3)
        end
    end
    
    return priority
end

function AM:MarkTarget(unit, priority)
    if not UnitExists(unit) then return end
    
    -- Encontrar el icono apropiado según prioridad
    local icon = nil
    for _, raidIcon in ipairs(RAID_ICONS) do
        if raidIcon.priority == priority then
            icon = raidIcon.id
            break
        end
    end
    
    if not icon then
        icon = RAID_ICONS[priority] and RAID_ICONS[priority].id or 8
    end
    
    -- Verificar si tenemos permisos para marcar
    if not self:CanMark() then return end
    
    SetRaidTarget(unit, icon)
    
    local unitID = GetUnitID(unit)
    if unitID then
        self.markedTargets[unitID] = {
            icon = icon,
            priority = priority,
            time = GetTime()
        }
    end
    
    self.lastMarkTime = GetTime()
    
    -- Broadcast a otros miembros
    self:BroadcastMark(unitID, icon, priority)
end

function AM:CanMark()
    -- En raid, verificar si somos líder o asistente
    if GetNumRaidMembers() > 0 then
        if IsRaidLeader() or IsRaidOfficer() then
            return true
        end
        return false
    end
    
    -- En party, verificar si somos líder
    if GetNumPartyMembers() > 0 then
        if IsPartyLeader() then
            return true
        end
        -- En party todos pueden marcar
        return true
    end
    
    -- Solo, siempre podemos marcar
    return true
end

function AM:ScanForPriorityTargets()
    -- Escanear objetivos cercanos y marcar los prioritarios
    local targets = {}
    
    -- Escanear targets de raid/party
    for i = 1, 40 do
        local unit = "raid" .. i .. "target"
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            local priority = self:GetTargetPriority(unit)
            if priority > 0 then
                table.insert(targets, {unit = unit, priority = priority})
            end
        end
    end
    
    -- Ordenar por prioridad
    table.sort(targets, function(a, b) return a.priority < b.priority end)
    
    -- Marcar los primeros
    for i, target in ipairs(targets) do
        if i > 3 then break end -- Máximo 3 marcas automáticas
        self:MarkTarget(target.unit, target.priority)
    end
end

function AM:BroadcastMark(unitID, icon, priority)
    if not TerrorSquadAI.Modules.CommunicationSync then return end
    
    local data = string.format("MARK:%s:%d:%d", unitID, icon, priority)
    TerrorSquadAI.Modules.CommunicationSync:SendMessage("AUTOMARK", data)
end

function AM:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= "TerrorSquadAI" then return end
    
    local _, _, msgType, data = string.find(message, "^(%w+):(.+)$")
    if msgType == "MARK" then
        self:ReceiveMark(data, sender)
    end
end

function AM:ReceiveMark(data, sender)
    local _, _, unitID, icon, priority = string.find(data, "^([^:]+):(%d+):(%d+)$")
    if not unitID or not icon or not priority then return end
    
    icon = tonumber(icon)
    priority = tonumber(priority)
    
    -- Guardar información de marca
    self.markedTargets[unitID] = {
        icon = icon,
        priority = priority,
        time = GetTime(),
        markedBy = sender
    }
end

function AM:ClearAllMarks()
    for i = 1, 40 do
        local unit = "raid" .. i .. "target"
        if UnitExists(unit) then
            SetRaidTarget(unit, 0)
        end
    end
    
    self.markedTargets = {}
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[AutoMarker]|r Todas las marcas eliminadas", 1, 0.84, 0)
end

function AM:MarkManual(unit, iconName)
    if not UnitExists(unit) then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[AutoMarker]|r Objetivo no válido", 1, 0, 0)
        return
    end
    
    local iconId = 0
    for _, icon in ipairs(RAID_ICONS) do
        if string.lower(icon.name) == string.lower(iconName) then
            iconId = icon.id
            break
        end
    end
    
    if iconId == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[AutoMarker]|r Icono no válido: " .. iconName, 1, 0, 0)
        return
    end
    
    SetRaidTarget(unit, iconId)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[AutoMarker]|r Marcado con " .. iconName, 1, 0.84, 0)
end

function AM:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[AutoMarker]|r " .. status, 1, 0.84, 0)
end
