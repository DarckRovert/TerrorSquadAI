-- TacticalMap.lua - Motor de Mapa Táctico 1.12.1
-- TerrorSquadAI v5.0 - Tactical Map Evolution
-- Maneja texturas de zona, coordenadas y blips de posición

local TacticalMap = {}
TerrorSquadAI:RegisterModule("TacticalMap", TacticalMap)

TacticalMap.config = {
    updateInterval = 0.2,
    mapAlpha = 0.7,
    blipSize = 12,
}

TacticalMap.currentMap = nil
TacticalMap.blips = {
    player = nil,
    allies = {},
    enemies = {},
}
TacticalMap.labelPool = {}
TacticalMap.activeLabels = {}
TacticalMap.pings = {}

function TacticalMap:Initialize()
    -- Initialize data structures, but don't create frames until Setup is called
    self.currentMap = nil
    self.labelPool = self.labelPool or {}
    self.activeLabels = self.activeLabels or {}
    self.pings = self.pings or {}
    self:CreatePollingFrame()
end

function TacticalMap:Setup(container)
    if not container then return end
    
    -- Si ya existe, reparentar
    if self.mapFrame then
        self.mapFrame:SetParent(container)
        self.mapFrame:SetAllPoints(container)
        self:LayoutTiles(self.mapFrame)
        return
    end

    -- Crear el frame contenedor del mapa tactico
    local frame = CreateFrame("Frame", "TSAI_TacticalMap_Internal", container)
    frame:SetWidth(400)
    frame:SetHeight(300)
    frame:SetPoint("CENTER", container, "CENTER", 0, 0)
    
    -- NIVEL BAJO: El mapa siempre debe estar al fondo del canvas
    frame:SetFrameLevel(1)
    
    -- Los 12 tiles del WorldMapDetail (estándar de Blizzard 1.12)
    frame.tiles = {}
    for i = 1, 12 do
        local tile = frame:CreateTexture("TSAI_MapTile_"..i, "BACKGROUND")
        tile:SetAlpha(self.config.mapAlpha)
        frame.tiles[i] = tile
    end
    
    self.mapFrame = frame
    self:LayoutTiles(frame)
    self:UpdateMapTextures()
end

function TacticalMap:LayoutTiles(frame)
    -- En 1.12.1, forzamos un ancho/alto base si no se detecta (400x300 es nuestro estandard)
    local width = frame:GetWidth()
    local height = frame:GetHeight()
    if width == 0 then width = 400 end
    if height == 0 then height = 300 end
    
    local tW = width / 4
    local tH = height / 3
    
    for i = 1, 12 do
        local row = math.floor((i-1) / 4)
        local col = math.mod(i-1, 4)
        local tile = frame.tiles[i]
        tile:SetWidth(tW)
        tile:SetHeight(tH)
        tile:SetPoint("TOPLEFT", frame, "TOPLEFT", col * tW, -(row * tH))
    end
end

function TacticalMap:UpdateMapTextures()
    -- NOTA: En 1.12, GetMapInfo() devuelve el nombre de la carpeta de texturas
    local mapName = GetMapInfo()
    if not mapName or mapName == "" then return end
    
    if mapName ~= self.currentMap then
        self.currentMap = mapName
        if self.mapFrame and self.mapFrame.tiles then
            for i = 1, 12 do
                local texturePath = "Interface\\WorldMap\\" .. mapName .. "\\" .. mapName .. i
                self.mapFrame.tiles[i]:SetTexture(texturePath)
            end
        end
    end
end

function TacticalMap:CreatePollingFrame()
    if self.pollingFrame then return end
    local f = CreateFrame("Frame")
    local elapsed = 0
    f:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= TacticalMap.config.updateInterval then
            elapsed = 0
            TacticalMap:Poll()
        end
    end)
    f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    f:SetScript("OnEvent", function()
        TacticalMap:UpdateMapTextures()
    end)
    self.pollingFrame = f
end

function TacticalMap:Poll()
    -- Solo procesar si el mapa táctico está visible
    local board = TerrorSquadAI.Modules.TerrorBoard
    if not board or not board.mainFrame or not board.mainFrame:IsShown() then return end
    
    -- En 1.12, para obtener coordenadas válidas de otros, el mapa interno debe estar sincronizado
    if not WorldMapFrame:IsShown() then
        SetMapToCurrentZone()
    end
    
    self:UpdateMapTextures()
    self:UpdateBlips()
end

function TacticalMap:UpdateBlips()
    if not self.mapFrame then return end

    -- Jugador
    local x, y = GetPlayerMapPosition("player")
    if x > 0 and y > 0 then
        self:UpdateBlip("player", x, y, "cyan")
    else
        if self.blips.player then self.blips.player:Hide() end
    end
    
    -- Ocultar todos los nombres activos para re-asignar
    if self.activeLabels then
        for unit, label in pairs(self.activeLabels) do
            label:Hide()
            table.insert(self.labelPool, label)
            self.activeLabels[unit] = nil
        end
    end
    
    -- Aliados (Raid/Party)
    local groupType = "party"
    local count = GetNumPartyMembers()
    if GetNumRaidMembers() > 0 then
        groupType = "raid"
        count = GetNumRaidMembers()
    end
    
    for i = 1, count do
        local unit = groupType .. i
        if not UnitIsUnit(unit, "player") then
            local ax, ay = GetPlayerMapPosition(unit)
            if ax > 0 and ay > 0 then
                self:UpdateBlip(unit, ax, ay, "green")
                self:ShowUnitLabel(unit, ax, ay)
            else
                if self.blips.allies and self.blips.allies[unit] then 
                    self.blips.allies[unit]:Hide() 
                end
            end
        end
    end
    
    self:UpdatePings()
