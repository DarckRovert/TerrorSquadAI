-- TerrorSquadAI Core Module
-- Advanced AI system for squad management and combat decisions
-- Author: DarckRovert (elnazzareno)
-- For: El Sequito del Terror

-- Namespace
TerrorSquadAI = {}
TerrorSquadAI.Version = "2.1.0"
TerrorSquadAI.Author = "DarckRovert"
TerrorSquadAI.Clan = "El Sequito del Terror"

-- Module registry
TerrorSquadAI.Modules = {}

-- Database
TerrorSquadAI.DB = {}
TerrorSquadAI.CharDB = {}

-- Localization
TerrorSquadAI.L = {}

-- Constants
TerrorSquadAI.ADDON_PREFIX = "TSAI"
TerrorSquadAI.DEBUG = true

-- Debug function
function TerrorSquadAI:Debug(msg)
    if self.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("[TerrorSquadAI] " .. tostring(msg), 1, 0.5, 0)
    end
end

-- Print function
function TerrorSquadAI:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("[|cFF8B0000TerrorSquadAI|r] " .. tostring(msg), 1, 1, 1)
end

-- Module registration
function TerrorSquadAI:RegisterModule(name, module)
    if not self.Modules[name] then
        self.Modules[name] = module
        self:Debug("Module registered: " .. name)
        return true
    end
    return false
end

-- Get module
function TerrorSquadAI:GetModule(name)
    return self.Modules[name]
end

-- Load localization
function TerrorSquadAI:LoadLocale()
    local locale = GetLocale()
    if locale == "esES" or locale == "esMX" then
        self.L = TerrorSquadAI_Locale_esES or {}
    else
        -- Default to Spanish for this addon
        self.L = TerrorSquadAI_Locale_esES or {}
    end
end

-- Initialize function
function TerrorSquadAI:Initialize()
    self:LoadLocale()
    self:Debug("Initializing TerrorSquadAI v" .. self.Version)
    
    -- Load saved variables
    if not TerrorSquadAIDB then
        TerrorSquadAIDB = {
            enabled = true,
            aiEnabled = true,
            alertsEnabled = true,
            syncEnabled = true,
            bigWigsIntegration = true,
            squadMembers = {},
            alertProfiles = {},
            strategicPreferences = {
                aggressiveness = 0.7,
                defensiveness = 0.5,
                coordination = 0.9
            }
        }
    end
    self.DB = TerrorSquadAIDB
    
    if not TerrorSquadAICharDB then
        TerrorSquadAICharDB = {
            position = {},
            alertHistory = {},
            combatStats = {}
        }
    end
    self.CharDB = TerrorSquadAICharDB
    
    -- Register addon communication (Vanilla WoW doesn't require prefix registration)
    -- In Vanilla, addon messages work without RegisterAddonMessagePrefix
    
    -- Initialize modules in order
    local initOrder = {
        -- UI Theme first (needed by other modules)
        "UITheme",
        -- Core modules
        "AIEngine", "ThreatAnalysis", "PredictiveSystem", "StrategicSuggestions",
        "BigWigsIntegration", "AlertSystem", "CommunicationSync", "SquadCoordination",
        -- Enhanced features
        "AutoMarker", "CooldownTracker", "GnomoFury", "TacticalPings", "StatusPanel",
        "FocusFireCoordinator", "InterruptCoordinator", "PositionOptimizer",
        "ResourceMonitor", "ThreatPredictor", "VoiceCommands", "MacroGenerator",
        "PerformanceTracker", "SmartTargeting",
        -- UI last
        "UI", "Config"
    }
    
    for _, name in ipairs(initOrder) do
        local module = self.Modules[name]
        if module and module.Initialize then
            module:Initialize()
            self:Debug("Module initialized: " .. name)
        end
    end
    
    self:Print(self.L["ADDON_LOADED"] or "¡Terror Squad AI cargado exitosamente!")
    self:Print(string.format(self.L["WELCOME_MESSAGE"] or "¡Bienvenido a El Sequito del Terror, %s!", UnitName("player")))
    self:Print("|cFFFF6600¡Modo Furia Gnómica activado! ¡Por elnazzareno y el Séquito!|r")
    
    -- Create minimap button
    self:CreateMinimapButton()
end

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "TerrorSquadAI" then
        TerrorSquadAI:Initialize()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Player entered world
        if TerrorSquadAI.Modules.SquadCoordination then
            TerrorSquadAI.Modules.SquadCoordination:AnnouncePresence()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entered combat
        if TerrorSquadAI.Modules.AIEngine then
            TerrorSquadAI.Modules.AIEngine:OnCombatStart()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Left combat
        if TerrorSquadAI.Modules.AIEngine then
            TerrorSquadAI.Modules.AIEngine:OnCombatEnd()
        end
    elseif event == "CHAT_MSG_ADDON" then
        if arg1 == TerrorSquadAI.ADDON_PREFIX then
            if TerrorSquadAI.Modules.CommunicationSync then
                TerrorSquadAI.Modules.CommunicationSync:OnMessageReceived(arg2, arg3, arg4)
            end
        end
    end
end)

