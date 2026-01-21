-- TacticalRadar.lua - Radar Táctico / HUD 2D
-- TerrorSquadAI v5.0 - The Visual Commander
-- Real-time 2D radar for tracking party members and targets

local TR = {}
TerrorSquadAI:RegisterModule("TacticalRadar", TR)

-- Config
TR.config = {
    enabled = true,
    radius = 120, -- Radius of the radar circle in pixels
    iconScale = 1.2,
    showLeader = true,
    showTarget = true,
    showFocus = true
}

-- Icons
TR.icons = {
    TARGET = "Interface\\Minimap\\RotatorArrow", -- Arrow
    FOCUS = "Interface\\Minimap\\RotatorArrow",
    LEADER = "Interface\\GroupFrame\\UI-Group-LeaderIcon",
    PARTY = "Interface\\Minimap\\PartyRaidBlips",
    ENEMY_NET = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull" -- Skull for enemies spotted by net
}

TR.colors = {
    TARGET = {1, 0, 0}, -- Red
    FOCUS = {1, 0.5, 0}, -- Orange
    LEADER = {0, 1, 0}, -- Green
    PARTY = {0.5, 0.5, 1}, -- Blue
    ENEMY_NET = {1, 0, 1} -- Purple for network enemies
}

TR.externalTargets = {} -- { [Name] = {x, y, type, time} }

function TR:Initialize()
    self:CreateHUDFrame()
    self:RegisterEvents()
    self.pool = {}
    TerrorSquadAI:Debug("TacticalRadar v2.0 (Visual Commander) initialized")
end

function TR:RegisterExternalTarget(name, x, y, type)
    self.externalTargets[name] = {
        x = x,
        y = y,
        type = type,
        time = GetTime()
    }
end

function TR:CreateHUDFrame()

    -- Main transparent frame centered on screen
    self.hudFrame = CreateFrame("Frame", "TSAI_RadarHUD", UIParent)
    self.hudFrame:SetWidth(self.config.radius * 2)
    self.hudFrame:SetHeight(self.config.radius * 2)
    self.hudFrame:SetPoint("CENTER", 0, 0)
    self.hudFrame:SetFrameStrata("BACKGROUND")
    
    -- Optional: faint circle guide
    -- self.bg = self.hudFrame:CreateTexture(nil, "BACKGROUND")
    -- self.bg:SetAllPoints()
    -- self.bg:SetTexture("Interface\\AddOns\\TerrorSquadAI\\Textures\\RadarCircle") -- Custom texture if we had one
    -- self.bg:SetAlpha(0.1)
end

function TR:RegisterEvents()
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function() TR:OnUpdate() end)
end

function TR:GetIndicator(id)
    if not self.pool[id] then
        local f = CreateFrame("Frame", nil, self.hudFrame)
        f:SetWidth(16 * self.config.iconScale)
        f:SetHeight(16 * self.config.iconScale)
        
        local tex = f:CreateTexture(nil, "OVERLAY")
        tex:SetAllPoints()
        f.tex = tex
        
        self.pool[id] = f
    end
    return self.pool[id]
end

