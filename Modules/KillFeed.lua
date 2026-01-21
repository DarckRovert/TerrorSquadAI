-- KillFeed.lua - Feed de Asesinatos Estilizado
-- TerrorSquadAI v4.0 - Phase 1
-- Mensajes de muerte estilo shooter en pantalla

local KF = {}
TerrorSquadAI:RegisterModule("KillFeed", KF)

-- Configuración
KF.config = {
    enabled = true,
    showEmotes = true,
    sound = true,
    duration = 5,
}

-- Estilos
KF.STYLES = {
    KILL = { color = {0, 1, 0}, icon = "🔫" }, -- Icono via textura o texto si fuente soporta
    DEATH = { color = {1, 0, 0}, icon = "☠️" },
    ASSIST = { color = {1, 0.5, 0}, icon = "🤝" },
}

-- Estado
KF.messages = {}

function KF:Initialize()
    self:CreateFeedFrame()
    self:RegisterEvents()
    if TerrorSquadAI.DEBUG then
        TerrorSquadAI:Debug("KillFeed inicializado")
    end
end

function KF:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
    frame:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH") -- Para muertes aliadas
    
    frame:SetScript("OnEvent", function()
        KF:OnCombatEvent(event, arg1)
    end)
    
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        KF:OnUpdate()
    end)
end

function KF:CreateFeedFrame()
    -- Frame contenedor en la parte superior derecha (debajo del minimapa o buffs)
    local f = CreateFrame("Frame", "TSAI_KillFeed", UIParent)
    f:SetWidth(300)
    f:SetHeight(150)
    f:SetPoint("TOP", UIParent, "TOP", 0, -150) -- Centrado arriba
    f:SetFrameStrata("HIGH")
    
    -- Fondo opcional para debug
    -- local bg = f:CreateTexture(nil, "BACKGROUND")
    -- bg:SetAllPoints()
    -- bg:SetTexture(0, 0, 0, 0.3)
    
    self.frame = f
    self.lines = {}
    
    -- Crear lineas
    for i = 1, 5 do
        local line = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        line:SetPoint("TOP", f, "TOP", 0, -(i-1)*25)
        line:SetJustifyH("CENTER")
        line:Hide()
        self.lines[i] = line
    end
end

function KF:OnCombatEvent(event, message)
    if not self.config.enabled then return end
    
    local text = nil
    local style = nil
    
    -- Parsear mensaje
    if event == "CHAT_MSG_COMBAT_HOSTILE_DEATH" then
        local _, _, enemy = string.find(message, "^(.+) muere")
        if not enemy then _, _, enemy = string.find(message, "^(.+) dies") end
        
        if enemy then
            -- Determinar si participamos (simple check de combate por ahora)
            -- Idealmente checkearíamos con PvPScorecard si lo golpeamos recientemente
            if UnitAffectingCombat("player") then
                text = string.format("[Tú]  >>>  [%s]", enemy)
                style = self.STYLES.KILL
            else
                -- Muerte genérica cerca
                 -- text = string.format("☠️ %s", enemy)
                 -- style = self.STYLES.ASSIST -- O gris
            end
        end
    elseif event == "CHAT_MSG_COMBAT_FRIENDLY_DEATH" then
        local _, _, friend = string.find(message, "^(.+) muere")
        if not friend then _, _, friend = string.find(message, "^(.+) dies") end
        
        if friend then
            -- Muerte aliada
            text = string.format("[%s]  ☠️  [Muerte]", friend)
            style = self.STYLES.DEATH
        end
    end
    
    if text and style then
        self:AddMessage(text, style)
    end
end

function KF:AddMessage(text, style)
    -- Shift lines down
    for i = 5, 2, -1 do
        local msg = self.messages[i-1]
        self.messages[i] = msg
    end
    
    self.messages[1] = {
        text = text,
        color = style.color,
        time = GetTime(),
        alpha = 1
    }
    
    self:UpdateDisplay()
    
    if self.config.sound then
        -- PlaySound("PVPEnterQueue") -- Sonido distintivo
    end
end

function KF:UpdateDisplay()
    for i = 1, 5 do
        local msg = self.messages[i]
        local line = self.lines[i]
        
        if msg then
            line:SetText(msg.text)
            line:SetTextColor(msg.color[1], msg.color[2], msg.color[3], msg.alpha)
            line:Show()
        else
            line:Hide()
        end
    end
end

function KF:OnUpdate()
    local now = GetTime()
    local dirty = false
    
    for i = 1, 5 do
        local msg = self.messages[i]
        if msg then
            local age = now - msg.time
            if age > self.config.duration then
                self.messages[i] = nil
                dirty = true
            elseif age > (self.config.duration - 1) then
                -- Fade out
                msg.alpha = self.config.duration - age
                dirty = true
            end
        end
    end
    
    if dirty then
        self:UpdateDisplay()
    end
end
