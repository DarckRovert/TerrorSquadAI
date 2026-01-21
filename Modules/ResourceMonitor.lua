-- ResourceMonitor.lua - Monitor de Recursos del Escuadrón

local RM = {}
TerrorSquadAI:RegisterModule("ResourceMonitor", RM)

-- Estado
RM.squadResources = {}
RM.lastUpdate = 0
RM.updateInterval = 2
RM.lowResourceWarnings = {}

-- Configuración
RM.config = {
    enabled = true,
    trackHealth = true,
    trackMana = true,
    warnLowResources = true,
    healthThreshold = 30,
    manaThreshold = 20,
    announceToRaid = false,
}

function RM:Initialize()
    self:RegisterEvents()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r ResourceMonitor inicializado", 1, 0.84, 0)
end

function RM:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("UNIT_HEALTH")
    frame:RegisterEvent("UNIT_MANA")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:SetScript("OnEvent", function()
        if event == "UNIT_HEALTH" then
            RM:OnHealthChange(arg1)
        elseif event == "UNIT_MANA" then
            RM:OnManaChange(arg1)
        elseif event == "CHAT_MSG_ADDON" then
            RM:OnAddonMessage(arg1, arg2, arg3, arg4)
        end
    end)
    
    -- Timer de actualización
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        local now = GetTime()
        if now - RM.lastUpdate >= RM.updateInterval then
            RM:Update()
            RM.lastUpdate = now
        end
    end)
end

function RM:Update()
    if not self.config.enabled then return end
    
    self:ScanSquadResources()
    self:BroadcastResources()
    self:CheckLowResources()
end

function RM:ScanSquadResources()
    self.squadResources = {}
    
    -- Escanear raid
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            local unit = "raid" .. i
            if UnitExists(unit) then
                self:AddUnitResources(unit)
            end
        end
    else
        -- Escanear party
        local numParty = GetNumPartyMembers()
        for i = 1, numParty do
            local unit = "party" .. i
            if UnitExists(unit) then
                self:AddUnitResources(unit)
            end
        end
        
        -- Añadir jugador
        self:AddUnitResources("player")
    end
end

function RM:AddUnitResources(unit)
    if not UnitExists(unit) then return end
    
    local name = UnitName(unit)
    local health = UnitHealth(unit)
    local healthMax = UnitHealthMax(unit)
    local mana = UnitMana(unit)
    local manaMax = UnitManaMax(unit)
    local powerType = UnitPowerType(unit)
    local _, class = UnitClass(unit)
    
    local healthPct = (health / healthMax) * 100
    local manaPct = manaMax > 0 and (mana / manaMax) * 100 or 0
    
    self.squadResources[name] = {
        unit = unit,
        name = name,
        class = class,
        health = health,
        healthMax = healthMax,
        healthPct = healthPct,
        mana = mana,
        manaMax = manaMax,
        manaPct = manaPct,
        powerType = powerType,
        isDead = UnitIsDeadOrGhost(unit),
        inCombat = UnitAffectingCombat(unit),
    }
end

function RM:OnHealthChange(unit)
    if not self.config.enabled or not self.config.trackHealth then return end
    if not unit then return end
    
    local name = UnitName(unit)
    if not name then return end
    
    local health = UnitHealth(unit)
    local healthMax = UnitHealthMax(unit)
    local healthPct = (health / healthMax) * 100
    
    -- Actualizar recursos
    if self.squadResources[name] then
        self.squadResources[name].health = health
        self.squadResources[name].healthPct = healthPct
    end
    
    -- Advertir si está bajo
    if healthPct <= self.config.healthThreshold and not UnitIsDeadOrGhost(unit) then
        self:WarnLowHealth(name, healthPct)
    end
end

