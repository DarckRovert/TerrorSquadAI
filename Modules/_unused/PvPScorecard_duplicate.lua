-- PvPScorecard.lua - Estadísticas de PvP
-- TerrorSquadAI v3.0 - Phase 2
-- Track y muestra estadísticas detalladas de PvP

local PVP = {}
TerrorSquadAI:RegisterModule("PvPScorecard", PVP)

-- Configuración
PVP.config = {
    enabled = true,
    trackBG = true,
    trackWorldPvP = true,
    announceRecords = true,
}

-- Estadísticas de sesión
PVP.session = {
    kills = 0,
    deaths = 0,
    assists = 0,
    honorableKills = 0,
    damageDealt = 0,
    healingDone = 0,
    objectivesCaptured = 0,
    killStreak = 0,
    bestKillStreak = 0,
    startTime = 0,
}

-- Estadísticas persistentes (guardadas)
PVP.stats = {}

-- Enemigos trackeados
PVP.enemyKills = {} -- {enemyName = killCount}
PVP.recentKills = {} -- {enemyName = timestamp}

function PVP:Initialize()
    self:RegisterEvents()
    self:LoadStats()
    self.session.startTime = GetTime()
    
    if TerrorSquadAI.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r PvPScorecard inicializado", 1, 0.84, 0)
    end
end

function PVP:LoadStats()
    if TerrorSquadAICharDB and TerrorSquadAICharDB.pvpStats then
        self.stats = TerrorSquadAICharDB.pvpStats
    else
        self.stats = {
            totalKills = 0,
            totalDeaths = 0,
            totalAssists = 0,
            totalHK = 0,
            bestStreak = 0,
            bgWins = 0,
            bgLosses = 0,
        }
    end
end

function PVP:SaveStats()
    if not TerrorSquadAICharDB then
        TerrorSquadAICharDB = {}
    end
    TerrorSquadAICharDB.pvpStats = self.stats
end

function PVP:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
    frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
    frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
    frame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
    frame:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
    frame:RegisterEvent("PLAYER_DEAD")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
    
    frame:SetScript("OnEvent", function()
        if event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
            PVP:OnHostileDeath(arg1)
        elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" or event == "CHAT_MSG_COMBAT_SELF_HITS" or event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
            PVP:OnPlayerDamage(arg1)
        elseif event == "CHAT_MSG_COMBAT_HONOR_GAIN" then
            PVP:OnHonorGain(arg1)
        elseif event == "PLAYER_DEAD" then
            PVP:OnPlayerDeath()
        elseif event == "PLAYER_REGEN_ENABLED" then
            PVP:OnCombatEnd()
        elseif event == "PLAYER_ENTERING_WORLD" then
            PVP:OnEnterWorld()
        elseif event == "UPDATE_BATTLEFIELD_STATUS" then
            PVP:OnBattlefieldUpdate()
        end
    end)
end

function PVP:OnPlayerDamage(message)
    if not self.config.enabled then return end
    if not message then return end
    
    -- Detectar a quién golpeamos
    -- "Golpeas a X por Y de daño." / "You hit X for Y damage."
    -- "Tu Hechizo impacta en X por Y." / "Your Spell hits X for Y."
    
    local target = nil
    
    -- Español / Inglés patrones comunes
    local _, _, t1 = string.find(message, "Golpeas a (.+) por")
    local _, _, t2 = string.find(message, "You hit (.+) for")
    local _, _, t3 = string.find(message, "impacta en (.+) por")
    local _, _, t4 = string.find(message, "hits (.+) for")
    local _, _, t5 = string.find(message, "sufre %d+ de daño de tu") -- DoTs ES
    local _, _, t6 = string.find(message, "suffers %d+ point.* from your") -- DoTs EN
    
    target = t1 or t2 or t3 or t4 or t5 or t6
    
    if target then
        self.recentKills[target] = GetTime() -- Usamos recentKills como "Tagged Enemies"
    end
end

function PVP:OnHostileDeath(message)
    if not self.config.enabled then return end
    if not message then return end
    
    -- Detectar si fue un jugador (contiene "muere" o "dies")
    local _, _, enemyName = string.find(message, "^(.+) muere")
    if not enemyName then
        _, _, enemyName = string.find(message, "^(.+) dies")
    end
    
    if enemyName then
        -- Verificar si nosotros participamos (TAGGED)
        local now = GetTime()
        local lastTagged = self.recentKills[enemyName]
        
        if lastTagged and (now - lastTagged) < 15 then
            -- Sí, le pegamos hace menos de 15 segundos -> Cuenta como Kill/Assist
            
            -- Asumimos Kill si fue muy reciente (< 2s) o si recibimos honor pronto
            -- Nota: En Vanilla es difícil distinguir Kill de Assist solo con logs
            -- contaremos todo como "Kill" para el contador personal si participamos
            
            self.session.kills = self.session.kills + 1
            self.session.killStreak = self.session.killStreak + 1
            self.stats.totalKills = self.stats.totalKills + 1
            
            -- Actualizar mejor racha
            if self.session.killStreak > self.session.bestKillStreak then
                self.session.bestKillStreak = self.session.killStreak
                
                if self.session.bestKillStreak > self.stats.bestStreak then
                    self.stats.bestStreak = self.session.bestKillStreak
                    if self.config.announceRecords then
                        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[PvP]|r ¡Nuevo récord de racha: " .. self.stats.bestStreak .. " kills!", 1, 0.4, 0)
                    end
                end
            end
            
            -- Trackear enemigo específico
            self.enemyKills[enemyName] = (self.enemyKills[enemyName] or 0) + 1
            
            self:SaveStats()
        end
        
        -- Limpiar tag
        self.recentKills[enemyName] = nil
    end
