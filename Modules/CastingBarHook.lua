-- CastingBarHook.lua - Detección de Casteo via CastingBar
-- TerrorSquadAI v3.0 - Phase 2
-- Hook al CastingBarFrame para detectar casts del target

local CBH = {}
TerrorSquadAI:RegisterModule("CastingBarHook", CBH)

-- Estado
CBH.targetCasting = false
CBH.targetSpell = nil
CBH.targetCastStart = 0

-- Configuración
CBH.config = {
    enabled = true,
    alertOnCast = true,
    alertPrioritySpells = true,
}

-- Hechizos prioritarios para alertar
local PRIORITY_SPELLS = {
    -- Heals
    ["Heal"] = true, ["Curar"] = true,
    ["Greater Heal"] = true, ["Curación superior"] = true,
    ["Flash Heal"] = true, ["Sanación relámpago"] = true,
    ["Healing Touch"] = true, ["Toque curativo"] = true,
    ["Regrowth"] = true, ["Recrecimiento"] = true,
    ["Chain Heal"] = true, ["Cadena de sanación"] = true,
    ["Holy Light"] = true, ["Luz Sagrada"] = true,
    
    -- CC
    ["Polymorph"] = true, ["Polimorfia"] = true,
    ["Fear"] = true, ["Miedo"] = true,
    ["Psychic Scream"] = true, ["Alarido psíquico"] = true,
    
    -- Big Damage
    ["Pyroblast"] = true, ["Piroexplosión"] = true,
    ["Mind Blast"] = true, ["Explosión mental"] = true,
}

function CBH:Initialize()
    self:HookCastingBar()
    self:RegisterEvents()
    
    if TerrorSquadAI.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r CastingBarHook inicializado", 1, 0.84, 0)
    end
end

function CBH:HookCastingBar()
    -- En Vanilla, el CastingBarFrame muestra el cast del target cuando lo tienes seleccionado
    -- Podemos hookear OnUpdate para detectar cuando hay un cast activo
    
    -- Guardar función original
    if TargetFrameSpellBar then
        self.originalOnUpdate = TargetFrameSpellBar:GetScript("OnUpdate")
        
        TargetFrameSpellBar:SetScript("OnUpdate", function()
            -- Llamar original si existe
            if CBH.originalOnUpdate then
                CBH.originalOnUpdate()
            end
            
            -- Nuestra lógica
            CBH:OnTargetCastUpdate()
        end)
    end
end

function CBH:OnTargetCastUpdate()
    if not self.config.enabled then return end
    if not TargetFrameSpellBar then return end
    
    -- Verificar si el frame está visible (indica cast activo)
    if TargetFrameSpellBar:IsShown() then
        if not self.targetCasting then
            -- Nuevo cast detectado
            self.targetCasting = true
            self.targetCastStart = GetTime()
            
            -- Intentar obtener nombre del spell del texto
            if TargetFrameSpellBar.Text then
                local spellText = TargetFrameSpellBar.Text:GetText()
                if spellText and spellText ~= self.targetSpell then
                    self.targetSpell = spellText
                    self:OnCastStart(spellText)
                end
            end
        end
    else
        if self.targetCasting then
            -- Cast terminó
            self:OnCastEnd()
            self.targetCasting = false
            self.targetSpell = nil
        end
    end
end

function CBH:OnCastStart(spellName)
    if not spellName then return end
    
    local isPriority = PRIORITY_SPELLS[spellName]
    
    -- Notificar a InterruptCoordinator si está disponible
    if TerrorSquadAI.Modules.InterruptCoordinator then
        local priority = isPriority and 9 or 5
        -- InterruptCoordinator puede usar esta info
    end
    
    -- Alertar si es spell prioritario
    if self.config.alertPrioritySpells and isPriority then
        local targetName = UnitName("target") or "Enemigo"
        local message = string.format("|cFFFF8800¡%s está casteando %s!|r", targetName, spellName)
        
        if TerrorSquadAI.Modules.AlertSystem then
            TerrorSquadAI.Modules.AlertSystem:ShowAlert(message, "WARNING")
        else
            DEFAULT_CHAT_FRAME:AddMessage(message, 1, 0.5, 0)
        end
        
        PlaySound("RaidWarning")
    elseif self.config.alertOnCast then
        -- Mensaje menos intrusivo para casts normales
        if TerrorSquadAI.DEBUG then
            local targetName = UnitName("target") or "Enemigo"
            DEFAULT_CHAT_FRAME:AddMessage(string.format("[Cast] %s: %s", targetName, spellName), 0.7, 0.7, 0.7)
        end
    end
end

function CBH:OnCastEnd()
    -- El cast terminó (completado o interrumpido)
    self.targetSpell = nil
end

function CBH:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    
    frame:SetScript("OnEvent", function()
        if event == "PLAYER_TARGET_CHANGED" then
            -- Reset estado al cambiar target
            CBH.targetCasting = false
            CBH.targetSpell = nil
        end
    end)
end

-- API para otros módulos
function CBH:IsTargetCasting()
    return self.targetCasting
end

function CBH:GetTargetSpell()
    return self.targetSpell
end

function CBH:IsPrioritySpell(spellName)
    return spellName and PRIORITY_SPELLS[spellName]
end

function CBH:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "|cFF00FF00Activado|r" or "|cFFFF0000Desactivado|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[CastingBarHook]|r " .. status, 1, 0.84, 0)
end

function CBH:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== CastingBar Hook Status ===|r", 1, 0.84, 0)
    DEFAULT_CHAT_FRAME:AddMessage("Habilitado: " .. (self.config.enabled and "Sí" or "No"), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Target casteando: " .. (self.targetCasting and "Sí" or "No"), 1, 1, 1)
    if self.targetSpell then
        DEFAULT_CHAT_FRAME:AddMessage("Spell actual: " .. self.targetSpell, 1, 1, 1)
    end
end
