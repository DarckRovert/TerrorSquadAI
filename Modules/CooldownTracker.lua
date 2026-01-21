-- CooldownTracker.lua - Rastreador de Cooldowns del Escuadrón

local CT = {}
TerrorSquadAI:RegisterModule("CooldownTracker", CT)

-- Cooldowns importantes por clase
local IMPORTANT_COOLDOWNS = {
    ["WARRIOR"] = {
        {name = "Recklessness", id = 1719, duration = 1800},
        {name = "Shield Wall", id = 871, duration = 1800},
        {name = "Retaliation", id = 20230, duration = 1800},
        {name = "Death Wish", id = 12292, duration = 180},
        {name = "Sweeping Strikes", id = 12328, duration = 180},
    },
    ["PALADIN"] = {
        {name = "Divine Shield", id = 642, duration = 300},
        {name = "Lay on Hands", id = 633, duration = 3600},
        {name = "Blessing of Protection", id = 1022, duration = 300},
        {name = "Hammer of Justice", id = 853, duration = 60},
        {name = "Divine Favor", id = 20216, duration = 120},
    },
    ["HUNTER"] = {
        {name = "Rapid Fire", id = 3045, duration = 300},
        {name = "Bestial Wrath", id = 19574, duration = 120},
        {name = "Deterrence", id = 19263, duration = 300},
        {name = "Feign Death", id = 5384, duration = 30},
        {name = "Intimidation", id = 19577, duration = 60},
    },
    ["ROGUE"] = {
        {name = "Evasion", id = 5277, duration = 300},
        {name = "Blade Flurry", id = 13877, duration = 120},
        {name = "Adrenaline Rush", id = 13750, duration = 300},
        {name = "Cold Blood", id = 14177, duration = 180},
        {name = "Preparation", id = 14185, duration = 600},
    },
    ["PRIEST"] = {
        {name = "Power Infusion", id = 10060, duration = 180},
        {name = "Inner Focus", id = 14751, duration = 180},
        {name = "Fear Ward", id = 6346, duration = 30},
        {name = "Psychic Scream", id = 8122, duration = 30},
        {name = "Desperate Prayer", id = 19236, duration = 600},
    },
    ["SHAMAN"] = {
        {name = "Bloodlust", id = 2825, duration = 600},
        {name = "Nature's Swiftness", id = 16188, duration = 180},
        {name = "Elemental Mastery", id = 16166, duration = 180},
        {name = "Grounding Totem", id = 8177, duration = 45},
        {name = "Stormstrike", id = 17364, duration = 10},
    },
    ["MAGE"] = {
        {name = "Ice Block", id = 45438, duration = 300},
        {name = "Evocation", id = 12051, duration = 480},
        {name = "Combustion", id = 11129, duration = 180},
        {name = "Presence of Mind", id = 12043, duration = 180},
        {name = "Cold Snap", id = 11958, duration = 480},
    },
    ["WARLOCK"] = {
        {name = "Death Coil", id = 6789, duration = 120},
        {name = "Howl of Terror", id = 5484, duration = 40},
        {name = "Amplify Curse", id = 18288, duration = 180},
        {name = "Conflagrate", id = 17962, duration = 10},
    },
    ["DRUID"] = {
        {name = "Barkskin", id = 22812, duration = 60},
        {name = "Nature's Swiftness", id = 17116, duration = 180},
        {name = "Innervate", id = 29166, duration = 360},
        {name = "Frenzied Regeneration", id = 22842, duration = 180},
        {name = "Swiftmend", id = 18562, duration = 15},
    },
}

CT.cooldowns = {}
CT.squadCooldowns = {}
CT.lastUpdate = 0

function CT:Initialize()
    self:RegisterEvents()
    self:StartUpdateTimer()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r CooldownTracker inicializado", 1, 0.84, 0)
end

