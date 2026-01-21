-- TerrorSquadAI UI Theme Module
-- Visual theme and styling system
-- Author: DarckRovert (elnazzareno)

local UITheme = {}
TerrorSquadAI:RegisterModule("UITheme", UITheme)

-- Terror Squad Color Palette
UITheme.Colors = {
    -- Primary Colors
    DarkRed = {0.545, 0, 0, 1},           -- #8B0000
    BloodRed = {0.7, 0, 0, 1},            -- #B30000
    BrightRed = {1, 0, 0, 1},             -- #FF0000
    
    -- Secondary Colors
    DarkGold = {0.8, 0.6, 0, 1},          -- #CC9900
    BrightGold = {1, 0.82, 0, 1},         -- #FFD700
    
    -- Neutral Colors
    Black = {0, 0, 0, 1},
    DarkGray = {0.15, 0.15, 0.15, 1},
    Gray = {0.3, 0.3, 0.3, 1},
    LightGray = {0.6, 0.6, 0.6, 1},
    White = {1, 1, 1, 1},
    
    -- Transparent variants
    BlackTransparent = {0, 0, 0, 0.85},
    DarkRedTransparent = {0.545, 0, 0, 0.7},
    
    -- Status Colors
    Green = {0, 1, 0, 1},
    Yellow = {1, 1, 0, 1},
    Orange = {1, 0.5, 0, 1},
    
    -- Threat Colors
    ThreatNone = {0, 1, 0, 1},
    ThreatLow = {0.5, 1, 0, 1},
    ThreatMedium = {1, 1, 0, 1},
    ThreatHigh = {1, 0.5, 0, 1},
    ThreatCritical = {1, 0, 0, 1}
}

-- Font Styles
UITheme.Fonts = {
    Title = "GameFontNormalHuge",
    Header = "GameFontNormalLarge",
    Normal = "GameFontNormal",
    Small = "GameFontNormalSmall",
    Tiny = "GameFontHighlightSmall"
}

-- Border Textures (using Vanilla WoW textures)
UITheme.Textures = {
    Border = "Interface\\DialogFrame\\UI-DialogBox-Border",
    Background = "Interface\\DialogFrame\\UI-DialogBox-Background",
    StatusBar = "Interface\\TargetingFrame\\UI-StatusBar",
    Button = "Interface\\Buttons\\UI-Panel-Button-Up",
    ButtonHighlight = "Interface\\Buttons\\UI-Panel-Button-Highlight",
    ButtonDown = "Interface\\Buttons\\UI-Panel-Button-Down",
    GoldBorder = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    Corner = "Interface\\DialogFrame\\UI-DialogBox-Corner"
}

function UITheme:Initialize()
    TerrorSquadAI:Debug("UITheme initialized")
end

-- Apply color to a texture
function UITheme:ApplyColor(texture, colorName)
    if not texture then return end
    local color = self.Colors[colorName]
    if color then
        texture:SetTexture(color[1], color[2], color[3], color[4] or 1)
    end
end

-- Create a styled frame with Terror Squad theme
function UITheme:CreateStyledFrame(name, parent, width, height)
    local frame = CreateFrame("Frame", name, parent)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:SetFrameStrata("MEDIUM")
    
    -- Background with gradient effect
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetTexture(0, 0, 0, 0.85)
    
    -- Dark red gradient overlay
    frame.gradient = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    frame.gradient:SetPoint("TOP", frame, "TOP", 0, 0)
    frame.gradient:SetWidth(width)
    frame.gradient:SetHeight(height * 0.3)
    frame.gradient:SetTexture(0.545, 0, 0, 0.4)
    
    -- Border
    frame.border = self:CreateBorder(frame)
    
    return frame
end

