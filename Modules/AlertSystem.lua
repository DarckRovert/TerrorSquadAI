-- TerrorSquadAI Alert System Module
-- Custom alert framework with personalized notifications
-- Author: DarckRovert (elnazzareno)
-- FIXED: Agregado sistema de cooldown para evitar spam de alertas

local AlertSystem = {}
TerrorSquadAI:RegisterModule("AlertSystem", AlertSystem)

-- Alert queue
AlertSystem.activeAlerts = {}
AlertSystem.alertQueue = {}
AlertSystem.maxActiveAlerts = 5
AlertSystem.alertCooldowns = {} -- Cooldown tracker para evitar spam
AlertSystem.cooldownDuration = 3 -- segundos entre alertas del mismo mensaje

-- Alert types
AlertSystem.ALERT_CRITICAL = "critical"
AlertSystem.ALERT_WARNING = "warning"
AlertSystem.ALERT_INFO = "info"
AlertSystem.ALERT_SUCCESS = "success"

-- Alert frames
AlertSystem.alertFrames = {}
AlertSystem.framePool = {}

function AlertSystem:Initialize()
    self.activeAlerts = {}
    self.alertQueue = {}
    self.alertFrames = {}
    self.alertCooldowns = {}
    self.cooldownDuration = 3
    
    -- Create alert frame pool
    self:CreateFramePool()
    
    -- Create update ticker
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame:SetScript("OnUpdate", function()
        AlertSystem:OnUpdate()
    end)
    
    TerrorSquadAI:Debug("AlertSystem initialized with anti-spam protection")
end

function AlertSystem:CreateFramePool()
    for i = 1, self.maxActiveAlerts do
        local frame = self:CreateAlertFrame(i)
        table.insert(self.framePool, frame)
    end
end

