-- StatusIndicator.lua - Indicador de Estado del Sistema
-- TerrorSquadAI v4.1 - Polish Update
-- Pequeño indicador visual que muestra el estado del addon

local SI = {}
TerrorSquadAI:RegisterModule("StatusIndicator", SI)

-- Configuración
SI.config = {
    enabled = true,
    showInCombat = true,
    position = "TOPRIGHT", -- Esquina de la pantalla
    offsetX = -250,
    offsetY = -10,
}

-- Estado
SI.currentStatus = "OK"
SI.lastCheck = 0
SI.checkInterval = 2

function SI:Initialize()
    self:CreateIndicator()
    self:StartMonitor()
    
    if TerrorSquadAI.DEBUG then
        TerrorSquadAI:Debug("StatusIndicator inicializado")
    end
end

function SI:CreateIndicator()
    local frame = CreateFrame("Frame", "TerrorSquadAI_StatusIndicator", UIParent)
    frame:SetWidth(24)
    frame:SetHeight(24)
    frame:SetPoint(self.config.position, UIParent, self.config.position, self.config.offsetX, self.config.offsetY)
    frame:SetFrameStrata("LOW")
    frame:EnableMouse(true)
    
    -- Icono de estado
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(16)
    icon:SetHeight(16)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
    frame.icon = icon
    
    -- Texto pequeño
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 3, 0)
    text:SetText("TSA")
    text:SetTextColor(0.5, 0.5, 0.5)
    frame.text = text
    
    -- Tooltip
    frame:SetScript("OnEnter", function()
        SI:ShowTooltip()
    end)
    
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Click para abrir config
    frame:SetScript("OnMouseUp", function()
        if arg1 == "LeftButton" then
            if TerrorSquadAI.Modules.Config then
                TerrorSquadAI.Modules.Config:Toggle()
            end
        end
    end)
    
    self.frame = frame
    self:UpdateStatus()
end

function SI:StartMonitor()
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        local now = GetTime()
        if now - SI.lastCheck >= SI.checkInterval then
            SI.lastCheck = now
            SI:CheckStatus()
        end
    end)
end

function SI:CheckStatus()
    local issues = {}
    local okCount = 0
    local totalChecks = 0
    
    -- Check 1: DB cargada
    totalChecks = totalChecks + 1
    if TerrorSquadAI.DB then
        okCount = okCount + 1
    else
        table.insert(issues, "Base de datos no cargada")
    end
    
    -- Check 2: Módulos críticos
    local criticalModules = {"AIEngine", "AlertSystem", "CommunicationSync"}
    for _, modName in ipairs(criticalModules) do
        totalChecks = totalChecks + 1
        if TerrorSquadAI.Modules[modName] then
            okCount = okCount + 1
        else
            table.insert(issues, "Módulo faltante: " .. modName)
        end
    end
    
    -- Check 3: IA habilitada
    totalChecks = totalChecks + 1
    if TerrorSquadAI.DB and TerrorSquadAI.DB.aiEnabled then
        okCount = okCount + 1
    else
        table.insert(issues, "Sistema IA deshabilitado")
    end
    
    -- Determinar estado
    if table.getn(issues) == 0 then
        self.currentStatus = "OK"
        self.issues = nil
    elseif table.getn(issues) <= 1 then
        self.currentStatus = "WARNING"
        self.issues = issues
    else
        self.currentStatus = "ERROR"
        self.issues = issues
    end
    
    self:UpdateStatus()
end

function SI:UpdateStatus()
    if not self.frame then return end
    
    if self.currentStatus == "OK" then
        self.frame.icon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
        self.frame.text:SetTextColor(0.3, 0.8, 0.3)
    elseif self.currentStatus == "WARNING" then
        self.frame.icon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Waiting")
        self.frame.text:SetTextColor(1, 0.8, 0)
    else
        self.frame.icon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
        self.frame.text:SetTextColor(1, 0.3, 0.3)
    end
end

function SI:ShowTooltip()
    GameTooltip:SetOwner(self.frame, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    
    GameTooltip:AddLine("|cFF8B0000Terror Squad AI|r - Estado", 1, 1, 1)
    GameTooltip:AddLine(" ")
    
    -- Estado general
    local statusColor
    if self.currentStatus == "OK" then
        statusColor = "|cFF00FF00"
        GameTooltip:AddLine(statusColor .. "✓ Sistema funcionando correctamente|r")
    elseif self.currentStatus == "WARNING" then
        statusColor = "|cFFFFCC00"
        GameTooltip:AddLine(statusColor .. "⚠ Advertencia|r")
    else
        statusColor = "|cFFFF0000"
        GameTooltip:AddLine(statusColor .. "✗ Error detectado|r")
    end
    
    -- Mostrar issues si hay
    if self.issues and table.getn(self.issues) > 0 then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Problemas:", 1, 0.5, 0)
        for _, issue in ipairs(self.issues) do
            GameTooltip:AddLine("  - " .. issue, 1, 0.7, 0.7)
        end
    end
    
    -- Estadísticas
    GameTooltip:AddLine(" ")
    
    local moduleCount = 0
    for _ in pairs(TerrorSquadAI.Modules) do
        moduleCount = moduleCount + 1
    end
    GameTooltip:AddDoubleLine("Módulos cargados:", moduleCount, 0.7, 0.7, 0.7, 1, 1, 1)
    
    -- Estado de sistemas principales
    local aiStatus = (TerrorSquadAI.DB and TerrorSquadAI.DB.aiEnabled) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
    GameTooltip:AddDoubleLine("Sistema IA:", aiStatus, 0.7, 0.7, 0.7, 1, 1, 1)
    
    local alertStatus = (TerrorSquadAI.DB and TerrorSquadAI.DB.alertsEnabled) and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"
    GameTooltip:AddDoubleLine("Alertas:", alertStatus, 0.7, 0.7, 0.7, 1, 1, 1)
    
    -- En combate?
    if UnitAffectingCombat("player") then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFFFF0000⚔ EN COMBATE|r")
    end
    
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cFFFFFF00Click:|r Abrir configuración", 0.5, 0.5, 0.5)
    
    GameTooltip:Show()
end

function SI:Toggle()
    self.config.enabled = not self.config.enabled
    if self.config.enabled then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

function SI:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function SI:Show()
    if self.frame then
        self.frame:Show()
    end
end
