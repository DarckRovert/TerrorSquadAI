-- TurtleModules/Core.lua - Núcleo de Contenido Turtle WoW
-- TerrorSquadAI v4.0 - Phase 2
-- Gestión de módulos específicos para contenido custom

local TurtleCore = {}
-- Registramos como módulo normal para que el Core principal lo cargue
TerrorSquadAI:RegisterModule("TurtleCore", TurtleCore)

TurtleCore.subModules = {}

function TurtleCore:Initialize()
    -- Este módulo actúa como contenedor y gestor de estado para raids de Turtle
    if TerrorSquadAI.DEBUG then
        TerrorSquadAI:Debug("TurtleCore inicializado")
    end
end

-- Funciones helper para módulos de Turtle
function TurtleCore:IsTurtleZone()
    local zone = GetRealZoneText()
    -- Lista de zonas custom conocidas
    if zone == "Emerald Sanctum" or zone == "Lower Karazhan Halls" or zone == "Crescent Grove" then
        return true
    end
    return false
end

function TurtleCore:RegisterSubModule(name, module)
    self.subModules[name] = module
end
