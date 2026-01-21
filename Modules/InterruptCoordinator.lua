-- InterruptCoordinator.lua - Coordinador de Interrupciones
-- Compatible con WoW 1.12 Vanilla (Turtle WoW)

local IC = {}
TerrorSquadAI:RegisterModule("InterruptCoordinator", IC)

-- Helper: Generar ID único para unidad (WoW 1.12 no tiene UnitGUID)
local function GetUnitID(unit)
    if not UnitExists(unit) then return nil end
    local name = UnitName(unit) or "Unknown"
    local level = UnitLevel(unit) or 0
    return name .. ":" .. level
end

-- Estado
IC.interruptQueue = {}
IC.lastInterrupt = 0
IC.interruptCooldown = 1.5
IC.squadInterrupts = {}

-- Configuración
IC.config = {
    enabled = true,
    autoInterrupt = false,
    announceInterrupts = true,
    coordinateWithSquad = true,
    prioritySpells = true,
}

-- Hechizos prioritarios para interrumpir
local PRIORITY_SPELLS = {
    -- Heals
    ["Heal"] = 10, ["Sanación"] = 10,
    ["Greater Heal"] = 10, ["Sanación superior"] = 10,
    ["Flash Heal"] = 9, ["Sanación relámpago"] = 9,
    ["Healing Touch"] = 10, ["Toque de sanación"] = 10,
    ["Regrowth"] = 9, ["Recrecimiento"] = 9,
    ["Chain Heal"] = 10, ["Sanación en cadena"] = 10,
    ["Holy Light"] = 9, ["Luz sagrada"] = 9,
    ["Flash of Light"] = 8, ["Destello de Luz"] = 8,
    
    -- CC
    ["Polymorph"] = 10, ["Polimorfia"] = 10,
    ["Fear"] = 9, ["Miedo"] = 9,
    ["Psychic Scream"] = 9, ["Alarido psíquico"] = 9,
    ["Howl of Terror"] = 9, ["Aullido de terror"] = 9,
    ["Hibernate"] = 8, ["Hibernar"] = 8,
    ["Sap"] = 8, ["Porrazo"] = 8,
    
    -- Damage
    ["Pyroblast"] = 9, ["Piroexplosión"] = 9,
    ["Frostbolt"] = 7, ["Descarga de escarcha"] = 7,
    ["Fireball"] = 7, ["Bola de fuego"] = 7,
    ["Shadow Bolt"] = 7, ["Descarga de las Sombras"] = 7,
    ["Mind Blast"] = 7, ["Explosión mental"] = 7,
    ["Lightning Bolt"] = 7, ["Descarga de relámpagos"] = 7,
    ["Chain Lightning"] = 8, ["Cadena de relámpagos"] = 8,
    
    -- Buffs importantes
    ["Bloodlust"] = 10, ["Ansia de sangre"] = 10,
    ["Power Infusion"] = 9, ["Infusión de poder"] = 9,
    ["Innervate"] = 9, ["Estimular"] = 9,
}

-- Habilidades de interrupción por clase (English defaults)
local INTERRUPT_ABILITIES = {
    ["WARRIOR"] = {name = "Shield Bash", id = 72, cooldown = 12},
    ["ROGUE"] = {name = "Kick", id = 1766, cooldown = 10},
    ["SHAMAN"] = {name = "Earth Shock", id = 8042, cooldown = 6},
    ["MAGE"] = {name = "Counterspell", id = 2139, cooldown = 10},
    ["WARLOCK"] = {name = "Spell Lock", id = 19244, cooldown = 24},
    ["HUNTER"] = {name = "Scatter Shot", id = 19503, cooldown = 30},
    ["PALADIN"] = {name = "Hammer of Justice", id = 853, cooldown = 60},
    ["DRUID"] = {name = "Bash", id = 5211, cooldown = 60},
}

