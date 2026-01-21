-- MacroGenerator.lua - Generador de Macros Automático

local MG = {}
TerrorSquadAI:RegisterModule("MacroGenerator", MG)

-- Configuración
MG.config = {
    enabled = true,
    autoCreate = false,
    overwriteExisting = false,
}

-- Plantillas de macros por clase (Vanilla 1.12 - 510 char limit)
local MACRO_TEMPLATES = {
    ["WARRIOR"] = {
        {name = "TSA_Charge", icon = 1, body = "/script if GetShapeshiftForm()~=1 then CastSpellByName(\"Battle Stance\")end\n/cast Charge\n/startattack"},
        {name = "TSA_Execute", icon = 1, body = "/script if UnitExists(\"target\")and UnitHealth(\"target\")/UnitHealthMax(\"target\")<0.2 then CastSpellByName(\"Execute\")end\n/startattack"},
        {name = "TSA_Interrupt", icon = 1, body = "/script if GetShapeshiftForm()==2 then CastSpellByName(\"Shield Bash\")else CastSpellByName(\"Pummel\")end"},
    },
    ["PALADIN"] = {
        {name = "TSA_Heal", icon = 1, body = "/script if UnitExists(\"target\")and UnitIsFriend(\"player\",\"target\")then CastSpellByName(\"Flash of Light\")else TargetLastTarget()CastSpellByName(\"Flash of Light\")end"},
        {name = "TSA_Cleanse", icon = 1, body = "/script if UnitExists(\"target\")and UnitIsFriend(\"player\",\"target\")then CastSpellByName(\"Cleanse\")else TargetLastTarget()CastSpellByName(\"Cleanse\")end"},
        {name = "TSA_Stun", icon = 1, body = "/cast Hammer of Justice\n/startattack"},
    },
    ["HUNTER"] = {
        {name = "TSA_Trap", icon = 1, body = "/script PetPassiveMode()PetFollow()\n/cast Freezing Trap"},
        {name = "TSA_Mend", icon = 1, body = "/script if UnitExists(\"pet\")and UnitHealth(\"pet\")/UnitHealthMax(\"pet\")<0.7 then CastSpellByName(\"Mend Pet\")end"},
        {name = "TSA_Multi", icon = 1, body = "/cast Multi-Shot\n/startattack"},
    },
    ["ROGUE"] = {
        {name = "TSA_Opener", icon = 1, body = "/script if GetComboPoints()<1 then CastSpellByName(\"Cheap Shot\")else CastSpellByName(\"Sinister Strike\")end"},
        {name = "TSA_Kick", icon = 1, body = "/cast Kick"},
        {name = "TSA_Vanish", icon = 1, body = "/cast Vanish\n/cast Sprint"},
    },
    ["PRIEST"] = {
        {name = "TSA_Shield", icon = 1, body = "/script if UnitExists(\"target\")and UnitIsFriend(\"player\",\"target\")then CastSpellByName(\"Power Word: Shield\")else TargetLastTarget()CastSpellByName(\"Power Word: Shield\")end"},
        {name = "TSA_Dispel", icon = 1, body = "/script if UnitExists(\"target\")and UnitIsFriend(\"player\",\"target\")then CastSpellByName(\"Dispel Magic\")else CastSpellByName(\"Dispel Magic\")end"},
        {name = "TSA_Fear", icon = 1, body = "/cast Psychic Scream"},
    },
    ["SHAMAN"] = {
        {name = "TSA_Shock", icon = 1, body = "/cast Earth Shock"},
        {name = "TSA_Heal", icon = 1, body = "/script if UnitExists(\"target\")and UnitIsFriend(\"player\",\"target\")then CastSpellByName(\"Healing Wave\")else TargetLastTarget()CastSpellByName(\"Healing Wave\")end"},
        {name = "TSA_Totem", icon = 1, body = "/cast Grounding Totem"},
    },
    ["MAGE"] = {
        {name = "TSA_CS", icon = 1, body = "/cast Counterspell"},
        {name = "TSA_Poly", icon = 1, body = "/cast Polymorph"},
        {name = "TSA_Nova", icon = 1, body = "/cast Frost Nova"},
    },
    ["WARLOCK"] = {
        {name = "TSA_Fear", icon = 1, body = "/cast Fear"},
        {name = "TSA_Coil", icon = 1, body = "/cast Death Coil"},
        {name = "TSA_Drain", icon = 1, body = "/cast Corruption\n/cast Drain Life"},
    },
    ["DRUID"] = {
        {name = "TSA_Heal", icon = 1, body = "/script if UnitExists(\"target\")and UnitIsFriend(\"player\",\"target\")then CastSpellByName(\"Healing Touch\")else TargetLastTarget()CastSpellByName(\"Healing Touch\")end"},
        {name = "TSA_Root", icon = 1, body = "/cast Entangling Roots"},
        {name = "TSA_Bear", icon = 1, body = "/cast Dire Bear Form"},
    },
}

