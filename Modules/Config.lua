-- TerrorSquadAI Configuration Module
-- Configuration panel and settings management
-- Author: DarckRovert (elnazzareno)

local Config = {}
TerrorSquadAI:RegisterModule("Config", Config)

-- Config frame
Config.configFrame = nil

function Config:Initialize()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF8B0000[TSA]|r Config:Initialize() iniciando...")
    
    -- Verificar que UITheme exista
    if not TerrorSquadAI.Modules.UITheme then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[TSA ERROR]|r UITheme no está cargado!")
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF8B0000[TSA]|r UITheme OK, creando frame...")
    
    -- Llamar directamente sin pcall
    self:CreateConfigFrame()
    
    if self.configFrame then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TSA]|r Config frame creado correctamente")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[TSA ERROR]|r Config frame NO fue asignado")
    end
end

function Config:CreateConfigFrame()
    local theme = TerrorSquadAI.Modules.UITheme
    
    -- Create styled frame
    local frame = theme:CreateStyledFrame("TerrorSquadAI_ConfigFrame", UIParent, 600, 650)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()
    
    -- Title with icon
    frame.icon = theme:CreateIcon(frame, "skull", 40)
    frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -20)
    
    frame.title, frame.titleShadow = theme:CreateTitleText(frame, "CONFIGURACIÓN")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -25)
    
    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.subtitle:SetPoint("TOP", frame.title, "BOTTOM", 0, -5)
    frame.subtitle:SetText("Terror Squad AI v" .. TerrorSquadAI.Version)
    frame.subtitle:SetTextColor(0.545, 0, 0, 1)
    
    -- Close button (styled)
    frame.closeButton = theme:CreateStyledButton("TerrorSquadAI_ConfigCloseButton", frame, 30, 30, "X")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)
    frame.closeButton:SetScript("OnClick", function()
        theme:FadeOut(Config.configFrame, 0.2, true)
    end)
    
    -- Scroll frame for settings
    local scrollFrame = CreateFrame("ScrollFrame", "TerrorSquadAI_ConfigScroll", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -90)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -40, 60)
    
    -- Style scrollbar
    local scrollBar = getglobal(scrollFrame:GetName() .. "ScrollBar")
    if scrollBar then
        scrollBar:SetWidth(16)
    end
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(520)
    scrollChild:SetHeight(1200)
    scrollFrame:SetScrollChild(scrollChild)
    
    local yOffset = -10
    
    -- General Settings Section
    local generalHeader, generalLine = theme:CreateSectionHeader(scrollChild, "⚡ CONFIGURACIÓN GENERAL", yOffset)
    generalHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    generalLine:SetWidth(500)
    yOffset = yOffset - 35
    
    -- Enable AI checkbox with icon
    local aiIcon = theme:CreateIcon(scrollChild, "star", 20)
    aiIcon:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset + 2)
    
    local enableAI = CreateFrame("CheckButton", "TerrorSquadAI_EnableAI", scrollChild, "UICheckButtonTemplate")
    enableAI:SetPoint("LEFT", aiIcon, "RIGHT", 10, 0)
    enableAI.text = enableAI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enableAI.text:SetPoint("LEFT", enableAI, "RIGHT", 5, 0)
    enableAI.text:SetText("Activar Sistema de IA")
    enableAI.text:SetTextColor(1, 1, 1, 1)
    enableAI:SetScript("OnClick", function()
        TerrorSquadAI.DB.aiEnabled = this:GetChecked() == 1
        TerrorSquadAI:Print("Sistema IA: " .. (TerrorSquadAI.DB.aiEnabled and "Activado" or "Desactivado"))
    end)
    enableAI:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Sistema de IA", 1, 0.82, 0)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Activa el motor de inteligencia artificial", 1, 1, 1, true)
        GameTooltip:AddLine("que analiza la situación de combate y", 1, 1, 1, true)
        GameTooltip:AddLine("proporciona sugerencias estratégicas.", 1, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFF00FF00Recomendado:|r Siempre activado", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    enableAI:SetScript("OnLeave", function() GameTooltip:Hide() end)
    yOffset = yOffset - 30
    
    -- Enable Alerts checkbox with icon
    local alertIcon = theme:CreateIcon(scrollChild, "triangle", 20)
    alertIcon:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset + 2)
    
    local enableAlerts = CreateFrame("CheckButton", "TerrorSquadAI_EnableAlerts", scrollChild, "UICheckButtonTemplate")
    enableAlerts:SetPoint("LEFT", alertIcon, "RIGHT", 10, 0)
    enableAlerts.text = enableAlerts:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enableAlerts.text:SetPoint("LEFT", enableAlerts, "RIGHT", 5, 0)
    enableAlerts.text:SetText("Activar Sistema de Alertas")
    enableAlerts.text:SetTextColor(1, 1, 1, 1)
    enableAlerts:SetScript("OnClick", function()
        TerrorSquadAI.DB.alertsEnabled = this:GetChecked() == 1
    end)
    enableAlerts:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Sistema de Alertas", 1, 0.82, 0)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Muestra alertas visuales en pantalla", 1, 1, 1, true)
        GameTooltip:AddLine("cuando ocurren eventos importantes", 1, 1, 1, true)
        GameTooltip:AddLine("como casts enemigos, vida baja, etc.", 1, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFF00FF00Recomendado:|r Siempre activado", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    enableAlerts:SetScript("OnLeave", function() GameTooltip:Hide() end)
    yOffset = yOffset - 30
    
    -- Enable Sync checkbox with icon
    local syncIcon = theme:CreateIcon(scrollChild, "diamond", 20)
    syncIcon:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset + 2)
    
    local enableSync = CreateFrame("CheckButton", "TerrorSquadAI_EnableSync", scrollChild, "UICheckButtonTemplate")
    enableSync:SetPoint("LEFT", syncIcon, "RIGHT", 10, 0)
    enableSync.text = enableSync:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enableSync.text:SetPoint("LEFT", enableSync, "RIGHT", 5, 0)
    enableSync.text:SetText("Activar Sincronización de Escuadrón")
    enableSync.text:SetTextColor(1, 1, 1, 1)
    enableSync:SetScript("OnClick", function()
        TerrorSquadAI.DB.syncEnabled = this:GetChecked() == 1
    end)
    enableSync:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Sincronización de Escuadrón", 1, 0.82, 0)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Comparte información con otros", 1, 1, 1, true)
        GameTooltip:AddLine("miembros del grupo que tengan", 1, 1, 1, true)
        GameTooltip:AddLine("TerrorSquadAI instalado.", 1, 1, 1, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFF00FF00Recomendado:|r Para grupos de guild", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    enableSync:SetScript("OnLeave", function() GameTooltip:Hide() end)
    yOffset = yOffset - 30
    
    -- Enable BigWigs Integration checkbox with icon
    local bigWigsIcon = theme:CreateIcon(scrollChild, "moon", 20)
    bigWigsIcon:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset + 2)
    
    local enableBigWigs = CreateFrame("CheckButton", "TerrorSquadAI_EnableBigWigs", scrollChild, "UICheckButtonTemplate")
    enableBigWigs:SetPoint("LEFT", bigWigsIcon, "RIGHT", 10, 0)
    enableBigWigs.text = enableBigWigs:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enableBigWigs.text:SetPoint("LEFT", enableBigWigs, "RIGHT", 5, 0)
    enableBigWigs.text:SetText("Activar Integración con BigWigs")
    enableBigWigs.text:SetTextColor(1, 1, 1, 1)
    enableBigWigs:SetScript("OnClick", function()
        TerrorSquadAI.DB.bigWigsIntegration = this:GetChecked() == 1
    end)
    yOffset = yOffset - 50

    -- v3.0 Modules Section
    local v3Header, v3Line = theme:CreateSectionHeader(scrollChild, "🚀 MÓDULOS v3.0", yOffset)
    v3Header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    v3Line:SetWidth(500)
    yOffset = yOffset - 35

    -- Helper function for module toggles
    local function CreateModuleToggle(name, label, moduleKey, icon)
        local iconFrame = theme:CreateIcon(scrollChild, icon or "star", 20)
        iconFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset + 2)
        
        local check = CreateFrame("CheckButton", "TerrorSquadAI_Enable" .. name, scrollChild, "UICheckButtonTemplate")
        check:SetPoint("LEFT", iconFrame, "RIGHT", 10, 0)
        
        check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        check.text:SetPoint("LEFT", check, "RIGHT", 5, 0)
        check.text:SetText(label)
        check.text:SetTextColor(1, 1, 1, 1)
        
        -- Load initial state
        if TerrorSquadAI.Modules[moduleKey] and TerrorSquadAI.Modules[moduleKey].config then
            check:SetChecked(TerrorSquadAI.Modules[moduleKey].config.enabled)
        end
        
        check:SetScript("OnClick", function()
            if TerrorSquadAI.Modules[moduleKey] and TerrorSquadAI.Modules[moduleKey].config then
                TerrorSquadAI.Modules[moduleKey].config.enabled = this:GetChecked() == 1
                TerrorSquadAI:Print(label .. ": " .. (this:GetChecked() == 1 and "Activado" or "Desactivado"))
            end
        end)
        
        yOffset = yOffset - 30
        return check
    end

    -- Create toggles for new modules
    frame.toggleDeathWatcher = CreateModuleToggle("DeathWatcher", "Auto-Target (DeathWatcher)", "DeathWatcher", "skull")
    frame.togglePvP = CreateModuleToggle("PvP", "PvP Scorecard", "PvPScorecard", "sword")
    frame.toggleBossTimer = CreateModuleToggle("BossTimer", "Boss Timer Lite", "BossTimerLite", "moon")
    frame.toggleBuffs = CreateModuleToggle("Buffs", "Buff Monitor", "BuffMonitor", "star")
    frame.toggleWipe = CreateModuleToggle("Wipe", "Wipe Predictor", "WipePredictor", "triangle")
    frame.toggleHealth = CreateModuleToggle("Health", "Critical Health Monitor", "CriticalHealthMonitor", "heart")
    frame.toggleCast = CreateModuleToggle("Cast", "Enemy Cast Detection", "CastingBarHook", "square")
    frame.toggleTactics = CreateModuleToggle("Tactics", "Terror Tactics System", "TerrorTactics", "diamond")

    yOffset = yOffset - 20

    -- v4.0 Modules Section
    local v4Header, v4Line = theme:CreateSectionHeader(scrollChild, "⚔️ MÓDULOS v4.0 (PvP)", yOffset)
    v4Header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    v4Line:SetWidth(500)
    yOffset = yOffset - 35

    frame.toggleEnemyCD = CreateModuleToggle("EnemyCD", "Enemy Cooldown Tracker", "EnemyCooldowns", "skull")
    frame.toggleRadar = CreateModuleToggle("Radar", "Tactical Radar HUD", "TacticalRadar", "moon")
    frame.toggleKillFeed = CreateModuleToggle("KillFeed", "Stylized Kill Feed", "KillFeed", "sword")

    yOffset = yOffset - 20

    -- Turtle Modules Section
    local turtleHeader, turtleLine = theme:CreateSectionHeader(scrollChild, "🐢 MÓDULOS TURTLE WOW (PvE)", yOffset)
    turtleHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    turtleLine:SetWidth(500)
    yOffset = yOffset - 35

    frame.toggleEmerald = CreateModuleToggle("ES", "Emerald Sanctum", "EmeraldSanctum", "leaf")
    frame.toggleLowerKara = CreateModuleToggle("LK", "Lower Karazhan", "LowerKarazhan", "skull")

    yOffset = yOffset - 20

    -- Logistics Section
    local logisticsHeader, logisticsLine = theme:CreateSectionHeader(scrollChild, "📦 LOGÍSTICA (Phase 3)", yOffset)
    logisticsHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    logisticsLine:SetWidth(500)
    yOffset = yOffset - 35

    frame.toggleLogistics = CreateModuleToggle("Logs", "War Logistics", "WarLogistics", "diamond")

    yOffset = yOffset - 20
    
    -- AI Behavior Section
    local aiHeader, aiLine = theme:CreateSectionHeader(scrollChild, "🧠 COMPORTAMIENTO DE IA", yOffset)
    aiHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    aiLine:SetWidth(500)
    yOffset = yOffset - 35
    
    -- Aggressiveness slider with styled bar
    local aggressLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    aggressLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
    aggressLabel:SetText("⚔️ Agresividad: 70%")
    aggressLabel:SetTextColor(1, 0.82, 0, 1)
    yOffset = yOffset - 25
    
    local aggressSlider = CreateFrame("Slider", "TerrorSquadAI_AggressSlider", scrollChild, "OptionsSliderTemplate")
    aggressSlider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    aggressSlider:SetMinMaxValues(0, 1)
    aggressSlider:SetValueStep(0.1)
    aggressSlider:SetWidth(450)
    aggressSlider:SetHeight(20)
    aggressSlider:SetScript("OnValueChanged", function()
        local value = this:GetValue()
        TerrorSquadAI.DB.strategicPreferences.aggressiveness = value
        aggressLabel:SetText(string.format("⚔️ Agresividad: %d%%", value * 100))
    end)
    yOffset = yOffset - 45
    
    -- Defensiveness slider
    local defenseLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    defenseLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
    defenseLabel:SetText("🛡️ Defensividad: 50%")
    defenseLabel:SetTextColor(1, 0.82, 0, 1)
    yOffset = yOffset - 25
    
    local defenseSlider = CreateFrame("Slider", "TerrorSquadAI_DefenseSlider", scrollChild, "OptionsSliderTemplate")
    defenseSlider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    defenseSlider:SetMinMaxValues(0, 1)
    defenseSlider:SetValueStep(0.1)
    defenseSlider:SetWidth(450)
    defenseSlider:SetHeight(20)
    defenseSlider:SetScript("OnValueChanged", function()
        local value = this:GetValue()
        TerrorSquadAI.DB.strategicPreferences.defensiveness = value
        defenseLabel:SetText(string.format("🛡️ Defensividad: %d%%", value * 100))
    end)
    yOffset = yOffset - 45
    
    -- Coordination slider
    local coordLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    coordLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, yOffset)
    coordLabel:SetText("🤝 Prioridad de Coordinación: 90%")
    coordLabel:SetTextColor(1, 0.82, 0, 1)
    yOffset = yOffset - 25
    
    local coordSlider = CreateFrame("Slider", "TerrorSquadAI_CoordSlider", scrollChild, "OptionsSliderTemplate")
    coordSlider:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 30, yOffset)
    coordSlider:SetMinMaxValues(0, 1)
    coordSlider:SetValueStep(0.1)
    coordSlider:SetWidth(450)
    coordSlider:SetHeight(20)
    coordSlider:SetScript("OnValueChanged", function()
        local value = this:GetValue()
        TerrorSquadAI.DB.strategicPreferences.coordination = value
        coordLabel:SetText(string.format("🤝 Prioridad de Coordinación: %d%%", value * 100))
    end)
    yOffset = yOffset - 55
    
    -- Info Section
    local infoHeader, infoLine = theme:CreateSectionHeader(scrollChild, "ℹ️ INFORMACIÓN", yOffset)
    infoHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOffset)
    infoLine:SetWidth(500)
    yOffset = yOffset - 35
    
    -- Info box with styled background
    local infoBox = CreateFrame("Frame", nil, scrollChild)
    infoBox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 15, yOffset)
    infoBox:SetWidth(490)
    infoBox:SetHeight(320)
    
    infoBox.bg = infoBox:CreateTexture(nil, "BACKGROUND")
    infoBox.bg:SetAllPoints()
    infoBox.bg:SetTexture(0.1, 0.1, 0.1, 0.6)
    
    infoBox.border = infoBox:CreateTexture(nil, "BORDER")
    infoBox.border:SetPoint("TOPLEFT", infoBox, "TOPLEFT", -2, 2)
    infoBox.border:SetPoint("BOTTOMRIGHT", infoBox, "BOTTOMRIGHT", 2, -2)
    infoBox.border:SetTexture(0.545, 0, 0, 0.8)
    
    local infoText = infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    infoText:SetPoint("TOPLEFT", infoBox, "TOPLEFT", 15, -15)
    infoText:SetWidth(460)
    infoText:SetJustifyH("LEFT")
    infoText:SetTextColor(0.9, 0.9, 0.9, 1)
    infoText:SetText("\n|cFFFFD700Creado por:|r DarckRovert (elnazzareno)\n|cFFFFD700Para:|r El Sequito del Terror\n\n|cFF8B0000Este addon proporciona:|r\nGestión avanzada de escuadrones con IA, análisis de combate y coordinación táctica para contenido PvP y PvE.\n\n|cFFFFD700Características:|r\n• Análisis de amenazas en tiempo real\n• Escenarios de combate predictivos\n• Sugerencias estratégicas\n• Integración con BigWigs\n• Sincronización de escuadrón\n• Sistema de alertas personalizado\n\n|cFFFFD700Comandos:|r\n/tsai - Mostrar ayuda\n/tsai config - Abrir este panel\n/tsai toggle - Activar/Desactivar IA\n/tsai status - Mostrar estado\n/tsai sync - Forzar sincronización")
    yOffset = yOffset - 330
    
    -- Save button (styled)
    local saveButton = theme:CreateStyledButton("TerrorSquadAI_SaveButton", frame, 120, 30, "✔ Guardar")
    saveButton:SetPoint("BOTTOM", frame, "BOTTOM", -70, 15)
    saveButton:SetScript("OnClick", function()
        Config:SaveSettings()
        TerrorSquadAI:Print("|cFF00FF00¡Configuración guardada!|r")
    end)
    
    -- Reset button (styled)
    local resetButton = theme:CreateStyledButton("TerrorSquadAI_ResetButton", frame, 120, 30, "↻ Restablecer")
    resetButton:SetPoint("BOTTOM", frame, "BOTTOM", 70, 15)
    resetButton:SetScript("OnClick", function()
        Config:ResetSettings()
        Config:LoadSettings()
        TerrorSquadAI:Print("|cFFFFD700¡Configuración restablecida!|r")
    end)
    
    self.configFrame = frame
    
    -- Store references to controls
    frame.enableAI = enableAI
    frame.enableAlerts = enableAlerts
    frame.enableSync = enableSync
    frame.enableBigWigs = enableBigWigs
    frame.aggressSlider = aggressSlider
    frame.defenseSlider = defenseSlider
    frame.coordSlider = coordSlider
