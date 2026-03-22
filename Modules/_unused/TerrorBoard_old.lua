-- TerrorBoard - Tactical Drawing Board for Raid Leaders
-- Allows RL to draw strategies and broadcast to raid members
-- Author: DarckRovert (elnazzareno)

local TerrorBoard = {}
TerrorSquadAI:RegisterModule("TerrorBoard", TerrorBoard)

TerrorBoard.config = {
    enabled = true,
    transparency = 0.9,
    size = 350,
    minSize = 250,
    maxSize = 500,
}

-- Element types
TerrorBoard.TYPES = {
    STAMP = "s",
    LINE = "l", 
    ZONE = "z",
    TEXT = "x",
}

-- Colors
TerrorBoard.COLORS = {
    red = {1, 0, 0, 0.5},
    green = {0, 1, 0, 0.5},
    blue = {0, 0.5, 1, 0.5},
    yellow = {1, 1, 0, 0.5},
    purple = {0.5, 0, 1, 0.5},
    white = {1, 1, 1, 0.8},
}

-- Raid icons for stamps
TerrorBoard.ICONS = {
    "skull", "cross", "square", "moon", 
    "triangle", "diamond", "circle", "star",
    "tank", "healer", "dps", "arrow"
}

-- Current state
TerrorBoard.elements = {}
TerrorBoard.currentTool = "stamp"
TerrorBoard.currentColor = "red"
TerrorBoard.currentIcon = "skull"
TerrorBoard.isDrawing = false
TerrorBoard.drawStart = nil

function TerrorBoard:Initialize()
    self:CreateMainFrame()
    self:RegisterEvents()
    self:RegisterSlashCommand()
    TerrorSquadAI:Print("|cFF00FF00[TerrorBoard]|r Módulo cargado - /board")
end

function TerrorBoard:RegisterSlashCommand()
    SLASH_TERRORBOARD1 = "/board"
    SLASH_TERRORBOARD2 = "/tboard"
    SlashCmdList["TERRORBOARD"] = function(msg)
        TerrorBoard:Toggle()
    end
end

function TerrorBoard:CreateMainFrame()
    local theme = TerrorSquadAI.Modules.UITheme
    local size = self.config.size
    
    -- Main frame
    local frame = CreateFrame("Frame", "TerrorBoard_MainFrame", UIParent)
    frame:SetWidth(size + 60)
    frame:SetHeight(size + 80)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()
    
    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetTexture(0.05, 0.05, 0.05, self.config.transparency)
    
    -- Border
    frame.border = frame:CreateTexture(nil, "BORDER")
    frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
    frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
    frame.border:SetTexture(0.545, 0, 0, 0.8)
    
    -- Title bar
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
    frame.title:SetText("|cFF8B0000⚔ TERROR BOARD ⚔|r")
    
    -- Close button
    frame.closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    frame.closeBtn:SetScript("OnClick", function() TerrorBoard:Hide() end)
    
    -- Canvas (drawing area)
    local canvas = CreateFrame("Frame", "TerrorBoard_Canvas", frame)
    canvas:SetWidth(size)
    canvas:SetHeight(size)
    canvas:SetPoint("TOP", frame, "TOP", 0, -35)
    canvas:EnableMouse(true)
    
    canvas.bg = canvas:CreateTexture(nil, "BACKGROUND")
    canvas.bg:SetAllPoints()
    canvas.bg:SetTexture(0.1, 0.1, 0.1, 0.9)
    
    -- Grid lines
    self:CreateGrid(canvas, size)
    
    -- Canvas mouse handlers
    canvas:SetScript("OnMouseDown", function() TerrorBoard:OnCanvasMouseDown(arg1) end)
    canvas:SetScript("OnMouseUp", function() TerrorBoard:OnCanvasMouseUp(arg1) end)
    
    frame.canvas = canvas
    
    -- Toolbar (left side)
    self:CreateToolbar(frame)
    
    -- Bottom controls
    self:CreateBottomControls(frame)
    
    self.mainFrame = frame