function AlertSystem:CreateAlertFrame(index)
    local frame = CreateFrame("Frame", "TerrorSquadAI_Alert" .. index, UIParent)
    frame:SetWidth(350)
    frame:SetHeight(60)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -100 - ((index - 1) * 70))
    frame:SetFrameStrata("HIGH")
    frame:Hide()
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetTexture(0, 0, 0, 0.8)
    
    -- Border
    frame.border = frame:CreateTexture(nil, "BORDER")
    frame.border:SetAllPoints()
    frame.border:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Border")
    
    -- Icon
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetWidth(40)
    frame.icon:SetHeight(40)
    frame.icon:SetPoint("LEFT", frame, "LEFT", 10, 0)
    frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    
    -- Text
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.text:SetPoint("LEFT", frame.icon, "RIGHT", 10, 0)
    frame.text:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    frame.text:SetJustifyH("LEFT")
    frame.text:SetText("Alert")
    
    -- Timer bar
    frame.timerBar = CreateFrame("StatusBar", nil, frame)
    frame.timerBar:SetWidth(330)
    frame.timerBar:SetHeight(4)
    frame.timerBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 5)
    frame.timerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.timerBar:SetMinMaxValues(0, 1)
    frame.timerBar:SetValue(1)
    
    -- Animation (Vanilla WoW doesn't support CreateAnimationGroup)
    -- Using simple alpha transitions instead
    frame.fadeIn = function()
        frame:SetAlpha(0)
        frame:Show()
        -- Simple fade in using OnUpdate
        local elapsed = 0
        frame:SetScript("OnUpdate", function()
            elapsed = elapsed + arg1
            if elapsed < 0.3 then
                frame:SetAlpha(elapsed / 0.3)
            else
                frame:SetAlpha(1)
                frame:SetScript("OnUpdate", nil)
            end
        end)
    end
    
    frame.fadeOut = function()
        local elapsed = 0
        frame:SetScript("OnUpdate", function()
            elapsed = elapsed + arg1
            if elapsed < 0.3 then
                frame:SetAlpha(1 - (elapsed / 0.3))
            else
                frame:SetAlpha(0)
                frame:Hide()
                frame:SetScript("OnUpdate", nil)
                AlertSystem:ReturnFrameToPool(frame)
            end
        end)
    end
    
    return frame
end

function AlertSystem:ShowAlert(alertData, alertType)
    if not TerrorSquadAI.DB.alertsEnabled then return end
    
    -- COMPAT: Si alertData es un string, convertirlo a tabla
    if type(alertData) == "string" then
        alertData = {
            message = alertData,
            type = alertType or self.ALERT_INFO
        }
    end
    
    if not alertData or not alertData.message then return end
    
    -- Check cooldown para evitar spam del mismo mensaje
    local messageKey = alertData.message
    if self.alertCooldowns[messageKey] then
        local timeSinceLastAlert = GetTime() - self.alertCooldowns[messageKey]
        if timeSinceLastAlert < self.cooldownDuration then
            return -- Mensaje todavía en cooldown
        end
    end
    
    -- Verificar si ya existe una alerta activa con el mismo mensaje
    for _, activeAlert in ipairs(self.activeAlerts) do
        if activeAlert.message == messageKey then
            return -- Ya hay una alerta activa con este mensaje
        end
    end
    
    -- Registrar cooldown
    self.alertCooldowns[messageKey] = GetTime()
    
    -- Create alert object
    local alert = {
        id = GetTime(),
        type = alertData.type or self.ALERT_INFO,
        message = alertData.message,
        icon = alertData.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
        duration = alertData.duration or 3,
        sound = alertData.sound or false,
        source = alertData.source or "AI",
        timestamp = GetTime(),
        frame = nil
    }
    
    -- Add to queue
    table.insert(self.alertQueue, alert)
    
    -- Process queue
    self:ProcessAlertQueue()
    
    -- Play sound if requested
    if alert.sound then
        self:PlayAlertSound(alert.type)
    end
    
    -- Store in history
    if not TerrorSquadAI.CharDB.alertHistory then
        TerrorSquadAI.CharDB.alertHistory = {}
    end
    table.insert(TerrorSquadAI.CharDB.alertHistory, {
        timestamp = time(),
        type = alert.type,
        message = alert.message
    })
    
    -- Keep only last 100 alerts
    if table.getn(TerrorSquadAI.CharDB.alertHistory) > 100 then
        table.remove(TerrorSquadAI.CharDB.alertHistory, 1)
    end
end

function AlertSystem:ProcessAlertQueue()
    -- Process queued alerts
    while table.getn(self.alertQueue) > 0 and table.getn(self.activeAlerts) < self.maxActiveAlerts do
        local alert = table.remove(self.alertQueue, 1)
        self:DisplayAlert(alert)
    end
end

function AlertSystem:DisplayAlert(alert)
    -- Get frame from pool
    local frame = self:GetFrameFromPool()
    if not frame then return end
    
    alert.frame = frame
    
    -- Configure frame
    frame.icon:SetTexture(alert.icon)
    frame.text:SetText(alert.message)
    
    -- Set colors based on type
    local r, g, b = self:GetAlertColor(alert.type)
    frame.bg:SetTexture(r * 0.3, g * 0.3, b * 0.3, 0.9)
    frame.timerBar:SetStatusBarColor(r, g, b, 1)
    frame.text:SetTextColor(r, g, b)
    
    -- Set timer
    frame.timerBar:SetMinMaxValues(0, alert.duration)
    frame.timerBar:SetValue(alert.duration)
    
    -- Show frame with fade in
    frame.fadeIn()
    
    -- Add to active alerts
    table.insert(self.activeAlerts, alert)
end

function AlertSystem:GetAlertColor(alertType)
    if alertType == self.ALERT_CRITICAL then
        return 1, 0, 0 -- Red
    elseif alertType == self.ALERT_WARNING then
        return 1, 0.5, 0 -- Orange
    elseif alertType == self.ALERT_SUCCESS then
        return 0, 1, 0 -- Green
    else
        return 0.5, 0.5, 1 -- Blue
    end
end

function AlertSystem:PlayAlertSound(alertType)
    if alertType == self.ALERT_CRITICAL then
        PlaySound("RaidWarning")
    elseif alertType == self.ALERT_WARNING then
        PlaySound("TellMessage")
    else
        PlaySound("MapPing")
    end
end

function AlertSystem:OnUpdate()
    local currentTime = GetTime()
    local i = 1
    
    while i <= table.getn(self.activeAlerts) do
        local alert = self.activeAlerts[i]
        local elapsed = currentTime - alert.timestamp
        
        if elapsed >= alert.duration then
            -- Remove alert
            if alert.frame then
                alert.frame.fadeOut()
            end
            table.remove(self.activeAlerts, i)
            
            -- Process queue
            self:ProcessAlertQueue()
        else
            -- Update timer bar
            if alert.frame and alert.frame.timerBar then
                alert.frame.timerBar:SetValue(alert.duration - elapsed)
            end
            i = i + 1
        end
    end
end

function AlertSystem:GetFrameFromPool()
    for i, frame in ipairs(self.framePool) do
        if not frame:IsShown() then
            return frame
        end
    end
    return nil
end

function AlertSystem:ReturnFrameToPool(frame)
    -- Frame is already in pool, just hidden
    -- Nothing to do
end

function AlertSystem:CreateAlertProfile(profileName, settings)
    if not TerrorSquadAI.DB.alertProfiles then
        TerrorSquadAI.DB.alertProfiles = {}
    end
    
    TerrorSquadAI.DB.alertProfiles[profileName] = {
        enabled = settings.enabled or true,
        soundEnabled = settings.soundEnabled or true,
        criticalOnly = settings.criticalOnly or false,
        position = settings.position or {x = 0, y = -100},
        scale = settings.scale or 1.0
    }
end

function AlertSystem:LoadAlertProfile(profileName)
    if not TerrorSquadAI.DB.alertProfiles or not TerrorSquadAI.DB.alertProfiles[profileName] then
        return false
    end
    
    local profile = TerrorSquadAI.DB.alertProfiles[profileName]
    
    -- Apply profile settings
    TerrorSquadAI.DB.alertsEnabled = profile.enabled
    
    -- Update frame positions and scale
    for i, frame in ipairs(self.framePool) do
        frame:ClearAllPoints()
        frame:SetPoint("TOP", UIParent, "TOP", profile.position.x, profile.position.y - ((i - 1) * 70))
        frame:SetScale(profile.scale)
    end
    
    return true
end

function AlertSystem:ClearAllAlerts()
    for _, alert in ipairs(self.activeAlerts) do
        if alert.frame then
            alert.frame:Hide()
        end
    end
    
    self.activeAlerts = {}
    self.alertQueue = {}
end

function AlertSystem:GetActiveAlerts()
    return self.activeAlerts
end

function AlertSystem:GetAlertHistory()
    return TerrorSquadAI.CharDB.alertHistory or {}
end