end

function Config:Show()
    if self.configFrame then
        self:LoadSettings()
        local theme = TerrorSquadAI.Modules.UITheme
        theme:FadeIn(self.configFrame, 0.3)
    end
end

function Config:Hide()
    if self.configFrame then
        local theme = TerrorSquadAI.Modules.UITheme
        theme:FadeOut(self.configFrame, 0.2, true)
    end
end

function Config:LoadSettings()
    if not self.configFrame then return end
    
    local frame = self.configFrame
    
    -- Load checkboxes
    frame.enableAI:SetChecked(TerrorSquadAI.DB.aiEnabled)
    frame.enableAlerts:SetChecked(TerrorSquadAI.DB.alertsEnabled)
    frame.enableSync:SetChecked(TerrorSquadAI.DB.syncEnabled)
    frame.enableBigWigs:SetChecked(TerrorSquadAI.DB.bigWigsIntegration)
    
    -- Load v3.0 Modules
    local function LoadModuleState(check, moduleKey)
        if check and TerrorSquadAI.Modules[moduleKey] and TerrorSquadAI.Modules[moduleKey].config then
            check:SetChecked(TerrorSquadAI.Modules[moduleKey].config.enabled)
        end
    end
    
    LoadModuleState(frame.toggleDeathWatcher, "DeathWatcher")
    LoadModuleState(frame.togglePvP, "PvPScorecard")
    LoadModuleState(frame.toggleBossTimer, "BossTimerLite")
    LoadModuleState(frame.toggleBuffs, "BuffMonitor")
    LoadModuleState(frame.toggleWipe, "WipePredictor")
    LoadModuleState(frame.toggleHealth, "CriticalHealthMonitor")
    LoadModuleState(frame.toggleCast, "CastingBarHook")
    LoadModuleState(frame.toggleTactics, "TerrorTactics")
    LoadModuleState(frame.toggleEnemyCD, "EnemyCooldowns")
    LoadModuleState(frame.toggleRadar, "TacticalRadar")
    LoadModuleState(frame.toggleKillFeed, "KillFeed")
    LoadModuleState(frame.toggleEmerald, "EmeraldSanctum")
    LoadModuleState(frame.toggleLowerKara, "LowerKarazhan")
    LoadModuleState(frame.toggleLogistics, "WarLogistics")
    
    -- Load sliders
    if TerrorSquadAI.DB.strategicPreferences then
        frame.aggressSlider:SetValue(TerrorSquadAI.DB.strategicPreferences.aggressiveness or 0.7)
        frame.defenseSlider:SetValue(TerrorSquadAI.DB.strategicPreferences.defensiveness or 0.5)
        frame.coordSlider:SetValue(TerrorSquadAI.DB.strategicPreferences.coordination or 0.9)
    end
