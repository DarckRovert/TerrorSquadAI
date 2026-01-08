-- TerrorSquadAI Squad Coordination Module
-- Advanced squad coordination and tactical management
-- Author: DarckRovert (elnazzareno)

local SquadCoordination = {}
TerrorSquadAI:RegisterModule("SquadCoordination", SquadCoordination)

-- Squad state
SquadCoordination.squadMembers = {}
SquadCoordination.squadLeader = nil
SquadCoordination.sharedTargets = {}
SquadCoordination.formations = {}
SquadCoordination.currentFormation = "spread"

-- Coordination modes
SquadCoordination.MODE_AUTONOMOUS = "autonomous"
SquadCoordination.MODE_COORDINATED = "coordinated"
SquadCoordination.MODE_LEADER_DIRECTED = "leader_directed"
SquadCoordination.currentMode = SquadCoordination.MODE_COORDINATED

function SquadCoordination:Initialize()
    self.squadMembers = {}
    self.sharedTargets = {}
    
    -- Initialize formations
    self:InitializeFormations()
    
    -- Register events
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    self.eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    self.eventFrame:RegisterEvent("PARTY_LEADER_CHANGED")
    
    self.eventFrame:SetScript("OnEvent", function()
        if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
            SquadCoordination:UpdateSquadRoster()
        elseif event == "PARTY_LEADER_CHANGED" then
            SquadCoordination:OnLeaderChanged()
        end
    end)
    
    -- Initial roster update
    self:UpdateSquadRoster()
    
    TerrorSquadAI:Debug("SquadCoordination initialized")
end

function SquadCoordination:InitializeFormations()
    self.formations = {
        spread = {
            name = "Formación Dispersa",
            description = "Dispérsense para evitar AoE",
            minDistance = 10
        },
        tight = {
            name = "Formación Compacta",
            description = "Agrúpense para curación y buffs",
            minDistance = 5
        },
        line = {
            name = "Formación en Línea",
            description = "Formen una línea para asalto coordinado",
            minDistance = 8
        },
        mobile = {
            name = "Formación Móvil",
            description = "Mantengan movilidad para PvP",
            minDistance = 12
        }
    }
end

function SquadCoordination:UpdateSquadRoster()
    self.squadMembers = {}
    
    -- Check if in raid
    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            local name, rank, subgroup, level, class = GetRaidRosterInfo(i)
            if name then
                self.squadMembers[name] = {
                    name = name,
                    rank = rank,
                    subgroup = subgroup,
                    level = level,
                    class = class,
                    unit = "raid" .. i,
                    isLeader = (rank == 2),
                    isAssist = (rank == 1)
                }
                
                if rank == 2 then
                    self.squadLeader = name
                end
            end
        end
    else
        -- Check if in party
        local numParty = GetNumPartyMembers()
        if numParty > 0 then
            -- Add player
            local playerName = UnitName("player")
            local _, playerClass = UnitClass("player")
            self.squadMembers[playerName] = {
                name = playerName,
                rank = 0,
                subgroup = 1,
                level = UnitLevel("player"),
                class = playerClass,
                unit = "player",
                isLeader = false,
                isAssist = false
            }
            
            -- Add party members
            for i = 1, numParty do
                local unit = "party" .. i
                local name = UnitName(unit)
                local _, class = UnitClass(unit)
                
                if name then
                    self.squadMembers[name] = {
                        name = name,
                        rank = 0,
                        subgroup = 1,
                        level = UnitLevel(unit),
                        class = class,
                        unit = unit,
                        isLeader = UnitIsPartyLeader(unit),
                        isAssist = false
                    }
                    
                    if UnitIsPartyLeader(unit) then
                        self.squadLeader = name
                    end
                end
            end
        end
    end
    
    TerrorSquadAI:Debug("Squad roster updated: " .. self:GetSquadSize() .. " members")
end

function SquadCoordination:OnLeaderChanged()
    self:UpdateSquadRoster()
    TerrorSquadAI:Debug("Squad leader changed to: " .. (self.squadLeader or "None"))
end

