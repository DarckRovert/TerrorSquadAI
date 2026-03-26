-- TerrorSquadAI <-> pfUI Bridge
-- Redirects TSAI alerts to pfUI message system and colors UnitFrames
-- Author: DarckRovert (elnazzareno)
-- For: El Sequito del Terror

local pfUIBridge = {}
TerrorSquadAI:RegisterModule("pfUIBridge", pfUIBridge)

pfUIBridge.pfUIDetected = false

function pfUIBridge:Initialize()
    if pfUI then
        self.pfUIDetected = true
        TerrorSquadAI:Debug("pfUI Bridge initialized - Sequito Edition")
        
        -- Hook into AlertSystem if available
        if TerrorSquadAI.Modules.AlertSystem then
            local oldShowAlert = TerrorSquadAI.Modules.AlertSystem.ShowAlert
            TerrorSquadAI.Modules.AlertSystem.ShowAlert = function(arg1, arg2)
                -- Call original
                oldShowAlert(arg1, arg2)
                
                -- Redirect to pfUI if possible
                if arg2 and type(arg2) == "table" and arg2.message then
                    pfUIBridge:DisplayInpfUI(arg2.message, arg2.type)
                end
            end
        end
    end
end

function pfUIBridge:DisplayInpfUI(message, alertType)
    if not self.pfUIDetected or not pfUI.api then return end
    
    local color = "ffffff"
    if alertType == "critical" or alertType == "danger" then
        color = "ff4444"
    elseif alertType == "warning" then
        color = "ffff44"
    elseif alertType == "info" or alertType == "tactical" then
        color = "00ccff"
    end
    
    -- Try to find pfUI's alert frame or just print to chat with branding
    -- If pfUI has a 'sequito' module, we can use its specific channel
    if pfUI.modules and pfUI.modules.sequito then
        -- Native Sequito translation/display could go here
    end
    
    -- For now, ensure it's visible in pfUI's main scroll if possible
    -- (Standard chat print but with pfUI branding)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Sequito]|r: |cff" .. color .. message .. "|r")
end

-- Hook into UnitFrames for Threat coloring
function pfUIBridge:UpdateUnitFrameThreat(unit, threatPercent)
    if not self.pfUIDetected or not pfUI.uf then return end
    
    -- This would require deeper pfUI UF hooking, which we can do if needed.
    -- For now, let's keep it simple as a proof of concept.
end
