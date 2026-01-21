-- TacticalPings.lua - Sistema de Pings Tácticos

local TP = {}
TerrorSquadAI:RegisterModule("TacticalPings", TP)

-- Tipos de pings tácticos
local PING_TYPES = {
    ATTACK = {name = "Atacar", color = {1, 0, 0}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"},
    DEFEND = {name = "Defender", color = {0, 0, 1}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7"},
    RETREAT = {name = "Retirada", color = {1, 1, 0}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3"},
    HELP = {name = "Ayuda", color = {1, 0.5, 0}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5"},
    DANGER = {name = "Peligro", color = {1, 0, 1}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"},
    GATHER = {name = "Agrupar", color = {0, 1, 0}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2"},
    OBJECTIVE = {name = "Objetivo", color = {0, 1, 1}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4"},
}

-- Estado
TP.activePings = {}
TP.lastPingTime = 0
TP.pingCooldown = 2
TP.maxPings = 5

-- Configuración
TP.config = {
    enabled = true,
    showOnMap = true,
    showOnScreen = true,
    playSound = true,
    pingDuration = 10,
}

function TP:Initialize()
    self:RegisterEvents()
    self:CreatePingFrames()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r TacticalPings inicializado", 1, 0.84, 0)
end

function TP:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("MINIMAP_PING")
    frame:SetScript("OnEvent", function()
        if event == "CHAT_MSG_ADDON" then
            TP:OnAddonMessage(arg1, arg2, arg3, arg4)
        elseif event == "MINIMAP_PING" then
            TP:OnMinimapPing(arg1, arg2, arg3)
        end
    end)
    
    -- Timer para actualizar pings
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        TP:UpdatePings()
    end)
end

function TP:CreatePingFrames()
    self.pingFrames = {}
    for i = 1, self.maxPings do
        local frame = CreateFrame("Frame", "TacticalPing" .. i, UIParent)
        frame:SetWidth(32)
        frame:SetHeight(32)
        frame:SetFrameStrata("HIGH")
        frame:Hide()
        
        local texture = frame:CreateTexture(nil, "OVERLAY")
        texture:SetAllPoints(frame)
        frame.texture = texture
        
        local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        text:SetPoint("BOTTOM", frame, "TOP", 0, 5)
        frame.text = text
        
        self.pingFrames[i] = frame
    end
end

function TP:SendPing(pingType, x, y, zone)
    if not self.config.enabled then return end
    
    local now = GetTime()
    if now - self.lastPingTime < self.pingCooldown then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TacticalPings]|r Espera " .. math.ceil(self.pingCooldown - (now - self.lastPingTime)) .. "s", 1, 0.5, 0)
        return
    end
    
    if not PING_TYPES[pingType] then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TacticalPings]|r Tipo de ping inválido", 1, 0, 0)
        return
    end
    
    -- Obtener posición del jugador si no se especifica
    if not x or not y then
        x, y = GetPlayerMapPosition("player")
        zone = GetRealZoneText()
    end
    
    local data = string.format("%s:%.3f:%.3f:%s:%s", pingType, x, y, zone or "", UnitName("player"))
    
    if TerrorSquadAI.Modules.CommunicationSync then
        TerrorSquadAI.Modules.CommunicationSync:SendMessage("TPING", data)
    end
    
    -- Mostrar ping localmente
    self:ShowPing(pingType, x, y, zone, UnitName("player"))
    
    self.lastPingTime = now
    
    -- Solo anunciar en chat si está habilitado
    if TerrorSquadAI.DB.chatMessagesEnabled then
        local pingInfo = PING_TYPES[pingType]
        local message = string.format("[Terror Squad] %s ping en %s", pingInfo.name, zone or "ubicación actual")
        if GetNumRaidMembers() > 0 then
            SendChatMessage(message, "RAID")
        elseif GetNumPartyMembers() > 0 then
            SendChatMessage(message, "PARTY")
        end
    end
end

function TP:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= "TerrorSquadAI" then return end
    
    local _, _, msgType, data = string.find(message, "^(%w+):(.+)$")
    if msgType == "TPING" then
        self:ReceivePing(data, sender)
    end
end

function TP:ReceivePing(data, sender)
    local _, _, pingType, x, y, zone, playerName = string.find(data, "^([^:]+):([%d%.]+):([%d%.]+):([^:]*):(.+)$")
    if not pingType or not x or not y then return end
    
    x = tonumber(x)
    y = tonumber(y)
    
    self:ShowPing(pingType, x, y, zone, playerName or sender)
end

function TP:ShowPing(pingType, x, y, zone, playerName)
    if not self.config.showOnScreen then return end
    
    local pingInfo = PING_TYPES[pingType]
    if not pingInfo then return end
    
    -- Encontrar frame disponible
    local frame = nil
    for i, f in ipairs(self.pingFrames) do
        if not f:IsShown() then
            frame = f
            break
        end
    end
    
    if not frame then
        -- Reutilizar el más antiguo
        frame = self.pingFrames[1]
    end
    
    -- Configurar frame
    frame.texture:SetTexture(pingInfo.icon)
    frame.texture:SetVertexColor(unpack(pingInfo.color))
    frame.text:SetText(playerName .. ": " .. pingInfo.name)
    frame.text:SetTextColor(unpack(pingInfo.color))
    
    -- Posicionar en pantalla (convertir coordenadas del mapa a pantalla)
    local screenX = UIParent:GetWidth() * x
    local screenY = UIParent:GetHeight() * (1 - y)
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", screenX, screenY)
    
    -- Guardar información del ping
    frame.pingData = {
        type = pingType,
        x = x,
        y = y,
        zone = zone,
        player = playerName,
        startTime = GetTime(),
        duration = self.config.pingDuration
    }
    
    frame:Show()
    
    -- Animación de aparición
    frame:SetAlpha(0)
    UIFrameFadeIn(frame, 0.3, 0, 1)
    
    -- Agregar a lista de pings activos
    table.insert(self.activePings, frame.pingData)
    
    -- Sonido
    if self.config.playSound then
        PlaySound("MapPing")
    end
    
    -- Mensaje en chat solo si está habilitado
    if TerrorSquadAI.DB.chatMessagesEnabled then
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD700[Ping Táctico]|r %s: %s en %s", playerName, pingInfo.name, zone or "ubicación"), unpack(pingInfo.color))
    end
end

function TP:UpdatePings()
    local now = GetTime()
    
    -- Actualizar frames de ping
    for i, frame in ipairs(self.pingFrames) do
        if frame:IsShown() and frame.pingData then
            local elapsed = now - frame.pingData.startTime
            local remaining = frame.pingData.duration - elapsed
            
            if remaining <= 0 then
                UIFrameFadeOut(frame, 0.5, 1, 0)
                frame:Hide()
                frame.pingData = nil
            else
                -- Parpadeo en los últimos segundos
                if remaining <= 3 then
                    local alpha = 0.3 + 0.7 * math.abs(math.sin(now * 3))
                    frame:SetAlpha(alpha)
                end
            end
        end
    end
    
    -- Limpiar pings expirados
    for i = table.getn(self.activePings), 1, -1 do
        local ping = self.activePings[i]
        if now - ping.startTime >= ping.duration then
            table.remove(self.activePings, i)
        end
    end
end

function TP:OnMinimapPing(unit, x, y)
    -- Convertir ping de minimapa en ping táctico
    if unit == "player" and self.config.enabled then
        -- Por defecto, usar ping de objetivo
        self:SendPing("OBJECTIVE", x, y)
    end
end

function TP:PingAttack()
    self:SendPing("ATTACK")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Ping]|r Atacar aquí", 1, 0, 0)
end

function TP:PingDefend()
    self:SendPing("DEFEND")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF0000FF[Ping]|r Defender aquí", 0, 0, 1)
end

function TP:PingRetreat()
    self:SendPing("RETREAT")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[Ping]|r Retirada", 1, 1, 0)
end

function TP:PingHelp()
    self:SendPing("HELP")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[Ping]|r Necesito ayuda", 1, 0.5, 0)
end

function TP:PingDanger()
    self:SendPing("DANGER")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[Ping]|r Peligro", 1, 0, 1)
end

function TP:PingGather()
    self:SendPing("GATHER")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Ping]|r Agruparse aquí", 0, 1, 0)
end

function TP:PingObjective()
    self:SendPing("OBJECTIVE")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[Ping]|r Objetivo", 0, 1, 1)
end

function TP:ClearAllPings()
    for i, frame in ipairs(self.pingFrames) do
        frame:Hide()
        frame.pingData = nil
    end
    self.activePings = {}
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TacticalPings]|r Todos los pings eliminados", 1, 0.84, 0)
end

function TP:GetActivePings()
    return self.activePings
end

function TP:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TacticalPings]|r " .. status, 1, 0.84, 0)
end

function TP:PrintHelp()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Pings Tácticos ===", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage("Tipos de ping disponibles:", 1, 1, 1)
    for type, info in pairs(PING_TYPES) do
        DEFAULT_CHAT_FRAME:AddMessage("  " .. info.name .. " (" .. type .. ")", unpack(info.color))
    end
    DEFAULT_CHAT_FRAME:AddMessage("Uso: /tsai ping <tipo>", 1, 1, 1)
end
