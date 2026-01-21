-- GnomoFury.lua - Modo Furia Gnómica para PvP

local GF = {}
TerrorSquadAI:RegisterModule("GnomoFury", GF)

-- Estado del modo furia
GF.furyMode = false
GF.furyLevel = 0
GF.furyStartTime = 0
GF.furyDuration = 30
GF.killStreak = 0
GF.lastKillTime = 0
GF.streakTimeout = 60

-- Configuración
GF.config = {
    enabled = true,
    autoActivate = true,
    minKillsForFury = 3,
    showMessages = true,
    playSound = true,
}

-- Niveles de furia
local FURY_LEVELS = {
    {name = "Enojado", kills = 3, bonus = 5},
    {name = "Furioso", kills = 5, bonus = 10},
    {name = "Ira Gnómica", kills = 7, bonus = 15},
    {name = "FURIA TOTAL", kills = 10, bonus = 25},
}

function GF:Initialize()
    self:RegisterEvents()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r GnomoFury inicializado", 1, 0.84, 0)
end

function GF:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
    frame:RegisterEvent("PLAYER_DEAD")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function()
        if event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
            -- Detectar kills en WoW 1.12
            if arg1 and string.find(arg1, UnitName("player")) then
                GF:OnPvPKill()
            end
        elseif event == "PLAYER_DEAD" then
            GF:OnPlayerDeath()
        elseif event == "PLAYER_REGEN_ENABLED" then
            GF:CheckStreakTimeout()
        end
    end)
    
    -- Timer para actualizar furia
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        GF:OnUpdate()
    end)
end

function GF:OnPvPKill()
    if not self.config.enabled then return end
    
    local now = GetTime()
    
    -- Verificar si es parte de un streak
    if now - self.lastKillTime <= self.streakTimeout then
        self.killStreak = self.killStreak + 1
    else
        self.killStreak = 1
    end
    
    self.lastKillTime = now
    
    -- Actualizar nivel de furia
    self:UpdateFuryLevel()
    
    -- Activar modo furia si es necesario
    if self.config.autoActivate and self.killStreak >= self.config.minKillsForFury then
        self:ActivateFury()
    end
    
    -- Anunciar kill streak
    self:AnnounceKillStreak()
end

-- OnCombatLog removido - no compatible con WoW 1.12
-- Ahora usamos CHAT_MSG_COMBAT_HOSTILE_DEATH

function GF:OnPlayerDeath()
    -- Perder el streak al morir
    if self.killStreak > 0 then
        if self.config.showMessages then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Gnomo Fury]|r Streak perdido: " .. self.killStreak .. " kills", 1, 0, 0)
        end
        self.killStreak = 0
        self:DeactivateFury()
    end
end

function GF:CheckStreakTimeout()
    local now = GetTime()
    if self.killStreak > 0 and now - self.lastKillTime > self.streakTimeout then
        if self.config.showMessages then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Gnomo Fury]|r Streak expirado", 1, 0.5, 0)
        end
        self.killStreak = 0
        self:DeactivateFury()
    end
end

function GF:UpdateFuryLevel()
    local newLevel = 0
    for i, level in ipairs(FURY_LEVELS) do
        if self.killStreak >= level.kills then
            newLevel = i
        end
    end
    
    if newLevel > self.furyLevel then
        self.furyLevel = newLevel
        if self.config.showMessages and newLevel > 0 then
            local levelData = FURY_LEVELS[newLevel]
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[Gnomo Fury]|r ¡Nivel alcanzado: " .. levelData.name .. "! (" .. levelData.bonus .. "% bonus)", 1, 0.4, 0)
        end
    end
end