end

function TerrorBoard:CreateGrid(canvas, size)
    local gridSize = 25
    local numLines = size / gridSize
    
    for i = 1, numLines - 1 do
        -- Vertical lines
        local vline = canvas:CreateTexture(nil, "ARTWORK")
        vline:SetWidth(1)
        vline:SetHeight(size)
        vline:SetPoint("TOPLEFT", canvas, "TOPLEFT", i * gridSize, 0)
        vline:SetTexture(0.3, 0.3, 0.3, 0.3)
        
        -- Horizontal lines
        local hline = canvas:CreateTexture(nil, "ARTWORK")
        hline:SetWidth(size)
        hline:SetHeight(1)
        hline:SetPoint("TOPLEFT", canvas, "TOPLEFT", 0, -i * gridSize)
        hline:SetTexture(0.3, 0.3, 0.3, 0.3)
    end
end

function TerrorBoard:CreateToolbar(frame)
    local tools = {
        {name = "stamp", icon = "📍", tip = "Colocar icono"},
        {name = "arrow", icon = "➡", tip = "Dibujar flecha"},
        {name = "line", icon = "📏", tip = "Dibujar línea"},
        {name = "zone", icon = "⭕", tip = "Zona circular"},
        {name = "text", icon = "📝", tip = "Añadir texto"},
        {name = "erase", icon = "🧹", tip = "Borrar elemento"},
    }
    
    local yOffset = -40
    for i, tool in ipairs(tools) do
        local btn = CreateFrame("Button", "TerrorBoard_Tool_" .. tool.name, frame)
        btn:SetWidth(30)
        btn:SetHeight(30)
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, yOffset)
        
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetTexture(0.2, 0.2, 0.2, 0.8)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.text:SetPoint("CENTER", btn, "CENTER", 0, 0)
        btn.text:SetText(tool.icon)
        
        btn.toolName = tool.name
        btn.toolTip = tool.tip
        btn:SetScript("OnClick", function()
            TerrorBoard:SelectTool(this.toolName)
        end)
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:AddLine(this.toolTip)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        yOffset = yOffset - 35
    end
    
    -- Color selector
    yOffset = yOffset - 10
    local colorLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colorLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, yOffset)
    colorLabel:SetText("Color:")
    
    yOffset = yOffset - 20
    local colorIdx = 0
    for colorName, rgba in pairs(self.COLORS) do
        local cbtn = CreateFrame("Button", "TerrorBoard_Color_" .. colorName, frame)
        cbtn:SetWidth(20)
        cbtn:SetHeight(20)
        cbtn:SetPoint("TOPLEFT", frame, "TOPLEFT", 5 + mod(colorIdx, 2) * 22, yOffset - math.floor(colorIdx / 2) * 22)
        
        cbtn.bg = cbtn:CreateTexture(nil, "BACKGROUND")
        cbtn.bg:SetAllPoints()
        cbtn.bg:SetTexture(rgba[1], rgba[2], rgba[3], 1)
        
        cbtn.colorName = colorName
        cbtn:SetScript("OnClick", function()
            TerrorBoard:SelectColor(this.colorName)
        end)
        
        colorIdx = colorIdx + 1
    end
end

