-- WarLogistics.lua - Logística de Guerra
-- TerrorSquadAI v4.0 - Phase 3
-- Monitor de suministros y reactivos

local WL = {}
TerrorSquadAI:RegisterModule("WarLogistics", WL)

WL.config = {
    enabled = true,
    autoCheck = true, -- Revisar al entrar a estancia/raid
    lowThreshold = 5,
}

-- Reactivos por clase
WL.reagents = {
    MAGE = {
        [17031] = "Rune of Teleportation", -- ID ejemplo, usaremos nombres para Vanilla seguro
        [17032] = "Rune of Portals",
        ["Arcane Powder"] = 5,
        ["Polvo Arcano"] = 5,
        ["Rune of Teleportation"] = 5,
        ["Runa de teletransporte"] = 5,
        ["Rune of Portals"] = 5,
        ["Runa de portales"] = 5,
    },
    PRIEST = {
        ["Sacred Candle"] = 5,
        ["Vela sagrada"] = 5,
    },
    PALADIN = {
        ["Symbol of Kings"] = 10,
        ["Símbolo de reyes"] = 10,
    },
    WARLOCK = {
        ["Soul Shard"] = 5,
        ["Fragmento de alma"] = 5,
    },
    ROGUE = {
        ["Flash Powder"] = 5,
        ["Polvo cegador"] = 5,
    },
    DRUID = {
        ["Wild Thornroot"] = 5,
        ["Raíz de espina salvaje"] = 5,
    }
}

-- Consumibles generales
WL.consumables = {
    ["Heavy Runecloth Bandage"] = 5,
    ["Venda de paño rúnico gruesa"] = 5,
    ["Major Healing Potion"] = 1,
    ["Poción mayor de curación"] = 1,
    ["Major Mana Potion"] = 1, -- Para casters
    ["Poción mayor de maná"] = 1,
}

function WL:Initialize()
    self:RegisterEvents()
    if TerrorSquadAI.DEBUG then
        TerrorSquadAI:Debug("WarLogistics inicializado")
    end
end

function WL:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("MERCHANT_SHOW") -- Recordatorio al visitar vendor
    
    frame:SetScript("OnEvent", function()
        WL:OnEvent(event)
    end)
end

function WL:OnEvent(event)
    if not self.config.enabled then return end
    
    if event == "MERCHANT_SHOW" then
        self:CheckSupplies(false) -- Check silencioso/recordatorio
    elseif self.config.autoCheck then
        local inInstance, instanceType = IsInInstance()
        if inInstance and (instanceType == "party" or instanceType == "raid") then
            -- Darle un momento para cargar inventario si acabamos de loguear
            -- Usar un timer simple en Vanilla
            local timerFrame = CreateFrame("Frame")
            local elapsed = 0
            timerFrame:SetScript("OnUpdate", function()
                elapsed = elapsed + arg1
                if elapsed >= 5 then
                    timerFrame:SetScript("OnUpdate", nil)
                    WL:CheckSupplies(true)
                end
            end)
        end
    end
end

function WL:CheckSupplies(alertCritical)
    local _, class = UnitClass("player")
    local missing = {}
    
    -- Chequear reactivos de clase
    if self.reagents[class] then
        for item, count in pairs(self.reagents[class]) do
           if type(item) == "string" then
                local current = self:GetItemCount(item)
                if current < count then
                    table.insert(missing, item .. " (" .. current .. "/" .. count .. ")")
                end
           end
        end
    end
    
    -- Chequear consumibles básicos
    -- (Solo ejemplo básico, idealmente configurable)
    -- Asumimos bandages para todos
    local bandageName = "Heavy Runecloth Bandage"
    -- Check locale? or just use string
    -- if GetItemCount(bandageName) < 5 then ... end
    
    if table.getn(missing) > 0 then
        local msg = "SUMINISTROS BAJOS: " .. table.concat(missing, ", ")
        if alertCritical then
            TerrorSquadAI:Alert("|cFFFF0000[Logística]|r " .. msg)
        else
            TerrorSquadAI:Print("|cFFFF0000[Logística]|r " .. msg)
        end
    elseif not alertCritical and event == "MERCHANT_SHOW" then
        -- TerrorSquadAI:Print("Suministros correctos.")
    end
end

-- Vanilla API: GetItemCount robusto (ID + Multi-Idioma + Cache Bypass)
function WL:GetItemCount(itemName)
    -- Caso especial: Soul Shard (ID 6265)
    -- Si buscan "Fragmento de alma" o "Soul Shard", usamos lógica blindada
    if itemName == "Soul Shard" or itemName == "Fragmento de alma" then
        local count = 0
        for bag = 0, 4 do
            for slot = 1, GetContainerNumSlots(bag) do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    -- Buscar por ID 6265 (Infalible)
                    if string.find(link, "6265") then
                        local _, c = GetContainerItemInfo(bag, slot)
                        count = count + (c or 1)
                    end
                end
            end
        end
        return count
    end

    -- 1. Intentar API nativa (rápido)
    if GetItemCount then
        local c = GetItemCount(itemName)
        if c and c > 0 then return c end
    end
    
    -- 2. Fallback: Iterar bolsas parseando links (para cuando GetItemInfo/API falla)
    local count = 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                 -- Extraer nombre del link: [Nombre]
                 local _, _, name = string.find(link, "%[(.+)%]")
                 if name and (name == itemName) then
                     local _, c = GetContainerItemInfo(bag, slot)
                     count = count + (c or 1)
                 end
            end
        end
    end
    return count
end