function SquadCoordination:AnnouncePresence()
    if not TerrorSquadAI.DB.syncEnabled then return end
    
    local message = string.format("TerrorSquadAI v%s active - El Sequito del Terror!", TerrorSquadAI.Version)
    
    if GetNumRaidMembers() > 0 then
        SendChatMessage(message, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(message, "PARTY")
    end
end

function SquadCoordination:UpdatePriorityTargets(priorityTargets)
    if not priorityTargets then return end
    
    self.sharedTargets = priorityTargets
    
    -- Broadcast to squad if enabled
    if TerrorSquadAI.DB.syncEnabled and TerrorSquadAI.Modules.CommunicationSync then
        for _, target in ipairs(priorityTargets) do
            TerrorSquadAI.Modules.CommunicationSync:BroadcastPriorityTarget(target)
        end
    end
end

function SquadCoordination:SetFormation(formationType)
    if not self.formations[formationType] then return false end
    
    self.currentFormation = formationType
    local formation = self.formations[formationType]
    
    -- Announce formation change
    if TerrorSquadAI.Modules.AlertSystem then
        TerrorSquadAI.Modules.AlertSystem:ShowAlert({
            type = "info",
            message = "Formación: " .. formation.name,
            duration = 3,
            icon = "Interface\\Icons\\Ability_Warrior_BattleShout"
        })
    end
    
    return true
end

function SquadCoordination:GetOptimalFormation()
    if not TerrorSquadAI.Modules.AIEngine then return "spread" end
    
    local aiEngine = TerrorSquadAI.Modules.AIEngine
    local scenario = aiEngine:GetCurrentScenario()
    
    -- Recommend formation based on scenario
    if scenario == aiEngine.SCENARIO_PVP_SKIRMISH or scenario == aiEngine.SCENARIO_WORLD_PVP then
        return "mobile"
    elseif scenario == aiEngine.SCENARIO_BOSS_FIGHT then
        return "spread"
    elseif scenario == aiEngine.SCENARIO_DUNGEON_TRASH then
        return "tight"
    end
    
    return "spread"
end

function SquadCoordination:AnalyzeSquadComposition()
    local composition = {
        total = 0,
        tanks = 0,
        healers = 0,
        dps = 0,
        classes = {},
        roles = {}
    }
    
    for _, member in pairs(self.squadMembers) do
        composition.total = composition.total + 1
        
        -- Count classes
        if not composition.classes[member.class] then
            composition.classes[member.class] = 0
        end
        composition.classes[member.class] = composition.classes[member.class] + 1
        
        -- Estimate roles (simplified)
        if member.class == "WARRIOR" then
            composition.tanks = composition.tanks + 1
            composition.dps = composition.dps + 0.5
        elseif member.class == "PRIEST" or member.class == "PALADIN" or member.class == "SHAMAN" then
            composition.healers = composition.healers + 1
            composition.dps = composition.dps + 0.3
        elseif member.class == "DRUID" then
            composition.tanks = composition.tanks + 0.5
            composition.healers = composition.healers + 0.5
            composition.dps = composition.dps + 0.5
        else
            composition.dps = composition.dps + 1
        end
    end
    
    return composition
end

function SquadCoordination:GetSquadEffectiveness()
    local composition = self:AnalyzeSquadComposition()
    
    if composition.total == 0 then return 0 end
    
    local effectiveness = 0.5
    
    -- Check role balance
    if composition.total >= 5 then
        if composition.tanks >= 1 and composition.healers >= 1 and composition.dps >= 2 then
            effectiveness = effectiveness + 0.3
        end
    end
    
    -- Check class diversity
    local classCount = 0
    for _ in pairs(composition.classes) do
        classCount = classCount + 1
    end
    effectiveness = effectiveness + (classCount * 0.05)
    
    -- Check if members have addon
    if TerrorSquadAI.Modules.CommunicationSync then
        local connectedCount = TerrorSquadAI.Modules.CommunicationSync:GetMemberCount()
        local syncRatio = connectedCount / composition.total
        effectiveness = effectiveness + (syncRatio * 0.2)
    end
    
    -- Cap at 1.0
    if effectiveness > 1.0 then
        effectiveness = 1.0
    end
    
    return effectiveness
end

function SquadCoordination:CoordinateFocusFire()
    -- Get priority target
    if not TerrorSquadAI.Modules.ThreatAnalysis then return end
    
    local priorityTargets = TerrorSquadAI.Modules.ThreatAnalysis:GetPriorityTargets()
    if not priorityTargets or table.getn(priorityTargets) == 0 then return end
    
    local topTarget = priorityTargets[1]
    if not topTarget then return end
    
    -- Announce focus target
    local message = "Fuego concentrado: " .. (topTarget.data.name or "Desconocido")
    
    if self:IsSquadLeader() then
        if GetNumRaidMembers() > 0 then
            SendChatMessage(message, "RAID_WARNING")
        elseif GetNumPartyMembers() > 0 then
            SendChatMessage(message, "PARTY")
        end
    end
    
    -- Show alert
    if TerrorSquadAI.Modules.AlertSystem then
        TerrorSquadAI.Modules.AlertSystem:ShowAlert({
            type = "warning",
            message = message,
            duration = 4,
            icon = "Interface\\Icons\\Ability_Hunter_MarkedForDeath"
        })
    end
end

function SquadCoordination:IsSquadLeader()
    local playerName = UnitName("player")
    return self.squadLeader == playerName
end

function SquadCoordination:GetSquadSize()
    local count = 0
    for _ in pairs(self.squadMembers) do
        count = count + 1
    end
    return count
end

function SquadCoordination:GetSquadMembers()
    return self.squadMembers
end

function SquadCoordination:GetSquadLeader()
    return self.squadLeader
end

function SquadCoordination:GetCurrentFormation()
    return self.currentFormation
end

function SquadCoordination:SetCoordinationMode(mode)
    if mode == self.MODE_AUTONOMOUS or mode == self.MODE_COORDINATED or mode == self.MODE_LEADER_DIRECTED then
        self.currentMode = mode
        TerrorSquadAI:Debug("Coordination mode set to: " .. mode)
        return true
    end
    return false
end

function SquadCoordination:GetCoordinationMode()
    return self.currentMode
end
