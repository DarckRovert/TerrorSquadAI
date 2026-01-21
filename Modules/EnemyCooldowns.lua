-- EnemyCooldowns.lua - Rastreador de Cooldowns Enemigos (PvP)
-- TerrorSquadAI v4.0 - Phase 1
-- Detecta y rastrea habilidades defensivas/ofensivas enemigas via Combat Log

local EC = {}
TerrorSquadAI:RegisterModule("EnemyCooldowns", EC)

-- Configuración
EC.config = {
    enabled = true,
    announce = true, -- Anunciar en chat/alerta
    showBars = true, -- Mostrar barras visuales
    sound = true,
    barScale = 1.0,
}

-- Base de datos de Cooldowns (Segundos)
-- IMPORTANTE: Nombres exactos en español para el cliente esES/esMX
local COOLDOWNS = {
    -- Mago
    ["Traslación"] =             { cd = 15, class = "MAGE", icon = "Interface\\Icons\\Spell_Arcane_Blink" },
    ["Blink"] =                  { cd = 15, class = "MAGE", icon = "Interface\\Icons\\Spell_Arcane_Blink" },
    ["Bloque de hielo"] =        { cd = 300, class = "MAGE", icon = "Interface\\Icons\\Spell_Frost_Frost" },
    ["Ice Block"] =              { cd = 300, class = "MAGE", icon = "Interface\\Icons\\Spell_Frost_Frost" },
    ["Counterspell"] =           { cd = 24, class = "MAGE", icon = "Interface\\Icons\\Spell_Frost_IceShock" }, 
    
    -- Paladín
    ["Escudo divino"] =          { cd = 300, class = "PALADIN", icon = "Interface\\Icons\\Spell_Holy_DivineIntervention" },
    ["Divine Shield"] =          { cd = 300, class = "PALADIN", icon = "Interface\\Icons\\Spell_Holy_DivineIntervention" },
    ["Bendición de protección"] ={ cd = 300, class = "PALADIN", icon = "Interface\\Icons\\Spell_Holy_SealOfProtection" },
    ["Blessing of Protection"] = { cd = 300, class = "PALADIN", icon = "Interface\\Icons\\Spell_Holy_SealOfProtection" },
    ["Martillo de justicia"] =   { cd = 60, class = "PALADIN", icon = "Interface\\Icons\\Spell_Holy_SealOfMight" },
    ["Hammer of Justice"] =      { cd = 60, class = "PALADIN", icon = "Interface\\Icons\\Spell_Holy_SealOfMight" },
    
    -- Pícaro
    ["Evasión"] =                { cd = 300, class = "ROGUE", icon = "Interface\\Icons\\Spell_Shadow_ShadowWard" },
    ["Evasion"] =                { cd = 300, class = "ROGUE", icon = "Interface\\Icons\\Spell_Shadow_ShadowWard" },
    ["Esfumarse"] =              { cd = 300, class = "ROGUE", icon = "Interface\\Icons\\Ability_Vanish" },
    ["Vanish"] =                 { cd = 300, class = "ROGUE", icon = "Interface\\Icons\\Ability_Vanish" },
    ["Ceguera"] =                { cd = 120, class = "ROGUE", icon = "Interface\\Icons\\Spell_Shadow_MindSteal" },
    ["Blind"] =                  { cd = 120, class = "ROGUE", icon = "Interface\\Icons\\Spell_Shadow_MindSteal" },
    ["Patada"] =                 { cd = 10, class = "ROGUE", icon = "Interface\\Icons\\Ability_Kick" },
    ["Kick"] =                   { cd = 10, class = "ROGUE", icon = "Interface\\Icons\\Ability_Kick" },
    
    -- Sacerdote
    ["Alarido psíquico"] =       { cd = 30, class = "PRIEST", icon = "Interface\\Icons\\Spell_Shadow_PsychicScream" },
    ["Psychic Scream"] =         { cd = 30, class = "PRIEST", icon = "Interface\\Icons\\Spell_Shadow_PsychicScream" },
    
    -- Guerrero
    ["Interceptar"] =            { cd = 30, class = "WARRIOR", icon = "Interface\\Icons\\Ability_Rogue_Sprint" },
    ["Intercept"] =              { cd = 30, class = "WARRIOR", icon = "Interface\\Icons\\Ability_Rogue_Sprint" },
    ["Muro de escudo"] =         { cd = 1800, class = "WARRIOR", icon = "Interface\\Icons\\Ability_Warrior_ShieldWall" },
    ["Shield Wall"] =            { cd = 1800, class = "WARRIOR", icon = "Interface\\Icons\\Ability_Warrior_ShieldWall" },
    
    -- Brujo
    ["Espiral de la muerte"] =   { cd = 120, class = "WARLOCK", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil" },
    ["Death Coil"] =             { cd = 120, class = "WARLOCK", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil" },
}

-- Estado
EC.activeCooldowns = {} -- {enemyName = {spellName = expireTime}}
EC.frames = {}
EC.unusedFrames = {}

function EC:Initialize()
    self:CreateAnchorFrame()
    self:RegisterEvents()
    
    if TerrorSquadAI.DEBUG then
        TerrorSquadAI:Debug("EnemyCooldowns inicializado")
    end
end

function EC:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")
    frame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
    frame:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
    
    frame:SetScript("OnEvent", function()
        EC:ParseCombatLog(event, arg1)
    end)
    
    -- Timer loop
    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        EC:OnUpdate()
    end)
end

function EC:ParseCombatLog(event, message)
    if not self.config.enabled then return end
    
    -- Patrones de combate (Lua 5.0 compatible - string.find)
    -- "X gana Y." (Spanish) or "X gains Y." (English)
    local _, _, caster, spell = string.find(message, "^(.+) gana (.+)%.$")
    if not caster then
         _, _, caster, spell = string.find(message, "^(.+) gains (.+)%.$")
    end
    
    if not caster then
        -- "X lanza Y." (Spanish) or "X casts Y." (English)
        _, _, caster, spell = string.find(message, "^(.+) lanza (.+)%.$")
        if not caster then
            _, _, caster, spell = string.find(message, "^(.+) casts (.+)%.$")
        end
    end
    
    if not caster then
        -- "X realiza Y sobre Z." (Spanish) or "X performs Y on Z." (English)
        _, _, caster, spell = string.find(message, "^(.+) realiza (.+) sobre")
        if not caster then
            _, _, caster, spell = string.find(message, "^(.+) performs (.+) on")
        end
    end
    
    if caster and spell then
        -- Limpiar nombres (eliminar ranks si existen)
        -- En Vanilla los mensajes suelen ser limpios, pero por si acaso
        
        -- Verificar si es un spell importante
        if COOLDOWNS[spell] then
            self:TrackCooldown(caster, spell)
        end
    end
end

function EC:TrackCooldown(caster, spell)
    local info = COOLDOWNS[spell]
    if not info then return end
    
    local now = GetTime()
    local expireTime = now + info.cd
    
    -- Inicializar tabla para el enemigo si no existe
    if not self.activeCooldowns[caster] then
        self.activeCooldowns[caster] = {}
    end
    
    -- Guardar CD
    self.activeCooldowns[caster][spell] = {
        expire = expireTime,
        icon = info.icon,
        class = info.class,
        duration = info.cd
    }
    
    -- Visuales
    self:UpdateUI(caster, spell)
    
    -- Alerta
    if self.config.announce then
        local color = "|cFFFF0000" -- Rojo por defecto
        if info.class == "MAGE" then color = "|cFF69CCF0"
        elseif info.class == "PALADIN" then color = "|cFFF58CBA"
        elseif info.class == "ROGUE" then color = "|cFFFFF569"
        end
        
        TerrorSquadAI:Alert(color .. caster .. "|r usó " .. spell .. " (" .. info.cd .. "s CD)")
    end
    
    if self.config.sound then
        PlaySound("igCreatureAggroSelect")
    end
end

-- Sistema de Barras Visuales
function EC:CreateAnchorFrame()
    local f = CreateFrame("Frame", "TerrorSquad_EC_Anchor", UIParent)
    f:SetWidth(200)
    f:SetHeight(20)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", f, "CENTER", 0, 0)
    text:SetText("Enemy Cooldowns")
    f.text = text
    
    -- Fondo semi-transparente para ver el anchor al configurar
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.4)
    f.bg = bg
    
    f:Hide() -- Ocultar por defecto, mostrar en config mode
    self.anchor = f
