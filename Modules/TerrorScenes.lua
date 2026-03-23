-- TerrorScenes.lua - Sistema de Escenas Guardadas para TerrorBoard
-- TerrorSquadAI v6.0 - Inspirado en RaidMark (Holle)
-- Lua 5.0 / WoW 1.12.1 compatible
-- Author: DarckRovert (elnazzareno)

local TerrorScenes = {}
TerrorSquadAI:RegisterModule("TerrorScenes", TerrorScenes)

-- Numero de slots disponibles (v7.0: 10 Grand Slots x 4 Sub-Escenas = 40)
TerrorScenes.NUM_SLOTS = 10
TerrorScenes.NUM_SUBSLOTS = 4
TerrorScenes.ui = {}

-- Variables de Estado v7.0
TerrorScenes.selectedGrandSlot = nil
TerrorScenes.selectedSubSlot = nil

-- ============================================================
-- Utilidades internas (Lua 5.0 puro)
-- ============================================================

local function ensureDB()
    if not TerrorSquadAIDB then TerrorSquadAIDB = {} end
    
    -- Migracion v6.x -> v7.0
    if TerrorSquadAIDB.scenes then
        TerrorSquadAIDB.grand_slots = {}
        for i = 1, TerrorScenes.NUM_SLOTS do
            local oldScene = TerrorSquadAIDB.scenes[i]
            TerrorSquadAIDB.grand_slots[i] = {
                name = "Grand Slot " .. i,
                scenes = {}
            }
            if oldScene then
                TerrorSquadAIDB.grand_slots[i].scenes[1] = oldScene
            end
        end
        TerrorSquadAIDB.scenes = nil -- Borrar DB vieja para mantener limpio
        TerrorSquadAI:Print("|cFF00FFFF[TerrorScenes]|r Base de datos migrada a v7.0 (10 Grand Slots).")
    end

    if not TerrorSquadAIDB.grand_slots then TerrorSquadAIDB.grand_slots = {} end
    for i = 1, TerrorScenes.NUM_SLOTS do
        if not TerrorSquadAIDB.grand_slots[i] then
            TerrorSquadAIDB.grand_slots[i] = {
                name = "Grand Slot " .. i,
                scenes = {}
            }
        end
    end
end

local function getTimestamp()
    return date("%d/%m %H:%M")
end

-- Captura el estado actual de marcadores del TerrorBoard
local function captureSnapshot()
    local TB = TerrorSquadAI.Modules.TerrorBoard
    if not TB or not TB.placedMarkers then return {} end
    local snap = {}
    for key, idx in pairs(TB.placedMarkers) do
        if key and idx then
            table.insert(snap, { key = key, idx = idx })
        end
    end
    return snap
end

-- Verificar si el jugador puede CARGAR en raid (solo RL)
local function canLoad()
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return true  -- solo, puede todo
    end
    return IsRaidLeader() == 1
end

-- ============================================================
-- API publica
-- ============================================================

function TerrorScenes:Initialize()
    ensureDB()
    TerrorSquadAI:Debug("TerrorScenes inicializado")
end

function TerrorScenes:Save(grandSlot, subSlot)
    if not grandSlot or grandSlot < 1 or grandSlot > self.NUM_SLOTS then return end
    if not subSlot or subSlot < 1 or subSlot > self.NUM_SUBSLOTS then return end
    ensureDB()

    local markers = captureSnapshot()
    if table.getn(markers) == 0 then
        -- Guardar slot vacio = borrar
        TerrorSquadAIDB.grand_slots[grandSlot].scenes[subSlot] = nil
        self:RefreshUI()
        TerrorSquadAI:Print("|cFFAAAAAA[Escenas]|r Slot " .. grandSlot .. "-" .. subSlot .. " limpiado.")
        return
    end

    local existing = TerrorSquadAIDB.grand_slots[grandSlot].scenes[subSlot] or {}
    TerrorSquadAIDB.grand_slots[grandSlot].scenes[subSlot] = {
        markers = markers,
        savedAt = getTimestamp(),
        count   = table.getn(markers),
        name    = existing.name or ("Escena " .. grandSlot .. "-" .. subSlot),
    }
    self:RefreshUI()
    TerrorSquadAI:Print("|cFF00FF66[Escenas]|r Slot " .. grandSlot .. "-" .. subSlot .. " guardado (" .. table.getn(markers) .. " marcadores).")