function RM:OnManaChange(unit)
    if not self.config.enabled or not self.config.trackMana then return end
    if not unit then return end
    
    local name = UnitName(unit)
    if not name then return end
    
    local mana = UnitMana(unit)
    local manaMax = UnitManaMax(unit)
    
    if manaMax == 0 then return end
    
    local manaPct = (mana / manaMax) * 100
    
    -- Actualizar recursos
    if self.squadResources[name] then
        self.squadResources[name].mana = mana
        self.squadResources[name].manaPct = manaPct
    end
    
    -- Advertir si está bajo
    if manaPct <= self.config.manaThreshold then
        self:WarnLowMana(name, manaPct)
    end
end

function RM:WarnLowHealth(name, healthPct)
    if not self.config.warnLowResources then return end
    
    local now = GetTime()
    local lastWarn = self.lowResourceWarnings[name .. "_health"] or 0
    
    -- No advertir más de una vez cada 10 segundos
    if now - lastWarn < 10 then return end
    
    self.lowResourceWarnings[name .. "_health"] = now
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF0000[Recursos]|r %s tiene %.0f%% HP", name, healthPct), 1, 0, 0)
    
    if self.config.announceToRaid and GetNumRaidMembers() > 0 then
        SendChatMessage(string.format("[Terror Squad] %s necesita heals (%.0f%% HP)", name, healthPct), "RAID")
    end
end

function RM:WarnLowMana(name, manaPct)
    if not self.config.warnLowResources then return end
    
    local now = GetTime()
    local lastWarn = self.lowResourceWarnings[name .. "_mana"] or 0
    
    -- No advertir más de una vez cada 15 segundos
    if now - lastWarn < 15 then return end
    
    self.lowResourceWarnings[name .. "_mana"] = now
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF0080FF[Recursos]|r %s tiene %.0f%% mana", name, manaPct), 0, 0.5, 1)
end

function RM:CheckLowResources()
    if not self.config.warnLowResources then return end
    
    local lowHealthCount = 0
    local lowManaCount = 0
    
    for name, res in pairs(self.squadResources) do
        if not res.isDead then
            if res.healthPct <= self.config.healthThreshold then
                lowHealthCount = lowHealthCount + 1
            end
            if res.manaMax > 0 and res.manaPct <= self.config.manaThreshold then
                lowManaCount = lowManaCount + 1
            end
        end
    end
    
    -- Advertir si muchos miembros están bajos
    if lowHealthCount >= 3 then
        local now = GetTime()
        local lastWarn = self.lowResourceWarnings["group_health"] or 0
        if now - lastWarn >= 20 then
            self.lowResourceWarnings["group_health"] = now
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Recursos]|r ¡" .. lowHealthCount .. " miembros con HP bajo!", 1, 0, 0)
        end
    end
end

function RM:BroadcastResources()
    if not TerrorSquadAI.Modules.CommunicationSync then return end
    
    local playerRes = self.squadResources[UnitName("player")]
    if not playerRes then return end
    
    local data = string.format("RES:%.0f:%.0f", playerRes.healthPct, playerRes.manaPct)
    TerrorSquadAI.Modules.CommunicationSync:SendMessage("RESOURCES", data)
end

function RM:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= "TerrorSquadAI" then return end
    
    local _, _, msgType, data = string.find(message, "^(%w+):(.+)$")
    if msgType == "RES" then
        self:ReceiveResources(data, sender)
    end
end

function RM:ReceiveResources(data, sender)
    local _, _, healthPct, manaPct = string.find(data, "^([%d%.]+):([%d%.]+)$")
    if not healthPct or not manaPct then return end
    
    healthPct = tonumber(healthPct)
    manaPct = tonumber(manaPct)
    
    -- Actualizar recursos del miembro remoto
    if self.squadResources[sender] then
        self.squadResources[sender].healthPct = healthPct
        self.squadResources[sender].manaPct = manaPct
    end
end

function RM:GetSquadResources()
    return self.squadResources
end

function RM:GetAverageHealth()
    local total = 0
    local count = 0
    
    for name, res in pairs(self.squadResources) do
        if not res.isDead then
            total = total + res.healthPct
            count = count + 1
        end
    end
    
    return count > 0 and (total / count) or 0
end