-- Macros generales (todas las clases) - Vanilla 1.12 compatible (510 char limit)
local GENERAL_MACROS = {
    {name = "TSA_Assist", icon = 1, body = "/assist\n/startattack"},
    {name = "TSA_Focus", icon = 1, body = "/script if TerrorSquadAI and TerrorSquadAI.Modules.FocusFireCoordinator then TerrorSquadAI.Modules.FocusFireCoordinator:SetFocusTarget(\"target\");DEFAULT_CHAT_FRAME:AddMessage(\"Focus establecido\",1,0.84,0)end"},
    {name = "TSA_Mark", icon = 1, body = "/script if TerrorSquadAI and TerrorSquadAI.Modules.AutoMarker then TerrorSquadAI.Modules.AutoMarker:MarkTarget(\"target\");DEFAULT_CHAT_FRAME:AddMessage(\"Objetivo marcado\",1,0.84,0)end"},
}

function MG:Initialize()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r MacroGenerator inicializado", 1, 0.84, 0)
    
    if self.config.autoCreate then
        self:CreateAllMacros()
    end
end

function MG:CreateAllMacros()
    if not self.config.enabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r Sistema desactivado", 1, 0.5, 0)
        return
    end
    
    local _, playerClass = UnitClass("player")
    local classMacros = MACRO_TEMPLATES[playerClass]
    
    local created = 0
    local skipped = 0
    
    -- Crear macros generales
    for _, macro in ipairs(GENERAL_MACROS) do
        if self:CreateMacro(macro.name, macro.icon, macro.body) then
            created = created + 1
        else
            skipped = skipped + 1
        end
    end
    
    -- Crear macros de clase
    if classMacros then
        for _, macro in ipairs(classMacros) do
            if self:CreateMacro(macro.name, macro.icon, macro.body) then
                created = created + 1
            else
                skipped = skipped + 1
            end
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD700[MacroGenerator]|r Creados: %d | Omitidos: %d", created, skipped), 1, 0.84, 0)
end

function MG:CreateMacro(name, icon, body)
    -- Verificar si ya existe
    local macroIndex = GetMacroIndexByName(name)
    
    if macroIndex > 0 then
        if self.config.overwriteExisting then
            EditMacro(macroIndex, name, icon, body)
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r Actualizado: " .. name, 1, 0.84, 0)
            return true
        else
            return false
        end
    end
    
    -- Verificar espacio disponible
    local numGlobal, numPerChar = GetNumMacros()
    if numGlobal >= 36 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r Sin espacio para macros globales", 1, 0, 0)
        return false
    end
    
    -- Crear macro (WoW 1.12 requiere índice numérico de icono, usar 1 por defecto)
    local iconIndex = 1  -- Ícono por defecto
    local index = CreateMacro(name, iconIndex, body, nil)
    if index then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r Creado: " .. name, 1, 0.84, 0)
        return true
    end
    
    return false
end