end

function PVP:OnHonorGain(message)
    if not self.config.enabled then return end
    
    -- Parsear honor ganado (formato: "X Honor Points" o "X Puntos de Honor")
    local _, _, honorStr = string.find(message, "(%d+)")
    local honor = tonumber(honorStr)
    if honor then
        self.session.honorableKills = self.session.honorableKills + 1
        self.stats.totalHK = self.stats.totalHK + 1
        self:SaveStats()
    end
end

function PVP:OnPlayerDeath()
    if not self.config.enabled then return end
    
    self.session.deaths = self.session.deaths + 1
    self.session.killStreak = 0 -- Reset racha
    self.stats.totalDeaths = self.stats.totalDeaths + 1
    
    self:SaveStats()
end

function PVP:OnCombatEnd()
    -- Limpiar kills recientes después de combate
    local now = GetTime()
    for name, time in pairs(self.recentKills) do
        if now - time > 30 then
            self.recentKills[name] = nil
        end
    end
end

function PVP:OnEnterWorld()
    -- Reset sesión si es nuevo login
    if self.session.startTime == 0 then
        self.session.startTime = GetTime()
    end
end

function PVP:OnBattlefieldUpdate()
    -- Detectar cuando entramos/salimos de BG
    for i = 1, MAX_BATTLEFIELD_QUEUES do
        local status = GetBattlefieldStatus(i)
        if status == "active" then
            -- Estamos en BG
            self.inBattleground = true
            return
        end
    end
    self.inBattleground = false
end

-- Calcular K/D ratio
function PVP:GetKDRatio()
    local deaths = math.max(1, self.session.deaths)
    return self.session.kills / deaths
end

-- Calcular KDA
function PVP:GetKDA()
    local deaths = math.max(1, self.session.deaths)
    return (self.session.kills + self.session.assists) / deaths
end

-- Mostrar estadísticas
function PVP:PrintScore()
    local sessionTime = GetTime() - self.session.startTime
    local mins = math.floor(sessionTime / 60)
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== PvP Scorecard (Sesión: " .. mins .. " mins) ===|r", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00Kills:|r %d  |cFFFF0000Deaths:|r %d  |cFFFFFF00Assists:|r %d", 
        self.session.kills, self.session.deaths, self.session.assists), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("K/D: |cFF00FFFF%.2f|r  KDA: |cFF00FFFF%.2f|r", 
        self:GetKDRatio(), self:GetKDA()), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Racha actual: %d  Mejor racha: %d", 
        self.session.killStreak, self.session.bestKillStreak), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("HKs: %d", self.session.honorableKills), 1, 1, 1)
    
    -- Top 3 enemigos más matados
    local sortedEnemies = {}
    for name, count in pairs(self.enemyKills) do
        table.insert(sortedEnemies, {name = name, count = count})
    end
    table.sort(sortedEnemies, function(a, b) return a.count > b.count end)
    
    if table.getn(sortedEnemies) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700Enemigos más matados:|r", 1, 0.84, 0)
        for i = 1, math.min(3, table.getn(sortedEnemies)) do
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %d. %s: %d kills", i, sortedEnemies[i].name, sortedEnemies[i].count), 1, 1, 1)
        end
    end
end

function PVP:PrintLifetimeStats()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== PvP Stats (Lifetime) ===|r", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Total Kills: %d  Deaths: %d  Assists: %d", 
        self.stats.totalKills, self.stats.totalDeaths, self.stats.totalAssists), 1, 1, 1)
    
    local deaths = math.max(1, self.stats.totalDeaths)
    local kd = self.stats.totalKills / deaths
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Lifetime K/D: |cFF00FFFF%.2f|r", kd), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Mejor racha de todos los tiempos: %d", self.stats.bestStreak), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Total HKs: %d", self.stats.totalHK), 1, 1, 1)
end

function PVP:ResetSession()
    self.session = {
        kills = 0,
        deaths = 0,
        assists = 0,
        honorableKills = 0,
        damageDealt = 0,
        healingDone = 0,
        objectivesCaptured = 0,
        killStreak = 0,
        bestKillStreak = 0,
        startTime = GetTime(),
    }
    self.enemyKills = {}
    self.recentKills = {}
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[PvPScorecard]|r Sesión reiniciada", 1, 0.84, 0)
end

function PVP:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[PvPScorecard]|r " .. status, 1, 0.84, 0)
end