-- Nombres en español para CastSpellByName
local INTERRUPT_NAMES_ES = {
    ["Shield Bash"] = "Azote de escudo",
    ["Kick"] = "Patada",
    ["Earth Shock"] = "Choque de tierra",
    ["Counterspell"] = "Contrahechizo",
    ["Spell Lock"] = "Bloqueo de hechizo", -- Felhunter
    ["Scatter Shot"] = "Disparo de dispersión",
    ["Hammer of Justice"] = "Martillo de justicia",
    ["Bash"] = "Azote",
}

function IC:Initialize()
    self:RegisterEvents()
    self:DetectPlayerInterrupts()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r InterruptCoordinator inicializado", 1, 0.84, 0)
end

function IC:RegisterEvents()
    local frame = CreateFrame("Frame")
    -- NOTA: En WoW 1.12 Vanilla NO existen los eventos UNIT_SPELLCAST_*
    -- Solo podemos detectar casts del jugador con SPELLCAST_START/STOP
    -- La detección de casts enemigos no es posible sin librería externa
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("SPELLCAST_STOP") -- Solo para jugador
    frame:SetScript("OnEvent", function()
        if event == "CHAT_MSG_ADDON" then
            IC:OnAddonMessage(arg1, arg2, arg3, arg4)
        elseif event == "SPELLCAST_STOP" then
            -- Nuestro cast terminó - verificar si fue interrupción
            IC:OnPlayerSpellStop()
        end
    end)
end

function IC:DetectPlayerInterrupts()
    local _, playerClass = UnitClass("player")
    self.playerInterrupt = INTERRUPT_ABILITIES[playerClass]
    
    if self.playerInterrupt then
        -- Ajustar nombre según idioma para CastSpellByName
        local locale = GetLocale()
        if (locale == "esES" or locale == "esMX") and INTERRUPT_NAMES_ES[self.playerInterrupt.name] then
            self.playerInterrupt.name = INTERRUPT_NAMES_ES[self.playerInterrupt.name]
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[InterruptCoordinator]|r Habilidad detectada: " .. self.playerInterrupt.name, 1, 0.84, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[InterruptCoordinator]|r Sin habilidad de interrupción disponible", 1, 0.5, 0)
    end
end

-- Llamado cuando terminamos de castear (WoW 1.12 solo detecta casts propios)
function IC:OnPlayerSpellStop()
    -- Esta función se llama cuando el jugador termina de castear
    -- En Vanilla no podemos saber qué hechizo terminó, solo que algo terminó
    -- La usamos para limpiar la cola de interrupciones viejas
    local now = GetTime()
    for i = table.getn(self.interruptQueue), 1, -1 do
        if now - self.interruptQueue[i].time > 5 then
            table.remove(self.interruptQueue, i)
        end
    end
end

function IC:OnSpellcastStart(unit, spellName)
    if not self.config.enabled then return end
    if not unit or not spellName then return end
    if not UnitCanAttack("player", unit) then return end
    
    self:ProcessCast(unit, spellName, false)
end

function IC:OnChannelStart(unit, spellName)
    if not self.config.enabled then return end
    if not unit or not spellName then return end
    if not UnitCanAttack("player", unit) then return end
    
    self:ProcessCast(unit, spellName, true)
end

function IC:ProcessCast(unit, spellName, isChannel)
    local priority = self:GetSpellPriority(spellName)
    
    if priority == 0 and not self.config.prioritySpells then
        priority = 5 -- Prioridad base para todos los hechizos
    end
    
    if priority > 0 then
        local unitID = GetUnitID(unit)
        local casterName = UnitName(unit)
        
        -- Añadir a cola de interrupciones
        table.insert(self.interruptQueue, {
            unit = unit,
            unitID = unitID,
            caster = casterName,
            spell = spellName,
            priority = priority,
            isChannel = isChannel,
            time = GetTime()
        })
        
        -- Ordenar por prioridad
        table.sort(self.interruptQueue, function(a, b)
            return a.priority > b.priority
        end)
        
        -- Anunciar
        if self.config.announceInterrupts and priority >= 8 then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF8800[Interrupt]|r %s casteando %s (P:%d)", casterName, spellName, priority), 1, 0.5, 0)
        end
        
        -- Intentar interrumpir automáticamente
        if self.config.autoInterrupt then
            self:TryInterrupt()
        end
        
        -- Coordinar con escuadrón
        if self.config.coordinateWithSquad then
            self:BroadcastCast(unitID, casterName, spellName, priority)
        end
    end
