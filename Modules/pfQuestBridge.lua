-- TerrorSquadAI <-> pfQuest Bridge
-- Syncs quest objectives and follows Sequito theme (Cyan/Pink)
-- Author: DarckRovert (elnazzareno)
-- For: El Sequito del Terror

local pfQuestBridge = {}
TerrorSquadAI:RegisterModule("pfQuestBridge", pfQuestBridge)

pfQuestBridge.pfQuestDetected = false

function pfQuestBridge:Initialize()
    if pfQuest or IsAddOnLoaded("pfQuest") then
        self.pfQuestDetected = true
        TerrorSquadAI:Debug("pfQuest Bridge initialized - Sequito Edition")
        
        -- Align colors with sequito_init.lua
        if pfQuest_colors and pfQuest_colors["Sequito_Cyan"] then
            self.mapColor = pfQuest_colors["Sequito_Cyan"]
        else
            self.mapColor = { 0, 0.8, 1 } -- Fallback Cyan
        end
    end
end

function pfQuestBridge:SyncQuestObjective(questID, objectiveID)
    if not self.pfQuestDetected then return end
    
    -- Notify squad about quest progress via CommunicationSync
    if TerrorSquadAI.Modules.CommunicationSync then
        TerrorSquadAI.Modules.CommunicationSync:SendMessage("QUEST_SYNC", {
            qid = questID,
            oid = objectiveID,
            player = UnitName("player")
        })
    end
end

function pfQuestBridge:GetWaypoints()
    -- Export waypoints to TSAI Radar
    return {} -- Placeholder
end