end

function TacticalMap:ShowUnitLabel(unit, x, y)
    if not self.mapFrame then return end
    local label = table.remove(self.labelPool)
    if not label then
        label = self.mapFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    end
    
    local name = UnitName(unit)
    if not name then return end
    
    label:SetText("|cFFCCFFFF" .. string.sub(name, 1, 8) .. "|r")
    
    local fW, fH = 400, 300
    label:SetPoint("BOTTOM", self.mapFrame, "TOPLEFT", x * fW, -(y * fH) - 12)
    label:Show()
    self.activeLabels[unit] = label
end

function TacticalMap:UpdateBlip(id, x, y, color)
    local blip
    if id == "player" then
        if not self.blips.player then
            self.blips.player = self:CreateBlipFrame("player")
        end
        blip = self.blips.player
    else
        if not self.blips.allies[id] then
            self.blips.allies[id] = self:CreateBlipFrame(id)
        end
        blip = self.blips.allies[id]
    end
    
    local fW, fH = 400, 300
    blip:ClearAllPoints()
    blip:SetPoint("CENTER", self.mapFrame, "TOPLEFT", x * fW, -(y * fH))
    
    if color == "cyan" then
        blip.dot:SetVertexColor(0, 1, 1, 1)
    elseif color == "green" then
        blip.dot:SetVertexColor(0, 1, 0, 1)
    end
    
    blip:Show()
    
    local now = GetTime()
    local scale = 1 + math.sin(now * 5) * 0.2
    blip.glow:SetWidth(self.config.blipSize * 2 * scale)
    blip.glow:SetHeight(self.config.blipSize * 2 * scale)
    blip.glow:SetAlpha(0.5 - math.sin(now * 5) * 0.2)
end

function TacticalMap:TriggerPing(x, y)
    if not self.mapFrame then return end
    local ping = nil
    for _, p in ipairs(self.pings) do
        if not p:IsShown() then ping = p break end
    end
    
    if not ping then
        ping = CreateFrame("Frame", nil, self.mapFrame)
        ping:SetWidth(40)
        ping:SetHeight(40)
        ping:SetFrameLevel(25) -- Encima de los blips
        ping.tex = ping:CreateTexture(nil, "OVERLAY")
        ping.tex:SetAllPoints()
        ping.tex:SetTexture("Interface\\Cooldown\\ping4")
        ping.tex:SetBlendMode("ADD")
        ping.tex:SetVertexColor(1, 1, 0, 0.8) -- Amarillo para visibilidad
        table.insert(self.pings, ping)
    end
    
    local fW, fH = 400, 300
    ping:SetPoint("CENTER", self.mapFrame, "TOPLEFT", x * fW, -(y * fH))
    ping.startTime = GetTime()
    ping:Show()
end

function TacticalMap:UpdatePings()
    if not self.pings then return end
    local now = GetTime()
    for _, p in ipairs(self.pings) do
        if p:IsShown() then
            local dur = now - p.startTime
            if dur > 1.0 then
                p:Hide()
            else
                local scale = 1 + dur * 3
                p:SetWidth(40 * scale)
                p:SetHeight(40 * scale)
                p:SetAlpha(1 - dur)
            end
        end
    end
end

function TacticalMap:SetOpacity(delta)
    self.config.mapAlpha = math.max(0.1, math.min(1.0, self.config.mapAlpha + delta))
    if self.mapFrame and self.mapFrame.tiles then
        for i = 1, 12 do
            self.mapFrame.tiles[i]:SetAlpha(self.config.mapAlpha)
        end
    end
end

function TacticalMap:CreateBlipFrame(id)
    local b = CreateFrame("Frame", "TSAI_Blip_" .. id, self.mapFrame)
    b:SetWidth(self.config.blipSize)
    b:SetHeight(self.config.blipSize)
    b:SetFrameLevel(20) -- Por encima del mapa
    
    b.dot = b:CreateTexture(nil, "OVERLAY")
    b.dot:SetAllPoints()
    b.dot:SetTexture("Interface\\Buttons\\UI-RadioButton")
    b.dot:SetTexCoord(0.25, 0.5, 0, 0.25)
    
    b.glow = b:CreateTexture(nil, "BACKGROUND")
    b.glow:SetTexture("Interface\\CharacterFrame\\UI-Party-TargetTransition")
    b.glow:SetBlendMode("ADD")
    b.glow:SetPoint("CENTER", b, "CENTER", 0, 0)
    
    return b
end

function TacticalMap:SetParent(parent)
    -- Deprecated in v5.1.5, now using Setup(container) for better control
    self:Setup(parent)
end

return TacticalMap