function TerrorBoard:CreateBottomControls(frame)
    local theme = TerrorSquadAI.Modules.UITheme
    
    -- Transparency slider
    local transLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    transLabel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 45)
    transLabel:SetText("Transparencia:")
    
    local transSlider = CreateFrame("Slider", "TerrorBoard_TransSlider", frame, "OptionsSliderTemplate")
    transSlider:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 25)
    transSlider:SetWidth(100)
    transSlider:SetHeight(15)
    transSlider:SetMinMaxValues(0.2, 1)
    transSlider:SetValueStep(0.1)
    transSlider:SetValue(self.config.transparency)
    transSlider:SetScript("OnValueChanged", function()
        TerrorBoard:SetTransparency(this:GetValue())
    end)
    
    -- Broadcast button (only for RL)
    local broadcastBtn = CreateFrame("Button", "TerrorBoard_BroadcastBtn", frame)
    broadcastBtn:SetWidth(100)
    broadcastBtn:SetHeight(25)
    broadcastBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 15)
    
    broadcastBtn.bg = broadcastBtn:CreateTexture(nil, "BACKGROUND")
    broadcastBtn.bg:SetAllPoints()
    broadcastBtn.bg:SetTexture(0.545, 0, 0, 0.9)
    
    broadcastBtn.text = broadcastBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    broadcastBtn.text:SetPoint("CENTER", broadcastBtn, "CENTER", 0, 0)
    broadcastBtn.text:SetText("📡 BROADCAST")
    
    broadcastBtn:SetScript("OnClick", function()
        TerrorBoard:Broadcast()
    end)
    
    -- Clear button
    local clearBtn = CreateFrame("Button", "TerrorBoard_ClearBtn", frame)
    clearBtn:SetWidth(60)
    clearBtn:SetHeight(25)
    clearBtn:SetPoint("RIGHT", broadcastBtn, "LEFT", -10, 0)
    
    clearBtn.bg = clearBtn:CreateTexture(nil, "BACKGROUND")
    clearBtn.bg:SetAllPoints()
    clearBtn.bg:SetTexture(0.3, 0.3, 0.3, 0.9)
    
    clearBtn.text = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    clearBtn.text:SetPoint("CENTER", clearBtn, "CENTER", 0, 0)
    clearBtn.text:SetText("Limpiar")
    
    clearBtn:SetScript("OnClick", function()
        TerrorBoard:ClearCanvas()
    end)
end

function TerrorBoard:SelectTool(toolName)
    self.currentTool = toolName
    TerrorSquadAI:Print("|cFF8B0000[TerrorBoard]|r Herramienta: " .. toolName)
end

function TerrorBoard:SelectColor(colorName)
    self.currentColor = colorName
    TerrorSquadAI:Print("|cFF8B0000[TerrorBoard]|r Color: " .. colorName)
end

function TerrorBoard:SetTransparency(value)
    self.config.transparency = value
    if self.mainFrame and self.mainFrame.bg then
        self.mainFrame.bg:SetTexture(0.05, 0.05, 0.05, value)
    end
end

function TerrorBoard:OnCanvasMouseDown(button)
    if button == "LeftButton" then
        local x, y = GetCursorPosition()
        local scale = self.mainFrame.canvas:GetEffectiveScale()
        local canvasX = self.mainFrame.canvas:GetLeft() * scale
        local canvasY = self.mainFrame.canvas:GetTop() * scale
        
        self.isDrawing = true
        self.drawStart = {
            x = (x - canvasX) / scale,
            y = (canvasY - y) / scale
        }
    end
end

function TerrorBoard:OnCanvasMouseUp(button)
    if button == "LeftButton" and self.isDrawing then
        local x, y = GetCursorPosition()
        local scale = self.mainFrame.canvas:GetEffectiveScale()
        local canvasX = self.mainFrame.canvas:GetLeft() * scale
        local canvasY = self.mainFrame.canvas:GetTop() * scale
        
        local endX = (x - canvasX) / scale
        local endY = (canvasY - y) / scale
        
        self:PlaceElement(self.drawStart.x, self.drawStart.y, endX, endY)
        self.isDrawing = false
        self.drawStart = nil
    end
end