-- Create stylized border
function UITheme:CreateBorder(frame)
    local border = {}
    
    -- Top
    border.top = frame:CreateTexture(nil, "OVERLAY")
    border.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 8)
    border.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 8)
    border.top:SetHeight(8)
    border.top:SetTexture(0.545, 0, 0, 1)
    
    -- Bottom
    border.bottom = frame:CreateTexture(nil, "OVERLAY")
    border.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, -8)
    border.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, -8)
    border.bottom:SetHeight(8)
    border.bottom:SetTexture(0.545, 0, 0, 1)
    
    -- Left
    border.left = frame:CreateTexture(nil, "OVERLAY")
    border.left:SetPoint("TOPLEFT", frame, "TOPLEFT", -8, 0)
    border.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -8, 0)
    border.left:SetWidth(8)
    border.left:SetTexture(0.545, 0, 0, 1)
    
    -- Right
    border.right = frame:CreateTexture(nil, "OVERLAY")
    border.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 8, 0)
    border.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 8, 0)
    border.right:SetWidth(8)
    border.right:SetTexture(0.545, 0, 0, 1)
    
    -- Corners (gold accent)
    border.topLeft = frame:CreateTexture(nil, "OVERLAY", nil, 1)
    border.topLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", -8, 8)
    border.topLeft:SetWidth(16)
    border.topLeft:SetHeight(16)
    border.topLeft:SetTexture(1, 0.82, 0, 1)
    
    border.topRight = frame:CreateTexture(nil, "OVERLAY", nil, 1)
    border.topRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 8, 8)
    border.topRight:SetWidth(16)
    border.topRight:SetHeight(16)
    border.topRight:SetTexture(1, 0.82, 0, 1)
    
    border.bottomLeft = frame:CreateTexture(nil, "OVERLAY", nil, 1)
    border.bottomLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", -8, -8)
    border.bottomLeft:SetWidth(16)
    border.bottomLeft:SetHeight(16)
    border.bottomLeft:SetTexture(1, 0.82, 0, 1)
    
    border.bottomRight = frame:CreateTexture(nil, "OVERLAY", nil, 1)
    border.bottomRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 8, -8)
    border.bottomRight:SetWidth(16)
    border.bottomRight:SetHeight(16)
    border.bottomRight:SetTexture(1, 0.82, 0, 1)
    
    return border
end

-- Create styled button
function UITheme:CreateStyledButton(name, parent, width, height, text)
    local button = CreateFrame("Button", name, parent)
    button:SetWidth(width)
    button:SetHeight(height)
    
    -- Background
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetTexture(0.2, 0.2, 0.2, 1)
    
    -- Border
    button.border = button:CreateTexture(nil, "BORDER")
    button.border:SetAllPoints()
    button.border:SetTexture(0.545, 0, 0, 1)
    button.border:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
    button.border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
    
    -- Text
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("CENTER", button, "CENTER")
    button.text:SetText(text)
    button.text:SetTextColor(1, 0.82, 0, 1)
    
    -- Hover effect
    button:SetScript("OnEnter", function()
        button.bg:SetTexture(0.545, 0, 0, 0.5)
        button.text:SetTextColor(1, 1, 1, 1)
    end)
    
    button:SetScript("OnLeave", function()
        button.bg:SetTexture(0.2, 0.2, 0.2, 1)
        button.text:SetTextColor(1, 0.82, 0, 1)
    end)
    
    return button
end

-- Create styled status bar
function UITheme:CreateStyledStatusBar(name, parent, width, height)
    local bar = CreateFrame("StatusBar", name, parent)
    bar:SetWidth(width)
    bar:SetHeight(height)
    bar:SetStatusBarTexture(self.Textures.StatusBar)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    
    -- Background
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetTexture(0.1, 0.1, 0.1, 0.8)
    
    -- Border
    bar.border = bar:CreateTexture(nil, "BORDER")
    bar.border:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
    bar.border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
    bar.border:SetTexture(0.545, 0, 0, 1)
    
    -- Text
    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bar.text:SetPoint("CENTER", bar, "CENTER")
    bar.text:SetTextColor(1, 1, 1, 1)
    
    return bar
end

