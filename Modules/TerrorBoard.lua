-- TerrorBoard - Simplified Tactical Board for Raid Leaders
-- Place raid markers on a grid, broadcast to raid
-- Author: DarckRovert (elnazzareno)

local TerrorBoard = {}
TerrorSquadAI:RegisterModule("TerrorBoard", TerrorBoard)

TerrorBoard.config = {
    enabled = true,
    gridSize = 8,
    cellSize = 40,
}

-- Raid icons (using WoW's built-in raid target icons)
TerrorBoard.MARKERS = {
    {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1", name = "Estrella", desc = "Punto de reuni\\195\179n táctico"},
    {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2", name = "Circulo", desc = "Zona de alto riesgo / AoE"},
    {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3", name = "Diamante", desc = "Área de curaci\\195\179n prioritaria"},
    {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4", name = "Triangulo", desc = "Posici\\195\179n del Tanque"},
    {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5", name = "Luna", desc = "Objetivo de Focus Fire"},
    {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6", name = "Cuadrado", desc = "Posici\\195\179n de Rango / Healers"},
    {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7", name = "Cruz", desc = "Zona de Buffs / Re-stack"},
    {icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8", name = "Calavera", desc = "Marca de ejecuci\\195\179n"}
}

TerrorBoard.placedMarkers = {}
TerrorBoard.selectedMarker = 1
TerrorBoard.selectedType = "marker"

function TerrorBoard:Initialize()
    self:CreateMainFrame()
    self:RegisterSlashCommand()
    self:RegisterSync()
    TerrorSquadAI:Print("|cFF00FF00[TerrorBoard]|r Cargado - /board")
end

function TerrorBoard:RegisterSlashCommand()
    SLASH_TERRORBOARD1 = "/board"
    SLASH_TERRORBOARD2 = "/tboard"
    SlashCmdList["TERRORBOARD"] = function(msg)
        TerrorBoard:Toggle()
    end
end

function TerrorBoard:CreateMainFrame()
    local gridSize = self.config.gridSize
    local cellSize = self.config.cellSize
    local totalSize = gridSize * cellSize
    
    -- Main frame (Glass Obsidian Design)
    local theme = TerrorSquadAI.Modules.UITheme
    local frame = theme:CreateStyledFrame("TerrorBoard_Main", UIParent, totalSize + 180, totalSize + 100)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 0.95)
    
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()
    
    -- Header: Tactical Command Center
    frame.header = frame:CreateTexture(nil, "OVERLAY")
    frame.header:SetHeight(30)
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -5)
    frame.header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, -5)
    frame.header:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    frame.header:SetVertexColor(0, 0.5, 1, 0.3)
    frame.header:SetBlendMode("ADD")
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("LEFT", frame.header, "LEFT", 10, 0)
    frame.title:SetText("|cFF00FFFFTACTICAL COMMAND CENTER|r")
    frame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    
    -- Status Indicator (Blinking)
    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.status:SetPoint("RIGHT", frame.header, "RIGHT", -10, 0)
    frame.status:SetText("|cFF00FF00ONLINE|r")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Grid canvas
    local canvas = CreateFrame("Frame", "TerrorBoard_Canvas", frame)
    canvas:SetWidth(totalSize)
    canvas:SetHeight(totalSize)
    canvas:SetPoint("TOPLEFT", frame, "TOPLEFT", 25, -65)
    
    -- Grid background decoration
    canvas.bg = canvas:CreateTexture(nil, "BACKGROUND")
    canvas.bg:SetAllPoints()
    canvas.bg:SetTexture(0, 0, 0, 0.5)
    
    -- Create grid cells with Corner Brackets
    canvas.cells = {}
    for row = 1, gridSize do
        canvas.cells[row] = {}
        for col = 1, gridSize do
            local cell = CreateFrame("Button", "TerrorBoard_Cell_"..row.."_"..col, canvas)
            cell:SetWidth(cellSize)
            cell:SetHeight(cellSize)
            cell:SetPoint("TOPLEFT", canvas, "TOPLEFT", (col-1)*cellSize, -((row-1)*cellSize))
            
            -- Tactical Corner Brackets
            theme:CreateCornerBrackets(cell, 6, {0, 0.8, 1, 0.3})
            
            cell.highlight = cell:CreateTexture(nil, "HIGHLIGHT")
            cell.highlight:SetAllPoints()
            cell.highlight:SetTexture("Interface\\Buttons\\UI-EmptySlot-White")
            cell.highlight:SetVertexColor(0, 1, 1, 0.1)
            cell.highlight:SetBlendMode("ADD")
            
            cell.icon = cell:CreateTexture(nil, "OVERLAY")
            cell.icon:SetWidth(cellSize - 10)
            cell.icon:SetHeight(cellSize - 10)
            cell.icon:SetPoint("CENTER", cell, "CENTER", 0, 0)
            cell.icon:Hide()
            
            cell.row = row
            cell.col = col
            cell:SetScript("OnClick", function()
                TerrorBoard:OnCellClick(this.row, this.col)
            end)
            
            canvas.cells[row][col] = cell
        end
    end
    
    frame.canvas = canvas
    
    -- Marker Selector Side-Panel
    local panel = CreateFrame("Frame", nil, frame)
    panel:SetWidth(110)
    panel:SetHeight(totalSize + 20)
    panel:SetPoint("LEFT", canvas, "RIGHT", 20, 0)
    
    local panelBg = panel:CreateTexture(nil, "BACKGROUND")
    panelBg:SetAllPoints()
    panelBg:SetTexture(0, 0.1, 0.2, 0.3)
    theme:CreateCornerBrackets(panel, 10, {0, 0.5, 1, 0.5})
    
    local markerLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    markerLabel:SetPoint("TOP", panel, "TOP", 0, -10)
    markerLabel:SetText("|cFF00CCFFMARKER ASSETS|r")
    
    -- Marker buttons
    self.markerButtons = {}
    for i = 1, 8 do
        local marker = self.MARKERS[i]
        local btn = CreateFrame("Button", "TerrorBoard_Marker_"..i, panel)
        btn:SetWidth(40)
        btn:SetHeight(40)
        local brow = math.floor((i-1) / 2)
        local bcol = math.mod(i-1, 2)
        btn:SetPoint("TOPLEFT", panel, "TOPLEFT", bcol * 50 + 10, -35 - brow * 50)
        
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints()
        btn.icon:SetTexture(marker.icon)
        
        btn.border = btn:CreateTexture(nil, "OVERLAY")
        btn.border:SetAllPoints()
        btn.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        btn.border:SetBlendMode("ADD")
        btn.border:Hide()
        
        btn.markerIndex = i
        btn:SetScript("OnClick", function()
            TerrorBoard:SelectMarker(this.markerIndex)
        end)
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            local m = TerrorBoard.MARKERS[this.markerIndex]
            GameTooltip:SetText("|cFF00FF00[TACTICAL]|r " .. (m.name or "Marcador"))
            GameTooltip:AddLine(m.desc or "", 1, 1, 1)
            GameTooltip:Show()
            theme:GlitchEffect(this.icon, 0.2)
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        self.markerButtons[i] = btn
    end
    
    -- Action Bar (Bottom Glass Panel)
    local actionBar = CreateFrame("Frame", nil, frame)
    actionBar:SetHeight(40)
    actionBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, 15)
    actionBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -15, 15)
    
    local actionBg = actionBar:CreateTexture(nil, "BACKGROUND")
    actionBg:SetAllPoints()
    actionBg:SetTexture(0, 0, 0, 0.4)
    theme:CreateCornerBrackets(actionBar, 8, {1, 1, 1, 0.2})
    
    local eraseBtn = theme:CreateStyledButton("TerrorBoard_Erase", actionBar, 80, 24, "Borrar")
    eraseBtn:SetPoint("LEFT", actionBar, "LEFT", 10, 0)
    eraseBtn:SetScript("OnClick", function() TerrorBoard:SelectEraser() end)
    
    local clearBtn = theme:CreateStyledButton("TerrorBoard_Clear", actionBar, 80, 24, "Limpiar")
    clearBtn:SetPoint("LEFT", eraseBtn, "RIGHT", 10, 0)
    clearBtn:SetScript("OnClick", function() TerrorBoard:ClearAll() end)
    
    local broadcastBtn = theme:CreateStyledButton("TerrorBoard_Broadcast", actionBar, 110, 24, "ENVIAR RAID")
    broadcastBtn:SetPoint("RIGHT", actionBar, "RIGHT", -10, 0)
    broadcastBtn:SetBackdropBorderColor(1, 0, 0, 0.8) -- Danger Red
    broadcastBtn:SetScript("OnClick", function() TerrorBoard:Broadcast() end)
    
    -- Global Scanline Animation
    frame.scanline = frame:CreateTexture(nil, "OVERLAY")
    frame.scanline:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    frame.scanline:SetBlendMode("ADD")
    frame.scanline:SetHeight(40)
    frame.scanline:SetAlpha(0.05)
    
    local elapsed = 0
    frame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        local now = GetTime()
        
        -- Blinking status
        if math.mod(math.floor(now * 2), 2) == 0 then
            frame.status:SetAlpha(0.2)
        else
            frame.status:SetAlpha(1)
        end
        
        -- Smooth scanline
        local totalH = this:GetHeight()
        local yPos = math.mod(now * 40, totalH)
        frame.scanline:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -yPos)
        frame.scanline:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -yPos)
    end)
    
    self.mainFrame = frame
    self:SelectMarker(1)
    
    frame:SetScript("OnShow", function()
        theme:GlitchEffect(this.header, 0.4)
    end)
end

function TerrorBoard:SelectMarker(index)
    self.selectedMarker = index
    self.selectedType = "marker"
    
    for i, btn in ipairs(self.markerButtons) do
        if i == index then
            btn.border:Show()
        else
            btn.border:Hide()
        end
    end
end

function TerrorBoard:SelectEraser()
    self.selectedType = "erase"
    for i, btn in ipairs(self.markerButtons) do
        btn.border:Hide()
    end
end

function TerrorBoard:OnCellClick(row, col)
    local cell = self.mainFrame.canvas.cells[row][col]
    
    if self.selectedType == "erase" then
        cell.icon:Hide()
        cell.markerIndex = nil
        self.placedMarkers[row.."_"..col] = nil
    else
        local marker = self.MARKERS[self.selectedMarker]
        cell.icon:SetTexture(marker.icon)
        cell.icon:Show()
        cell.markerIndex = self.selectedMarker
        self.placedMarkers[row.."_"..col] = self.selectedMarker
        
        -- God-Tier Feedback
        TerrorSquadAI.Modules.UITheme:GlitchEffect(cell.icon, 0.2)
    end
end

function TerrorBoard:ClearAll()
    local gridSize = self.config.gridSize
    for row = 1, gridSize do
        for col = 1, gridSize do
            local cell = self.mainFrame.canvas.cells[row][col]
            cell.icon:Hide()
            cell.markerIndex = nil
        end
    end
    self.placedMarkers = {}
end

function TerrorBoard:Broadcast()
    if not IsRaidLeader() and not IsRaidOfficer() then
        TerrorSquadAI:Print("|cFFFF0000[TerrorBoard]|r Solo lider puede enviar")
        return
    end
    
    local parts = {}
    for key, idx in pairs(self.placedMarkers) do
        table.insert(parts, key..":"..idx)
    end
    local data = table.concat(parts, ";")
    
    if GetNumRaidMembers() > 0 then
        SendAddonMessage("TSAI_BOARD", data, "RAID")
        TerrorSquadAI:Print("|cFF00FF00[TerrorBoard]|r Enviado!")
    elseif GetNumPartyMembers() > 0 then
        SendAddonMessage("TSAI_BOARD", data, "PARTY")
        TerrorSquadAI:Print("|cFF00FF00[TerrorBoard]|r Enviado!")
    else
        TerrorSquadAI:Print("|cFFFF0000[TerrorBoard]|r No estas en grupo")
    end
end

function TerrorBoard:ReceiveBoard(data)
    self:ClearAll()
    if data == "" then return end
    
    local function split(p, d)
        local t = {}
        local f = "(.-)" .. d
        for e in string.gfind(p .. d, f) do
            table.insert(t, e)
        end
        return t
    end
    
    local entries = split(data, ";")
    for _, entry in ipairs(entries) do
        if entry ~= "" then
            local entryParts = split(entry, ":")
            local key, idx = entryParts[1], entryParts[2]
            
            local keyParts = split(key, "_")
            local row, col = keyParts[1], keyParts[2]
            
            row, col, idx = tonumber(row), tonumber(col), tonumber(idx)
            
            if row and col and idx and self.mainFrame then
                local cell = self.mainFrame.canvas.cells[row][col]
                if cell and self.MARKERS[idx] then
                    cell.icon:SetTexture(self.MARKERS[idx].icon)
                    cell.icon:Show()
                    self.placedMarkers[row.."_"..col] = idx
                end
            end
        end
    end
end

function TerrorBoard:RegisterSync()
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:SetScript("OnEvent", function()
        if arg1 == "TSAI_BOARD" and arg4 ~= UnitName("player") then
            PlaySound("igMainMenuOpen")
            TerrorSquadAI:Print("|cFF00FF00[TerrorBoard]|r Recibido de "..arg4)
            TerrorBoard:ReceiveBoard(arg2)
            TerrorBoard:Show()
        end
    end)
end

function TerrorBoard:Show()
    if self.mainFrame then 
        self.mainFrame:Show() 
        TerrorSquadAI.Modules.UITheme:GlitchEffect(self.mainFrame.header, 0.4)
    end
end

function TerrorBoard:Hide()
    if self.mainFrame then self.mainFrame:Hide() end
end

function TerrorBoard:Toggle()
    if self.mainFrame and self.mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

TerrorBoard:Initialize()