function TerrorBoard:PlaceElement(x1, y1, x2, y2)
    local element = nil
    
    if self.currentTool == "stamp" then
        element = {t = self.TYPES.STAMP, x = x1, y = y1, i = self.currentIcon}
        self:RenderStamp(element)
    elseif self.currentTool == "arrow" or self.currentTool == "line" then
        local isArrow = self.currentTool == "arrow" and 1 or 0
        element = {t = self.TYPES.LINE, x1 = x1, y1 = y1, x2 = x2, y2 = y2, a = isArrow, c = self.currentColor}
        self:RenderLine(element)
    elseif self.currentTool == "zone" then
        local radius = math.sqrt((x2-x1)^2 + (y2-y1)^2)
        element = {t = self.TYPES.ZONE, x = x1, y = y1, r = radius, c = self.currentColor}
        self:RenderZone(element)
    elseif self.currentTool == "text" then
        -- TODO: Popup for text input
        element = {t = self.TYPES.TEXT, x = x1, y = y1, m = "STACK"}
        self:RenderText(element)
    elseif self.currentTool == "erase" then
        self:EraseAt(x1, y1)
        return
    end
    
    if element then
        table.insert(self.elements, element)
    end
end

function TerrorBoard:RenderStamp(elem)
    local canvas = self.mainFrame.canvas
    local stamp = canvas:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    stamp:SetPoint("TOPLEFT", canvas, "TOPLEFT", elem.x - 10, -elem.y + 10)
    stamp:SetText(self:GetIconText(elem.i))
    elem.frame = stamp
end

function TerrorBoard:RenderLine(elem)
    local canvas = self.mainFrame.canvas
    local color = self.COLORS[elem.c] or self.COLORS.white
    
    -- Simple line using texture
    local line = canvas:CreateTexture(nil, "OVERLAY")
    local dx = elem.x2 - elem.x1
    local dy = elem.y2 - elem.y1
    local length = math.sqrt(dx*dx + dy*dy)
    local angle = math.atan2(dy, dx)
    
    line:SetWidth(length)
    line:SetHeight(3)
    line:SetPoint("TOPLEFT", canvas, "TOPLEFT", elem.x1, -elem.y1)
    line:SetTexture(color[1], color[2], color[3], color[4])
    
    elem.frame = line
end

function TerrorBoard:RenderZone(elem)
    local canvas = self.mainFrame.canvas
    local color = self.COLORS[elem.c] or self.COLORS.red
    
    -- Approximate circle with square (WoW 1.12 limitation)
    local zone = canvas:CreateTexture(nil, "OVERLAY")
    zone:SetWidth(elem.r * 2)
    zone:SetHeight(elem.r * 2)
    zone:SetPoint("CENTER", canvas, "TOPLEFT", elem.x, -elem.y)
    zone:SetTexture(color[1], color[2], color[3], color[4])
    
    elem.frame = zone
end

function TerrorBoard:RenderText(elem)
    local canvas = self.mainFrame.canvas
    local text = canvas:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOPLEFT", canvas, "TOPLEFT", elem.x, -elem.y)
    text:SetText("|cFFFFFFFF" .. elem.m .. "|r")
    elem.frame = text
end

function TerrorBoard:GetIconText(iconName)
    local icons = {
        skull = "{skull}",
        cross = "{cross}",
        square = "{square}",
        moon = "{moon}",
        triangle = "{triangle}",
        diamond = "{diamond}",
        circle = "{circle}",
        star = "{star}",
        tank = "🛡",
        healer = "✚",
        dps = "⚔",
        arrow = "➤",
    }
    return icons[iconName] or "●"
end

function TerrorBoard:EraseAt(x, y)
    -- Find and remove element near click
    for i = table.getn(self.elements), 1, -1 do
        local elem = self.elements[i]
        local ex, ey = elem.x or elem.x1, elem.y or elem.y1
        if math.abs(ex - x) < 20 and math.abs(ey - y) < 20 then
            if elem.frame then
                elem.frame:Hide()
            end
            table.remove(self.elements, i)
            return
        end
    end
end

function TerrorBoard:ClearCanvas()
    for _, elem in ipairs(self.elements) do
        if elem.frame then
            elem.frame:Hide()
        end
    end
    self.elements = {}
    TerrorSquadAI:Print("|cFF8B0000[TerrorBoard]|r Canvas limpiado")
end