function GF:ActivateFury()
    if self.furyMode then return end
    
    self.furyMode = true
    self.furyStartTime = GetTime()
    
    if self.config.showMessages then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[GNOMO FURY]|r ¡MODO FURIA ACTIVADO!", 1, 0, 0)
    end
    
    -- Anunciar al grupo
    if TerrorSquadAI.Modules.CommunicationSync then
        TerrorSquadAI.Modules.CommunicationSync:SendMessage("FURY", "ACTIVATED:" .. self.killStreak)
    end
    
    -- Enviar mensaje al raid
    if GetNumRaidMembers() > 0 then
        SendChatMessage("[Terror Squad] ¡FURIA GNÓMICA ACTIVADA! (" .. self.killStreak .. " kills)", "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage("[Terror Squad] ¡FURIA GNÓMICA ACTIVADA! (" .. self.killStreak .. " kills)", "PARTY")
    end
end

function GF:DeactivateFury()
    if not self.furyMode then return end
    
    self.furyMode = false
    self.furyLevel = 0
    
    if self.config.showMessages then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Gnomo Fury]|r Modo furia desactivado", 1, 0.5, 0)
    end
end

function GF:OnUpdate()
    if not self.furyMode then return end
    
    local now = GetTime()
    local elapsed = now - self.furyStartTime
    
    -- Desactivar si expiró
    if elapsed >= self.furyDuration then
        self:DeactivateFury()
    end
end

function GF:AnnounceKillStreak()
    if not self.config.showMessages then return end
    
    local messages = {
        [3] = "¡TRIPLE KILL!",
        [5] = "¡KILLING SPREE!",
        [7] = "¡RAMPAGE!",
        [10] = "¡UNSTOPPABLE!",
        [15] = "¡GODLIKE!",
    }
    
    local message = messages[self.killStreak]
    if message then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[GNOMO FURY]|r " .. message, 1, 0, 0)
        
        -- Anunciar al grupo en hitos importantes
        if GetNumRaidMembers() > 0 then
            SendChatMessage("[Terror Squad] " .. UnitName("player") .. ": " .. message .. " (" .. self.killStreak .. " kills)", "RAID")
        end
    end
end

function GF:GetFuryBonus()
    if not self.furyMode or self.furyLevel == 0 then
        return 0
    end
    
    local levelData = FURY_LEVELS[self.furyLevel]
    return levelData and levelData.bonus or 0
end

function GF:GetStatus()
    return {
        active = self.furyMode,
        level = self.furyLevel,
        killStreak = self.killStreak,
        bonus = self:GetFuryBonus(),
        timeRemaining = self.furyMode and (self.furyDuration - (GetTime() - self.furyStartTime)) or 0
    }
end

function GF:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Gnomo Fury Status ===", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage("Kill Streak: " .. self.killStreak, 1, 1, 1)
    
    if self.furyMode then
        local levelData = FURY_LEVELS[self.furyLevel]
        local timeLeft = self.furyDuration - (GetTime() - self.furyStartTime)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000MODO FURIA ACTIVO|r", 1, 0, 0)
        DEFAULT_CHAT_FRAME:AddMessage("Nivel: " .. (levelData and levelData.name or "Ninguno"), 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("Bonus: " .. self:GetFuryBonus() .. "%", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("Tiempo restante: " .. math.floor(timeLeft) .. "s", 1, 1, 1)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Estado: Inactivo", 1, 0.5, 0.5)
        if self.killStreak >= self.config.minKillsForFury then
            DEFAULT_CHAT_FRAME:AddMessage("¡Listo para activar!", 0, 1, 0)
        else
            local needed = self.config.minKillsForFury - self.killStreak
            DEFAULT_CHAT_FRAME:AddMessage("Kills necesarios: " .. needed, 1, 1, 1)
        end
    end
end

function GF:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Gnomo Fury]|r " .. status, 1, 0.84, 0)
end

function GF:ManualActivate()
    if self.killStreak >= self.config.minKillsForFury then
        self:ActivateFury()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Gnomo Fury]|r Necesitas al menos " .. self.config.minKillsForFury .. " kills", 1, 0, 0)
    end
end

function GF:ResetStreak()
    self.killStreak = 0
    self:DeactivateFury()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Gnomo Fury]|r Streak reiniciado", 1, 0.84, 0)
end
