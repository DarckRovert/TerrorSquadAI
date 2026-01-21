-- TerrorSquadAI Tactical HUD Module
-- Visual holographic overlay for critical combat awareness
-- Author: DarckRovert (elnazzareno)

local TacticalHUD = {}
TerrorSquadAI:RegisterModule("TacticalHUD", TacticalHUD)

-- Config
TacticalHUD.config = {
    enabled = true,
    scale = 1.0,
    animations = true,
}

function TacticalHUD:Initialize()
    self:CreateFrames()
    self:RegisterEvents()
    TerrorSquadAI:Debug("TacticalHUD initialized")
end

function TacticalHUD:CreateFrames()
    -- Main Parent Frame
    self.frame = CreateFrame("Frame", "TSAI_TacticalHUD", UIParent)
    self.frame:SetAllPoints()
    self.frame:SetFrameStrata("HIGH") -- Above normal UI, below tooltips
    self.frame:SetAlpha(0)
    
    -- 1. Critical Alert Overlay (Red Pulse edges)
    self.critFrame = CreateFrame("Frame", nil, self.frame)
    self.critFrame:SetAllPoints()
    self.critFrame.tex = self.critFrame:CreateTexture(nil, "BACKGROUND")
    self.critFrame.tex:SetAllPoints()
    -- Use a red vignette texture or similar. In 1.12 we might need to construct it or use a generic one.
    -- Using LowHealth texture is a safe bet for "Critical" look
    self.critFrame.tex:SetTexture("Interface\\FullScreenTextures\\LowHealth") 
    self.critFrame:SetAlpha(0)
    
    -- 2. Message Frame (Center-Top Hologram)
    self.msgFrame = CreateFrame("Frame", nil, self.frame)
    self.msgFrame:SetWidth(512)
    self.msgFrame:SetHeight(128)
    self.msgFrame:SetPoint("TOP", 0, -150)
    
    self.msgBg = self.msgFrame:CreateTexture(nil, "BACKGROUND")
    self.msgBg:SetAllPoints()
    self.msgBg:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight") -- Generic gradient
    self.msgBg:SetBlendMode("ADD")
    self.msgBg:SetVertexColor(0, 0.8, 1, 0.5)
    
    self.msgIcon = self.msgFrame:CreateTexture(nil, "ARTWORK")
    self.msgIcon:SetWidth(48)
    self.msgIcon:SetHeight(48)
    self.msgIcon:SetPoint("LEFT", 20, 0)
    
    self.msgText = self.msgFrame:CreateFontString(nil, "OVERLAY")
    self.msgText:SetFont("Fonts\\FRIZQT__.TTF", 24, "OUTLINE")
    self.msgText:SetPoint("LEFT", self.msgIcon, "RIGHT", 10, 0)
    self.msgText:SetPoint("RIGHT", -10, 0)
    self.msgText:SetJustifyH("LEFT")
    self.msgText:SetText("SYSTEM ONLINE")
    
    self.msgFrame:SetAlpha(0)
    
    -- Animation State
    self.activeAlert = nil
    self.animStartTime = 0
    self.animDuration = 0
end

function TacticalHUD:RegisterEvents()
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function() 
        TacticalHUD:OnUpdate() 
    end)
    
    -- Test command
    -- /script TerrorSquadAI.Modules.TacticalHUD:ShowAlert("TEST ALERT", "CRITICAL", "Interface\\Icons\\Spell_Fire_Fireball")
end

function TacticalHUD:ShowAlert(text, type, icon)
    if not self.config.enabled then return end
    
    self.activeAlert = {
        text = text,
        type = type or "TACTICAL",
        icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark",
        startTime = GetTime(),
        duration = 3.5, -- Seconds
        phase = "FADE_IN"
    }
    
    -- Setup visuals based on type
    if type == "CRITICAL" then
        self.msgBg:SetVertexColor(1, 0, 0, 0.6) -- Red
        self.msgText:SetTextColor(1, 0.2, 0.2)
        -- Trigger screen flash
        self.critFrame:SetAlpha(1)
        UIFrameFadeOut(self.critFrame, 1.5, 1, 0)
        PlaySound("RaidWarning")
    elseif type == "DEFENSIVE" then
        self.msgBg:SetVertexColor(0, 1, 0.2, 0.6) -- Green
        self.msgText:SetTextColor(0.2, 1, 0.2)
        PlaySound("igSpellVolumeHigh")
    else -- TACTICAL/Info
        self.msgBg:SetVertexColor(0, 0.6, 1, 0.6) -- Blue
        self.msgText:SetTextColor(0.4, 0.8, 1)
        PlaySound("igMainMenuOption")
    end
    
    self.msgText:SetText(string.upper(text))
    self.msgIcon:SetTexture(self.activeAlert.icon)
    self.msgFrame:SetAlpha(0)
end

function TacticalHUD:OnUpdate()
    if not self.activeAlert then return end
    
    local now = GetTime()
    local elapsed = now - self.activeAlert.startTime
    
    if elapsed > self.activeAlert.duration then
        self.activeAlert = nil
        self.msgFrame:SetAlpha(0)
        return
    end
    
    -- Animation Logic
    local alpha = 0
    if elapsed < 0.5 then -- Fade In
        alpha = elapsed / 0.5
    elseif elapsed > (self.activeAlert.duration - 0.5) then -- Fade Out
        alpha = (self.activeAlert.duration - elapsed) / 0.5
    else -- Sustain
        alpha = 1
    end
    
    self.msgFrame:SetAlpha(alpha)
    
    -- Pulse effect for Critical
    if self.activeAlert.type == "CRITICAL" then
        local scale = 1.0 + (math.sin(elapsed * 10) * 0.05)
        self.msgFrame:SetScale(scale)
    else
        self.msgFrame:SetScale(1.0)
    end
end

-- Hook for testing
function TacticalHUD:Test()
    self:ShowAlert("¡BOMBA! ALÉJATE", "CRITICAL", "Interface\\Icons\\Spell_Shadow_MindBomb")
end
