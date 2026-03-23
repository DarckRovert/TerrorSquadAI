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

-- v6.1: Estado de punteros en tiempo real (inspirado en RaidMark)
TacticalMap.pointerSlots = {
    { color = "RED",    r = 1,   g = 0.1, b = 0.1, owner = nil, lastX = nil, lastY = nil },  -- Solo RL
    { color = "BLUE",   r = 0.3, g = 0.5, b = 1,   owner = nil, lastX = nil, lastY = nil },
    { color = "GREEN",  r = 0.2, g = 0.9, b = 0.2, owner = nil, lastX = nil, lastY = nil },
    { color = "YELLOW", r = 1,   g = 0.9, b = 0.1, owner = nil, lastX = nil, lastY = nil },
}
TacticalMap.myPointerSlot = nil
TacticalMap.pointerActive  = false
TacticalMap.pointerDots    = {}   -- { [playerName] = frame } para puntos remotos
TacticalMap.ptrTimer       = 0
TacticalMap.PTR_INTERVAL   = 0.033  -- 30fps max

-- v6.3: Verificacion anti-spoof interna para punteros
local function SenderCanControlPTR(sender, color)
    if not sender then return false end
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then return true end
    
    local senderRank = -1
    for i = 1, 40 do
        local name, rank = GetRaidRosterInfo(i)
        if name == sender then
            senderRank = rank
            break
        end
    end
    
    if senderRank == 2 then return true end -- RL puede todo
    if senderRank == 1 then
        -- Assist solo puede colores 2, 3, 4 (Blue, Green, Yellow)
        if color == "RED" then return false end
        return true
    end
    return false
end

function TacticalMap:Initialize()
    -- Initialize data structures, but don't create frames until Setup is called
    self.currentMap = nil
    self.labelPool = self.labelPool or {}
    self.activeLabels = self.activeLabels or {}
    self.pings = self.pings or {}
    self.pointerDots = self.pointerDots or {}
    self:CreatePollingFrame()
    self:RegisterPointerSync()  -- v6.1: Punteros en tiempo real
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

-- ============================================================
-- v6.1: Sistema de Punteros en Tiempo Real (inspirado en RaidMark)
-- Lua 5.0 / WoW 1.12.1 compatible
-- ============================================================

-- Obtener canal de broadcast (igual que TerrorBoard)
local function GetPtrChannel()
    if GetNumRaidMembers() > 0 then return "RAID" end
    if GetNumPartyMembers() > 0 then return "PARTY" end
    return nil
end

-- Reclamar un slot de puntero por color
function TacticalMap:ClaimPointer(colorName)
    local myName = UnitName("player")
    for i, slot in ipairs(self.pointerSlots) do
        if slot.color == colorName then
            if slot.owner then
                TerrorSquadAI:Print("|cFFFF4444[Puntero]|r El slot " .. colorName .. " ya esta ocupado por " .. slot.owner)
                return
            end
            -- Solo el RL puede reclamar el slot ROJO
            if i == 1 and not (IsRaidLeader() == 1) then
                TerrorSquadAI:Print("|cFFFF4444[Puntero]|r El puntero ROJO es exclusivo del Lider de Raid.")
                return
            end
            slot.owner = myName
            self.myPointerSlot = i
            self.pointerActive = true
            local ch = GetPtrChannel()
            if ch then
                SendAddonMessage("TSAI_PTR", "PTR_CLAIM;" .. colorName, ch)
            end
            TerrorSquadAI:Print("|cFF00FF66[Puntero]|r Puntero " .. colorName .. " reclamado. Mueve el cursor sobre el mapa.")
            return
        end
    end
end

-- Liberar el slot propio
function TacticalMap:ReleasePointer()
    if not self.myPointerSlot then return end
    local slot = self.pointerSlots[self.myPointerSlot]
    if slot then
        local ch = GetPtrChannel()
        if ch then
            SendAddonMessage("TSAI_PTR", "PTR_REL;" .. slot.color, ch)
        end
        slot.owner = nil
        slot.lastX = nil
        slot.lastY = nil
    end
    self.myPointerSlot = nil
    self.pointerActive = false
    -- Ocultar punto propio
    local myName = UnitName("player")
    if self.pointerDots[myName] then
        self.pointerDots[myName]:Hide()
    end
    TerrorSquadAI:Print("|cFFAAAAAA[Puntero]|r Puntero liberado.")
end

