-- SmartTargeting.lua - Sistema de Targeteo Inteligente

local ST = {}
TerrorSquadAI:RegisterModule("SmartTargeting", ST)

-- Helper: Generar ID único para unidad (WoW 1.12 no tiene UnitGUID)
local function GetUnitID(unit)
    if not UnitExists(unit) then return nil end
    local name = UnitName(unit)
    local level = UnitLevel(unit)
    return name .. ":" .. level
end

-- Helper: Division segura para porcentajes de salud
local function SafeHealthPercent(unit)
    if not UnitExists(unit) then return 1 end
    local max = UnitHealthMax(unit)
    if not max or max == 0 then return 1 end
    return UnitHealth(unit) / max
end

-- Estado
ST.targetHistory = {}
ST.targetPriorities = {}
ST.lastTargetTime = 0
ST.targetCooldown = 0.5

-- Configuración
ST.config = {
    enabled = true,
    autoTarget = false,
    preferLowHealth = true,
    preferCasters = true,
    preferHealers = true,
    avoidCrowdControl = true,
    respectFocus = true,
}

-- Prioridades de targeteo
local TARGET_PRIORITIES = {
    -- Clases (PvP)
    ["PRIEST"] = 100,
    ["PALADIN"] = 95,
    ["DRUID"] = 90,
    ["SHAMAN"] = 90,
    ["MAGE"] = 85,
    ["WARLOCK"] = 85,
    ["HUNTER"] = 75,
    ["ROGUE"] = 70,
    ["WARRIOR"] = 65,
    
    -- Clasificaciones (PvE)
    ["worldboss"] = 100,
    ["rareelite"] = 90,
    ["elite"] = 80,
    ["rare"] = 75,
    ["normal"] = 60,
}

function ST:Initialize()
    self:RegisterEvents()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r SmartTargeting inicializado", 1, 0.84, 0)
end

function ST:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_TARGET_CHANGED" then
            ST:OnTargetChanged()
        elseif event == "PLAYER_REGEN_DISABLED" then
            ST:OnEnterCombat()
        elseif event == "UNIT_HEALTH" then
            ST:OnHealthChange(arg1)
        end
    end)
end

function ST:OnTargetChanged()
    if not UnitExists("target") then return end
    
    local unitID = GetUnitID("target")
    local name = UnitName("target")
    
    if not unitID then return end
    
    -- Registrar en historial
    table.insert(self.targetHistory, {
        unitID = unitID,
        name = name,
        time = GetTime(),
    })
    
    -- Mantener historial limitado
    while table.getn(self.targetHistory) > 20 do
        table.remove(self.targetHistory, 1)
    end
end

function ST:OnEnterCombat()
    if self.config.autoTarget then
        self:FindBestTarget()
    end
end

function ST:OnHealthChange(unit)
    if not self.config.enabled then return end
    if not self.config.preferLowHealth then return end
    
    -- Si un enemigo está bajo de salud, considerar cambiar target
    if UnitCanAttack("player", unit) then
        local healthPct = SafeHealthPercent(unit) * 100
        if healthPct < 20 and self.config.autoTarget then
            self:ConsiderTarget(unit)
        end
    end
end

function ST:FindBestTarget()
    if not self.config.enabled then return end
    
    local now = GetTime()
    if now - self.lastTargetTime < self.targetCooldown then
        return
    end
    
    local candidates = self:ScanForTargets()
    if table.getn(candidates) == 0 then return end
    
    -- Ordenar por prioridad
    table.sort(candidates, function(a, b)
        return a.priority > b.priority
    end)
    
    local best = candidates[1]
    if best and best.unit then
        TargetUnit(best.unit)
        self.lastTargetTime = now
    end
end

