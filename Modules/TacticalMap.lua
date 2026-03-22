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

function TacticalMap:Initialize()
    self:CreateMapFrame()
    self:CreatePollingFrame()
end

function TacticalMap:CreateMapFrame()
    -- Este frame será el contenedor del mapa
    local frame = CreateFrame("Frame", "TSAI_TacticalMap_Container", UIParent)
    frame:SetWidth(400)
    frame:SetHeight(400)
    frame:Hide()
    
    -- Los 12 tiles del WorldMapDetail (estándar de Blizzard 1.12)
    frame.tiles = {}
    for i = 1, 12 do
        local tile = frame:CreateTexture("TSAI_MapTile_"..i, "BACKGROUND")
        tile:SetAlpha(self.config.mapAlpha)
        frame.tiles[i] = tile
    end
    
    self.mapFrame = frame
    self:LayoutTiles(frame)
end

function TacticalMap:LayoutTiles(frame)
    local width = frame:GetWidth()
    local height = frame:GetHeight()
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
    -- NOTA: En 1.12, GetMapInfo() devuelve el nombre de la carpeta de texturas de la zona
    local mapName = GetMapInfo()
    if not mapName or mapName == "" then return end
    
    if mapName ~= self.currentMap then
        self.currentMap = mapName
        for i = 1, 12 do
            local texturePath = "Interface\\WorldMap\\" .. mapName .. "\\" .. mapName .. i
            self.mapFrame.tiles[i]:SetTexture(texturePath)
        end
    end
end

function TacticalMap:CreatePollingFrame()
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
    
    -- Actualizar texturas si es necesario
    -- En 1.12, para obtener coordenadas válidas de otros, el mapa interno debe estar en la zona correcta
    if not WorldMapFrame:IsShown() then
        SetMapToCurrentZone()
    end
    
    self:UpdateMapTextures()
    
    -- Actualizar posiciones
    self:UpdateBlips()
end

function TacticalMap:UpdateBlips()
    -- Jugador
    local x, y = GetPlayerMapPosition("player")
    if x > 0 and y > 0 then
        self:UpdateBlip("player", x, y, "cyan")
    else
        if self.blips.player then self.blips.player:Hide() end
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
            else
                if self.blips.allies[unit] then self.blips.allies[unit]:Hide() end
            end
        end
    end
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
    
    -- Convertir x, y porcentual a posición de frame
    local fW = self.mapFrame:GetWidth()
    local fH = self.mapFrame:GetHeight()
    
    blip:ClearAllPoints()
    blip:SetPoint("CENTER", self.mapFrame, "TOPLEFT", x * fW, -(y * fH))
    
    -- Color
    if color == "cyan" then
        blip.dot:SetVertexColor(0, 1, 1, 1)
    elseif color == "green" then
        blip.dot:SetVertexColor(0, 1, 0, 1)
    end
    
    blip:Show()
    
    -- Animación simple de pulso manual (1.12 compatible)
    local now = GetTime()
    local scale = 1 + math.sin(now * 5) * 0.2
    blip.glow:SetWidth(self.config.blipSize * 2 * scale)
    blip.glow:SetHeight(self.config.blipSize * 2 * scale)
    blip.glow:SetAlpha(0.5 - math.sin(now * 5) * 0.2)
end

function TacticalMap:CreateBlipFrame(id)
    local b = CreateFrame("Frame", "TSAI_Blip_" .. id, self.mapFrame)
    b:SetWidth(self.config.blipSize)
    b:SetHeight(self.config.blipSize)
    
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
    self.mapFrame:SetParent(parent)
    self.mapFrame:SetAllPoints(parent)
    self:LayoutTiles(self.mapFrame)
    self.mapFrame:Show()
end

return TacticalMap