-- Crear o reutilizar un punto visual en el mapa
function TacticalMap:GetOrCreateDot(playerName, r, g, b)
    if not self.mapFrame then return nil end
    if self.pointerDots[playerName] then
        local d = self.pointerDots[playerName]
        d.dot:SetVertexColor(r, g, b, 1)
        return d
    end
    local dot = CreateFrame("Frame", nil, self.mapFrame)
    dot:SetWidth(10)
    dot:SetHeight(10)
    dot:SetFrameLevel(50) -- Encima de todo

    dot.dot = dot:CreateTexture(nil, "OVERLAY")
    dot.dot:SetAllPoints()
    dot.dot:SetTexture("Interface\\Minimap\\PartyRaidBlips")
    dot.dot:SetTexCoord(0, 0.125, 0, 0.5)
    dot.dot:SetVertexColor(r, g, b, 1)

    -- Glow pulsante
    dot.glow = dot:CreateTexture(nil, "BACKGROUND")
    dot.glow:SetTexture("Interface\\CharacterFrame\\UI-Party-TargetTransition")
    dot.glow:SetBlendMode("ADD")
    dot.glow:SetPoint("CENTER", dot, "CENTER", 0, 0)
    dot.glow:SetWidth(18)
    dot.glow:SetHeight(18)
    dot.glow:SetVertexColor(r, g, b, 0.4)

    dot:Hide()
    self.pointerDots[playerName] = dot
    return dot
end

-- Mover un punto de puntero en el mapa (coordenadas 0-1)
function TacticalMap:AddRemotePointerDot(sender, colorName, px, py)
    if not self.mapFrame then return end
    -- Buscar el color del slot
    local r, g, b = 1, 1, 1
    for _, slot in ipairs(self.pointerSlots) do
        if slot.color == colorName then
            r, g, b = slot.r, slot.g, slot.b
            break
        end
    end
    local dot = self:GetOrCreateDot(sender, r, g, b)
    if not dot then return end
    local mW = self.mapFrame:GetWidth()
    local mH = self.mapFrame:GetHeight()
    if mW == 0 then mW = 400 end
    if mH == 0 then mH = 300 end
    dot:ClearAllPoints()
    dot:SetPoint("CENTER", self.mapFrame, "TOPLEFT", px * mW, -(py * mH))
    dot:Show()
    -- Actualizar slot
    for _, slot in ipairs(self.pointerSlots) do
        if slot.color == colorName then
            slot.lastX = px
            slot.lastY = py
            break
        end
    end
end

-- Enviar posicion propia del puntero
function TacticalMap:BroadcastPointerPos(px, py)
    if not self.myPointerSlot then return end
    local slot = self.pointerSlots[self.myPointerSlot]
    if not slot then return end
    local ch = GetPtrChannel()
    if not ch then return end
    SendAddonMessage("TSAI_PTR",
        "PTR;" .. slot.color .. ";" ..
        string.format("%.4f", px) .. ";" ..
        string.format("%.4f", py), ch)
    -- Mostrar punto propio en el mapa
    local myName = UnitName("player")
    self:AddRemotePointerDot(myName, slot.color, px, py)
end