function ST:ScanForTargets()
    local candidates = {}
    
    -- Escanear targets de raid/party
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            local unit = "raid" .. i .. "target"
            if UnitExists(unit) and UnitCanAttack("player", unit) then
                local priority = self:CalculatePriority(unit)
                if priority > 0 then
                    table.insert(candidates, {
                        unit = unit,
                        priority = priority,
                        unitID = GetUnitID(unit),
                    })
                end
            end
        end
    else
        local numParty = GetNumPartyMembers()
        for i = 1, numParty do
            local unit = "party" .. i .. "target"
            if UnitExists(unit) and UnitCanAttack("player", unit) then
                local priority = self:CalculatePriority(unit)
                if priority > 0 then
                    table.insert(candidates, {
                        unit = unit,
                        priority = priority,
                        unitID = GetUnitID(unit),
                    })
                end
            end
        end
    end
    
    -- Considerar target actual
    if UnitExists("target") and UnitCanAttack("player", "target") then
        local priority = self:CalculatePriority("target")
        if priority > 0 then
            table.insert(candidates, {
                unit = "target",
                priority = priority,
                unitID = GetUnitID("target"),
            })
        end
    end
    
    -- Eliminar duplicados
    local seen = {}
    local unique = {}
    for _, candidate in ipairs(candidates) do
        if candidate.unitID and not seen[candidate.unitID] then
            seen[candidate.unitID] = true
            table.insert(unique, candidate)
        end
    end
    
    return unique
end

function ST:CalculatePriority(unit)
    if not UnitExists(unit) then return 0 end
    if not UnitCanAttack("player", unit) then return 0 end
    
    local priority = 0
    
    -- Prioridad base por clase/tipo
    if UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        priority = TARGET_PRIORITIES[class] or 60
        
        -- Bonus para healers
        if self.config.preferHealers then
            if class == "PRIEST" or class == "PALADIN" or class == "DRUID" or class == "SHAMAN" then
                priority = priority + 10
            end
        end
        
        -- Bonus para casters
        if self.config.preferCasters then
            if class == "MAGE" or class == "WARLOCK" or class == "PRIEST" then
                priority = priority + 5
            end
        end
    else
        -- PvE
        local classification = UnitClassification(unit)
        priority = TARGET_PRIORITIES[classification] or 60
    end
    
    -- Bonus por salud baja
    if self.config.preferLowHealth then
        local healthPct = SafeHealthPercent(unit) * 100
        if healthPct < 20 then
            priority = priority + 30
        elseif healthPct < 40 then
            priority = priority + 15
        elseif healthPct < 60 then
            priority = priority + 5
        end
    end
    
    -- NOTA: UnitCastingInfo/UnitChannelInfo NO existen en WoW 1.12
    -- No podemos detectar si el enemigo está casteando
    -- if UnitCastingInfo(unit) or UnitChannelInfo(unit) then
    --     priority = priority + 20
    -- end
    
    -- Penalización por CC
    if self.config.avoidCrowdControl then
        if self:IsUnderCrowdControl(unit) then
            priority = priority - 50
        end
    end
    
    -- Penalización por distancia
    local distance = self:EstimateDistance(unit)
    if distance > 30 then
        priority = priority - 20
    elseif distance > 20 then
        priority = priority - 10
    end
    
    -- Bonus si es el focus del escuadrón
    if self.config.respectFocus and TerrorSquadAI.Modules.FocusFireCoordinator then
        local focusTarget = TerrorSquadAI.Modules.FocusFireCoordinator:GetCurrentTarget()
        local unitID = GetUnitID(unit)
        if focusTarget.unitID and unitID and focusTarget.unitID == unitID then
            priority = priority + 50
        end
    end
    
    return math.max(0, priority)
end

function ST:IsUnderCrowdControl(unit)
    if not UnitExists(unit) then return false end
    
    -- Verificar debuffs comunes de CC
    local ccDebuffs = {
        "Polymorph",
        "Sap",
        "Hibernate",
        "Fear",
        "Psychic Scream",
        "Howl of Terror",
        "Seduction",
        "Banish",
        "Freezing Trap",
    }
    
    for i = 1, 16 do
        local name = UnitDebuff(unit, i)
        if name then
            for _, ccName in ipairs(ccDebuffs) do
                if string.find(name, ccName) then
                    return true
                end
            end
        end
    end
    
    return false
end

