-- BossTimerLite.lua - Timers Simples para Bosses
-- TerrorSquadAI v3.0 - Phase 4
-- Timers básicos para bosses comunes sin depender de BigWigs

local BTL = {}
TerrorSquadAI:RegisterModule("BossTimerLite", BTL)

-- Configuración
BTL.config = {
    enabled = true,
    showBars = true,
    announceTimers = true,
    warnBeforeSeconds = 5,
}

-- Estado
BTL.activeTimers = {}
BTL.currentBoss = nil

-- Base de datos de bosses y sus timers
-- TODO: Expandir con más bosses de Turtle WoW
BTL.bossData = {
    -- Molten Core
    ["Ragnaros"] = {
        timers = {
            {name = "Submerge", duration = 180, warning = "¡Ragnaros se sumerge pronto!"},
            {name = "Wrath of Ragnaros", duration = 30, warning = "¡Knockback próximo!"},
        }
    },
    ["Majordomo Executus"] = {
        timers = {
            {name = "Teleport", duration = 20, warning = "Teleport próximo"},
        }
    },
    ["Golemagg the Incinerator"] = {
        timers = {
            {name = "Earthquake", duration = 45, warning = "¡Earthquake próximo!"},
        }
    },
    
    -- Onyxia
    ["Onyxia"] = {
        timers = {
            {name = "Phase 2 (Air)", duration = 60, warning = "Fase aérea próxima"},
            {name = "Deep Breath", duration = 25, warning = "¡DEEP BREATH! Apartarse"},
        }
    },
    
    -- BWL
    ["Chromaggus"] = {
        timers = {
            {name = "Breath", duration = 30, warning = "¡Breath próximo!"},
        }
    },
    ["Nefarian"] = {
        timers = {
            {name = "Class Call", duration = 30, warning = "¡Class Call próximo!"},
            {name = "Shadow Flame", duration = 15, warning = "Shadow Flame próximo"},
        }
    },
    
    -- AQ40
    ["C'Thun"] = {
        timers = {
            {name = "Eye Beam", duration = 45, warning = "¡Eye Beam próximo!"},
        }
    },
    
    -- Naxx
    ["Kel'Thuzad"] = {
        timers = {
            {name = "Frost Blast", duration = 30, warning = "¡Frost Blast próximo!"},
            {name = "Mind Control", duration = 60, warning = "Mind Control próximo"},
        }
    },
}

function BTL:Initialize()
    self:RegisterEvents()
    self:CreateTimerFrame()
    
    if TerrorSquadAI.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r BossTimerLite inicializado", 1, 0.84, 0)
    end
end

function BTL:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
    
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_TARGET_CHANGED" then
            BTL:CheckForBoss()
        elseif event == "PLAYER_REGEN_DISABLED" then
            BTL:OnCombatStart()
        elseif event == "PLAYER_REGEN_ENABLED" then
            BTL:OnCombatEnd()
        elseif event == "CHAT_MSG_MONSTER_YELL" then
            BTL:OnBossYell(arg1, arg2)
        end
    end)
end

function BTL:CreateTimerFrame()
    self.frame = CreateFrame("Frame", "TerrorSquadAI_BossTimers", UIParent)
    self.frame:SetWidth(200)
    self.frame:SetHeight(100)
    self.frame:SetPoint("TOP", UIParent, "TOP", 0, -150)
    self.frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    self.frame:Hide()
    
    -- Título
    self.titleText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.titleText:SetPoint("TOP", 0, -8)
    self.titleText:SetText("Boss Timers")
    
    -- Container para timers
    self.timerContainer = CreateFrame("Frame", nil, self.frame)
    self.timerContainer:SetPoint("TOPLEFT", 8, -30)
    self.timerContainer:SetPoint("BOTTOMRIGHT", -8, 8)
end

function BTL:CheckForBoss()
    if not UnitExists("target") then return end
    
    local targetName = UnitName("target")
    if not targetName then return end
    
    if self.bossData[targetName] then
        self.currentBoss = targetName
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[BossTimer]|r Boss detectado: " .. targetName, 1, 0.84, 0)
    end
end

function BTL:OnCombatStart()
    if self.currentBoss and self.bossData[self.currentBoss] then
        self:StartBossTimers(self.currentBoss)
    end
end