-- Registrar receptor de punteros y frame de throttle
function TacticalMap:RegisterPointerSync()
    -- Frame de throttle para envio (33ms)
    local ptrThrottle = CreateFrame("Frame", "TSAI_PtrThrottle")
    ptrThrottle:SetScript("OnUpdate", function()
        TacticalMap.ptrTimer = TacticalMap.ptrTimer + arg1
        if TacticalMap.ptrTimer >= TacticalMap.PTR_INTERVAL then
            TacticalMap.ptrTimer = 0
            -- Si el puntero esta activo, enviar posicion del cursor sobre el mapa
            if TacticalMap.pointerActive and TacticalMap.myPointerSlot and TacticalMap.mapFrame then
                local mx, my = GetCursorPosition()
                local s = UIParent:GetEffectiveScale()
                local mL = TacticalMap.mapFrame:GetLeft()
                local mT = TacticalMap.mapFrame:GetTop()
                local mW = TacticalMap.mapFrame:GetWidth()
                local mH = TacticalMap.mapFrame:GetHeight()
                if mL and mT and mW and mW > 0 and mH and mH > 0 then
                    local px = (mx/s - mL) / mW
                    local py = (mT - my/s) / mH
                    -- Solo enviar si el cursor esta dentro del canvas (0-1)
                    if px >= 0 and px <= 1 and py >= 0 and py <= 1 then
                        TacticalMap:BroadcastPointerPos(px, py)
                    end
                end
            end
        end
    end)

    -- Receptor de mensajes de puntero
    local f = CreateFrame("Frame", "TSAI_PtrSync")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:SetScript("OnEvent", function()
        if arg1 ~= "TSAI_PTR" then return end
        local sender = arg4
        if sender == UnitName("player") then return end
        local msg = arg2 or ""

        -- Parsear mensaje (separador ;, Lua 5.0 compatible)
        local parts = {}
        for part in string.gfind(msg .. ";", "([^;]*);") do
            table.insert(parts, part)
        end
        local cmd = parts[1]

        if cmd == "PTR" then
            local colorName = parts[2]
            local px = tonumber(parts[3])
            local py = tonumber(parts[4])
            if colorName and px and py then
                -- v6.3 Anti-spoof: Verificar que el sender sea el dueño del slot o tenga rango
                if SenderCanControlPTR(sender, colorName) then
                    TacticalMap:AddRemotePointerDot(sender, colorName, px, py)
                end
            end

        elseif cmd == "PTR_CLAIM" then
            local colorName = parts[2]
            if colorName and SenderCanControlPTR(sender, colorName) then
                for _, slot in ipairs(TacticalMap.pointerSlots) do
                    if slot.color == colorName and not slot.owner then
                        slot.owner = sender
                        break
                    end
                end
            end

        elseif cmd == "PTR_REL" then
            local colorName = parts[2]
            if colorName then
                -- Al liberar no revisamos permiso estricto, pero sí que sea su propio slot
                for _, slot in ipairs(TacticalMap.pointerSlots) do
                    if slot.color == colorName and slot.owner == sender then
                        slot.owner = nil
                        slot.lastX = nil
                        slot.lastY = nil
                        if TacticalMap.pointerDots[sender] then
                            TacticalMap.pointerDots[sender]:Hide()
                        end
                        break
                    end
                end
            end

        elseif cmd == "PTR_CLEAR" then
            -- v6.3: PTR_CLEAR solo del Raid Leader real
            local isRL = false
            for i = 1, 40 do
                local name, rank = GetRaidRosterInfo(i)
                if name == sender and rank == 2 then
                    isRL = true
                    break
                end
            end
            
            if isRL or (GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0) then
                for i = 2, 4 do
                    TacticalMap.pointerSlots[i].owner = nil
                    TacticalMap.pointerSlots[i].lastX  = nil
                    TacticalMap.pointerSlots[i].lastY  = nil
                end
                for name, dot in pairs(TacticalMap.pointerDots) do
                    if name ~= UnitName("player") then
                        dot:Hide()
                    end
                end
                local mySlot = TacticalMap.myPointerSlot
                if mySlot and mySlot > 1 then
                    TacticalMap.myPointerSlot = nil
                    TacticalMap.pointerActive  = false
                end
            end
        end
    end)
end

-- v5.1.7: Control de opacidad del mapa
function TacticalMap:SetOpacity(delta)
    local newAlpha = self.config.mapAlpha + delta
    if newAlpha > 1.0 then newAlpha = 1.0 end
    if newAlpha < 0.0 then newAlpha = 0.0 end
    
    self.config.mapAlpha = newAlpha
    if self.mapFrame and self.mapFrame.tiles then
        for i = 1, 12 do
            self.mapFrame.tiles[i]:SetAlpha(newAlpha)
        end
    end
end

-- v5.1.5: Animacion de Ping (Shockwave) cuando se coloca un marcador
function TacticalMap:TriggerPing(x, y)
    if not self.mapFrame then return end
    
    -- Reutilizar un frame de ping si está disponible en la pool de TacticalPings (si existe)
    -- O crear uno local simple para feedback "God-Tier"
    local ping = CreateFrame("Frame", nil, self.mapFrame)
    ping:SetWidth(40)
    ping:SetHeight(40)
    ping:SetFrameLevel(60) -- Por encima de los punteros
    
    local cW = self.mapFrame:GetWidth()
    local cH = self.mapFrame:GetHeight()
    ping:SetPoint("CENTER", self.mapFrame, "TOPLEFT", x * cW, -(y * cH))
    
    local tex = ping:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\Cooldown\\ping4")
    tex:SetAllPoints()
    tex:SetBlendMode("ADD")
    tex:SetVertexColor(0, 1, 1, 0.8)
    
    local elapsed = 0
    ping:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        local scale = 1 + elapsed * 3
        local alpha = 0.8 - elapsed * 2
        
        if alpha <= 0 then
            this:Hide()
            this:SetScript("OnUpdate", nil)
        else
            this:SetWidth(40 * scale)
            this:SetHeight(40 * scale)
            tex:SetAlpha(alpha)
        end
    end)
end

return TacticalMap