end

function EC:GetBarFrame()
    -- Reutilizar frame si existe
    local frame = table.remove(self.unusedFrames)
    
    if not frame then
        -- Crear nuevo frame
        local count = table.getn(self.frames) + 1
        frame = CreateFrame("StatusBar", "TSAI_EC_Bar"..count, UIParent)
        frame:SetWidth(150)
        frame:SetHeight(16)
        frame:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        frame:SetStatusBarColor(1, 0, 0, 1)
        
        -- Icono
        frame.icon = frame:CreateTexture(nil, "OVERLAY")
        frame.icon:SetWidth(16)
        frame.icon:SetHeight(16)
        frame.icon:SetPoint("RIGHT", frame, "LEFT", -5, 0)
        
        -- Texto nombre
        frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.nameText:SetPoint("LEFT", frame, "LEFT", 5, 0)
        frame.nameText:SetTextColor(1, 1, 1)
        
        -- Texto tiempo
        frame.timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.timeText:SetPoint("RIGHT", frame, "RIGHT", -5, 0)
        frame.timeText:SetTextColor(1, 1, 1)
        
        -- Fondo
        frame.bg = frame:CreateTexture(nil, "BACKGROUND")
        frame.bg:SetAllPoints()
        frame.bg:SetTexture(0, 0, 0, 0.5)
    end
    
    table.insert(self.frames, frame)
    return frame