-- Create title text with glow effect
function UITheme:CreateTitleText(parent, text)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetText(text)
    title:SetTextColor(1, 0.82, 0, 1) -- Gold
    
    -- Shadow effect
    local shadow = parent:CreateFontString(nil, "BACKGROUND", "GameFontNormalHuge")
    shadow:SetPoint("CENTER", title, "CENTER", 2, -2)
    shadow:SetText(text)
    shadow:SetTextColor(0, 0, 0, 0.8)
    
    return title, shadow
end

-- Create section header
function UITheme:CreateSectionHeader(parent, text, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetText(text)
    header:SetTextColor(0.545, 0, 0, 1) -- Dark Red
    
    -- Underline
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOP", header, "BOTTOM", 0, -2)
    line:SetWidth(200)
    line:SetHeight(2)
    line:SetTexture(1, 0.82, 0, 0.5) -- Gold
    
    return header, line
end

-- Fade in animation
function UITheme:FadeIn(frame, duration)
    if not frame then return end
    
    frame:SetAlpha(0)
    frame:Show()
    
    local elapsed = 0
    local startAlpha = 0
    local endAlpha = 1
    
    frame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        local progress = elapsed / duration
        
        if progress >= 1 then
            frame:SetAlpha(endAlpha)
            frame:SetScript("OnUpdate", nil)
        else
            frame:SetAlpha(startAlpha + (endAlpha - startAlpha) * progress)
        end
    end)
end

-- Fade out animation
function UITheme:FadeOut(frame, duration, hideOnComplete)
    if not frame then return end
    
    local elapsed = 0
    local startAlpha = frame:GetAlpha()
    local endAlpha = 0
    
    frame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        local progress = elapsed / duration
        
        if progress >= 1 then
            frame:SetAlpha(endAlpha)
            if hideOnComplete then
                frame:Hide()
            end
            frame:SetScript("OnUpdate", nil)
        else
            frame:SetAlpha(startAlpha + (endAlpha - startAlpha) * progress)
        end
    end)
end

-- Pulse animation for alerts
function UITheme:PulseAnimation(frame, minAlpha, maxAlpha, speed)
    if not frame then return end
    
    local elapsed = 0
    local increasing = true
    
    frame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1 * speed
        
        local alpha
        if increasing then
            alpha = minAlpha + (maxAlpha - minAlpha) * elapsed
            if alpha >= maxAlpha then
                alpha = maxAlpha
                increasing = false
                elapsed = 0
            end
        else
            alpha = maxAlpha - (maxAlpha - minAlpha) * elapsed
            if alpha <= minAlpha then
                alpha = minAlpha
                increasing = true
                elapsed = 0
            end
        end
        
        frame:SetAlpha(alpha)
    end)
end

-- Stop all animations
function UITheme:StopAnimations(frame)
    if frame then
        frame:SetScript("OnUpdate", nil)
    end
end

-- Get threat color based on level
function UITheme:GetThreatColor(threatLevel)
    if threatLevel >= 4 then
        return self.Colors.ThreatCritical
    elseif threatLevel >= 3 then
        return self.Colors.ThreatHigh
    elseif threatLevel >= 2 then
        return self.Colors.ThreatMedium
    elseif threatLevel >= 1 then
        return self.Colors.ThreatLow
    else
        return self.Colors.ThreatNone
    end
end

-- Create icon texture (using class icons or raid icons)
function UITheme:CreateIcon(parent, iconType, size)
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(size or 32)
    icon:SetHeight(size or 32)
    
    -- Use raid target icons as placeholders
    if iconType == "skull" then
        icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    elseif iconType == "cross" then
        icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_7")
    elseif iconType == "square" then
        icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_6")
    elseif iconType == "moon" then
        icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_5")
    elseif iconType == "triangle" then
        icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_4")
    elseif iconType == "diamond" then
        icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_3")
    elseif iconType == "circle" then
        icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_2")
    elseif iconType == "star" then
        icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    else
        -- Default icon
        icon:SetTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
    end
    
    return icon
end
