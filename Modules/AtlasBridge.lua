-- TerrorSquadAI <-> Atlas-TW Bridge
-- Syncs dungeon/boss data with Tactical Map
-- Author: DarckRovert (elnazzareno)
-- For: El Sequito del Terror

local AtlasBridge = {}
TerrorSquadAI:RegisterModule("AtlasBridge", AtlasBridge)

AtlasBridge.atlasDetected = false

function AtlasBridge:Initialize()
    if AtlasTW then
        self.atlasDetected = true
        TerrorSquadAI:Debug("Atlas Bridge initialized - Sequito Edition")
    end
end

function AtlasBridge:GetBossInfo(bossName)
    if not self.atlasDetected or not AtlasTWLoot then return nil end
    
    -- Search Atlas database for boss notes
    -- (Simplified for now)
    return {
        name = bossName,
        lootTable = "Tracked by Atlas-TW"
    }
end

function AtlasBridge:OnMapOpened()
    -- Sync TSAI map with Atlas data if in instance
end