end

function EC:UpdateUI(caster, spell)
    if not self.config.showBars then return end
    
    -- Encontrar si ya existe barra para esto
    -- Nota: Simplificación - solo creamos una nueva por ahora
    -- En versión completa, gestionaríamos barras existentes para actualizar tiempos
    
    local cdInfo = self.activeCooldowns[caster][spell]
    if not cdInfo then return end
    
    local bar = self:GetBarFrame()
    bar.data = {
        caster = caster,
        spell = spell,
        expire = cdInfo.expire,
        duration = cdInfo.duration
    }
    
    bar.icon:SetTexture(cdInfo.icon)
    bar.nameText:SetText(caster .. ": " .. spell)
    bar:SetMinMaxValues(0, cdInfo.duration)
    bar:SetValue(cdInfo.duration) -- Al inicio lleno
    bar:Show()
    
    self:LayoutBars()
end

function EC:LayoutBars()
    -- Organizar barras verticalmente desde el anchor
    local yOffset = 0
    if self.anchor:IsShown() then yOffset = -20 end
    
    for _, bar in ipairs(self.frames) do
        if bar:IsShown() then
            bar:ClearAllPoints()
            bar:SetPoint("TOP", self.anchor, "BOTTOM", 0, yOffset)
            yOffset = yOffset - 18
        end
    end
end

function EC:OnUpdate()
    local now = GetTime()
    local needsLayout = false
    
    for i = table.getn(self.frames), 1, -1 do
        local bar = self.frames[i]
        if bar:IsShown() and bar.data then
            local remaining = bar.data.expire - now
            
            if remaining <= 0 then
                -- CD expirado - Guardar data antes de limpiar
                local savedCaster = bar.data.caster
                local savedSpell = bar.data.spell
                
                bar:Hide()
                bar.data = nil
                table.remove(self.frames, i)
                table.insert(self.unusedFrames, bar)
                needsLayout = true
                
                -- Limpiar estado (usar saved data)
                if self.activeCooldowns[savedCaster] then
                    self.activeCooldowns[savedCaster][savedSpell] = nil
                end
                
                -- Alerta de "CD DISPONIBLE"
                TerrorSquadAI:Debug(savedCaster .. " recuperó " .. savedSpell)
            else
                -- Actualizar barra
                bar:SetValue(remaining)
                bar.timeText:SetText(string.format("%.1f", remaining))
                
                -- Color dinámico
                if remaining < 5 then
                    bar:SetStatusBarColor(1, 0, 0) -- Rojo, va a expirar (peligro vuelve)
                else
                    bar:SetStatusBarColor(0, 1, 0) -- Verde, seguro
                end
            end
        end
    end
    
    if needsLayout then
        self:LayoutBars()
    end
end

function EC:Test()
    self:TrackCooldown("TargetDummy", "Traslación")
    self:TrackCooldown("TargetDummy", "Bloque de hielo")
end
