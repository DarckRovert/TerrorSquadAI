-- PositionOptimizer.lua - Optimizador de Posicionamiento Táctico

local PO = {}
TerrorSquadAI:RegisterModule("PositionOptimizer", PO)

-- Estado
PO.currentFormation = "NONE"
PO.squadPositions = {}
PO.lastUpdate = 0
PO.updateInterval = 2

-- Configuración
PO.config = {
    enabled = true,
    autoSuggest = true,
    announceFormations = true,
    showWarnings = true,
}

-- Formaciones tácticas
local FORMATIONS = {
    SPREAD = {
        name = "Dispersión",
        minDistance = 10,
        maxDistance = 30,
        description = "Separarse para evitar AoE",
    },
    TIGHT = {
        name = "Agrupado",
        minDistance = 0,
        maxDistance = 10,
        description = "Agruparse para heals AoE",
    },
    LINE = {
        name = "Línea",
        minDistance = 5,
        maxDistance = 15,
        description = "Formación en línea",
    },
    CIRCLE = {
        name = "Círculo",
        minDistance = 8,
        maxDistance = 12,
        description = "Rodear al objetivo",
    },
}

function PO:Initialize()
    self:RegisterEvents()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r PositionOptimizer inicializado", 1, 0.84, 0)
end

function PO:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_REGEN_DISABLED" then
            PO:OnEnterCombat()
        elseif event == "CHAT_MSG_ADDON" then
            PO:OnAddonMessage(arg1, arg2, arg3, arg4)
        end
    end)
    
    -- Timer de actualización
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        local now = GetTime()
        if now - PO.lastUpdate >= PO.updateInterval then
            PO:Update()
            PO.lastUpdate = now
        end
    end)
end

function PO:OnEnterCombat()
    if not self.config.enabled then return end
    if self.config.autoSuggest then
        self:AnalyzeAndSuggest()
    end
end

function PO:Update()
    if not self.config.enabled then return end
    if not UnitAffectingCombat("player") then return end
    
    self:UpdateSquadPositions()
    self:CheckFormationCompliance()
end

function PO:UpdateSquadPositions()
    self.squadPositions = {}
    
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
                local x, y = GetPlayerMapPosition(unit)
                if x and y and x > 0 and y > 0 then
                    table.insert(self.squadPositions, {
                        unit = unit,
                        name = UnitName(unit),
                        x = x,
                        y = y,
                    })
                end
            end
        end
    else
        local numParty = GetNumPartyMembers()
        for i = 1, numParty do
            local unit = "party" .. i
            if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
                local x, y = GetPlayerMapPosition(unit)
                if x and y and x > 0 and y > 0 then
                    table.insert(self.squadPositions, {
                        unit = unit,
                        name = UnitName(unit),
                        x = x,
                        y = y,
                    })
                end
            end
        end
        
        -- Añadir jugador
        local px, py = GetPlayerMapPosition("player")
        if px and py and px > 0 and py > 0 then
            table.insert(self.squadPositions, {
                unit = "player",
                name = UnitName("player"),
                x = px,
                y = py,
            })
        end
    end
end

function PO:AnalyzeAndSuggest()
    if not UnitExists("target") then return end
    
    local targetType = UnitClassification("target")
    local isPlayer = UnitIsPlayer("target")
    local numEnemies = self:CountNearbyEnemies()
    
    local suggestedFormation = nil
    
    -- Sugerencias basadas en situación
    if isPlayer then
        -- PvP
        if numEnemies > 3 then
            suggestedFormation = "SPREAD" -- Evitar AoE
        else
            suggestedFormation = "CIRCLE" -- Rodear
        end
    else
        -- PvE
        if targetType == "worldboss" or targetType == "rareelite" then
            suggestedFormation = "SPREAD" -- Jefes con AoE
        elseif numEnemies > 5 then
            suggestedFormation = "TIGHT" -- Muchos adds, agruparse para AoE heals
        else
            suggestedFormation = "LINE" -- Formación estándar
        end
    end
    
    if suggestedFormation and suggestedFormation ~= self.currentFormation then
        self:SuggestFormation(suggestedFormation)
    end
end

function PO:CountNearbyEnemies()
    local count = 0
    -- Esta es una aproximación, en Vanilla no hay forma directa de contar enemigos
    -- Se podría mejorar con parseo de combat log
    return count
end

