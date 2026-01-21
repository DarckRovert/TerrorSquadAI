-- TurtleModules/LowerKarazhan.lua
-- Módulo para Lower Karazhan Halls (Dungeon 5-10 man custom)

local LK = {}
TerrorSquadAI:RegisterModule("LowerKarazhan", LK)

LK.config = {
    enabled = true,
    alerts = true,
}

function LK:Initialize()
    self:RegisterEvents()
    if TerrorSquadAI.Modules.TurtleCore then
        TerrorSquadAI.Modules.TurtleCore:RegisterSubModule("LowerKarazhan", self)
    end
end

function LK:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF")
    frame:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
    
    frame:SetScript("OnEvent", function()
        LK:OnEvent(event, arg1)
    end)
end

function LK:OnEvent(event, message)
    if not self.config.enabled then return end
    
    -- Mobs peligrosos de Lower Kara
    
    -- Skeletal Usher (Ice Tomb?)
    if string.find(message, "Ice Tomb") or string.find(message, "Tumba de hielo") then
         self:Alert("¡TUMBA DE HIELO! - ¡DISPELEAR!")
    end
    
    -- Spectral Patron (Arcane Explosion)
    if string.find(message, "Arcane Explosion") or string.find(message, "Explosión Arcana") then
         self:Alert("¡AoE Arcano! - ¡INTERRUMPIR!")
    end
    
    -- Bosses
    -- Moroes (Vanish/Garrote)
    if string.find(message, "Vanish") or string.find(message, "Esfumarse") then
         self:Alert("¡MOROES VANISHED! - ¡CUIDADO KIDNEY SHOT!")
    end
end

function LK:Alert(msg)
    if self.config.alerts then
       TerrorSquadAI:Alert("|cFFAB47BC[Kara]|r " .. msg)
       if TerrorSquadAI.Modules.AlertSystem then
            TerrorSquadAI.Modules.AlertSystem:ShowAlert({
                type = "warning",
                message = msg,
                duration = 3,
                sound = true
            })
       end
    end
end