end

function Config:SaveSettings()
    -- Guardar configuración de módulos en la DB
    if not TerrorSquadAI.DB.modules then 
        TerrorSquadAI.DB.modules = {} 
    end
    
    for name, module in pairs(TerrorSquadAI.Modules) do
        if module.config then
            -- Copiar tabla de config para persistencia
            TerrorSquadAI.DB.modules[name] = {}
            for k, v in pairs(module.config) do
                TerrorSquadAI.DB.modules[name][k] = v
            end
        end
    end
end

function Config:ResetSettings()
    TerrorSquadAI.DB.aiEnabled = true
    TerrorSquadAI.DB.alertsEnabled = true
    TerrorSquadAI.DB.syncEnabled = true
    TerrorSquadAI.DB.bigWigsIntegration = true
    TerrorSquadAI.DB.strategicPreferences = {
        aggressiveness = 0.7,
        defensiveness = 0.5,
        coordination = 0.9
    }
    
    -- Reset v3.0 Modules
    local function ResetModule(moduleKey)
        if TerrorSquadAI.Modules[moduleKey] and TerrorSquadAI.Modules[moduleKey].config then
            TerrorSquadAI.Modules[moduleKey].config.enabled = true
        end
    end
    
    ResetModule("DeathWatcher")
    ResetModule("PvPScorecard")
    ResetModule("BossTimerLite")
    ResetModule("BuffMonitor")
    ResetModule("WipePredictor")
    ResetModule("CriticalHealthMonitor")
    ResetModule("CastingBarHook")
    ResetModule("TerrorTactics")
    ResetModule("EnemyCooldowns")
    ResetModule("TacticalRadar")
    ResetModule("KillFeed")
    ResetModule("EmeraldSanctum")
    ResetModule("LowerKarazhan")
    ResetModule("WarLogistics")
end

-- Toggle config panel visibility
function Config:Toggle()
    if self.configFrame then
        if self.configFrame:IsShown() then
            self.configFrame:Hide()
        else
            self.configFrame:Show()
        end
    else
        TerrorSquadAI:Print("|cFFFF0000Error:|r Config frame no creado")
    end
end

-- Show config panel
function Config:Show()
    if self.configFrame then
        self.configFrame:Show()
    end
end

-- Hide config panel
function Config:Hide()
    if self.configFrame then
        self.configFrame:Hide()
    end
end

