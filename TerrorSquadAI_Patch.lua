-- TerrorSquadAI_Patch.lua
-- Sistema de hooks para compatibilidad con cliente español
-- Autor: DarckRovert
-- Versión: 1.0.0

-- Verificar si el cliente está en español
local isSpanishClient = TerrorSquadAI_IsSpanishClient()

if not isSpanishClient then
    -- Si no es cliente español, no hacer nada
    DEFAULT_CHAT_FRAME:AddMessage("|cFF8B0000[TerrorSquadAI]|r Cliente en inglés detectado - Patch de localización no necesario", 0.5, 1, 0.5)
    return
end

DEFAULT_CHAT_FRAME:AddMessage("|cFF8B0000[TerrorSquadAI]|r Cliente español detectado - Activando sistema de localización", 1, 0.84, 0)

-- ============================================
-- HOOK: UNIT_SPELLCAST_START
-- Traduce nombres de hechizos cuando se detectan
-- ============================================

local originalGetSpellName = GetSpellName
function GetSpellName(spellId, bookType)
    local spanishName, rank = originalGetSpellName(spellId, bookType)
    if not spanishName then return nil, nil end
    
    -- Intentar traducir
    local englishName = TerrorSquadAI_TranslateSpell(spanishName)
    
    -- Si se encontró traducción, devolver nombre en inglés
    -- Esto permite que los módulos funcionen con nombres en inglés
    if englishName and englishName ~= spanishName then
        return englishName, rank
    end
    
    return spanishName, rank
end

-- ============================================
-- HOOK: UnitBuff / UnitDebuff
-- Traduce nombres de buffs/debuffs
-- ============================================

local originalUnitBuff = UnitBuff
function UnitBuff(unit, index, showCastable)
    local buffTexture, buffApplications = originalUnitBuff(unit, index, showCastable)
    if not buffTexture then return nil, nil end
    
    -- En Vanilla WoW, UnitBuff no devuelve el nombre directamente
    -- Necesitamos usar tooltip para obtener el nombre
    local buffName = TerrorSquadAI_GetBuffName(unit, index, false)
    if buffName then
        local englishName = TerrorSquadAI_TranslateSpell(buffName)
        if englishName and englishName ~= buffName then
            -- Guardar traducción en caché global
            if not TerrorSquadAI_BuffCache then
                TerrorSquadAI_BuffCache = {}
            end
            TerrorSquadAI_BuffCache[buffTexture] = englishName
        end
    end
    
    return buffTexture, buffApplications
end

local originalUnitDebuff = UnitDebuff
function UnitDebuff(unit, index, showCastable)
    local debuffTexture, debuffApplications, debuffType = originalUnitDebuff(unit, index, showCastable)
    if not debuffTexture then return nil, nil, nil end
    
    local debuffName = TerrorSquadAI_GetBuffName(unit, index, true)
    if debuffName then
        local englishName = TerrorSquadAI_TranslateSpell(debuffName)
        if englishName and englishName ~= debuffName then
            if not TerrorSquadAI_DebuffCache then
                TerrorSquadAI_DebuffCache = {}
            end
            TerrorSquadAI_DebuffCache[debuffTexture] = englishName
        end
    end
    
    return debuffTexture, debuffApplications, debuffType
end

-- ============================================
-- Función auxiliar: Obtener nombre de buff/debuff usando tooltip
-- ============================================

function TerrorSquadAI_GetBuffName(unit, index, isDebuff)
    if not TerrorSquadAI_TooltipFrame then
        TerrorSquadAI_TooltipFrame = CreateFrame("GameTooltip", "TerrorSquadAI_TooltipFrame", nil, "GameTooltipTemplate")
        TerrorSquadAI_TooltipFrame:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    
    TerrorSquadAI_TooltipFrame:ClearLines()
    
    if isDebuff then
        TerrorSquadAI_TooltipFrame:SetUnitDebuff(unit, index)
    else
        TerrorSquadAI_TooltipFrame:SetUnitBuff(unit, index)
    end
    
    local text = TerrorSquadAI_TooltipFrameTextLeft1:GetText()
    return text
end

-- ============================================
-- HOOK: Módulos específicos de TerrorSquadAI
-- ============================================