end

function IC:GetSpellPriority(spellName)
    return PRIORITY_SPELLS[spellName] or 0
end

function IC:TryInterrupt()
    if not self.playerInterrupt then return false end
    
    local now = GetTime()
    if now - self.lastInterrupt < self.interruptCooldown then
        return false
    end
    
    -- Verificar si la habilidad está disponible
    local start, duration = GetSpellCooldown(self.playerInterrupt.id, BOOKTYPE_SPELL)
    if start and start > 0 and duration and duration > 1.5 then
        return false -- En cooldown
    end
    
    -- Obtener el objetivo de mayor prioridad
    if table.getn(self.interruptQueue) == 0 then return false end
    
    local target = self.interruptQueue[1]
    
    -- Verificar si el objetivo existe
    if not UnitExists(target.unit) then
        table.remove(self.interruptQueue, 1)
        return false
    end
    
    -- NOTA: En WoW 1.12 no podemos detectar si el enemigo está casteando
    -- UnitCastingInfo/UnitChannelInfo NO existen en Vanilla
    -- Removemos el cast de la cola después de un tiempo
    if GetTime() - target.time > 3 then
        table.remove(self.interruptQueue, 1)
        return false
    end
    
    -- Verificar rango
    if not CheckInteractDistance(target.unit, 3) then
        return false -- Fuera de rango
    end
    
    -- Targetear y usar interrupción
    local currentTargetID = GetUnitID("target")
    if currentTargetID ~= target.unitID then
        TargetByName(target.caster)
    end
    
    if UnitExists("target") and GetUnitID("target") == target.unitID then
        CastSpellByName(self.playerInterrupt.name)
        self.lastInterrupt = now
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Interrupt]|r Interrumpiendo " .. target.spell, 1, 0, 0)
        
        -- Anunciar al grupo (desactivado por defecto para evitar spam)
        -- if target.priority >= 8 then
        --     local message = string.format("[Terror Squad] Interrumpiendo %s de %s", target.spell, target.caster)
        --     if GetNumRaidMembers() > 0 then
        --         SendChatMessage(message, "RAID")
        --     elseif GetNumPartyMembers() > 0 then
        --         SendChatMessage(message, "PARTY")
        --     end
        -- end
        
        table.remove(self.interruptQueue, 1)
        return true
    end
    
    return false
end

function IC:OnInterrupted(unit, spellName)
    if not unit then return end
    
    local unitID = GetUnitID(unit)
    
    -- Remover de la cola
    for i = table.getn(self.interruptQueue), 1, -1 do
        if self.interruptQueue[i].unitID == unitID then
            table.remove(self.interruptQueue, i)
        end
    end
end

function IC:OnSpellcastSucceeded(unit, spellName)
    if not unit then return end
    
    -- Si es nuestra interrupción, registrarla
    if unit == "player" and self.playerInterrupt and spellName == self.playerInterrupt.name then
        self:BroadcastInterrupt()
    end
end

function IC:BroadcastCast(guid, caster, spell, priority)
    if not TerrorSquadAI.Modules.CommunicationSync then return end
    
    local data = string.format("CAST:%s:%s:%s:%d", guid, caster, spell, priority)
    TerrorSquadAI.Modules.CommunicationSync:SendMessage("INTERRUPT", data)
end

function IC:BroadcastInterrupt()
    if not TerrorSquadAI.Modules.CommunicationSync then return end
    
    local data = string.format("INT:%s:%d", UnitName("player"), GetTime())
    TerrorSquadAI.Modules.CommunicationSync:SendMessage("INTERRUPT", data)