end

function TerrorScenes:Load(grandSlot, subSlot)
    if not grandSlot or grandSlot < 1 or grandSlot > self.NUM_SLOTS then return end
    if not subSlot or subSlot < 1 or subSlot > self.NUM_SUBSLOTS then return end
    ensureDB()

    if not canLoad() then
        TerrorSquadAI:Print("|cFFFF4444[Escenas]|r Solo el lider de raid puede cargar escenas.")
        return
    end

    local data = TerrorSquadAIDB.grand_slots[grandSlot].scenes[subSlot]
    if not data or not data.markers then
        TerrorSquadAI:Print("|cFFAAAAAA[Escenas]|r Slot " .. grandSlot .. "-" .. subSlot .. " esta vacio.")
        return
    end

    local TB = TerrorSquadAI.Modules.TerrorBoard
    if not TB then return end

    -- Limpiar estado actual
    TB:ClearAll()

    -- Restaurar marcadores del snapshot
    local loaded = 0
    for _, entry in ipairs(data.markers) do
        if entry.key and entry.idx then
            local kx, ky = TB:ParseKey(entry.key)
            if kx and ky then
                TB:PlaceMarker(kx, ky, entry.idx)
                loaded = loaded + 1
            end
        end
    end

    TerrorSquadAI:Print("|cFF00FF66[Escenas]|r Slot " .. grandSlot .. "-" .. subSlot .. " cargado (" .. loaded .. " marcadores).")

    -- Broadcast al raid si esta en grupo
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        TB:Broadcast()
    end
end

-- v6.2: BroadcastLoad — cargar escena Y enviarla al raid directamente
function TerrorScenes:BroadcastLoad(grandSlot, subSlot)
    if not grandSlot or grandSlot < 1 or grandSlot > self.NUM_SLOTS then return end
    if not subSlot or subSlot < 1 or subSlot > self.NUM_SUBSLOTS then return end
    if not canLoad() then
        TerrorSquadAI:Print("|cFFFF4444[Escenas]|r Solo el lider de raid puede hacer BroadcastLoad.")
        return
    end
    self:Load(grandSlot, subSlot)  -- Load ya llama Broadcast si esta en grupo
    TerrorSquadAI:Print("|cFF00FFFF[Escenas]|r Escena " .. grandSlot .. "-" .. subSlot .. " enviada al raid.")
end

function TerrorScenes:Delete(grandSlot, subSlot)
    if not grandSlot or grandSlot < 1 or grandSlot > self.NUM_SLOTS then return end
    if not subSlot or subSlot < 1 or subSlot > self.NUM_SUBSLOTS then return end
    ensureDB()
    TerrorSquadAIDB.grand_slots[grandSlot].scenes[subSlot] = nil
    self:RefreshUI()
    TerrorSquadAI:Print("|cFFAAAAAA[Escenas]|r Slot " .. grandSlot .. "-" .. subSlot .. " borrado.")
end

-- ============================================================
-- Construccion de la UI de slots
-- Retorna el frame de la barra de escenas para anclar en TerrorBoard
-- ============================================================