function ST:EstimateDistance(unit)
    if not UnitExists(unit) then return 999 end
    
    -- Aproximación usando CheckInteractDistance
    if CheckInteractDistance(unit, 1) then
        return 5
    elseif CheckInteractDistance(unit, 2) then
        return 10
    elseif CheckInteractDistance(unit, 3) then
        return 20
    elseif CheckInteractDistance(unit, 4) then
        return 30
    else
        return 40
    end
end

function ST:ConsiderTarget(unit)
    if not self.config.enabled then return end
    if not UnitExists(unit) then return end
    
    local currentPriority = 0
    if UnitExists("target") then
        currentPriority = self:CalculatePriority("target")
    end
    
    local newPriority = self:CalculatePriority(unit)
    
    -- Cambiar solo si es significativamente mejor
    if newPriority > currentPriority + 20 then
        TargetUnit(unit)
    end
end

function ST:TargetNearest()
    if not self.config.enabled then return end
    
    TargetNearestEnemy()
    
    -- Verificar si es un buen target
    if UnitExists("target") then
        local priority = self:CalculatePriority("target")
        if priority < 30 then
            -- Buscar mejor target
            self:FindBestTarget()
        end
    end
end

function ST:TargetLowestHealth()
    if not self.config.enabled then return end
    
    local candidates = self:ScanForTargets()
    if table.getn(candidates) == 0 then return end
    
    -- Ordenar por salud
    table.sort(candidates, function(a, b)
        local healthA = SafeHealthPercent(a.unit)
        local healthB = SafeHealthPercent(b.unit)
        return healthA < healthB
    end)
    
    if candidates[1] and candidates[1].unit then
        TargetUnit(candidates[1].unit)
    end
end

function ST:TargetHighestPriority()
    self:FindBestTarget()
end

function ST:CycleTargets()
    if not self.config.enabled then return end
    
    local candidates = self:ScanForTargets()
    if table.getn(candidates) == 0 then return end
    
    -- Encontrar target actual en la lista
    local currentID = UnitExists("target") and GetUnitID("target") or nil
    local currentIndex = 0
    
    for i, candidate in ipairs(candidates) do
        if candidate.unitID == currentID then
            currentIndex = i
            break
        end
    end
    
    -- Siguiente target
    local nextIndex = currentIndex + 1
    if nextIndex > table.getn(candidates) then
        nextIndex = 1
    end
    
    if candidates[nextIndex] and candidates[nextIndex].unit then
        TargetUnit(candidates[nextIndex].unit)
    end
end

function ST:GetTargetHistory()
    return self.targetHistory
end

function ST:ClearHistory()
    self.targetHistory = {}
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[SmartTargeting]|r Historial limpiado", 1, 0.84, 0)
end

function ST:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Smart Targeting Status ===", 1, 0.84, 0)
    
    DEFAULT_CHAT_FRAME:AddMessage("Auto-target: " .. (self.config.autoTarget and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Preferir HP bajo: " .. (self.config.preferLowHealth and "Sí" or "No"), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Preferir casters: " .. (self.config.preferCasters and "Sí" or "No"), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Preferir healers: " .. (self.config.preferHealers and "Sí" or "No"), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Evitar CC: " .. (self.config.avoidCrowdControl and "Sí" or "No"), 1, 1, 1)
    
    if UnitExists("target") then
        local priority = self:CalculatePriority("target")
        DEFAULT_CHAT_FRAME:AddMessage("\nTarget actual: " .. UnitName("target"), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("Prioridad: " .. priority, 1, 1, 1)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("\nHistorial: " .. table.getn(self.targetHistory) .. " targets", 1, 1, 1)
end

function ST:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[SmartTargeting]|r " .. status, 1, 0.84, 0)
end

function ST:ToggleAuto()
    self.config.autoTarget = not self.config.autoTarget
    local status = self.config.autoTarget and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[SmartTargeting]|r Auto-target " .. status, 1, 0.84, 0)
end

function ST:ToggleLowHealth()
    self.config.preferLowHealth = not self.config.preferLowHealth
    local status = self.config.preferLowHealth and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[SmartTargeting]|r Preferir HP bajo " .. status, 1, 0.84, 0)
end