function CT:RegisterEvents()
    local frame = CreateFrame("Frame")
    -- NOTA: UNIT_SPELLCAST_SUCCEEDED NO existe en WoW 1.12 Vanilla
    -- Usamos SPELLCAST_STOP para detectar cuando el jugador termina un cast
    frame:RegisterEvent("SPELLCAST_STOP")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function()
        if event == "SPELLCAST_STOP" then
            CT:OnPlayerSpellCast()
        elseif event == "CHAT_MSG_ADDON" then
            CT:OnAddonMessage(arg1, arg2, arg3, arg4)
        elseif event == "PLAYER_ENTERING_WORLD" then
            CT:ScanCurrentCooldowns()
        end
    end)
end

function CT:StartUpdateTimer()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function()
        local now = GetTime()
        if now - CT.lastUpdate >= 5 then
            CT:UpdateCooldowns()
            CT.lastUpdate = now
        end
    end)
end

-- Reemplaza OnSpellCast con detección basada en cooldowns
function CT:OnPlayerSpellCast()
    -- Escanear cooldowns del jugador para detectar cuál se usó
    local _, playerClass = UnitClass("player")
    local classCooldowns = IMPORTANT_COOLDOWNS[playerClass]
    if not classCooldowns then return end
    
    for _, cooldown in ipairs(classCooldowns) do
        -- Buscar el hechizo y verificar si entró en cooldown
        local i = 1
        while true do
            local spellName = GetSpellName(i, BOOKTYPE_SPELL)
            if not spellName then break end
            
            if spellName == cooldown.name then
                local start, duration = GetSpellCooldown(i, BOOKTYPE_SPELL)
                if start and start > 0 and duration and duration > 1.5 then
                    -- Se activó un cooldown importante
                    self:TrackCooldown(cooldown, UnitName("player"))
                    self:BroadcastCooldown(cooldown)
                end
                break
            end
            i = i + 1
        end
    end
end

function CT:TrackCooldown(cooldown, playerName)
    local now = GetTime()
    self.cooldowns[cooldown.name] = {
        name = cooldown.name,
        player = playerName,
        startTime = now,
        duration = cooldown.duration,
        endTime = now + cooldown.duration
    }
end

function CT:BroadcastCooldown(cooldown)
    -- Usar TerrorSquadAI.Modules en lugar de TSA (no definido)
    if not TerrorSquadAI.Modules.CommunicationSync then return end
    local data = string.format("CD:%s:%d:%d", cooldown.name, GetTime(), cooldown.duration)
    TerrorSquadAI.Modules.CommunicationSync:SendMessage("COOLDOWN", data)
end

function CT:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= "TerrorSquadAI" then return end
    local _, _, msgType, data = string.find(message, "^(%w+):(.+)$")
    if msgType == "COOLDOWN" then
        self:ReceiveCooldown(data, sender)
    end
end

function CT:ReceiveCooldown(data, sender)
    local _, _, spellName, startTime, duration = string.find(data, "^([^:]+):([%d%.]+):(%d+)$")
    if not spellName or not startTime or not duration then return end
    startTime = tonumber(startTime)
    duration = tonumber(duration)
    if not self.squadCooldowns[sender] then
        self.squadCooldowns[sender] = {}
    end
    self.squadCooldowns[sender][spellName] = {
        name = spellName,
        player = sender,
        startTime = startTime,
        duration = duration,
        endTime = startTime + duration
    }
end

function CT:ScanCurrentCooldowns()
    local _, playerClass = UnitClass("player")
    local classCooldowns = IMPORTANT_COOLDOWNS[playerClass]
    if not classCooldowns then return end
    
    for _, cooldown in ipairs(classCooldowns) do
        -- Buscar el hechizo en el libro de hechizos por nombre
        local i = 1
        while true do
            local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
            if not spellName then break end
            
            if spellName == cooldown.name then
                local start, duration = GetSpellCooldown(i, BOOKTYPE_SPELL)
                if start and start > 0 and duration and duration > 1.5 then
                    self.cooldowns[cooldown.name] = {
                        name = cooldown.name,
                        player = UnitName("player"),
                        startTime = start,
                        duration = duration,
                        endTime = start + duration
                    }
                end
                break
            end
            i = i + 1
        end
    end