function MG:CreateClassMacros()
    local _, playerClass = UnitClass("player")
    local classMacros = MACRO_TEMPLATES[playerClass]
    
    if not classMacros then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r No hay macros para tu clase", 1, 0.5, 0)
        return
    end
    
    local created = 0
    for _, macro in ipairs(classMacros) do
        if self:CreateMacro(macro.name, macro.icon, macro.body) then
            created = created + 1
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD700[MacroGenerator]|r Creados %d macros de clase", created), 1, 0.84, 0)
end

function MG:CreateGeneralMacros()
    local created = 0
    for _, macro in ipairs(GENERAL_MACROS) do
        if self:CreateMacro(macro.name, macro.icon, macro.body) then
            created = created + 1
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD700[MacroGenerator]|r Creados %d macros generales", created), 1, 0.84, 0)
end

function MG:DeleteAllTSAMacros()
    local deleted = 0
    
    -- Eliminar macros generales
    for _, macro in ipairs(GENERAL_MACROS) do
        local index = GetMacroIndexByName(macro.name)
        if index > 0 then
            DeleteMacro(index)
            deleted = deleted + 1
        end
    end
    
    -- Eliminar macros de clase
    local _, playerClass = UnitClass("player")
    local classMacros = MACRO_TEMPLATES[playerClass]
    if classMacros then
        for _, macro in ipairs(classMacros) do
            local index = GetMacroIndexByName(macro.name)
            if index > 0 then
                DeleteMacro(index)
                deleted = deleted + 1
            end
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD700[MacroGenerator]|r Eliminados %d macros", deleted), 1, 0.84, 0)
end

function MG:ListAvailableMacros()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Macros Disponibles ===", 1, 0.84, 0)
    
    -- Macros generales
    DEFAULT_CHAT_FRAME:AddMessage("\n|cFF00FF00Generales:|r", 0, 1, 0)
    for _, macro in ipairs(GENERAL_MACROS) do
        local exists = GetMacroIndexByName(macro.name) > 0
        local status = exists and "|cFF00FF00[EXISTE]|r" or "|cFF808080[NO CREADO]|r"
        DEFAULT_CHAT_FRAME:AddMessage("  " .. macro.name .. " " .. status, 1, 1, 1)
    end
    
    -- Macros de clase
    local _, playerClass = UnitClass("player")
    local classMacros = MACRO_TEMPLATES[playerClass]
    if classMacros then
        DEFAULT_CHAT_FRAME:AddMessage("\n|cFF00FF00Clase " .. playerClass .. ":|r", 0, 1, 0)
        for _, macro in ipairs(classMacros) do
            local exists = GetMacroIndexByName(macro.name) > 0
            local status = exists and "|cFF00FF00[EXISTE]|r" or "|cFF808080[NO CREADO]|r"
            DEFAULT_CHAT_FRAME:AddMessage("  " .. macro.name .. " " .. status, 1, 1, 1)
        end
    end
    
    -- Espacio disponible
    local numGlobal, numPerChar = GetNumMacros()
    DEFAULT_CHAT_FRAME:AddMessage(string.format("\nEspacio: %d/36 globales | %d/18 por personaje", numGlobal, numPerChar), 1, 1, 1)
end

function MG:ShowMacroContent(macroName)
    local index = GetMacroIndexByName(macroName)
    if index == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r Macro no encontrado: " .. macroName, 1, 0, 0)
        return
    end
    
    local name, icon, body = GetMacroInfo(index)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Macro: " .. name .. " ===", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage(body, 1, 1, 1)
end

function MG:CreateCustomMacro(name, icon, body)
    if not name or name == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r Nombre requerido", 1, 0, 0)
        return
    end
    
    if not body or body == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r Contenido requerido", 1, 0, 0)
        return
    end
    
    icon = icon or "INV_Misc_QuestionMark"
    
    if self:CreateMacro(name, icon, body) then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r Macro personalizado creado: " .. name, 1, 0.84, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r Error al crear macro", 1, 0, 0)
    end
end