function BTL:OnCombatEnd()
    self:ClearAllTimers()
    self.currentBoss = nil
    self.frame:Hide()
end

function BTL:StartBossTimers(bossName)
    if not self.config.enabled then return end
    
    local bossInfo = self.bossData[bossName]
    if not bossInfo then return end
    
    -- Limpiar timers anteriores
    self:ClearAllTimers()
    
    -- Iniciar nuevos timers
    for _, timerInfo in ipairs(bossInfo.timers) do
        self:StartTimer(timerInfo.name, timerInfo.duration, timerInfo.warning)
    end
    
    if self.config.showBars then
        self.frame:Show()
        self.titleText:SetText(bossName)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[BossTimer]|r Iniciados timers para " .. bossName, 1, 0.84, 0)
end

function BTL:StartTimer(name, duration, warning)
    local timer = {
        name = name,
        duration = duration,
        remaining = duration,
        warning = warning,
        warned = false,
        startTime = GetTime(),
    }
    
    table.insert(self.activeTimers, timer)
    
    -- Crear update frame para este timer
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        local elapsed = GetTime() - timer.startTime
        timer.remaining = timer.duration - elapsed
        
        if timer.remaining <= 0 then
            -- Timer completado - reiniciar
            timer.startTime = GetTime()
            timer.remaining = timer.duration
            timer.warned = false
            
            if BTL.config.announceTimers then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[Timer]|r " .. timer.name .. " - ¡AHORA!", 1, 0.5, 0)
            end
        elseif timer.remaining <= BTL.config.warnBeforeSeconds and not timer.warned then
            -- Advertencia
            timer.warned = true
            if timer.warning then
                if TerrorSquadAI.Modules.AlertSystem then
                    TerrorSquadAI.Modules.AlertSystem:ShowAlert(timer.warning, "WARNING")
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Timer]|r " .. timer.warning, 1, 1, 0)
                end
                PlaySound("RaidWarning")
            end
        end
        
        BTL:UpdateDisplay()
    end)
    
    timer.updateFrame = updateFrame
end

function BTL:UpdateDisplay()
    if not self.frame:IsShown() then return end
    
    -- Simple text display de timers activos
    local text = ""
    for i, timer in ipairs(self.activeTimers) do
        local mins = math.floor(timer.remaining / 60)
        local secs = math.floor(math.mod(timer.remaining, 60))
        local color = timer.remaining <= 5 and "|cFFFF0000" or "|cFFFFFFFF"
        text = text .. string.format("%s%s: %d:%02d|r\n", color, timer.name, mins, secs)
    end
    
    if not self.timerText then
        self.timerText = self.timerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.timerText:SetPoint("TOPLEFT", self.timerContainer, "TOPLEFT", 5, -5)
        self.timerText:SetJustifyH("LEFT")
    end
    self.timerText:SetText(text)
end

function BTL:ClearAllTimers()
    for _, timer in ipairs(self.activeTimers) do
        if timer.updateFrame then
            timer.updateFrame:SetScript("OnUpdate", nil)
        end
    end
    self.activeTimers = {}
end

function BTL:OnBossYell(message, sender)
    -- Detectar eventos por yells del boss
    -- TODO: Agregar detección de eventos específicos
end

-- Comando para iniciar timers manualmente
function BTL:ManualStart(bossName)
    if self.bossData[bossName] then
        self.currentBoss = bossName
        self:StartBossTimers(bossName)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[BossTimer]|r Boss no encontrado: " .. (bossName or "nil"), 1, 0, 0)
        self:ListBosses()
    end
end

function BTL:ListBosses()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Bosses Disponibles ===|r", 1, 0.84, 0)
    for bossName, _ in pairs(self.bossData) do
        DEFAULT_CHAT_FRAME:AddMessage("  - " .. bossName, 1, 1, 1)
    end
end

function BTL:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[BossTimerLite]|r " .. status, 1, 0.84, 0)
end

function BTL:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Boss Timer Status ===|r", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage("Boss actual: " .. (self.currentBoss or "Ninguno"), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Timers activos: " .. table.getn(self.activeTimers), 1, 1, 1)
    
    for _, timer in ipairs(self.activeTimers) do
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s: %.0fs", timer.name, timer.remaining), 1, 1, 1)
    end
end
