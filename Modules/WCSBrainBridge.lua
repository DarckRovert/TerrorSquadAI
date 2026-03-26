-- TerrorSquadAI <-> WCS_Brain Bridge
-- Connects the Tactical AI with the Deep Learning Warlock Brain
-- Author: DarckRovert (elnazzareno)
-- For: El Sequito del Terror

local WCSBrainBridge = {}
TerrorSquadAI:RegisterModule("WCSBrainBridge", WCSBrainBridge)

WCSBrainBridge.wcsDetected = false

function WCSBrainBridge:Initialize()
    if WCS_Brain or WCS_BrainCore then
        self.wcsDetected = true
        TerrorSquadAI:Debug("WCS_Brain Bridge initialized - MASTER BRAIN LINK ACTIVE")
        
        -- Hook into WCS_Brain events if possible
        -- The bridge acts as a messenger between the two systems
    end
end

-- Exported function to share AI decisions with the squad
function WCSBrainBridge:OnAIDecision(spellName, score, reason)
    if not self.wcsDetected then return end
    
    -- If the decision is of high tactical value, sync it
    if score > 80 and TerrorSquadAI.Modules.CommunicationSync then
        TerrorSquadAI.Modules.CommunicationSync:SendMessage("AI_STRATEGY", {
            spell = spellName,
            pri = score,
            target = UnitName("target")
        })
    end
end

-- Get Warlock specific status for the squad panel
function WCSBrainBridge:GetWarlockStatus()
    if not self.wcsDetected or not WCS_BrainCore then return nil end
    
    return {
        shards = WCS_BrainCore.State.soulShards or 0,
        isCasting = WCS_BrainCore.State.isCasting,
        lastSpell = WCS_BrainCore.State.lastSpell
    }
end