function RM:GetAverageMana()
    local total = 0
    local count = 0
    
    for name, res in pairs(self.squadResources) do
        if not res.isDead and res.manaMax > 0 then
            total = total + res.manaPct
            count = count + 1
        end
    end
    
    return count > 0 and (total / count) or 0
end

function RM:GetLowHealthMembers()
    local lowHealth = {}
    
    for name, res in pairs(self.squadResources) do
        if not res.isDead and res.healthPct <= self.config.healthThreshold then
            table.insert(lowHealth, {
                name = name,
                healthPct = res.healthPct,
                class = res.class,
            })
        end
    end
    
    -- Ordenar por HP más bajo
    table.sort(lowHealth, function(a, b)
        return a.healthPct < b.healthPct
    end)
    
    return lowHealth
end

function RM:GetLowManaMembers()
    local lowMana = {}
    
    for name, res in pairs(self.squadResources) do
        if not res.isDead and res.manaMax > 0 and res.manaPct <= self.config.manaThreshold then
            table.insert(lowMana, {
                name = name,
                manaPct = res.manaPct,
                class = res.class,
            })
        end
    end
    
    -- Ordenar por mana más bajo
    table.sort(lowMana, function(a, b)
        return a.manaPct < b.manaPct
    end)
    
    return lowMana
end

function RM:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Resource Monitor Status ===", 1, 0.84, 0)
    
    local avgHealth = self:GetAverageHealth()
    local avgMana = self:GetAverageMana()
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("HP Promedio: %.0f%%", avgHealth), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Mana Promedio: %.0f%%", avgMana), 1, 1, 1)
    
    local lowHealth = self:GetLowHealthMembers()
    if table.getn(lowHealth) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("\n|cFFFF0000Miembros con HP bajo:|r", 1, 0, 0)
        for i, member in ipairs(lowHealth) do
            if i <= 5 then -- Mostrar solo los primeros 5
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s: %.0f%%", member.name, member.healthPct), 1, 1, 1)
            end
        end
    end
    
    local lowMana = self:GetLowManaMembers()
    if table.getn(lowMana) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("\n|cFF0080FFMiembros con mana bajo:|r", 0, 0.5, 1)
        for i, member in ipairs(lowMana) do
            if i <= 5 then -- Mostrar solo los primeros 5
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s: %.0f%%", member.name, member.manaPct), 1, 1, 1)
            end
        end
    end
end

function RM:PrintDetailedStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Recursos del Escuadrón ===", 1, 0.84, 0)
    
    local members = {}
    for name, res in pairs(self.squadResources) do
        table.insert(members, res)
    end
    
    -- Ordenar por HP
    table.sort(members, function(a, b)
        return a.healthPct < b.healthPct
    end)
    
    for i, res in ipairs(members) do
        local status = res.isDead and "|cFF808080[MUERTO]|r" or ""
        local combat = res.inCombat and "|cFFFF0000[C]|r" or ""
        
        if res.manaMax > 0 then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %s %s - HP: %.0f%% | Mana: %.0f%%", 
                res.name, status, combat, res.healthPct, res.manaPct), 1, 1, 1)
        else
            DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %s %s - HP: %.0f%%", 
                res.name, status, combat, res.healthPct), 1, 1, 1)
        end
    end
end

function RM:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Recursos]|r " .. status, 1, 0.84, 0)
end

function RM:ToggleWarnings()
    self.config.warnLowResources = not self.config.warnLowResources
    local status = self.config.warnLowResources and "activadas" or "desactivadas"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Recursos]|r Advertencias " .. status, 1, 0.84, 0)
end

function RM:SetHealthThreshold(value)
    value = math.max(10, math.min(50, value))
    self.config.healthThreshold = value
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Recursos]|r Umbral de HP: " .. value .. "%", 1, 0.84, 0)
end

function RM:SetManaThreshold(value)
    value = math.max(10, math.min(50, value))
    self.config.manaThreshold = value
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Recursos]|r Umbral de mana: " .. value .. "%", 1, 0.84, 0)
end
