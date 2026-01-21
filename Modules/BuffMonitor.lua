-- BuffMonitor.lua - Monitor de Buffs del Raid
-- TerrorSquadAI v3.0 - Phase 3
-- Escanea y muestra buffs importantes faltantes en el raid

local BM = {}
TerrorSquadAI:RegisterModule("BuffMonitor", BM)

-- Configuración
BM.config = {
    enabled = true,
    scanInterval = 10, -- Segundos entre escaneos
    alertOnMissing = true,
    showInPanel = true,
}

-- Buffs importantes por clase/rol
local IMPORTANT_BUFFS = {
    -- Priest
    {name = "Power Word: Fortitude", shortName = "Fort", class = "PRIEST", icon = "spell_holy_wordfortitude"},
    {name = "Palabra de poder: entereza", shortName = "Fort", class = "PRIEST"},
    {name = "Prayer of Fortitude", shortName = "Fort", class = "PRIEST"},
    {name = "Divine Spirit", shortName = "Spirit", class = "PRIEST"},
    {name = "Espíritu divino", shortName = "Spirit", class = "PRIEST"},
    {name = "Shadow Protection", shortName = "Shadow", class = "PRIEST"},
    
    -- Druid
    {name = "Mark of the Wild", shortName = "MotW", class = "DRUID"},
    {name = "Marca de lo Salvaje", shortName = "MotW", class = "DRUID"},
    {name = "Gift of the Wild", shortName = "MotW", class = "DRUID"},
    {name = "Thorns", shortName = "Thorns", class = "DRUID"},
    
    -- Mage
    {name = "Arcane Intellect", shortName = "AI", class = "MAGE"},
    {name = "Intelecto Arcano", shortName = "AI", class = "MAGE"},
    {name = "Arcane Brilliance", shortName = "AI", class = "MAGE"},
    
    -- Paladin
    {name = "Blessing of Might", shortName = "Might", class = "PALADIN"},
    {name = "Bendición de poder", shortName = "Might", class = "PALADIN"},
    {name = "Blessing of Kings", shortName = "Kings", class = "PALADIN"},
    {name = "Bendición de reyes", shortName = "Kings", class = "PALADIN"},
    {name = "Blessing of Wisdom", shortName = "Wisdom", class = "PALADIN"},
    {name = "Blessing of Salvation", shortName = "Salv", class = "PALADIN"},
    
    -- Warlock
    {name = "Detect Invisibility", shortName = "DetInvis", class = "WARLOCK"},
    {name = "Unending Breath", shortName = "Water", class = "WARLOCK"},
}

-- Estado
BM.lastScan = 0
BM.buffStatus = {} -- {buffShortName = {present = X, missing = Y, players = {}}}

function BM:Initialize()
    self:RegisterEvents()
    self:StartScanner()
    
    if TerrorSquadAI.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r BuffMonitor inicializado", 1, 0.84, 0)
    end
end

function BM:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("RAID_ROSTER_UPDATE")
    frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    
    frame:SetScript("OnEvent", function()
        -- Escanear cuando cambia el grupo
        BM:ScanBuffs()
    end)
end

function BM:StartScanner()
    local frame = CreateFrame("Frame")
    local elapsed = 0
    
    frame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= BM.config.scanInterval then
            elapsed = 0
            if BM.config.enabled then
                BM:ScanBuffs()
            end
        end
    end)
end

function BM:ScanBuffs()
    local now = GetTime()
    if now - self.lastScan < 2 then return end -- Throttle
    self.lastScan = now
    
    -- Reset status
    self.buffStatus = {}
    
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid == 0 and numParty == 0 then return end
    
    -- Determinar unidades a escanear
    local units = {}
    if numRaid > 0 then
        for i = 1, numRaid do
            table.insert(units, "raid" .. i)
        end
    else
        table.insert(units, "player")
        for i = 1, numParty do
            table.insert(units, "party" .. i)
        end
    end
    
    -- Escanear cada tipo de buff
    for _, buffInfo in ipairs(IMPORTANT_BUFFS) do
        local shortName = buffInfo.shortName
        
        if not self.buffStatus[shortName] then
            self.buffStatus[shortName] = {
                present = 0,
                missing = 0,
                missingPlayers = {},
            }
        end
    end
    
    -- Escanear cada unidad
    for _, unit in ipairs(units) do
        if UnitExists(unit) and not UnitIsDead(unit) then
            self:ScanUnitBuffs(unit)
        end
    end
end

function BM:ScanUnitBuffs(unit)
    local playerName = UnitName(unit)
    if not playerName then return end
    
    -- Obtener todos los buffs del jugador
    local playerBuffs = {}
    for i = 1, 32 do
        local buffName = UnitBuff(unit, i)
        if buffName then
            playerBuffs[buffName] = true
        else
            break
        end
    end
    
    -- Verificar qué buffs importantes tiene
    local buffsSeen = {}
    
    for _, buffInfo in ipairs(IMPORTANT_BUFFS) do
        local shortName = buffInfo.shortName
        
        if not buffsSeen[shortName] then
            local hasBuff = playerBuffs[buffInfo.name]
            
            if hasBuff then
                self.buffStatus[shortName].present = self.buffStatus[shortName].present + 1
                buffsSeen[shortName] = true
            end
        end
    end
    
    -- Marcar buffs faltantes
    for shortName, status in pairs(self.buffStatus) do
        if not buffsSeen[shortName] then
            status.missing = status.missing + 1
            table.insert(status.missingPlayers, playerName)
        end
    end
end

function BM:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Estado de Buffs del Raid ===|r", 1, 0.84, 0)
    
    local hasMissing = false
    
    for shortName, status in pairs(self.buffStatus) do
        if status.missing > 0 then
            hasMissing = true
            local color = "|cFFFF0000"
            if status.missing <= 2 then
                color = "|cFFFFFF00"
            end
            
            DEFAULT_CHAT_FRAME:AddMessage(string.format("%s%s|r: %d sin buff", 
                color, shortName, status.missing), 1, 1, 1)
        end
    end
    
    if not hasMissing then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Todos tienen los buffs importantes!|r", 0, 1, 0)
    end
end

function BM:PrintDetails(shortName)
    shortName = shortName or "Fort"
    
    if not self.buffStatus[shortName] then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Buff no encontrado:|r " .. shortName, 1, 0, 0)
        return
    end
    
    local status = self.buffStatus[shortName]
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== " .. shortName .. " ===|r", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Con buff: %d  Sin buff: %d", status.present, status.missing), 1, 1, 1)
    
    if table.getn(status.missingPlayers) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Faltantes:", 1, 0.5, 0.5)
        for _, name in ipairs(status.missingPlayers) do
            DEFAULT_CHAT_FRAME:AddMessage("  - " .. name, 1, 1, 1)
        end
    end
end

function BM:GetMissingSummary()
    local summary = {}
    for shortName, status in pairs(self.buffStatus) do
        if status.missing > 0 then
            table.insert(summary, {
                buff = shortName,
                missing = status.missing,
            })
        end
    end
    return summary
end

function BM:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[BuffMonitor]|r " .. status, 1, 0.84, 0)
end

-- Comando /tsa buffs
function BM:Scan()
    self:ScanBuffs()
    self:PrintStatus()
end
