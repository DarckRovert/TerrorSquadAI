-- TerrorSquadAI SquadMind Module
-- Collective intelligence for group cooldown tracking
-- Phase 6 - The Predictive Strategist

local SquadMind = {}
TerrorSquadAI:RegisterModule("SquadMind", SquadMind)

-- Tracked Cooldowns (English names, localized lookup needed for full compatibility)
-- Vanilla 1.12 Spell Names
SquadMind.trackedCDs = {
    -- Warrior
    ["Shield Wall"] = 1800,
    ["Last Stand"] = 600,
    ["Challenging Shout"] = 600,
    -- Paladin
    ["Divine Shield"] = 300,
    ["Divine Protection"] = 300,
    ["Lay on Hands"] = 3600,
    ["Blessing of Protection"] = 300,
    -- Druid
    ["Tranquility"] = 300,
    ["Innervate"] = 360,
    ["Rebirth"] = 1800,
    -- Mage
    ["Ice Block"] = 300,
    -- Rogue
    ["Vanish"] = 300,
    ["Blind"] = 300,
    -- Priest
    ["Psychic Scream"] = 30,
    ["Power Infusion"] = 180,
    -- Warlock
    ["Soulstone Resurrection"] = 1800
}

SquadMind.state = {
    groupCooldowns = {} -- { [UnitName] = { [SpellName] = { readyAt = time, duration = dur } } }
}

function SquadMind:Initialize()
    self:RegisterEvents()
    TerrorSquadAI:Debug("SquadMind (Collective Intelligence) initialized")
end

function SquadMind:RegisterEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
    f:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS")
    f:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
    
    -- Specific event for spells/abilities use might need combat log parsing
    -- In 1.12 parsing combat log text is the only way
    -- "X casts Y."
    
    f:SetScript("OnEvent", function()
        SquadMind:ParseCombatLog(arg1)
    end)
end

function SquadMind:ParseCombatLog(msg)
    if not msg then return end
    
    -- Regex to find who cast what
    -- "%s casts %s." (Cast)
    -- "%s performs %s." (Instant)
    
    for spellName, cdDuration in pairs(self.trackedCDs) do
        if string.find(msg, spellName) then
            -- Find the caster
            local _, _, caster = string.find(msg, "^(.+) casts "..spellName)
            if not caster then
                _, _, caster = string.find(msg, "^(.+) performs "..spellName)
            end
            
            if caster then
                self:RecordCooldown(caster, spellName, cdDuration)
            end
        end
    end
end

function SquadMind:RecordCooldown(caster, spellName, duration)
    if not self.state.groupCooldowns[caster] then
        self.state.groupCooldowns[caster] = {}
    end
    
    self.state.groupCooldowns[caster][spellName] = {
        readyAt = GetTime() + duration,
        duration = duration
    }
    
    if TerrorSquadAI.DEBUG then
        TerrorSquadAI:Debug("SquadMind: " .. caster .. " used " .. spellName .. " (CD: " .. duration .. "s)")
    end
    
    -- Notify AlertSystem if it's a critical defensive (Tank CD used)
    if spellName == "Shield Wall" or spellName == "Last Stand" then
        if TerrorSquadAI.Modules.AlertSystem then
            TerrorSquadAI.Modules.AlertSystem:ShowAlert({
                type = "tactical",
                message = caster .. ": " .. spellName .. " UP",
                icon = "Interface\\Icons\\Spell_Holy_PowerWordShield" -- Generic icon
            })
        end
    end
end

-- API: Check if a cooldown is available in the group
-- Returns count of available casts
function SquadMind:IsCooldownAvailable(spellName)
    local availableCount = 0
    local totalCount = 0
    
    -- Iterate raid/party
    local num = GetNumRaidMembers()
    local prefix = "raid"
    if num == 0 then 
        num = GetNumPartyMembers() 
        prefix = "party"
    end
    
    for i=1, num do
        local unit = prefix..i
        local name = UnitName(unit)
        if name then
            -- Check if class matches? (Optimization)
            -- Simplified: Check if we have seen them use it before (Tracking only known users)
            -- OR assume if class matches they have it.
            -- For Phase 6 Prototype: Only track tracked history.
            
            if self.state.groupCooldowns[name] and self.state.groupCooldowns[name][spellName] then
                if GetTime() > self.state.groupCooldowns[name][spellName].readyAt then
                    availableCount = availableCount + 1
                end
            else
                -- Haven't seen them use it. Assume available? Or unknown?
                -- Assume available if we want to be optimistic, but risky.
                -- Let's return 1 if we haven't seen it used, assuming they have it?
                -- Too complex for now. Just track known CDs.
            end
        end
    end
    
    return availableCount
end

function SquadMind:GetGroupStatus()
    -- Calculate "Group Defensive Health"
    -- Based on available Shield Walls, Bops, Tranquilities
    return "ANALYZING"
end
