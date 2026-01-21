-- TerrorSquadAI UI Module
-- Main user interface and tactical overlay
-- Author: DarckRovert (elnazzareno)

local UI = {}
TerrorSquadAI:RegisterModule("UI", UI)

-- UI state
UI.mainFrame = nil
UI.suggestionFrames = {}
UI.tacticalOverlay = nil
UI.isVisible = false

function UI:Initialize()
    -- Create main UI frame
    self:CreateMainFrame()
    
    -- Create tactical overlay
    self:CreateTacticalOverlay()
    
    -- Create suggestion display
    self:CreateSuggestionDisplay()
    
    TerrorSquadAI:Debug("UI initialized")
end

function UI:CreateMainFrame()
    local theme = TerrorSquadAI.Modules.UITheme
    
    -- Create styled frame
    local frame = theme:CreateStyledFrame("TerrorSquadAI_MainFrame", UIParent, 400, 300)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()
    
    -- Title with glow effect
    frame.title, frame.titleShadow = theme:CreateTitleText(frame, "TERROR SQUAD AI")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -20)
    
    -- Subtitle
    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.subtitle:SetPoint("TOP", frame.title, "BOTTOM", 0, -5)
    frame.subtitle:SetText("Sistema de Inteligencia Artificial")
    frame.subtitle:SetTextColor(0.7, 0.7, 0.7, 1)
    
    -- Icon
    frame.icon = theme:CreateIcon(frame, "skull", 48)
    frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -20)
    
    -- Status section
    local yOffset = -100
    
    frame.statusHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.statusHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, yOffset)
    frame.statusHeader:SetText("Estado del Sistema")
    frame.statusHeader:SetTextColor(0.545, 0, 0, 1)
    yOffset = yOffset - 25
    
    -- AI Status with icon
    frame.aiIcon = theme:CreateIcon(frame, "star", 20)
    frame.aiIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, yOffset)
    
    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.status:SetPoint("LEFT", frame.aiIcon, "RIGHT", 10, 0)
    frame.status:SetText("IA: |cFF00FF00Activa|r")
    yOffset = yOffset - 25
    
    -- Threat with icon
    frame.threatIcon = theme:CreateIcon(frame, "triangle", 20)
    frame.threatIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, yOffset)
    
    frame.threatText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.threatText:SetPoint("LEFT", frame.threatIcon, "RIGHT", 10, 0)
    frame.threatText:SetText("Amenaza: Ninguna")
    yOffset = yOffset - 25
    
    -- Squad with icon
    frame.squadIcon = theme:CreateIcon(frame, "diamond", 20)
    frame.squadIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, yOffset)
    
    frame.squadText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.squadText:SetPoint("LEFT", frame.squadIcon, "RIGHT", 10, 0)
    frame.squadText:SetText("Escuadrón: 0 miembros")
    yOffset = yOffset - 30
    
    -- Effectiveness bar
    frame.effectivenessLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.effectivenessLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, yOffset)
    frame.effectivenessLabel:SetText("Efectividad del Escuadrón:")
    frame.effectivenessLabel:SetTextColor(1, 0.82, 0, 1)
    yOffset = yOffset - 20
    
    frame.effectivenessBar = theme:CreateStyledStatusBar("TerrorSquadAI_EffectivenessBar", frame, 350, 20)
    frame.effectivenessBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, yOffset)
    frame.effectivenessBar:SetStatusBarColor(0, 1, 0, 1)
    frame.effectivenessBar:SetValue(0)
    frame.effectivenessBar.text:SetText("0%")
    
    -- Close button (styled)
    frame.closeButton = theme:CreateStyledButton("TerrorSquadAI_MainCloseButton", frame, 80, 25, "Cerrar")
    frame.closeButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    frame.closeButton:SetScript("OnClick", function()
        theme:FadeOut(UI.mainFrame, 0.2, true)
    end)
    
    self.mainFrame = frame
end

