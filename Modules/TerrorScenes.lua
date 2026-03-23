-- TerrorScenes.lua - Sistema de Escenas Guardadas para TerrorBoard
-- TerrorSquadAI v6.0 - Inspirado en RaidMark (Holle)
-- Lua 5.0 / WoW 1.12.1 compatible
-- Author: DarckRovert (elnazzareno)

local TerrorScenes = {}
TerrorSquadAI:RegisterModule("TerrorScenes", TerrorScenes)

-- Numero de slots disponibles
TerrorScenes.NUM_SLOTS = 4
TerrorScenes.ui = {}

-- ============================================================
-- Utilidades internas (Lua 5.0 puro)
-- ============================================================

local function ensureDB()
    if not TerrorSquadAIDB then TerrorSquadAIDB = {} end
    if not TerrorSquadAIDB.scenes then TerrorSquadAIDB.scenes = {} end
    for i = 1, TerrorScenes.NUM_SLOTS do
        if not TerrorSquadAIDB.scenes[i] then
            TerrorSquadAIDB.scenes[i] = nil -- slot vacio
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

function TerrorScenes:Save(slot)
    if not slot or slot < 1 or slot > self.NUM_SLOTS then return end
    ensureDB()

    local markers = captureSnapshot()
    if table.getn(markers) == 0 then
        -- Guardar slot vacio = borrar
        TerrorSquadAIDB.scenes[slot] = nil
        self:RefreshUI()
        TerrorSquadAI:Print("|cFFAAAAAA[Escenas]|r Slot " .. slot .. " limpiado.")
        return
    end

    TerrorSquadAIDB.scenes[slot] = {
        markers = markers,
        savedAt = getTimestamp(),
        count   = table.getn(markers),
    }
    self:RefreshUI()
    TerrorSquadAI:Print("|cFF00FF66[Escenas]|r Slot " .. slot .. " guardado (" .. table.getn(markers) .. " marcadores).")
end

function TerrorScenes:Load(slot)
    if not slot or slot < 1 or slot > self.NUM_SLOTS then return end
    ensureDB()

    if not canLoad() then
        TerrorSquadAI:Print("|cFFFF4444[Escenas]|r Solo el lider de raid puede cargar escenas.")
        return
    end

    local data = TerrorSquadAIDB.scenes[slot]
    if not data or not data.markers then
        TerrorSquadAI:Print("|cFFAAAAAA[Escenas]|r Slot " .. slot .. " esta vacio.")
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

    TerrorSquadAI:Print("|cFF00FF66[Escenas]|r Slot " .. slot .. " cargado (" .. loaded .. " marcadores).")

    -- Broadcast al raid si esta en grupo
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        TB:Broadcast()
    end
end

function TerrorScenes:Delete(slot)
    if not slot or slot < 1 or slot > self.NUM_SLOTS then return end
    ensureDB()
    TerrorSquadAIDB.scenes[slot] = nil
    self:RefreshUI()
    TerrorSquadAI:Print("|cFFAAAAAA[Escenas]|r Slot " .. slot .. " borrado.")
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
    bar:SetWidth(175)
    bar:SetHeight(24)
    bar:SetPoint("RIGHT", anchorBtn, "LEFT", -8, 0)
    bar:SetFrameLevel(parentBar:GetFrameLevel() + 1)

    -- Separador visual izquierdo
    local sep = bar:CreateTexture(nil, "ARTWORK")
    sep:SetWidth(1)
    sep:SetHeight(20)
    sep:SetPoint("LEFT", bar, "LEFT", 0, 0)
    sep:SetTexture(0, 1, 1, 0.3)

    -- Boton [S] Guardar (usa slot seleccionado)
    local saveBtn = theme:CreateStyledButton("TSAI_SceneSave", bar, 24, 22, "S")
    saveBtn:SetPoint("LEFT", bar, "LEFT", 6, 0)
    saveBtn:SetBackdropBorderColor(0.2, 1, 0.4, 0.9)
    saveBtn:SetScript("OnClick", function()
        if TerrorScenes.selectedSlot then
            TerrorScenes:Save(TerrorScenes.selectedSlot)
        else
            TerrorSquadAI:Print("|cFFAAAAAA[Escenas]|r Selecciona un slot primero.")
        end
    end)
    saveBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText("|cFF00FF66Guardar Escena|r")
        GameTooltip:AddLine("Guarda marcadores actuales en el slot seleccionado.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    saveBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- 4 Botones de slot [1][2][3][4]
    self.slotBtns = {}
    for i = 1, self.NUM_SLOTS do
        local idx = i
        local btn = theme:CreateStyledButton("TSAI_SceneSlot"..i, bar, 22, 22, tostring(i))
        btn:SetPoint("LEFT", bar, "LEFT", 6 + 28 + (i-1)*26, 0)
        btn:SetScript("OnClick", function()
            if TerrorScenes.selectedSlot == idx then
                -- Doble click = cargar
                TerrorScenes:Load(idx)
            else
                -- Primer click = seleccionar
                TerrorScenes.selectedSlot = idx
                TerrorScenes:RefreshUI()
            end
        end)
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_TOP")
            ensureDB()
            local d = TerrorSquadAIDB.scenes[idx]
            if d then
                GameTooltip:SetText("|cFFFFD700Slot " .. idx .. "|r")
                GameTooltip:AddLine("Guardado: " .. (d.savedAt or "?"), 0.8, 0.8, 0.8)
                GameTooltip:AddLine("Marcadores: " .. (d.count or 0), 0.6, 1, 0.6)
                if TerrorScenes.selectedSlot == idx then
                    GameTooltip:AddLine("Click = CARGAR al lienzo", 0.4, 1, 0.4, true)
                else
                    GameTooltip:AddLine("Click = Seleccionar | 2x Click = Cargar", 0.7, 0.7, 0.7, true)
                end
            else
                GameTooltip:SetText("|cFFAAAAAA[Slot " .. idx .. " - vacio]|r")
                GameTooltip:AddLine("Selecciona y pulsa [S] para guardar.", 0.7, 0.7, 0.7, true)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        self.slotBtns[i] = btn
    end

    self.ui.bar = bar
    self:RefreshUI()
    return bar
end

-- Actualizar colores de botones segun estado
function TerrorScenes:RefreshUI()
    if not self.slotBtns then return end
    ensureDB()
    for i = 1, self.NUM_SLOTS do
        local btn = self.slotBtns[i]
        if btn then
            local d = TerrorSquadAIDB.scenes[i]
            local sel = (self.selectedSlot == i)
            local hasDat = d and d.markers
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
end
