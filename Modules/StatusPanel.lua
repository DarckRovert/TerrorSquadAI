-- StatusPanel.lua - Panel de Estado del Escuadrón

local SP = {}
TerrorSquadAI:RegisterModule("StatusPanel", SP)

-- Estado
SP.frame = nil
SP.visible = false
SP.locked = false
SP.updateInterval = 0.5
SP.lastUpdate = 0

-- Configuración
SP.config = {
    enabled = true,
    showInCombat = true,
    showOutOfCombat = false,
    x = 0,
    y = -200,
    width = 250,
    height = 150,
    alpha = 0.9,
}

function SP:Initialize()
    self:CreateFrame()
    self:RegisterEvents()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r StatusPanel inicializado", 1, 0.84, 0)
end

function SP:CreateFrame()
    local frame = CreateFrame("Frame", "TerrorSquadStatusPanel", UIParent)
    frame:SetWidth(self.config.width)
    frame:SetHeight(self.config.height)
    frame:SetPoint("TOP", UIParent, "TOP", self.config.x, self.config.y)
    frame:SetFrameStrata("MEDIUM")
    frame:SetAlpha(self.config.alpha)
    frame:Hide()
    
    -- Fondo
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetTexture(0, 0, 0, 0.7)
    frame.bg = bg
    
    -- Borde
    local border = CreateFrame("Frame", nil, frame)
    border:SetAllPoints(frame)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    border:SetBackdropBorderColor(1, 0.84, 0, 1)
    
    -- Título
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -10)
    title:SetText("|cFFFFD700Terror Squad AI|r")
    frame.title = title
    
    -- Texto de estado
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -35)
    statusText:SetJustifyH("LEFT")
    statusText:SetWidth(self.config.width - 20)
    frame.statusText = statusText
    
    -- Barra de amenaza
    local threatBar = CreateFrame("StatusBar", nil, frame)
    threatBar:SetWidth(self.config.width - 20)
    threatBar:SetHeight(20)
    threatBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
    threatBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    threatBar:SetMinMaxValues(0, 100)
    threatBar:SetValue(0)
    threatBar:SetStatusBarColor(0, 1, 0)
    frame.threatBar = threatBar
    
    local threatText = threatBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    threatText:SetPoint("CENTER", threatBar, "CENTER")
    threatText:SetText("Amenaza: 0%")
    threatBar.text = threatText
    
    -- Hacer movible
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        if not SP.locked then
            this:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        SP:SavePosition()
    end)
    
    -- Botón de cierre
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function()
        SP:Hide()
    end)
    
    self.frame = frame
end

function SP:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_REGEN_DISABLED" then
            SP:OnEnterCombat()
        elseif event == "PLAYER_REGEN_ENABLED" then
            SP:OnLeaveCombat()
        elseif event == "PLAYER_ENTERING_WORLD" then
            SP:LoadPosition()
        end
    end)
    
    -- Timer de actualización
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        local now = GetTime()
        if now - SP.lastUpdate >= SP.updateInterval then
            SP:Update()
            SP.lastUpdate = now
        end
    end)
end

function SP:OnEnterCombat()
    if self.config.enabled and self.config.showInCombat then
        self:Show()
    end
end

function SP:OnLeaveCombat()
    if not self.config.showOutOfCombat then
        self:Hide()
    end
end

function SP:Update()
    if not self.frame or not self.frame:IsShown() then return end
    
    local status = self:GatherStatus()
    self:UpdateDisplay(status)
end