function UI:CreateTacticalOverlay()
    local theme = TerrorSquadAI.Modules.UITheme
    
    -- Create styled frame
    local frame = theme:CreateStyledFrame("TerrorSquadAI_TacticalOverlay", UIParent, 320, 220)
    frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -150)
    frame:SetFrameStrata("LOW")
    frame:SetAlpha(0.95)
    frame:Hide()
    
    -- Title with icon
    frame.icon = theme:CreateIcon(frame, "cross", 24)
    frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("LEFT", frame.icon, "RIGHT", 10, 0)
    frame.title:SetText("Vista Táctica")
    frame.title:SetTextColor(1, 0.82, 0, 1)
    
    local yOffset = -50
    
    -- Combat status with pulsing indicator
    frame.combatIndicator = frame:CreateTexture(nil, "OVERLAY")
    frame.combatIndicator:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    frame.combatIndicator:SetWidth(12)
    frame.combatIndicator:SetHeight(12)
    frame.combatIndicator:SetTexture(0, 1, 0, 1)
    
    frame.combatStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.combatStatus:SetPoint("LEFT", frame.combatIndicator, "RIGHT", 8, 0)
    frame.combatStatus:SetJustifyH("LEFT")
    frame.combatStatus:SetText("Estado: |cFF00FF00Inactivo|r")
    yOffset = yOffset - 25
    
    -- Scenario
    frame.scenarioIcon = theme:CreateIcon(frame, "square", 16)
    frame.scenarioIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, yOffset + 2)
    
    frame.scenario = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.scenario:SetPoint("LEFT", frame.scenarioIcon, "RIGHT", 8, 0)
    frame.scenario:SetJustifyH("LEFT")
    frame.scenario:SetText("Escenario: Desconocido")
    yOffset = yOffset - 30
    
    -- Threat section
    frame.threatLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.threatLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    frame.threatLabel:SetText("Nivel de Amenaza:")
    frame.threatLabel:SetTextColor(0.545, 0, 0, 1)
    yOffset = yOffset - 18
    
    frame.threatBar = theme:CreateStyledStatusBar("TerrorSquadAI_ThreatBar", frame, 290, 20)
    frame.threatBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    frame.threatBar:SetMinMaxValues(0, 4)
    frame.threatBar:SetValue(0)
    frame.threatBar:SetStatusBarColor(0, 1, 0, 1)
    frame.threatBar.text:SetText("Ninguna")
    yOffset = yOffset - 30
    
    -- Effectiveness section
    frame.effectivenessLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.effectivenessLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    frame.effectivenessLabel:SetText("Efectividad del Escuadrón:")
    frame.effectivenessLabel:SetTextColor(0.545, 0, 0, 1)
    yOffset = yOffset - 18
    
    frame.effectivenessBar = theme:CreateStyledStatusBar("TerrorSquadAI_EffectivenessBar2", frame, 290, 20)
    frame.effectivenessBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, yOffset)
    frame.effectivenessBar:SetStatusBarColor(1, 0.82, 0, 1)
    frame.effectivenessBar:SetValue(0)
    frame.effectivenessBar.text:SetText("N/A")
    yOffset = yOffset - 30
    
    -- Connected members
    frame.connectedIcon = theme:CreateIcon(frame, "diamond", 16)
    frame.connectedIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", 17, yOffset + 2)
    
    frame.connected = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.connected:SetPoint("LEFT", frame.connectedIcon, "RIGHT", 8, 0)
    frame.connected:SetJustifyH("LEFT")
    frame.connected:SetText("Conectados: 0")
    
    self.tacticalOverlay = frame
    
    -- Update timer
    frame:SetScript("OnUpdate", function()
        UI:UpdateTacticalOverlay()
    end)
end

function UI:CreateSuggestionDisplay()
    -- Suggestions are displayed via AlertSystem
    -- This is a placeholder for additional suggestion UI
end

function UI:Show()
    if self.mainFrame then
        local theme = TerrorSquadAI.Modules.UITheme
        theme:FadeIn(self.mainFrame, 0.3)
        self.isVisible = true
    end
end

function UI:Hide()
    if self.mainFrame then
        local theme = TerrorSquadAI.Modules.UITheme
        theme:FadeOut(self.mainFrame, 0.2, true)
        self.isVisible = false
    end
end

function UI:Toggle()
    if self.isVisible then
        self:Hide()
    else
        self:Show()
    end
end

function UI:ShowTacticalOverlay()
    if self.tacticalOverlay then
        local theme = TerrorSquadAI.Modules.UITheme
        theme:FadeIn(self.tacticalOverlay, 0.3)
    end
end

function UI:HideTacticalOverlay()
    if self.tacticalOverlay then
        local theme = TerrorSquadAI.Modules.UITheme
        theme:FadeOut(self.tacticalOverlay, 0.2, true)
    end
end