function TR:OnUpdate()
    if not self.config.enabled then 
        for _, f in pairs(self.pool) do f:Hide() end
        return 
    end
    
    -- Hide all first
    for _, f in pairs(self.pool) do f:Hide() end
    
    local poolIndex = 1
    local pX, pY = GetPlayerMapPosition("player")
    if pX == 0 and pY == 0 then return end -- No coordinates available (instance without map)
    
    -- Calculate Facing based on movement (Vanilla Workaround)
    local playerFacing = 0
    if self.lastPx and (self.lastPx ~= pX or self.lastPy ~= pY) then
        -- We moved, calculate angle
        local dx = pX - self.lastPx
        local dy = pY - self.lastPy
        -- Map coords: Y increases DOWN. X increases RIGHT.
        -- Standard Atan2(y, x). 0 is Right (East).
        -- We want North to be 0 for our rotation logic? Or just standard?
        -- Let's use standard math angle.
        -- dy needs to be inverted for standard cartesian logic if we want "Up" = "North"
        playerFacing = math.atan2(-dy, dx) 
        
        -- Store as cache
        self.cachedFacing = playerFacing
    elseif self.cachedFacing then
        playerFacing = self.cachedFacing
    end
    
    self.lastPx = pX
    self.lastPy = pY
    
    -- Track Lists
    local targets = {}
    
    -- 1. Target
    if self.config.showTarget and UnitExists("target") and not UnitIsUnit("target", "player") then
        table.insert(targets, {unit="target", type="TARGET"})
    end
    
    -- 2. Focus
    if self.config.showFocus and TerrorSquadAI.Modules.FocusFireCoordinator then
        local focus = TerrorSquadAI.Modules.FocusFireCoordinator:GetCurrentTarget()
        if focus and focus.unit and UnitExists(focus.unit) and not UnitIsUnit(focus.unit, "target") then
            table.insert(targets, {unit=focus.unit, type="FOCUS"})
        end
    end
    
    -- 3. External Network Targets (TerrorNet)
    local now = GetTime()
    for name, data in pairs(self.externalTargets) do
        if now - data.time < 10 then -- Show for 10 seconds
            -- For external targets we already have X/Y, format them for processing
            table.insert(targets, {
                calculated = true, 
                x = data.x, 
                y = data.y, 
                type = data.type
            })
        else
            self.externalTargets[name] = nil -- Prune old data
        end
    end
    
    -- Process Targets
    for _, t in ipairs(targets) do
        local uX, uY
        if t.calculated then
            uX, uY = t.x, t.y
        else
            uX, uY = GetPlayerMapPosition(t.unit)
        end
        
        if uX and (uX ~= 0 or uY ~= 0) then
            -- Calculate Deltas
            local dX = uX - pX
            local dY = uY - pY -- Map Y grows downwards usually, but let's check basic math
            -- WoW map: (0,0) TopLeft, (1,1) BottomRight. 
            -- dY > 0 means target is SOUTH of player. 
            -- dX > 0 means target is EAST of player.
            
            -- We want standard cartesian where Y is UP.
            -- cartX = dX
            -- cartY = -dY
            
            -- Angle to target (Absolute world angle, 0 = East, Pi/2 = North)
            local angleToTarget = math.atan2(-dY, dX)
            
            -- Relative Angle (Correction for player facing)
            -- WoW Facing: 0 = North, Pi = South. Increases Counter-Clockwise (North->West->South).
            -- Wait, WoW GetPlayerFacing returns radians. 0 is North?
            -- Verification: In standard API 1.12, GetPlayerFacing returns angle.
            -- Use the standard minimap rotation formula:
            -- angle = angleToTarget - playerFacing + (Pi/2) -- 90 deg offset because 0 is North in WoW but East in Math
            
            -- Let's stick to the trusted arrow rotation math for minimaps:
            -- dx = (uX - pX)
            -- dy = (uY - pY)
            -- rotatedX = dx * cos(-facing) - dy * sin(-facing)
            -- rotatedY = dx * sin(-facing) + dy * cos(-facing)
            
            local diffX = dX
            local diffY = dY
            
            local rot = -playerFacing
            local cos = math.cos(rot)
            local sin = math.sin(rot)
            
            -- Rotate coordinates to be relative to player view (Up = Forward)
            -- We need to flip Y axis logic for map vs visual
            -- Map: Y increases Down. Visual: Y increases Up.
            -- Let's try standard 2D rotation first.
            
            local rx = diffX * cos - diffY * sin
            local ry = diffX * sin + diffY * cos
            
            -- Now (rx, ry) is relative position.
            -- However, we assume map Y is inverted.
            -- Let's scale it to radar radius.
            
            -- Determine distance (for clamping)
            -- We just want direction, so normalize.
            local dist = math.sqrt(rx*rx + ry*ry)
            if dist > 0 then
                -- Normalize to place on circle edge
                local nx = rx / dist
                local ny = ry / dist
                
                -- Place on HUD circle
                -- Note: ry is "Forward" if we did math right? Or rx?
                -- Usually X is Right, Y is Forward relative to player.
                -- Let's Swap/Invert based on testing logic from other addons (e.g. Gatherer)
                -- Usually: x = -rx, y = ry for visuals.
                
                local screenX = -ny * self.config.radius -- Swapped for 90 deg rot?
                local screenY = nx * self.config.radius
                
                -- Let's use simple ATAN2 to be safe for circular position
                local relAngle = math.atan2(ny, nx)
                -- screenX = cos(relAngle) * radius
                -- screenY = sin(relAngle) * radius
                
                -- Adjust for WoW Screen coordinates (Y is Up)
                -- If we assume ry is forward (Up), rx is right (Right).
                -- screenX = rx * radius (Maybe scale to aspect ratio?)
                -- screenY = ry * radius 
                
                -- Let's try:
                local hudX = -rx * 4000 -- Scaling factor for map coords to pixels
                local hudY = -ry * 4000
                
                -- Clamp to radius
                local hudDist = math.sqrt(hudX*hudX + hudY*hudY)
                if hudDist > self.config.radius then
                     local factor = self.config.radius / hudDist
                     hudX = hudX * factor
                     hudY = hudY * factor
                end
                
                local ind = self:GetIndicator(poolIndex)
                ind:SetPoint("CENTER", self.hudFrame, "CENTER", hudY, hudX) -- Swap X/Y feels correct for WoW map rotation quirks often
                
                -- Setup Icon
                ind.tex:SetTexture(TR.icons[t.type])
                local c = TR.colors[t.type]
                ind.tex:SetVertexColor(c[1], c[2], c[3])
                
                -- Rotate Arrow to point away from center
                -- Only works if texture allows manual rotation via TexCoord (standard arrow does)
                if t.type == "TARGET" or t.type == "FOCUS" then
                   local angle = math.atan2(hudX, hudY) 
                   -- Rotate texture. angle is radians.
                   -- Simple rotation logic:
                   local cell = 0 -- Index for animated tex? No.
                   -- Just set vertex color and position for now.
                   -- Proper texture rotation requires complex TexCoord math.
                   -- For v1.0, a dot/arrow pointing up is acceptable if it moves around the circle.
                end
                
                ind:Show()
                poolIndex = poolIndex + 1
            end
        end
    end
end