function PO:SuggestFormation(formation)
    if not FORMATIONS[formation] then return end
    
    local formData = FORMATIONS[formation]
    
    if self.config.announceFormations then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Posición]|r Sugerencia: " .. formData.name, 1, 0.84, 0)
        DEFAULT_CHAT_FRAME:AddMessage("  " .. formData.description, 1, 1, 1)
        
        -- Anunciar al grupo
        local message = "[Terror Squad] Formación: " .. formData.name .. " - " .. formData.description
        if GetNumRaidMembers() > 0 then
            SendChatMessage(message, "RAID_WARNING")
        elseif GetNumPartyMembers() > 0 then
            SendChatMessage(message, "PARTY")
        end
    end
    
    self:SetFormation(formation)
end

function PO:SetFormation(formation)
    if not FORMATIONS[formation] then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Posición]|r Formación inválida", 1, 0, 0)
        return
    end
    
    self.currentFormation = formation
    
    -- Broadcast a otros miembros
    if TerrorSquadAI.Modules.CommunicationSync then
        TerrorSquadAI.Modules.CommunicationSync:SendMessage("FORMATION", formation)
    end
end

function PO:CheckFormationCompliance()
    if self.currentFormation == "NONE" then return end
    if table.getn(self.squadPositions) < 2 then return end
    
    local formation = FORMATIONS[self.currentFormation]
    if not formation then return end
    
    -- Calcular distancias promedio
    local totalDistance = 0
    local count = 0
    
    for i = 1, table.getn(self.squadPositions) do
        for j = i + 1, table.getn(self.squadPositions) do
            local pos1 = self.squadPositions[i]
            local pos2 = self.squadPositions[j]
            local distance = self:CalculateDistance(pos1.x, pos1.y, pos2.x, pos2.y)
            totalDistance = totalDistance + distance
            count = count + 1
        end
    end
    
    if count > 0 then
        local avgDistance = totalDistance / count
        
        -- Verificar si están cumpliendo la formación
        if avgDistance < formation.minDistance or avgDistance > formation.maxDistance then
            if self.config.showWarnings then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[Posición]|r Formación no cumplida - Ajustar distancia", 1, 0.5, 0)
            end
        end
    end
end

function PO:CalculateDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy) * 1000 -- Aproximación a yardas
end

function PO:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= "TerrorSquadAI" then return end
    
    local _, _, msgType, data = string.find(message, "^(%w+):(.+)$")
    if msgType == "FORMATION" then
        self:ReceiveFormation(data, sender)
    end
end

function PO:ReceiveFormation(formation, sender)
    if not FORMATIONS[formation] then return end
    
    self.currentFormation = formation
    local formData = FORMATIONS[formation]
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD700[Posición]|r %s ordenó: %s", sender, formData.name), 1, 0.84, 0)
end

function PO:CommandSpread()
    self:SetFormation("SPREAD")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Posición]|r ¡DISPERSARSE!", 1, 0.84, 0)
end

function PO:CommandTight()
    self:SetFormation("TIGHT")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Posición]|r ¡AGRUPARSE!", 1, 0.84, 0)
end

function PO:CommandLine()
    self:SetFormation("LINE")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Posición]|r Formación en línea", 1, 0.84, 0)
end

function PO:CommandCircle()
    self:SetFormation("CIRCLE")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Posición]|r Rodear al objetivo", 1, 0.84, 0)
end

function PO:ClearFormation()
    self.currentFormation = "NONE"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Posición]|r Formación libre", 1, 0.84, 0)
end

function PO:GetCurrentFormation()
    return self.currentFormation
end

function PO:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Position Optimizer Status ===", 1, 0.84, 0)
    
    if self.currentFormation ~= "NONE" then
        local formData = FORMATIONS[self.currentFormation]
        DEFAULT_CHAT_FRAME:AddMessage("Formación Actual: " .. formData.name, 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("Descripción: " .. formData.description, 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage(string.format("Distancia: %d-%d yardas", formData.minDistance, formData.maxDistance), 1, 1, 1)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Sin formación activa", 1, 0.5, 0.5)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("\nMiembros rastreados: " .. table.getn(self.squadPositions), 1, 1, 1)
end

function PO:PrintFormations()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Formaciones Disponibles ===", 1, 0.84, 0)
    
    for key, form in pairs(FORMATIONS) do
        DEFAULT_CHAT_FRAME:AddMessage(form.name .. " (" .. key .. ")", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("  " .. form.description, 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  Distancia: %d-%d yardas", form.minDistance, form.maxDistance), 0.6, 0.6, 0.6)
    end
end

function PO:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Posición]|r " .. status, 1, 0.84, 0)
end

function PO:ToggleAutoSuggest()
    self.config.autoSuggest = not self.config.autoSuggest
    local status = self.config.autoSuggest and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Posición]|r Auto-sugerencias " .. status, 1, 0.84, 0)
end
