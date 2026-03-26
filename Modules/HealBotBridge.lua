-- TerrorSquadAI <-> HealBot Bridge
-- Monitors healing status and integrates visuals with Sequito HealBot
-- Author: DarckRovert (elnazzareno)
-- For: El Sequito del Terror

local HealBotBridge = {}
TerrorSquadAI:RegisterModule("HealBotBridge", HealBotBridge)

HealBotBridge.healBotDetected = false

function HealBotBridge:Initialize()
    if HealBot then
        self.healBotDetected = true
        TerrorSquadAI:Debug("HealBot Bridge initialized - Sequito Edition")
    end
end

-- Exported function to be called by TSAI Brain
function HealBotBridge:GetHealerStatus()
    if not self.healBotDetected then return nil end
    
    local myName = UnitName("player")
    local _, class = UnitClass("player")
    
    if class == "PRIEST" or class == "DRUID" or class == "PALADIN" or class == "SHAMAN" then
        local mana = UnitMana("player")
        local maxMana = UnitManaMax("player")
        local manaPercent = (mana / maxMana) * 100
        
        return {
            name = myName,
            manaPercent = manaPercent,
            isHealing = true -- Simplified
        }
    end
    return nil
end

-- Synchronize visuals with DarkTheme
function HealBotBridge:ApplySequitoSkins()
    if not self.healBotDetected then return end
    
    -- Call HealBot Séquito modules if they exist
    if HealBot_DarkTheme then
        -- Align TSAI HUD colors with HealBot's DarkTheme
    end
end