function TerrorScenes:BuildUI(parentBar, anchorBtn, theme)
    if not parentBar or not theme then return end

    local L = TerrorSquadAI.L

    -- Frame contenedor de la barra de escenas
    -- Anclado por su RIGHT al LEFT del boton de referencia (broadcastBtn)
    local bar = CreateFrame("Frame", "TSAI_SceneBar", parentBar)
    bar:SetWidth(220)   -- 10 slots en 2 filas + boton Save
    bar:SetHeight(24)
    bar:SetPoint("RIGHT", anchorBtn, "LEFT", -8, 0)
    bar:SetFrameLevel(parentBar:GetFrameLevel() + 1)

    -- Separador visual izquierdo
    local sep = bar:CreateTexture(nil, "ARTWORK")
    sep:SetWidth(1)
    sep:SetHeight(20)
    sep:SetPoint("LEFT", bar, "LEFT", 0, 0)
    sep:SetTexture(0, 1, 1, 0.3)

    -- Boton [S] Guardar
    local saveBtn = theme:CreateStyledButton("TSAI_SceneSave", bar, 24, 22, "S")
    saveBtn:SetPoint("LEFT", bar, "LEFT", 6, 0)
    saveBtn:SetBackdropBorderColor(0.2, 1, 0.4, 0.9)
    saveBtn:SetScript("OnClick", function()
        if TerrorScenes.selectedGrandSlot and TerrorScenes.selectedSubSlot then
            TerrorScenes:Save(TerrorScenes.selectedGrandSlot, TerrorScenes.selectedSubSlot)
        else
            TerrorSquadAI:Print("|cFFAAAAAA[Escenas]|r Selecciona un Grand Slot y un Sub Slot primero.")
        end
    end)
    saveBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText("|cFF00FF66Guardar Escena|r")
        GameTooltip:AddLine("Guarda marcadores en la sub-escena seleccionada.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    saveBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Panel de Sub-Escenas (4 botones) [NUEVO v7.0]
    local subBar = CreateFrame("Frame", "TSAI_SubSceneBar", bar)
    subBar:SetWidth(120)
    subBar:SetHeight(20)
    subBar:SetPoint("TOP", bar, "BOTTOM", 0, -4)
    subBar:Hide()
    self.ui.subBar = subBar

    local numerals = {"I", "II", "III", "IV"}
    self.subBtns = {}
    for j = 1, self.NUM_SUBSLOTS do
        local subIdx = j
        local subBtn = theme:CreateStyledButton("TSAI_SubSceneSlot"..j, subBar, 26, 16, numerals[j])
        subBtn:SetPoint("LEFT", subBar, "LEFT", (j-1)*30, 0)
        subBtn:SetScript("OnClick", function()
            if TerrorScenes.selectedSubSlot == subIdx then
                -- Doble click = Cargar
                TerrorScenes:Load(TerrorScenes.selectedGrandSlot, subIdx)
            else
                TerrorScenes.selectedSubSlot = subIdx
                TerrorScenes:RefreshUI()
            end
        end)
        subBtn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_TOP")
            ensureDB()
            local gs = TerrorSquadAIDB.grand_slots[TerrorScenes.selectedGrandSlot]
            if gs and gs.scenes[subIdx] then
                local d = gs.scenes[subIdx]
                GameTooltip:SetText("|cFFFFD700" .. (d.name or "Sub-Escena " .. subIdx) .. "|r")
                GameTooltip:AddLine("Guardado: " .. (d.savedAt or "?"), 0.8, 0.8, 0.8)
                GameTooltip:AddLine("Marcadores: " .. (d.count or 0), 0.6, 1, 0.6)
                if TerrorScenes.selectedSubSlot == subIdx then
                    GameTooltip:AddLine("Click = CARGAR", 0.4, 1, 0.4, true)
                else
                    GameTooltip:AddLine("Click = Seleccionar | 2xClick = Cargar", 0.7, 0.7, 0.7, true)
                end
            else
                GameTooltip:SetText("|cFFAAAAAA[Sub-Escena " .. subIdx .. " - vacia]|r")
                GameTooltip:AddLine("Selecciona y pulsa [S] para guardar.", 0.7, 0.7, 0.7, true)
            end
            GameTooltip:Show()
        end)
        subBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.subBtns[j] = subBtn
    end

    -- 10 Botones de slot [1]-[10] en 2 filas de 5 (Grand Slots v7.0)
    self.slotBtns = {}
    for i = 1, self.NUM_SLOTS do
        local idx  = i
        local col  = math.mod(i-1, 5)           -- 0..4
        local row  = math.floor((i-1) / 5)      -- 0 o 1 (dos filas)
        local btn = theme:CreateStyledButton("TSAI_SceneSlot"..i, bar, 20, 10, tostring(i))
        btn:SetPoint("TOPLEFT", bar, "TOPLEFT", 6 + 28 + col * 22, -row * 12)
        btn:SetScript("OnClick", function()
            if TerrorScenes.selectedGrandSlot == idx then
                -- Deseleccionar
                TerrorScenes.selectedGrandSlot = nil
                TerrorScenes.selectedSubSlot = nil
            else
                TerrorScenes.selectedGrandSlot = idx
                if not TerrorScenes.selectedSubSlot then
                    TerrorScenes.selectedSubSlot = 1
                end
            end
            TerrorScenes:RefreshUI()
        end)
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_TOP")
            ensureDB()
            local gs = TerrorSquadAIDB.grand_slots[idx]
            if gs then
                local count = 0
                for s=1, TerrorScenes.NUM_SUBSLOTS do
                    if gs.scenes[s] then count = count + 1 end
                end
                GameTooltip:SetText("|cFFFFD700" .. gs.name .. " (Banco " .. idx .. ")|r")
                GameTooltip:AddLine("Escenas guardadas: " .. count .. "/4", 0.8, 0.8, 0.8)
                GameTooltip:AddLine("Click = Expandir Banco", 0.7, 0.7, 0.7, true)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.slotBtns[i] = btn
    end

    self.ui.bar = bar
    
    -- v7.0: EditBox para el nombre de la sub-escena (flotante sobre la barra)
    local nameBox = CreateFrame("EditBox", "TSAI_SceneNameEdit", bar)
    nameBox:SetWidth(150)
    nameBox:SetHeight(18)
    nameBox:SetPoint("BOTTOM", bar, "TOP", 15, 4)
    nameBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    nameBox:SetAutoFocus(false)
    nameBox:SetTextInsets(4, 4, 0, 0)
    nameBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        edgeSize = 8, insets = {left=1, right=1, top=1, bottom=1}
    })
    nameBox:SetScript("OnEnterPressed", function()
        this:ClearFocus()
        if TerrorScenes.selectedGrandSlot and TerrorScenes.selectedSubSlot then
            ensureDB()
            local gs = TerrorSquadAIDB.grand_slots[TerrorScenes.selectedGrandSlot]
            if gs and gs.scenes[TerrorScenes.selectedSubSlot] then
                gs.scenes[TerrorScenes.selectedSubSlot].name = this:GetText()
                TerrorScenes:RefreshUI()
                TerrorSquadAI:Print("|cFF00FF66[Escenas]|r Nombre de slot " .. TerrorScenes.selectedGrandSlot .. "-" .. TerrorScenes.selectedSubSlot .. " actualizado.")
            end
        end
    end)
    nameBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    nameBox:Hide()
    self.ui.nameBox = nameBox

    self:RefreshUI()
    return bar