function TerrorBoard:Broadcast()
    if not IsRaidLeader() and not IsRaidOfficer() then
        TerrorSquadAI:Print("|cFFFF0000[TerrorBoard]|r Solo el líder o asistentes pueden transmitir")
        return
    end
    
    -- Serialize elements
    local data = self:Serialize()
    
    -- Send via addon message
    if GetNumRaidMembers() > 0 then
        SendAddonMessage("TSAI_BOARD", data, "RAID")
        TerrorSquadAI:Print("|cFF00FF00[TerrorBoard]|r Estrategia enviada a la raid!")
    elseif GetNumPartyMembers() > 0 then
        SendAddonMessage("TSAI_BOARD", data, "PARTY")
        TerrorSquadAI:Print("|cFF00FF00[TerrorBoard]|r Estrategia enviada al grupo!")
    else
        TerrorSquadAI:Print("|cFFFF0000[TerrorBoard]|r No estás en un grupo")
    end
end

function TerrorBoard:Serialize()
    local parts = {}
    for _, elem in ipairs(self.elements) do
        local str = elem.t
        if elem.t == self.TYPES.STAMP then
            str = str .. ":" .. elem.x .. ":" .. elem.y .. ":" .. elem.i
        elseif elem.t == self.TYPES.LINE then
            str = str .. ":" .. elem.x1 .. ":" .. elem.y1 .. ":" .. elem.x2 .. ":" .. elem.y2 .. ":" .. elem.a .. ":" .. elem.c
        elseif elem.t == self.TYPES.ZONE then
            str = str .. ":" .. elem.x .. ":" .. elem.y .. ":" .. elem.r .. ":" .. elem.c
        elseif elem.t == self.TYPES.TEXT then
            str = str .. ":" .. elem.x .. ":" .. elem.y .. ":" .. elem.m
        end
        table.insert(parts, str)
    end
    return table.concat(parts, ";")
end

function TerrorBoard:Deserialize(data)
    self:ClearCanvas()
    
    local parts = {strsplit(";", data)}
    for _, part in ipairs(parts) do
        local fields = {strsplit(":", part)}
        local elemType = fields[1]
        
        if elemType == self.TYPES.STAMP then
            local elem = {t = elemType, x = tonumber(fields[2]), y = tonumber(fields[3]), i = fields[4]}
            table.insert(self.elements, elem)
            self:RenderStamp(elem)
        elseif elemType == self.TYPES.LINE then
            local elem = {t = elemType, x1 = tonumber(fields[2]), y1 = tonumber(fields[3]), x2 = tonumber(fields[4]), y2 = tonumber(fields[5]), a = tonumber(fields[6]), c = fields[7]}
            table.insert(self.elements, elem)
            self:RenderLine(elem)
        elseif elemType == self.TYPES.ZONE then
            local elem = {t = elemType, x = tonumber(fields[2]), y = tonumber(fields[3]), r = tonumber(fields[4]), c = fields[5]}
            table.insert(self.elements, elem)
            self:RenderZone(elem)
        elseif elemType == self.TYPES.TEXT then
            local elem = {t = elemType, x = tonumber(fields[2]), y = tonumber(fields[3]), m = fields[4]}
            table.insert(self.elements, elem)
            self:RenderText(elem)
        end
    end
end

function TerrorBoard:RegisterEvents()
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    eventFrame:SetScript("OnEvent", function()
        if event == "CHAT_MSG_ADDON" and arg1 == "TSAI_BOARD" then
            TerrorBoard:OnBoardReceived(arg2, arg4)
        end
    end)
end

function TerrorBoard:OnBoardReceived(data, sender)
    if sender == UnitName("player") then return end
    
    PlaySound("igMainMenuOpen")
    TerrorSquadAI:Print("|cFF00FF00[TerrorBoard]|r Nueva estrategia recibida de " .. sender)
    
    self:Deserialize(data)
    self:Show()
end

function TerrorBoard:Show()
    if self.mainFrame then
        self.mainFrame:Show()
    end
end

function TerrorBoard:Hide()
    if self.mainFrame then
        self.mainFrame:Hide()
    end
end

function TerrorBoard:Toggle()
    if self.mainFrame and self.mainFrame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