function SP:GatherStatus()
    local status = {
        inCombat = UnitAffectingCombat("player"),
        health = 0,
        healthMax = 0,
        mana = 0,
        manaMax = 0,
        healthPct = 0,
        manaPct = 0,
        threat = 0,
        squadMembers = 0,
        squadAlive = 0,
        aiActive = false,
        scenario = "Ninguno",
        targetName = nil,
        targetLevel = nil,
    }
    
    -- Si estamos en combate y tenemos objetivo, mostrar info del objetivo
    local unit = "player"
    if status.inCombat and UnitExists("target") and UnitCanAttack("player", "target") then
        unit = "target"
        status.targetName = UnitName("target")
        status.targetLevel = UnitLevel("target")
    end
    
    -- Obtener stats de la unidad (player o target)
    status.health = UnitHealth(unit)
    status.healthMax = UnitHealthMax(unit)
    status.mana = UnitMana(unit)
    status.manaMax = UnitManaMax(unit)
    
    -- Calcular porcentajes
    status.healthPct = status.healthMax > 0 and (status.health / status.healthMax) * 100 or 0
    status.manaPct = status.manaMax > 0 and (status.mana / status.manaMax) * 100 or 0
    
    -- Contar miembros del escuadrón
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    if numRaid > 0 then
        status.squadMembers = numRaid
        for i = 1, numRaid do
            if not UnitIsDeadOrGhost("raid" .. i) then
                status.squadAlive = status.squadAlive + 1
            end
        end
    elseif numParty > 0 then
        status.squadMembers = numParty + 1
        status.squadAlive = 1
        for i = 1, numParty do
            if not UnitIsDeadOrGhost("party" .. i) then
                status.squadAlive = status.squadAlive + 1
            end
        end
    else
        status.squadMembers = 1
        status.squadAlive = 1
    end
    
    -- Obtener amenaza del módulo ThreatPredictor (reemplaza ThreatAnalysis)
    if TerrorSquadAI.Modules.ThreatPredictor and TerrorSquadAI.Modules.ThreatPredictor.GetCurrentThreat then
        status.threat = TerrorSquadAI.Modules.ThreatPredictor:GetCurrentThreat() or 0
    else
        status.threat = 0
    end
    
    -- Obtener estado del AI
    if TerrorSquadAI.Modules.AIEngine then
        status.aiActive = TerrorSquadAI.DB.aiEnabled or false
        status.scenario = TerrorSquadAI.Modules.AIEngine.currentScenario or "Ninguno"
    else
        status.aiActive = false
        status.scenario = "Ninguno"
    end
    
    -- v3.0 Info: Táctica Activa
    if TerrorSquadAI.Modules.TerrorTactics and TerrorSquadAI.Modules.TerrorTactics.activeTactic then
        status.activeTactic = TerrorSquadAI.Modules.TerrorTactics.activeTactic
    end
    
    -- v3.0 Info: PvP Scores (si hay actividad)
    if TerrorSquadAI.Modules.PvPScorecard and TerrorSquadAI.Modules.PvPScorecard.session then
        status.pvpKills = TerrorSquadAI.Modules.PvPScorecard.session.kills or 0
        status.pvpDeaths = TerrorSquadAI.Modules.PvPScorecard.session.deaths or 0
        if status.pvpKills > 0 or status.pvpDeaths > 0 then
            local deaths = math.max(1, status.pvpDeaths)
            status.pvpRatio = status.pvpKills / deaths
        end
    end
    
    return status
end