-- Hook para CooldownTracker
local function HookCooldownTracker()
    local CT = TerrorSquadAI:GetModule("CooldownTracker")
    if not CT then return end
    
    local originalOnSpellCast = CT.OnSpellCast
    function CT:OnSpellCast(unit, spellName, spellRank)
        -- Traducir nombre del hechizo antes de procesarlo
        local englishName = TerrorSquadAI_TranslateSpell(spellName)
        if englishName then
            spellName = englishName
        end
        
        return originalOnSpellCast(self, unit, spellName, spellRank)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF8B0000[TerrorSquadAI]|r CooldownTracker hook aplicado", 0.5, 1, 0.5)
end

-- Hook para InterruptCoordinator
local function HookInterruptCoordinator()
    local IC = TerrorSquadAI:GetModule("InterruptCoordinator")
    if not IC then return end
    
    local originalOnSpellcastStart = IC.OnSpellcastStart
    function IC:OnSpellcastStart(unit, spellName)
        -- Traducir nombre del hechizo antes de procesarlo
        local englishName = TerrorSquadAI_TranslateSpell(spellName)
        if englishName then
            spellName = englishName
        end
        
        return originalOnSpellcastStart(self, unit, spellName)
    end
    
    local originalOnChannelStart = IC.OnChannelStart
    function IC:OnChannelStart(unit, spellName)
        -- Traducir nombre del hechizo antes de procesarlo
        local englishName = TerrorSquadAI_TranslateSpell(spellName)
        if englishName then
            spellName = englishName
        end
        
        return originalOnChannelStart(self, unit, spellName)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF8B0000[TerrorSquadAI]|r InterruptCoordinator hook aplicado", 0.5, 1, 0.5)
end

-- ============================================
-- Aplicar hooks cuando los módulos estén cargados
-- ============================================

local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("ADDON_LOADED")
hookFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "TerrorSquadAI" then
        -- Esperar un frame para asegurar que todos los módulos estén cargados
        local delayFrame = CreateFrame("Frame")
        local elapsed = 0
        delayFrame:SetScript("OnUpdate", function()
            elapsed = elapsed + arg1
            if elapsed >= 0.5 then
                HookCooldownTracker()
                HookInterruptCoordinator()
                delayFrame:SetScript("OnUpdate", nil)
                DEFAULT_CHAT_FRAME:AddMessage("|cFF8B0000[TerrorSquadAI]|r Sistema de localización activado completamente", 1, 1, 0)
            end
        end)
    end
end)

-- ============================================
-- Comandos de diagnóstico
-- ============================================

-- Comando para verificar traducciones
SLASH_TSAILOCALE1 = "/tsailocale"
SlashCmdList["TSAILOCALE"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF8B0000[TerrorSquadAI Locale]|r", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage("Cliente: " .. GetLocale(), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Es español: " .. tostring(isSpanishClient), 1, 1, 1)
    
    local count = 0
    for _ in pairs(TerrorSquadAI_SpellDB) do
        count = count + 1
    end
    DEFAULT_CHAT_FRAME:AddMessage("Hechizos en base de datos: " .. count, 1, 1, 1)
    
    if msg and msg ~= "" then
        local english = TerrorSquadAI_TranslateSpell(msg)
        DEFAULT_CHAT_FRAME:AddMessage("Traducción de '" .. msg .. "': " .. tostring(english), 0.5, 1, 0.5)
    end
end

-- Comando para listar hechizos traducidos
SLASH_TSAISPELLS1 = "/tsaispells"
SlashCmdList["TSAISPELLS"] = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF8B0000[TerrorSquadAI]|r Hechizos traducidos:", 1, 0.84, 0)
    
    local spells = {}
    for spanish, english in pairs(TerrorSquadAI_SpellDB) do
        table.insert(spells, {spanish = spanish, english = english})
    end
    
    table.sort(spells, function(a, b) return a.spanish < b.spanish end)
    
    local count = 0
    for _, spell in ipairs(spells) do
        if not msg or msg == "" or string.find(string.lower(spell.spanish), string.lower(msg)) or string.find(string.lower(spell.english), string.lower(msg)) then
            DEFAULT_CHAT_FRAME:AddMessage(spell.spanish .. " -> " .. spell.english, 0.8, 0.8, 1)
            count = count + 1
            if count >= 20 then
                DEFAULT_CHAT_FRAME:AddMessage("... (mostrando primeros 20 resultados)", 1, 1, 0)
                break
            end
        end
    end
    
    if count == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("No se encontraron hechizos", 1, 0.5, 0.5)
    end
end

DEFAULT_CHAT_FRAME:AddMessage("|cFF8B0000[TerrorSquadAI]|r Patch de localización cargado. Usa /tsailocale y /tsaispells", 1, 0.84, 0)