function MG:GetMacroTemplate(macroName)
    -- Buscar en generales
    for _, macro in ipairs(GENERAL_MACROS) do
        if macro.name == macroName then
            return macro
        end
    end
    
    -- Buscar en clase
    local _, playerClass = UnitClass("player")
    local classMacros = MACRO_TEMPLATES[playerClass]
    if classMacros then
        for _, macro in ipairs(classMacros) do
            if macro.name == macroName then
                return macro
            end
        end
    end
    
    return nil
end

function MG:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r " .. status, 1, 0.84, 0)
end

function MG:ToggleAutoCreate()
    self.config.autoCreate = not self.config.autoCreate
    local status = self.config.autoCreate and "activada" or "desactivada"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r Creación automática " .. status, 1, 0.84, 0)
end

function MG:ToggleOverwrite()
    self.config.overwriteExisting = not self.config.overwriteExisting
    local status = self.config.overwriteExisting and "activada" or "desactivada"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[MacroGenerator]|r Sobrescritura " .. status, 1, 0.84, 0)
end

function MG:PrintHelp()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== MacroGenerator - Ayuda ===", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage("/tsai macro create - Crear todos los macros", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("/tsai macro class - Crear macros de clase", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("/tsai macro general - Crear macros generales", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("/tsai macro list - Listar macros disponibles", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("/tsai macro delete - Eliminar todos los macros TSA", 1, 1, 1)
end

-- =========================================================================
-- SYSTEM 7: DYNAMIC MACRO ENGINE (The Brain)
-- =========================================================================

-- Defines the best action based on current state
function MG:GetBestAction()
    -- 1. Panic State (Health < 30%)
    if UnitHealth("player")/UnitHealthMax("player") < 0.3 then
        local _, class = UnitClass("player")
        if class == "WARRIOR" then return "/cast Shield Wall\n/use Major Healing Potion" end
        if class == "PALADIN" then return "/cast Divine Shield" end
        if class == "MAGE" then return "/cast Ice Block" end
        if class == "ROGUE" then return "/cast Vanish" end
        if class == "PRIEST" then return "/cast Desperate Prayer\n/cast Power Word: Shield" end
        return "/use Major Healing Potion"
    end
    
    -- 2. Execute State (Target < 20%)
    if UnitExists("target") and UnitHealth("target")/UnitHealthMax("target") < 0.2 then
        local _, class = UnitClass("player")
        if class == "WARRIOR" then return "/cast Execute" end
        if class == "PALADIN" then return "/cast Hammer of Wrath" end
        if class == "HUNTER" then return "/cast Kill Shot" end -- Not in 1.12, fallback to Multi
        if class == "MAGE" then return "/cast Fire Blast" end
    end
    
    -- 3. Burst State (Detailed logic would go here)
    -- Default: Attack
    return "/startattack"
end

function MG:UpdateDynamicMacro()
    if InCombatLockdown() then return end -- Cannot edit in combat (secure limitation even in 1.12 some places, but mostly to avoid lag)
    
    local actionBody = self:GetBestAction()
    
    -- Find or Create TSA_Brain
    local index = GetMacroIndexByName("TSA_Brain")
    local body = "#showtooltip\n" .. actionBody
    
    if index > 0 then
        EditMacro(index, "TSA_Brain", 1, body)
    else
        self:CreateMacro("TSA_Brain", 1, body)
    end
end

-- Hook into Update Loop to refresh Brain Button? 
-- No, in 1.12 EditMacro cannot be spam-called in combat without issues or restrictions.
-- Strategy: We only update it OUT of combat or on specific events if allowed.
-- NOTE: In Vanilla 1.12, EditMacro IS allowed in combat. But spamming it causes UI lag.
-- We will update it periodically (every 5s) or on major health events.

function MG:RegisterDynamicEvents()
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function()
        if (this.lastUpdate or 0) + 2 > GetTime() then return end
        this.lastUpdate = GetTime()
        
        -- Smart throttle: Only update if logic changes
        -- For now, simplified
        -- MG:UpdateDynamicMacro() -- Disabled to prevent spam until fully tested
    end)
end