end

function CT:UpdateCooldowns()
    local now = GetTime()
    for name, cd in pairs(self.cooldowns) do
        if cd.endTime <= now then
            self.cooldowns[name] = nil
        end
    end
    for player, cds in pairs(self.squadCooldowns) do
        for name, cd in pairs(cds) do
            if cd.endTime <= now then
                self.squadCooldowns[player][name] = nil
            end
        end
    end
end

function CT:GetAvailableCooldowns()
    local available = {}
    local now = GetTime()
    local _, playerClass = UnitClass("player")
    local classCooldowns = IMPORTANT_COOLDOWNS[playerClass]
    if classCooldowns then
        for _, cooldown in ipairs(classCooldowns) do
            local cd = self.cooldowns[cooldown.name]
            if not cd or cd.endTime <= now then
                table.insert(available, {
                    player = UnitName("player"),
                    spell = cooldown.name,
                    ready = true
                })
            end
        end
    end
    for player, cds in pairs(self.squadCooldowns) do
        for name, cd in pairs(cds) do
            if cd.endTime <= now then
                table.insert(available, {
                    player = player,
                    spell = name,
                    ready = true
                })
            end
        end
    end
    return available
end

function CT:GetCooldownStatus(spellName, player)
    local now = GetTime()
    if not player or player == UnitName("player") then
        local cd = self.cooldowns[spellName]
        if cd then
            local remaining = cd.endTime - now
            return remaining > 0, remaining
        end
    else
        if self.squadCooldowns[player] and self.squadCooldowns[player][spellName] then
            local cd = self.squadCooldowns[player][spellName]
            local remaining = cd.endTime - now
            return remaining > 0, remaining
        end
    end
    return false, 0
end

function CT:GetAllCooldowns()
    local allCDs = {}
    local now = GetTime()
    for name, cd in pairs(self.cooldowns) do
        local remaining = math.max(0, cd.endTime - now)
        table.insert(allCDs, {
            player = cd.player,
            spell = name,
            remaining = remaining,
            ready = remaining <= 0
        })
    end
    for player, cds in pairs(self.squadCooldowns) do
        for name, cd in pairs(cds) do
            local remaining = math.max(0, cd.endTime - now)
            table.insert(allCDs, {
                player = player,
                spell = name,
                remaining = remaining,
                ready = remaining <= 0
            })
        end
    end
    return allCDs
end

function CT:PrintCooldowns()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Cooldowns del Escuadrón ===", 1, 0.84, 0)
    local allCDs = self:GetAllCooldowns()
    if table.getn(allCDs) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("No hay cooldowns rastreados", 1, 1, 1)
        return
    end
    local ready = {}
    local onCD = {}
    for _, cd in ipairs(allCDs) do
        if cd.ready then
            table.insert(ready, cd)
        else
            table.insert(onCD, cd)
        end
    end
    if table.getn(ready) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Disponibles:|r", 0.5, 1, 0.5)
        for _, cd in ipairs(ready) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s: %s", cd.player, cd.spell), 1, 1, 1)
        end
    end
    if table.getn(onCD) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000En Cooldown:|r", 1, 0.5, 0.5)
        for _, cd in ipairs(onCD) do
            local mins = math.floor(cd.remaining / 60)
            local secs = math.floor(math.mod(cd.remaining, 60))
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s: %s (%dm %ds)", cd.player, cd.spell, mins, secs), 1, 1, 1)
        end
    end
end

function CT:GetCooldownsForClass(className)
    return IMPORTANT_COOLDOWNS[className] or {}
end

function CT:IsImportantCooldown(spellName)
    for class, cooldowns in pairs(IMPORTANT_COOLDOWNS) do
        for _, cd in ipairs(cooldowns) do
            if cd.name == spellName then
                return true
            end
        end
    end
    return false
end
