-- Commands.lua - Sistema de comandos slash para TerrorSquadAI

local function HandleSlashCommand(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do
        table.insert(args, string.lower(word))
    end
    
    local cmd = args[1]
    local subcmd = args[2]
    
    if not cmd or cmd == "" or cmd == "help" then
        TerrorSquadAI:Print("|cFFFFD700=== TerrorSquadAI v4.1 Comandos ===|r")
        TerrorSquadAI:Print("/tsa config - Abrir configuración")
        TerrorSquadAI:Print("/tsa status - Ver estado del addon")
        TerrorSquadAI:Print("/tsa toggle - Activar/desactivar IA")
        TerrorSquadAI:Print("")
        TerrorSquadAI:Print("|cFF00FF00--- Combate ---|r")
        TerrorSquadAI:Print("/tsa target next/prev - Objetivo inteligente")
        TerrorSquadAI:Print("/tsa focus next/clear - Fuego concentrado")
        TerrorSquadAI:Print("/tsa tactic <nombre> - Activar táctica")
        TerrorSquadAI:Print("")
        TerrorSquadAI:Print("|cFFFFFF00--- v3.0 Nuevos ---|r")
        TerrorSquadAI:Print("/tsa score - Estadísticas PvP")
        TerrorSquadAI:Print("/tsa buffs - Ver buffs faltantes")
        TerrorSquadAI:Print("/tsa wipe - Estado predictor de wipe")
        TerrorSquadAI:Print("/tsa boss <nombre> - Timer de boss")
        return
    end
    
    -- Config
    if cmd == "config" or cmd == "options" or cmd == "menu" then
        if TerrorSquadAI.Modules.Config then
            TerrorSquadAI.Modules.Config:Toggle()
        else
            TerrorSquadAI:Print("|cFFFF0000Error:|r Módulo Config no disponible")
        end
        return
    end
    
    -- Toggle AI
    if cmd == "toggle" then
        TerrorSquadAI.DB.aiEnabled = not TerrorSquadAI.DB.aiEnabled
        TerrorSquadAI:Print("Sistema IA: " .. (TerrorSquadAI.DB.aiEnabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"))
        return
    end
    
    -- Status
    if cmd == "status" then
        TerrorSquadAI:Print("=== Estado de TerrorSquadAI ===")
        TerrorSquadAI:Print("Versi\195\179n: " .. TerrorSquadAI.Version)
        TerrorSquadAI:Print("IA: " .. (TerrorSquadAI.DB.aiEnabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"))
        
        local numModules = 0
        for _ in pairs(TerrorSquadAI.Modules) do
            numModules = numModules + 1
        end
        TerrorSquadAI:Print("M\195\179dulos cargados: " .. numModules)
        
        if TerrorSquadAI.Modules.ThreatPredictor then
            local threat = TerrorSquadAI.Modules.ThreatPredictor:GetCurrentThreat() or 0
            TerrorSquadAI:Print("Amenaza actual: " .. threat .. "%")
        end
        return
    end
    
    -- Marker commands
    if cmd == "marker" then
        if not TerrorSquadAI.Modules.AutoMarker then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo AutoMarker no disponible")
            return
        end
        
        if subcmd == "toggle" then
            TerrorSquadAI.Modules.AutoMarker.config.enabled = not TerrorSquadAI.Modules.AutoMarker.config.enabled
            TerrorSquadAI:Print("Marcado autom\195\161tico: " .. (TerrorSquadAI.Modules.AutoMarker.config.enabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"))
        else
            TerrorSquadAI:Print("Uso: /tsa marker toggle")
        end
        return
    end
    
    -- Focus commands
    if cmd == "focus" then
        if not TerrorSquadAI.Modules.FocusFireCoordinator then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo FocusFireCoordinator no disponible")
            return
        end
        
        if subcmd == "next" then
            TerrorSquadAI.Modules.FocusFireCoordinator:FindNextTarget()
            TerrorSquadAI:Print("Buscando siguiente objetivo prioritario...")
        elseif subcmd == "clear" then
            TerrorSquadAI.Modules.FocusFireCoordinator:ClearTarget()
        else
            TerrorSquadAI:Print("Uso: /tsa focus next | /tsa focus clear")
        end
        return
    end
    
    -- Target commands
    if cmd == "target" then
        if not TerrorSquadAI.Modules.SmartTargeting then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo SmartTargeting no disponible")
            return
        end
        
        if subcmd == "next" then
            TerrorSquadAI.Modules.SmartTargeting:CycleTarget(1)
            TerrorSquadAI:Print("Cambiando a siguiente objetivo inteligente...")
        elseif subcmd == "prev" then
            TerrorSquadAI.Modules.SmartTargeting:CycleTarget(-1)
            TerrorSquadAI:Print("Cambiando a objetivo anterior...")
        else
            TerrorSquadAI:Print("Uso: /tsa target next | /tsa target prev")
        end
        return
    end
    
    -- Ping commands
    if cmd == "ping" then
        if not TerrorSquadAI.Modules.TacticalPings then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo TacticalPings no disponible")
            return
        end
        
        local validPings = {"atacar", "defender", "ayuda", "peligro", "reagrupar", "retirada", "posicion"}
        if subcmd and subcmd ~= "" then
            local found = false
            for _, ping in ipairs(validPings) do
                if ping == subcmd then
                    found = true
                    break
                end
            end
            
            if found then
                TerrorSquadAI.Modules.TacticalPings:SendPing(subcmd)
            else
                TerrorSquadAI:Print("Tipo de ping inv\195\161lido. Tipos: atacar, defender, ayuda, peligro, reagrupar, retirada, posicion")
            end
        else
            TerrorSquadAI:Print("Uso: /tsa ping <tipo>")
            TerrorSquadAI:Print("Tipos: atacar, defender, ayuda, peligro, reagrupar, retirada, posicion")
        end
        return
    end
    
    -- Formation commands
    if cmd == "formation" then
        if not TerrorSquadAI.Modules.PositionOptimizer then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo PositionOptimizer no disponible")
            return
        end
        
        local validFormations = {"linea", "circulo", "cuna", "dispersion"}
        if subcmd and subcmd ~= "" then
            local found = false
            for _, formation in ipairs(validFormations) do
                if formation == subcmd then
                    found = true
                    break
                end
            end
            
            if found then
                TerrorSquadAI.Modules.PositionOptimizer:SuggestFormation(subcmd)
            else
                TerrorSquadAI:Print("Formaci\195\179n inv\195\161lida. Tipos: linea, circulo, cuna, dispersion")
            end
        else
            TerrorSquadAI:Print("Uso: /tsa formation <tipo>")
            TerrorSquadAI:Print("Tipos: linea, circulo, cuna, dispersion")
        end
        return
    end
    
    -- Cooldowns
    if cmd == "cooldowns" then
        if not TerrorSquadAI.Modules.CooldownTracker then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo CooldownTracker no disponible")
            return
        end
        
        TerrorSquadAI.Modules.CooldownTracker:PrintCooldowns()
        return
    end
    
    -- Macros
    if cmd == "macros" then
        if not TerrorSquadAI.Modules.MacroGenerator then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo MacroGenerator no disponible")
            return
        end
        
        if subcmd == "generate" then
            TerrorSquadAI.Modules.MacroGenerator:CreateGeneralMacros()
            TerrorSquadAI.Modules.MacroGenerator:CreateClassMacros()
        else
            TerrorSquadAI:Print("Uso: /tsa macros generate")
        end
        return
    end
    
    -- Gnomo Fury
    if cmd == "gnomo" then
        if not TerrorSquadAI.Modules.GnomoFury then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo GnomoFury no disponible")
            return
        end
        
        if subcmd == "toggle" then
            TerrorSquadAI.Modules.GnomoFury.config.enabled = not TerrorSquadAI.Modules.GnomoFury.config.enabled
            TerrorSquadAI:Print("Modo Furia Gn\195\179mica: " .. (TerrorSquadAI.Modules.GnomoFury.config.enabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"))
        else
            TerrorSquadAI:Print("Uso: /tsa gnomo toggle")
        end
        return
    end
    
    -- Panel
    if cmd == "panel" then
        if not TerrorSquadAI.Modules.StatusPanel then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo StatusPanel no disponible")
            return
        end
        
        if subcmd == "toggle" then
            if TerrorSquadAI.Modules.StatusPanel.frame:IsShown() then
                TerrorSquadAI.Modules.StatusPanel.frame:Hide()
                TerrorSquadAI:Print("Panel de estado ocultado")
            else
                TerrorSquadAI.Modules.StatusPanel.frame:Show()
                TerrorSquadAI:Print("Panel de estado mostrado")
            end
        else
            TerrorSquadAI:Print("Uso: /tsa panel toggle")
        end
        return
    end
    
    
    -- Status
    if cmd == "status" then
        TerrorSquadAI:Print("=== Estado de TerrorSquadAI ===")
        TerrorSquadAI:Print("Versi\195\179n: " .. TerrorSquadAI.Version)
        TerrorSquadAI:Print("IA: " .. (TerrorSquadAI.DB.aiEnabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"))
        
        local numModules = 0
        for _ in pairs(TerrorSquadAI.Modules) do
            numModules = numModules + 1
        end
        TerrorSquadAI:Print("M\195\179dulos cargados: " .. numModules)
        
        if TerrorSquadAI.Modules.ThreatPredictor then
            local threat = TerrorSquadAI.Modules.ThreatPredictor:GetCurrentThreat() or 0
            TerrorSquadAI:Print("Amenaza actual: " .. threat .. "%")
        end
        return
    end
    
    -- Marker commands
    if cmd == "marker" then
        if not TerrorSquadAI.Modules.AutoMarker then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo AutoMarker no disponible")
            return
        end
        
        if subcmd == "toggle" then
            TerrorSquadAI.Modules.AutoMarker.config.enabled = not TerrorSquadAI.Modules.AutoMarker.config.enabled
            TerrorSquadAI:Print("Marcado autom\195\161tico: " .. (TerrorSquadAI.Modules.AutoMarker.config.enabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"))
        else
            TerrorSquadAI:Print("Uso: /tsa marker toggle")
        end
        return
    end
    
    -- Focus commands
    if cmd == "focus" then
        if not TerrorSquadAI.Modules.FocusFireCoordinator then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo FocusFireCoordinator no disponible")
            return
        end
        
        if subcmd == "next" then
            TerrorSquadAI.Modules.FocusFireCoordinator:FindNextTarget()
            TerrorSquadAI:Print("Buscando siguiente objetivo prioritario...")
        elseif subcmd == "clear" then
            TerrorSquadAI.Modules.FocusFireCoordinator:ClearTarget()
        else
            TerrorSquadAI:Print("Uso: /tsa focus next | /tsa focus clear")
        end
        return
    end
    
    -- Target commands
    if cmd == "target" then
        if not TerrorSquadAI.Modules.SmartTargeting then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo SmartTargeting no disponible")
            return
        end
        
        if subcmd == "next" then
            TerrorSquadAI.Modules.SmartTargeting:CycleTarget(1)
            TerrorSquadAI:Print("Cambiando a siguiente objetivo inteligente...")
        elseif subcmd == "prev" then
            TerrorSquadAI.Modules.SmartTargeting:CycleTarget(-1)
            TerrorSquadAI:Print("Cambiando a objetivo anterior...")
        else
            TerrorSquadAI:Print("Uso: /tsa target next | /tsa target prev")
        end
        return
    end
    
    -- Ping commands
    if cmd == "ping" then
        if not TerrorSquadAI.Modules.TacticalPings then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo TacticalPings no disponible")
            return
        end
        
        local validPings = {"atacar", "defender", "ayuda", "peligro", "reagrupar", "retirada", "posicion"}
        if subcmd and subcmd ~= "" then
            local found = false
            for _, ping in ipairs(validPings) do
                if ping == subcmd then
                    found = true
                    break
                end
            end
            
            if found then
                TerrorSquadAI.Modules.TacticalPings:SendPing(subcmd)
            else
                TerrorSquadAI:Print("Tipo de ping inv\195\161lido. Tipos: atacar, defender, ayuda, peligro, reagrupar, retirada, posicion")
            end
        else
            TerrorSquadAI:Print("Uso: /tsa ping <tipo>")
            TerrorSquadAI:Print("Tipos: atacar, defender, ayuda, peligro, reagrupar, retirada, posicion")
        end
        return
    end
    
    -- Formation commands
    if cmd == "formation" then
        if not TerrorSquadAI.Modules.PositionOptimizer then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo PositionOptimizer no disponible")
            return
        end
        
        local validFormations = {"linea", "circulo", "cuna", "dispersion"}
        if subcmd and subcmd ~= "" then
            local found = false
            for _, formation in ipairs(validFormations) do
                if formation == subcmd then
                    found = true
                    break
                end
            end
            
            if found then
                TerrorSquadAI.Modules.PositionOptimizer:SuggestFormation(subcmd)
            else
                TerrorSquadAI:Print("Formaci\195\179n inv\195\161lida. Tipos: linea, circulo, cuna, dispersion")
            end
        else
            TerrorSquadAI:Print("Uso: /tsa formation <tipo>")
            TerrorSquadAI:Print("Tipos: linea, circulo, cuna, dispersion")
        end
        return
    end
    
    -- Cooldowns
    if cmd == "cooldowns" then
        if not TerrorSquadAI.Modules.CooldownTracker then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo CooldownTracker no disponible")
            return
        end
        
        TerrorSquadAI.Modules.CooldownTracker:PrintCooldowns()
        return
    end
    
    -- Macros
    if cmd == "macros" then
        if not TerrorSquadAI.Modules.MacroGenerator then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo MacroGenerator no disponible")
            return
        end
        
        if subcmd == "generate" then
            TerrorSquadAI.Modules.MacroGenerator:CreateGeneralMacros()
            TerrorSquadAI.Modules.MacroGenerator:CreateClassMacros()
        else
            TerrorSquadAI:Print("Uso: /tsa macros generate")
        end
        return
    end
    
    -- Gnomo Fury
    if cmd == "gnomo" then
        if not TerrorSquadAI.Modules.GnomoFury then
            TerrorSquadAI:Print("|cFFFF0000Error:|r M\195\179dulo GnomoFury no disponible")
            return
        end
        
        if subcmd == "toggle" then
            TerrorSquadAI.Modules.GnomoFury.config.enabled = not TerrorSquadAI.Modules.GnomoFury.config.enabled
            TerrorSquadAI:Print("Modo Furia Gn\195\179mica: " .. (TerrorSquadAI.Modules.GnomoFury.config.enabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"))
        else
            TerrorSquadAI:Print("Uso: /tsa gnomo toggle")
        end
        return
    end
    
    -- ==========================================
    -- v3.0 NEW COMMANDS
    -- ==========================================
    
    -- PvP Score
    if cmd == "score" or cmd == "pvp" then
        if TerrorSquadAI.Modules.PvPScorecard then
            if subcmd == "reset" then
                TerrorSquadAI.Modules.PvPScorecard:ResetSession()
            elseif subcmd == "lifetime" or subcmd == "all" then
                TerrorSquadAI.Modules.PvPScorecard:PrintLifetimeStats()
            else
                TerrorSquadAI.Modules.PvPScorecard:PrintScore()
            end
        else
            TerrorSquadAI:Print("|cFFFF0000Error:|r Módulo PvPScorecard no disponible")
        end
        return
    end
    
    -- Buffs
    if cmd == "buffs" or cmd == "buff" then
        if TerrorSquadAI.Modules.BuffMonitor then
            TerrorSquadAI.Modules.BuffMonitor:Scan()
        else
            TerrorSquadAI:Print("|cFFFF0000Error:|r Módulo BuffMonitor no disponible")
        end
        return
    end
    
    -- Wipe Predictor
    if cmd == "wipe" then
        if TerrorSquadAI.Modules.WipePredictor then
            TerrorSquadAI.Modules.WipePredictor:PrintStatus()
        else
            TerrorSquadAI:Print("|cFFFF0000Error:|r Módulo WipePredictor no disponible")
        end
        return
    end
    
    -- Tactic
    if cmd == "tactic" or cmd == "tactics" then
        if TerrorSquadAI.Modules.TerrorTactics then
            if subcmd and subcmd ~= "" then
                TerrorSquadAI.Modules.TerrorTactics:ActivateTactic(subcmd)
            else
                TerrorSquadAI.Modules.TerrorTactics:PrintAvailable()
            end
        else
            TerrorSquadAI:Print("|cFFFF0000Error:|r Módulo TerrorTactics no disponible")
        end
        return
    end
    
    -- Boss Timer
    if cmd == "boss" or cmd == "timer" then
        if TerrorSquadAI.Modules.BossTimerLite then
            if subcmd and subcmd ~= "" then
                TerrorSquadAI.Modules.BossTimerLite:ManualStart(subcmd)
            else
                TerrorSquadAI.Modules.BossTimerLite:ListBosses()
            end
        else
            TerrorSquadAI:Print("|cFFFF0000Error:|r Módulo BossTimerLite no disponible")
        end
        return
    end
    
    -- Health Monitor
    if cmd == "health" then
        if TerrorSquadAI.Modules.CriticalHealthMonitor then
            TerrorSquadAI.Modules.CriticalHealthMonitor:PrintStatus()
        else
            TerrorSquadAI:Print("|cFFFF0000Error:|r Módulo CriticalHealthMonitor no disponible")
        end
        return
    end
    
    -- DeathWatcher
    if cmd == "autotarget" or cmd == "death" then
        if TerrorSquadAI.Modules.DeathWatcher then
            if subcmd == "toggle" then
                TerrorSquadAI.Modules.DeathWatcher:Toggle()
            else
                TerrorSquadAI.Modules.DeathWatcher:PrintStatus()
            end
        else
            TerrorSquadAI:Print("|cFFFF0000Error:|r Módulo DeathWatcher no disponible")
        end
        return
    end
    
    -- Unknown command
    TerrorSquadAI:Print("|cFFFF0000Comando desconocido:|r " .. cmd)
    TerrorSquadAI:Print("Usa /tsa help para ver todos los comandos")
end

-- Register slash commands (incluye ambos /tsa y /tsai)
SLASH_TERRORSQUADAI1 = "/tsa"
SLASH_TERRORSQUADAI2 = "/tsai"
SLASH_TERRORSQUADAI3 = "/terrorsquad"
SlashCmdList["TERRORSQUADAI"] = HandleSlashCommand

-- Chat toggle command
SLASH_TSACHAT1 = "/tsachat"
SlashCmdList["TSACHAT"] = function(msg)
    TerrorSquadAI.CHAT_ALERTS = not TerrorSquadAI.CHAT_ALERTS
    local status = TerrorSquadAI.CHAT_ALERTS and "|cFF00FF00Activados|r" or "|cFFFF0000Desactivados|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[TerrorSquadAI]|r Mensajes en chat: " .. status)
end

-- TerrorSquadAI:Print("Comandos cargados. Usa /tsa help para ver la lista completa.")
