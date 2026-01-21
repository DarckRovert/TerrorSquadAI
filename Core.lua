-- TerrorSquadAI Core Module
-- Advanced AI system for squad management and combat decisions
-- Author: DarckRovert (elnazzareno)
-- For: El Sequito del Terror

-- Namespace
TerrorSquadAI = {}
TerrorSquadAI.Version = "4.1.1"
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
TerrorSquadAI.DEBUG = false -- Desactivado para evitar spam
TerrorSquadAI.CHAT_ALERTS = false -- Desactivar mensajes en chat, solo alertas visuales

-- Debug function
function TerrorSquadAI:Debug(msg)
    if self.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("[TerrorSquadAI] " .. tostring(msg), 1, 0.5, 0)
    end
end

-- Print function (siempre muestra mensajes de comandos)
function TerrorSquadAI:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("[|cFF8B0000TerrorSquadAI|r] " .. tostring(msg), 1, 1, 1)
end

-- Alert function (solo muestra si CHAT_ALERTS está activado)
function TerrorSquadAI:Alert(msg)
    if self.CHAT_ALERTS then
        DEFAULT_CHAT_FRAME:AddMessage("[|cFF8B0000TerrorSquadAI|r] " .. tostring(msg), 1, 1, 1)
    end
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
            chatMessagesEnabled = false,
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
    
    -- Migración: Asegurar que chatMessagesEnabled existe
    if self.DB.chatMessagesEnabled == nil then
        self.DB.chatMessagesEnabled = false
    end
    
    -- Inicializar tabla de configuración de módulos si no existe
    if not self.DB.modules then
        self.DB.modules = {}
    end
    
    -- Cargar configuraciones guardadas de módulos
    for name, savedConfig in pairs(self.DB.modules) do
        if self.Modules[name] and self.Modules[name].config then
            for key, value in pairs(savedConfig) do
                self.Modules[name].config[key] = value
            end
        end
    end
    
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
        -- v3.0 New modules (Phases 1-4)
        "DeathWatcher", "CriticalHealthMonitor", "PvPScorecard", "CastingBarHook",
        "BuffMonitor", "WipePredictor", "TerrorTactics", "BossTimerLite",
        -- v4.0 New modules
        "EnemyCooldowns", "TacticalRadar", "TacticalHUD", "KillFeed", "SquadMind",
        -- v4.0 Turtle
        "TurtleCore", "EmeraldSanctum", "LowerKarazhan",
        -- v4.0 Logistics
        "WarLogistics", "TerrorNet",
        -- UI last
        "UI", "Config"
    }
    
    local modulesLoaded = 0
    for _, name in ipairs(initOrder) do
        local module = self.Modules[name]
        if module and module.Initialize then
            module:Initialize()
            modulesLoaded = modulesLoaded + 1
            self:Debug("Module initialized: " .. name)
        end
    end
    
    -- Mensaje consolidado de inicialización (v3.0 - menos spam)
    self:Print(string.format("|cFF8B0000TerrorSquadAI v%s|r cargado (%d módulos)", self.Version, modulesLoaded))
    self:Print(string.format("¡Bienvenido, %s! Usa |cFFFFFF00/tsa help|r para comandos.", UnitName("player")))
    
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
        TerrorSquadAI:Print("/tsai chat toggle - Activar/desactivar mensajes de chat")
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
    elseif cmd == "chat toggle" or cmd == "chat" then
        TerrorSquadAI.DB.chatMessagesEnabled = not TerrorSquadAI.DB.chatMessagesEnabled
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r Mensajes de chat: " .. (TerrorSquadAI.DB.chatMessagesEnabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"), 1, 0.84, 0)
    elseif cmd == "status" or cmd == "estado" then
        TerrorSquadAI:Print("Reporte de Estado:")
        TerrorSquadAI:Print("IA: " .. (TerrorSquadAI.DB.aiEnabled and "ACTIVADO" or "DESACTIVADO"))
        TerrorSquadAI:Print("Alertas: " .. (TerrorSquadAI.DB.alertsEnabled and "ACTIVADO" or "DESACTIVADO"))
        TerrorSquadAI:Print("Mensajes de chat: " .. (TerrorSquadAI.DB.chatMessagesEnabled and "ACTIVADO" or "DESACTIVADO"))
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
    -- NEW COMMANDS (Phases 5-7)
    elseif cmd == "radar" then
         if TerrorSquadAI.Modules.TacticalRadar then
             local sub = "toggle" -- default
             -- Check if there's a second arg? (Simple parser here only gets single string)
             -- Need better parsing for "radar toggle" vs "radar scale"
             -- For now, existing modules assume single command or internal toggle
             if TerrorSquadAI.Modules.TacticalRadar.config.enabled then
                 TerrorSquadAI.Modules.TacticalRadar.config.enabled = false
                 TerrorSquadAI:Print("Radar Táctico: DESACTIVADO")
             else
                 TerrorSquadAI.Modules.TacticalRadar.config.enabled = true
                 TerrorSquadAI:Print("Radar Táctico: ACTIVADO")
             end
         end
    elseif cmd == "hud" then
         if TerrorSquadAI.Modules.TacticalHUD then
             -- Simple test trigger
             TerrorSquadAI.Modules.TacticalHUD:ShowAlert("HUD TEST", "CRITICAL")
         end
    elseif string.find(cmd, "^macro") then
        if TerrorSquadAI.Modules.MacroGenerator then
            if string.find(cmd, "create") then
                TerrorSquadAI.Modules.MacroGenerator:CreateAllMacros()
            elseif string.find(cmd, "delete") then
                TerrorSquadAI.Modules.MacroGenerator:DeleteAllTSAMacros()
            elseif string.find(cmd, "list") then
                TerrorSquadAI.Modules.MacroGenerator:ListAvailableMacros()
            else
                TerrorSquadAI.Modules.MacroGenerator:PrintHelp()
            end
        end
    elseif cmd == "net" then
         if TerrorSquadAI.Modules.TerrorNet then
             TerrorSquadAI:Print("TerrorNet Status: ONLINE")
             local count = 0
             for k,v in pairs(TerrorSquadAI.Modules.TerrorNet.networkData) do count = count + 1 end
             TerrorSquadAI:Print("Tracked Entities: " .. count)
         end
    else
        TerrorSquadAI:Print("Comando desconocido. Escribe /tsai help para ver los comandos.")
    end
end

-- Create Minimap Button
function TerrorSquadAI:CreateMinimapButton()
    self:Print("Creando botón de minimapa...")
    
    local button = CreateFrame("Button", "TerrorSquadAIMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("HIGH") -- Subido para estar encima de otros elementos
    button:SetFrameLevel(10)
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
    
    -- Position - Posición original que funcionaba
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