end

function IC:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= "TerrorSquadAI" then return end
    
    local _, _, msgType, data = string.find(message, "^(%w+):(.+)$")
    if msgType == "CAST" then
        self:ReceiveCast(data, sender)
    elseif msgType == "INT" then
        self:ReceiveInterrupt(data, sender)
    end
end

function IC:ReceiveCast(data, sender)
    local _, _, guid, caster, spell, priority = string.find(data, "^([^:]+):([^:]+):([^:]+):(%d+)$")
    if not guid or not caster or not spell or not priority then return end
    
    priority = tonumber(priority)
    
    -- Guardar información del cast del escuadrón
    if not self.squadInterrupts[sender] then
        self.squadInterrupts[sender] = {}
    end
    
    self.squadInterrupts[sender].lastCast = {
        guid = guid,
        caster = caster,
        spell = spell,
        priority = priority,
        time = GetTime()
    }
end

function IC:ReceiveInterrupt(data, sender)
    local _, _, player, time = string.find(data, "^([^:]+):([%d%.]+)$")
    if not player or not time then return end
    
    time = tonumber(time)
    
    if not self.squadInterrupts[sender] then
        self.squadInterrupts[sender] = {}
    end
    
    self.squadInterrupts[sender].lastInterrupt = time
end

function IC:ManualInterrupt()
    if not self.playerInterrupt then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Interrupt]|r No tienes habilidad de interrupción", 1, 0, 0)
        return
    end
    
    if not UnitExists("target") then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Interrupt]|r Necesitas un objetivo", 1, 0, 0)
        return
    end
    
    -- UnitCastingInfo/UnitChannelInfo NO existen en Vanilla WoW
    -- En Vanilla no podemos detectar casts enemigos directamente
    local casting = nil
    if not casting then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Interrupt]|r No se puede detectar casts en Vanilla", 1, 0.5, 0)
        return
    end
    
    CastSpellByName(self.playerInterrupt.name)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[Interrupt]|r Usando " .. self.playerInterrupt.name, 1, 0, 0)
end

function IC:ClearQueue()
    self.interruptQueue = {}
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Interrupt]|r Cola de interrupciones limpiada", 1, 0.84, 0)
end

function IC:PrintQueue()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Cola de Interrupciones ===", 1, 0.84, 0)
    
    if table.getn(self.interruptQueue) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("Cola vacía", 1, 1, 1)
        return
    end
    
    for i, cast in ipairs(self.interruptQueue) do
        DEFAULT_CHAT_FRAME:AddMessage(string.format("%d. %s - %s (P:%d)", i, cast.caster, cast.spell, cast.priority), 1, 1, 1)
    end
end

function IC:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Interrupt Coordinator Status ===", 1, 0.84, 0)
    
    if self.playerInterrupt then
        DEFAULT_CHAT_FRAME:AddMessage("Habilidad: " .. self.playerInterrupt.name, 1, 1, 1)
        
        local start, duration = GetSpellCooldown(self.playerInterrupt.id, BOOKTYPE_SPELL)
        if start > 0 and duration > 1.5 then
            local remaining = duration - (GetTime() - start)
            DEFAULT_CHAT_FRAME:AddMessage(string.format("Cooldown: %.1fs", remaining), 1, 0.5, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("Estado: |cFF00FF00Disponible|r", 0, 1, 0)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("Sin habilidad de interrupción", 1, 0.5, 0.5)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("\nCola: " .. table.getn(self.interruptQueue) .. " casts", 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Auto-interrupt: " .. (self.config.autoInterrupt and "|cFF00FF00ON|r" or "|cFFFF0000OFF|r"), 1, 1, 1)
end

function IC:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Interrupt]|r " .. status, 1, 0.84, 0)
end

function IC:ToggleAuto()
    self.config.autoInterrupt = not self.config.autoInterrupt
    local status = self.config.autoInterrupt and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Interrupt]|r Auto-interrupt " .. status, 1, 0.84, 0)
end
