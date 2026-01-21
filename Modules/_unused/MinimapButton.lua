-- MinimapButton.lua - Botón de Minimapa para TerrorSquadAI
-- v4.1 - Polish Update
-- Proporciona acceso rápido a la configuración y comandos

local MB = {}
TerrorSquadAI:RegisterModule("MinimapButton", MB)

-- Estado
MB.isDragging = false
MB.position = 225 -- Ángulo en grados (default: arriba-derecha)

-- Configuración
MB.config = {
    enabled = true,
    showTooltip = true,
}

function MB:Initialize()
    self:LoadPosition()
    self:CreateButton()
    
    -- Mensaje siempre visible para confirmar carga
    DEFAULT_CHAT_FRAME:AddMessage("|cFF8B0000[TerrorSquadAI]|r Minimap button cargado. Busca el icono de demonio en tu minimapa.", 1, 0.84, 0)
end

function MB:LoadPosition()
    -- Cargar posición guardada
    if TerrorSquadAI.DB and TerrorSquadAI.DB.minimapPosition then
        self.position = TerrorSquadAI.DB.minimapPosition
    end
end

function MB:SavePosition()
    if TerrorSquadAI.DB then
        TerrorSquadAI.DB.minimapPosition = self.position
    end
end

function MB:CreateButton()
    -- Crear frame del botón
    local button = CreateFrame("Button", "TerrorSquadAI_MinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:EnableMouse(true)
    button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    
    -- Textura del icono (usar un icono de raid existente por ahora)
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\Icons\\Spell_Shadow_SummonImp")
    button.icon = icon
    
    -- Borde del minimapa (estilo minimap tracking)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetWidth(54)
    border:SetHeight(54)
    border:SetPoint("CENTER", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.border = border
    
    -- Highlight
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetWidth(32)
    highlight:SetHeight(32)
    highlight:SetPoint("CENTER", 0, 0)
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button.highlight = highlight
    
    -- Scripts
    button:SetScript("OnClick", function()
        if arg1 == "LeftButton" then
            MB:OnLeftClick()
        elseif arg1 == "RightButton" then
            MB:OnRightClick()
        end
    end)
    
    button:SetScript("OnDragStart", function()
        MB.isDragging = true
    end)
    
    button:SetScript("OnDragStop", function()
        MB.isDragging = false
        MB:SavePosition()
    end)
    
    button:SetScript("OnUpdate", function()
        if MB.isDragging then
            MB:UpdatePosition()
        end
    end)
    
    button:SetScript("OnEnter", function()
        if MB.config.showTooltip then
            MB:ShowTooltip()
        end
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    self.button = button
    self:PositionButton()
end

function MB:PositionButton()
    if not self.button then return end
    
    -- Calcular posición en el borde del minimapa
    local angle = math.rad(self.position)
    local radius = 78 -- Un poco más cerca para asegurar visibilidad
    
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    
    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    self.button:Show() -- Asegurar que está visible
end

function MB:UpdatePosition()
    -- Calcular ángulo basado en posición del cursor
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    
    cx = cx / scale
    cy = cy / scale
    
    local dx = cx - mx
    local dy = cy - my
    
    self.position = math.deg(math.atan2(dy, dx))
    self:PositionButton()
end

function MB:OnLeftClick()
    -- Abrir panel de configuración
    if TerrorSquadAI.Modules.Config then
        TerrorSquadAI.Modules.Config:Toggle()
    else
        TerrorSquadAI:Print("Config module not loaded")
    end
end

function MB:OnRightClick()
    -- Mostrar menú rápido
    self:ShowQuickMenu()
end

function MB:ShowQuickMenu()
    -- Crear menú dropdown si no existe
    if not self.quickMenu then
        self:CreateQuickMenu()
    end
    
    -- Toggle del menú
    if self.quickMenu:IsShown() then
        self.quickMenu:Hide()
    else
        self.quickMenu:ClearAllPoints()
        self.quickMenu:SetPoint("TOPRIGHT", self.button, "BOTTOMLEFT", 0, 0)
        self.quickMenu:Show()
    end
end

function MB:CreateQuickMenu()
    local menu = CreateFrame("Frame", "TerrorSquadAI_QuickMenu", UIParent)
    menu:SetWidth(150)
    menu:SetHeight(180)
    menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    menu:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    menu:SetFrameStrata("DIALOG")
    menu:Hide()
    
    -- Título
    local title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", 0, -8)
    title:SetText("|cFF8B0000Terror Squad AI|r")
    
    local yOffset = -25
    
    -- Botón: Toggle IA
    local aiBtn = self:CreateMenuButton(menu, "IA: ON", yOffset, function()
        if TerrorSquadAI.DB then
            TerrorSquadAI.DB.aiEnabled = not TerrorSquadAI.DB.aiEnabled
            local status = TerrorSquadAI.DB.aiEnabled and "ON" or "OFF"
            this:SetText("IA: " .. status)
            TerrorSquadAI:Print("Sistema IA: " .. status)
        end
    end)
    yOffset = yOffset - 25
    
    -- Botón: Toggle Alertas
    local alertBtn = self:CreateMenuButton(menu, "Alertas: ON", yOffset, function()
        if TerrorSquadAI.DB then
            TerrorSquadAI.DB.alertsEnabled = not TerrorSquadAI.DB.alertsEnabled
            local status = TerrorSquadAI.DB.alertsEnabled and "ON" or "OFF"
            this:SetText("Alertas: " .. status)
        end
    end)
    yOffset = yOffset - 25
    
    -- Botón: Toggle Sync
    local syncBtn = self:CreateMenuButton(menu, "Sync: ON", yOffset, function()
        if TerrorSquadAI.DB then
            TerrorSquadAI.DB.syncEnabled = not TerrorSquadAI.DB.syncEnabled
            local status = TerrorSquadAI.DB.syncEnabled and "ON" or "OFF"
            this:SetText("Sync: " .. status)
        end
    end)
    yOffset = yOffset - 25
    
    -- Separador
    local sep = menu:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetWidth(130)
    sep:SetPoint("TOP", 0, yOffset - 5)
    sep:SetTexture(0.5, 0.5, 0.5, 0.5)
    yOffset = yOffset - 15
    
    -- Botón: Preset PvP
    local pvpBtn = self:CreateMenuButton(menu, "Modo PvP", yOffset, function()
        MB:ApplyPreset("PvP")
        menu:Hide()
    end)
    yOffset = yOffset - 25
    
    -- Botón: Preset PvE
    local pveBtn = self:CreateMenuButton(menu, "Modo PvE", yOffset, function()
        MB:ApplyPreset("PvE")
        menu:Hide()
    end)
    yOffset = yOffset - 25
    
    -- Botón: Cerrar
    local closeBtn = self:CreateMenuButton(menu, "Cerrar", yOffset, function()
        menu:Hide()
    end)
    
    -- Click afuera cierra el menú
    menu:SetScript("OnUpdate", function()
        if not MouseIsOver(menu) and not MouseIsOver(MB.button) then
            if IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then
                menu:Hide()
            end
        end
    end)
    
    self.quickMenu = menu
end

function MB:CreateMenuButton(parent, text, yOffset, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(130)
    btn:SetHeight(20)
    btn:SetPoint("TOP", 0, yOffset)
    
    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btnText:SetPoint("LEFT", 10, 0)
    btnText:SetText(text)
    btn.text = btnText
    
    btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    
    btn:SetScript("OnClick", onClick)
    
    btn.SetText = function(self, newText)
        self.text:SetText(newText)
    end
    
    return btn
end

function MB:ApplyPreset(presetName)
    if presetName == "PvP" then
        -- Configuración óptima para PvP
        if TerrorSquadAI.DB then
            TerrorSquadAI.DB.aiEnabled = true
            TerrorSquadAI.DB.alertsEnabled = true
            TerrorSquadAI.DB.syncEnabled = true
        end
        
        -- Activar módulos PvP
        local pvpModules = {"EnemyCooldowns", "TacticalRadar", "KillFeed", "PvPScorecard", "DeathWatcher"}
        for _, modName in ipairs(pvpModules) do
            if TerrorSquadAI.Modules[modName] and TerrorSquadAI.Modules[modName].config then
                TerrorSquadAI.Modules[modName].config.enabled = true
            end
        end
        
        TerrorSquadAI:Print("|cFF00FF00Modo PvP activado|r - Cooldowns enemigos, Radar, KillFeed habilitados")
        
    elseif presetName == "PvE" then
        -- Configuración óptima para PvE
        if TerrorSquadAI.DB then
            TerrorSquadAI.DB.aiEnabled = true
            TerrorSquadAI.DB.alertsEnabled = true
            TerrorSquadAI.DB.bigWigsIntegration = true
        end
        
        -- Activar módulos PvE
        local pveModules = {"BossTimerLite", "WipePredictor", "BuffMonitor", "CriticalHealthMonitor"}
        for _, modName in ipairs(pveModules) do
            if TerrorSquadAI.Modules[modName] and TerrorSquadAI.Modules[modName].config then
                TerrorSquadAI.Modules[modName].config.enabled = true
            end
        end
        
        TerrorSquadAI:Print("|cFF00FF00Modo PvE activado|r - Boss Timers, Wipe Predictor, Buff Monitor habilitados")
    end
end

function MB:ShowTooltip()
    GameTooltip:SetOwner(self.button, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    
    GameTooltip:AddLine("|cFF8B0000Terror Squad AI|r", 1, 1, 1)
    GameTooltip:AddLine(" ")
    
    -- Estado
    local aiStatus = (TerrorSquadAI.DB and TerrorSquadAI.DB.aiEnabled) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
    GameTooltip:AddDoubleLine("Sistema IA:", aiStatus, 1, 0.82, 0, 1, 1, 1)
    
    local alertStatus = (TerrorSquadAI.DB and TerrorSquadAI.DB.alertsEnabled) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
    GameTooltip:AddDoubleLine("Alertas:", alertStatus, 1, 0.82, 0, 1, 1, 1)
    
    local syncStatus = (TerrorSquadAI.DB and TerrorSquadAI.DB.syncEnabled) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
    GameTooltip:AddDoubleLine("Sync:", syncStatus, 1, 0.82, 0, 1, 1, 1)
    
    -- Contar módulos activos
    local activeModules = 0
    local totalModules = 0
    for name, mod in pairs(TerrorSquadAI.Modules) do
        totalModules = totalModules + 1
        if mod.config and mod.config.enabled then
            activeModules = activeModules + 1
        elseif not mod.config then
            activeModules = activeModules + 1 -- Módulos sin config están siempre activos
        end
    end
    
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("Módulos:", activeModules .. "/" .. totalModules, 0.5, 0.5, 1, 1, 1, 1)
    
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cFFFFFF00Click Izq:|r Abrir Config", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cFFFFFF00Click Der:|r Menú Rápido", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cFFFFFF00Arrastrar:|r Mover botón", 0.7, 0.7, 0.7)
    
    GameTooltip:Show()
end

function MB:Toggle()
    if self.button then
        if self.button:IsShown() then
            self.button:Hide()
        else
            self.button:Show()
        end
    end
end

function MB:Hide()
    if self.button then
        self.button:Hide()
    end
end

function MB:Show()
    if self.button then
        self.button:Show()
    end
end