-- Slash commands
SLASH_TERRORSQUADAI1 = "/tsai"
SLASH_TERRORSQUADAI2 = "/terrorsquad"
SlashCmdList["TERRORSQUADAI"] = function(msg)
    local cmd = string.lower(msg or "")
    
    if cmd == "" or cmd == "help" or cmd == "ayuda" then
        TerrorSquadAI:Print("|cFFFFFF00=== Comandos Terror Squad AI ===|r")
        TerrorSquadAI:Print("/tsai config - Abrir configuración")
        TerrorSquadAI:Print("/tsai toggle - Activar/desactivar sistema IA")
        TerrorSquadAI:Print("/tsai status - Mostrar estado actual")
        TerrorSquadAI:Print("/tsai sync - Forzar sincronización con escuadrón")
        TerrorSquadAI:Print("/tsai debug - Activar/desactivar modo debug")
        TerrorSquadAI:Print("/tsai panel - Mostrar/ocultar panel de estado")
        TerrorSquadAI:Print("/tsai stats - Mostrar estadísticas de rendimiento")
        TerrorSquadAI:Print("/tsai macros - Generar macros sugeridos")
        TerrorSquadAI:Print("/tsai target - Sugerir mejor objetivo")
        TerrorSquadAI:Print("/tsai autotarget - Activar/desactivar targeteo automático")
        TerrorSquadAI:Print("/voz [comando] - Comandos de voz (ver /voz help)")
    elseif cmd == "config" then
        if TerrorSquadAI.Modules.Config then
            TerrorSquadAI.Modules.Config:Show()
        end
    elseif cmd == "toggle" then
        TerrorSquadAI.DB.aiEnabled = not TerrorSquadAI.DB.aiEnabled
        TerrorSquadAI:Print("Sistema IA: " .. (TerrorSquadAI.DB.aiEnabled and "Activado" or "Desactivado"))
    elseif cmd == "status" or cmd == "estado" then
        TerrorSquadAI:Print("Reporte de Estado:")
        TerrorSquadAI:Print("IA: " .. (TerrorSquadAI.DB.aiEnabled and "ACTIVADO" or "DESACTIVADO"))
        TerrorSquadAI:Print("Alertas: " .. (TerrorSquadAI.DB.alertsEnabled and "ACTIVADO" or "DESACTIVADO"))
        TerrorSquadAI:Print("Sincronización: " .. (TerrorSquadAI.DB.syncEnabled and "ACTIVADO" or "DESACTIVADO"))
        TerrorSquadAI:Print("BigWigs: " .. (TerrorSquadAI.DB.bigWigsIntegration and "ACTIVADO" or "DESACTIVADO"))
    elseif cmd == "sync" then
        if TerrorSquadAI.Modules.CommunicationSync then
            TerrorSquadAI.Modules.CommunicationSync:ForceSyncAll()
            TerrorSquadAI:Print("Sincronizando con escuadrón...")
        end
    elseif cmd == "debug" then
        TerrorSquadAI.DEBUG = not TerrorSquadAI.DEBUG
        TerrorSquadAI:Print("Modo debug: " .. (TerrorSquadAI.DEBUG and "ACTIVADO" or "DESACTIVADO"))
    elseif cmd == "panel" then
        if TerrorSquadAI.Modules.StatusPanel then
            TerrorSquadAI.Modules.StatusPanel:Toggle()
        end
    elseif cmd == "stats" or cmd == "estadisticas" then
        if TerrorSquadAI.Modules.PerformanceTracker then
            TerrorSquadAI.Modules.PerformanceTracker:ReportStats()
        end
        if TerrorSquadAI.Modules.GnomoFury then
            local stats = TerrorSquadAI.Modules.GnomoFury:GetStats()
            TerrorSquadAI:Print(string.format("|cFFFF6600Furia Gnómica: %d%% | K/D: %d/%d (%.2f)|r", 
                stats.furyLevel, stats.kills, stats.deaths, stats.kd))
        end
    elseif cmd == "macros" then
        if TerrorSquadAI.Modules.MacroGenerator then
            TerrorSquadAI.Modules.MacroGenerator:GeneratePvPMacros()
            TerrorSquadAI.Modules.MacroGenerator:GenerateClassMacros()
        end
    elseif cmd == "target" or cmd == "objetivo" then
        if TerrorSquadAI.Modules.SmartTargeting then
            TerrorSquadAI.Modules.SmartTargeting:SuggestTarget()
        end
    elseif cmd == "autotarget" then
        if TerrorSquadAI.Modules.SmartTargeting then
            TerrorSquadAI.Modules.SmartTargeting:ToggleAutoTarget()
        end
    else
        TerrorSquadAI:Print("Comando desconocido. Escribe /tsai help para ver los comandos.")
    end
end

-- Create Minimap Button
function TerrorSquadAI:CreateMinimapButton()
    local button = CreateFrame("Button", "TerrorSquadAIMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    
    -- Icon texture
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\Spell_Shadow_Charm")
    button.icon = icon
    
    -- Border
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(52)
    overlay:SetHeight(52)
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    
    -- Position
    button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52, -52)
    
    -- Make it draggable
    button:SetMovable(true)
    button:EnableMouse(true)
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    button:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)
    
    -- Click handler
    button:SetScript("OnClick", function()
        if arg1 == "LeftButton" then
            if TerrorSquadAI.Modules.Config then
                TerrorSquadAI.Modules.Config:Show()
            else
                TerrorSquadAI:Print("Abriendo interfaz...")
            end
        elseif arg1 == "RightButton" then
            TerrorSquadAI.DB.aiEnabled = not TerrorSquadAI.DB.aiEnabled
            TerrorSquadAI:Print("Sistema IA: " .. (TerrorSquadAI.DB.aiEnabled and "Activado" or "Desactivado"))
        end
    end)
    
    -- Tooltip
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Terror Squad AI", 1, 1, 1)
        GameTooltip:AddLine("Click izquierdo: Abrir interfaz", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Click derecho: Activar/Desactivar IA", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Arrastrar: Mover botón", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("Estado: " .. (TerrorSquadAI.DB.aiEnabled and "|cFF00FF00ACTIVADO|r" or "|cFFFF0000DESACTIVADO|r"), 1, 1, 1)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    self.MinimapButton = button
    self:Print("Botón flotante creado. Arrástralo para moverlo.")
end