function SP:UpdateDisplay(status)
    if not self.frame then return end
    
    -- Actualizar texto de estado
    local text = ""
    
    -- Estado de combate
    if status.inCombat then
        text = text .. "|cFFFF0000En Combate|r\n"
        
        -- Si tenemos objetivo, mostrar su info
        if status.targetName then
            text = text .. string.format("Objetivo: |cFFFFD700%s|r", status.targetName)
            if status.targetLevel and status.targetLevel > 0 then
                text = text .. string.format(" (Nv %d)", status.targetLevel)
            end
            text = text .. "\n"
        end
    else
        text = text .. "|cFF00FF00Fuera de Combate|r\n"
    end
    
    -- Táctica Activa (v3.0 priority display)
    if status.activeTactic then
        text = text .. "|cFFFF0000⚠️ TÁCTICA: " .. string.upper(status.activeTactic) .. "|r\n"
    end
    
    -- PvP Stats (v3.0)
    if status.pvpKills then
        text = text .. string.format("PvP: |cFF00FF00%d K|r / |cFFFF0000%d D|r (%.2f)\n", status.pvpKills, status.pvpDeaths, status.pvpRatio or 0)
    end
    
    -- Salud y mana (del jugador o del objetivo según contexto)
    local label = status.targetName and "Objetivo" or "Tú"
    text = text .. string.format("%s - Salud: |cFF00FF00%.0f%%|r\n", label, status.healthPct)
    if status.manaPct > 0 then
        text = text .. string.format("%s - Mana: |cFF0080FF%.0f%%|r\n", label, status.manaPct)
    end
    
    -- Escuadrón
    text = text .. string.format("Escuadrón: |cFFFFD700%d/%d|r vivos\n", status.squadAlive, status.squadMembers)
    
    -- AI
    local aiStatus = status.aiActive and "|cFF00FF00Activo|r" or "|cFFFF0000Inactivo|r"
    text = text .. "AI: " .. aiStatus .. "\n"
    text = text .. "Escenario: |cFFFFD700" .. status.scenario .. "|r"
    
    self.frame.statusText:SetText(text)
    
    -- Actualizar barra de amenaza
    local threatValue = tonumber(status.threat) or 0
    if threatValue >= 0 and threatValue <= 100 then
        self.frame.threatBar:SetValue(threatValue)
        self.frame.threatBar.text:SetText(string.format("Amenaza: %.0f%%", threatValue))
        
        -- Color de la barra según amenaza
        if threatValue < 30 then
            self.frame.threatBar:SetStatusBarColor(0, 1, 0) -- Verde
        elseif threatValue < 60 then
            self.frame.threatBar:SetStatusBarColor(1, 1, 0) -- Amarillo
        elseif threatValue < 80 then
            self.frame.threatBar:SetStatusBarColor(1, 0.5, 0) -- Naranja
        else
            self.frame.threatBar:SetStatusBarColor(1, 0, 0) -- Rojo
        end
    end
end

function SP:Show()
    if self.frame and self.config.enabled then
        self.frame:Show()
        self.visible = true
        self:Update()
    end
end

function SP:Hide()
    if self.frame then
        self.frame:Hide()
        self.visible = false
    end
end

function SP:Toggle()
    if self.visible then
        self:Hide()
    else
        self:Show()
    end
end

function SP:Lock()
    self.locked = true
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[StatusPanel]|r Panel bloqueado", 1, 0.84, 0)
end

function SP:Unlock()
    self.locked = false
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[StatusPanel]|r Panel desbloqueado - puedes moverlo", 1, 0.84, 0)
end

function SP:SavePosition()
    if not self.frame then return end
    
    local point, _, relativePoint, x, y = self.frame:GetPoint()
    self.config.x = x
    self.config.y = y
end

function SP:LoadPosition()
    if not self.frame then return end
    
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOP", UIParent, "TOP", self.config.x, self.config.y)
end

function SP:Reset()
    self.config.x = 0
    self.config.y = -200
    self:LoadPosition()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[StatusPanel]|r Posición reiniciada", 1, 0.84, 0)
end

function SP:SetAlpha(alpha)
    alpha = math.max(0.1, math.min(1, alpha))
    self.config.alpha = alpha
    if self.frame then
        self.frame:SetAlpha(alpha)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[StatusPanel]|r Transparencia: " .. (alpha * 100) .. "%", 1, 0.84, 0)
end

function SP:SetSize(width, height)
    self.config.width = width or self.config.width
    self.config.height = height or self.config.height
    
    if self.frame then
        self.frame:SetWidth(self.config.width)
        self.frame:SetHeight(self.config.height)
        self.frame.statusText:SetWidth(self.config.width - 20)
        self.frame.threatBar:SetWidth(self.config.width - 20)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[StatusPanel]|r Tamaño actualizado", 1, 0.84, 0)
end

function SP:ToggleConfig(option)
    if self.config[option] ~= nil then
        self.config[option] = not self.config[option]
        local status = self.config[option] and "activado" or "desactivado"
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[StatusPanel]|r " .. option .. ": " .. status, 1, 0.84, 0)
    end
end