end

-- Actualizar colores de botones segun estado (v7.0)
function TerrorScenes:RefreshUI()
    if not self.slotBtns then return end
    ensureDB()
    
    -- Ocultar EditBox por defecto
    if self.ui.nameBox then self.ui.nameBox:Hide() end

    -- Refrescar Grand Slots
    for i = 1, self.NUM_SLOTS do
        local btn = self.slotBtns[i]
        if btn then
            local gs = TerrorSquadAIDB.grand_slots[i]
            local sel = (self.selectedGrandSlot == i)
            local hasDat = false
            if gs then
                for s=1, self.NUM_SUBSLOTS do
                    if gs.scenes[s] then hasDat = true; break end
                end
            end
            
            if sel then
                -- Seleccionado: borde cian brillante
                btn:SetBackdropBorderColor(0, 1, 1, 1)
                btn:SetBackdropColor(0, 0.15, 0.2, 1)
            elseif hasDat then
                -- Tiene datos: borde dorado
                btn:SetBackdropBorderColor(1, 0.85, 0, 0.9)
                btn:SetBackdropColor(0.08, 0.08, 0.05, 1)
            else
                -- Vacio: gris
                btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.7)
                btn:SetBackdropColor(0.05, 0.05, 0.05, 1)
            end
        end
    end

    -- Refrescar Sub-Escenas si hay un Grand Slot seleccionado
    if self.selectedGrandSlot and self.ui.subBar then
        self.ui.subBar:Show()
        local gs = TerrorSquadAIDB.grand_slots[self.selectedGrandSlot]
        
        for j = 1, self.NUM_SUBSLOTS do
            local sBtn = self.subBtns[j]
            if sBtn then
                local sel = (self.selectedSubSlot == j)
                local d = gs and gs.scenes[j]

                if sel then
                    sBtn:SetBackdropBorderColor(0, 1, 1, 1)
                    sBtn:SetBackdropColor(0, 0.15, 0.2, 1)
                    if self.ui.nameBox then
                        self.ui.nameBox:Show()
                        self.ui.nameBox:SetText(d and d.name or "Nueva Escena")
                    end
                elseif d then
                    sBtn:SetBackdropBorderColor(1, 0.85, 0, 0.9)
                    sBtn:SetBackdropColor(0.08, 0.08, 0.05, 1)
                else
                    sBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.7)
                    sBtn:SetBackdropColor(0.05, 0.05, 0.05, 1)
                end
            end
        end
    else
        if self.ui.subBar then self.ui.subBar:Hide() end
    end
end