function UI:UpdateTacticalOverlay()
    if not self.tacticalOverlay or not self.tacticalOverlay:IsShown() then return end
    
    local frame = self.tacticalOverlay
    
    -- Update combat status
    if TerrorSquadAI.Modules.AIEngine then
        local aiEngine = TerrorSquadAI.Modules.AIEngine
        local inCombat = aiEngine:IsInCombat()
        
        if inCombat then
            frame.combatStatus:SetText("Estado: |cFFFF0000En Combate|r")
            frame.combatIndicator:SetTexture(1, 0, 0, 1)
            local theme = TerrorSquadAI.Modules.UITheme
            theme:PulseAnimation(frame.combatIndicator, 0.5, 1, 3)
        else
            frame.combatStatus:SetText("Estado: |cFF00FF00Inactivo|r")
            frame.combatIndicator:SetTexture(0, 1, 0, 1)
            local theme = TerrorSquadAI.Modules.UITheme
            theme:StopAnimations(frame.combatIndicator)
            frame.combatIndicator:SetAlpha(1)
        end
        
        -- Update scenario
        local scenario = aiEngine:GetCurrentScenario()
        local scenarioText = "Desconocido"
        if scenario == aiEngine.SCENARIO_BOSS_FIGHT then
            scenarioText = "Jefe"
        elseif scenario == aiEngine.SCENARIO_PVP_SKIRMISH then
            scenarioText = "Escaramuza PvP"
        elseif scenario == aiEngine.SCENARIO_PVP_BATTLEGROUND then
            scenarioText = "Campo de Batalla"
        elseif scenario == aiEngine.SCENARIO_DUNGEON_TRASH then
            scenarioText = "Mazmorra"
        elseif scenario == aiEngine.SCENARIO_WORLD_PVP then
            scenarioText = "PvP Mundial"
        end
        frame.scenario:SetText("Escenario: " .. scenarioText)
    end
    
    -- Update threat
    if TerrorSquadAI.Modules.ThreatAnalysis then
        local theme = TerrorSquadAI.Modules.UITheme
        local threat = TerrorSquadAI.Modules.ThreatAnalysis:GetCurrentThreat()
        frame.threatBar:SetValue(threat)
        
        -- Color based on threat using theme
        local color = theme:GetThreatColor(threat)
        frame.threatBar:SetStatusBarColor(color[1], color[2], color[3], color[4])
        
        local threatNames = {"Ninguna", "Baja", "Media", "Alta", "Crítica"}
        frame.threatBar.text:SetText(threatNames[threat + 1] or "Desconocida")
        
        -- Pulse animation on critical threat
        if threat >= 4 then
            theme:PulseAnimation(frame.threatBar, 0.7, 1, 2)
        else
            theme:StopAnimations(frame.threatBar)
            frame.threatBar:SetAlpha(1)
        end
    end
    
    -- Update effectiveness
    if TerrorSquadAI.Modules.SquadCoordination then
        local effectiveness = TerrorSquadAI.Modules.SquadCoordination:GetSquadEffectiveness()
        local effectivenessPercent = math.floor(effectiveness * 100)
        frame.effectivenessBar:SetValue(effectivenessPercent)
        frame.effectivenessBar.text:SetText(string.format("%d%%", effectivenessPercent))
        
        -- Color based on effectiveness
        if effectivenessPercent >= 80 then
            frame.effectivenessBar:SetStatusBarColor(0, 1, 0, 1)
        elseif effectivenessPercent >= 50 then
            frame.effectivenessBar:SetStatusBarColor(1, 1, 0, 1)
        else
            frame.effectivenessBar:SetStatusBarColor(1, 0.5, 0, 1)
        end
    end
    
    -- Update connected members
    if TerrorSquadAI.Modules.CommunicationSync then
        local connected = TerrorSquadAI.Modules.CommunicationSync:GetMemberCount()
        frame.connected:SetText("Conectados: " .. connected)
    end
end

function UI:UpdateMainFrame()
    if not self.mainFrame or not self.mainFrame:IsShown() then return end
    
    local frame = self.mainFrame
    
    -- Update status
    if TerrorSquadAI.DB.aiEnabled then
        frame.status:SetText("AI: |cFF00FF00Active|r")
    else
        frame.status:SetText("AI: |cFFFF0000Disabled|r")
    end
    
    -- Update threat
    if TerrorSquadAI.Modules.ThreatAnalysis then
        local threat = TerrorSquadAI.Modules.ThreatAnalysis:GetCurrentThreat()
        local threatNames = {"None", "Low", "Medium", "High", "Critical"}
        frame.threatText:SetText("Threat: " .. (threatNames[threat + 1] or "Unknown"))
    end
    
    -- Update squad info
    if TerrorSquadAI.Modules.SquadCoordination then
        local squadSize = TerrorSquadAI.Modules.SquadCoordination:GetSquadSize()
        frame.squadText:SetText("Squad: " .. squadSize .. " members")
    end
end

function UI:UpdateSuggestions(suggestions)
    -- Suggestions are handled by AlertSystem
    -- This could be extended for a dedicated suggestion panel
end

function UI:ShowCombatSummary(combatData)
    -- Show post-combat summary
    -- Placeholder for future implementation
end
