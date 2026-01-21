-- TurtleModules/EmeraldSanctum.lua
-- Módulo para la raid Emerald Sanctum (Tier 2.5 custom)

local ES = {}
TerrorSquadAI:RegisterModule("EmeraldSanctum", ES)

-- Configuración
ES.config = {
    enabled = true,
    announce = true,
    timers = true,
}

function ES:Initialize()
    self:RegisterEvents()
    -- Registrarse con TurtleCore si está disponible
    if TerrorSquadAI.Modules.TurtleCore then
        TerrorSquadAI.Modules.TurtleCore:RegisterSubModule("EmeraldSanctum", self)
    end
end

function ES:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS")
    frame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF")
    frame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
    frame:RegisterEvent("CHAT_MSG_MONSTER_YELL")
    
    frame:SetScript("OnEvent", function()
        ES:OnEvent(event, arg1)
    end)
end

function ES:OnEvent(event, message)
    if not self.config.enabled then return end
    
    -- Dreamscythe & Solnius
    -- Nota: Patrones genéricos de dragones para empezar
    
    -- Aliento (Breath)
    if string.find(message, "Deep Breath") or string.find(message, "Aliento profundo") then
        self:StartTimer("Deep Breath", 15, "Interface\\Icons\\Spell_Shadow_LifeDrain")
        self:Alert("¡ALIENTO PROFUNDO! - ¡ESCONDETE!")
    elseif string.find(message, "Dream Fog") or string.find(message, "Niebla onírica") then
        self:Alert("¡Niebla Onírica! - ¡SAL DEL ÁREA!")
    end
    
    -- Fear (Alarido)
    if string.find(message, "Bellowing Roar") or string.find(message, "Rugido bramante") then
        self:StartTimer("Miedo (Roar)", 30, "Interface\\Icons\\Spell_Shadow_PsychicScream")
        self:Alert("¡MIEDO EN 2s! - ¡USA FEAR WARD/TOTEM!")
    end
    
    if string.find(message, "Tail Sweep") or string.find(message, "Coletazo") then
        -- Solo alerta visual, sin timer fijo
        -- self:Alert("¡Cuidado con la cola!")
    end
end

function ES:StartTimer(name, duration, icon)
    if self.config.timers and TerrorSquadAI.Modules.BossTimerLite then
        TerrorSquadAI.Modules.BossTimerLite:StartTimer(name, duration, icon)
    end
end

function ES:Alert(msg)
    if self.config.announce then
        TerrorSquadAI:Alert("|cFF00FF00[ES]|r " .. msg)
        if TerrorSquadAI.Modules.AlertSystem then
            TerrorSquadAI.Modules.AlertSystem:ShowAlert({
                type = "critical",
                message = msg,
                duration = 3,
                sound = true
            })
        end
    end
end
