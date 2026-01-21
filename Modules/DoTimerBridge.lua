-- TerrorSquadAI <-> DoTimer Bridge
-- Provides intelligent DoT suggestions based on DoTimer data

local TSA = TerrorSquadAI
if not TSA then return end

-- Bridge state
local dotBridge = {
  doTimerDetected = false,
  lastSuggestionTime = 0,
  SUGGESTION_COOLDOWN = 30, -- 30 seconds between DoT suggestions (anti-spam)
  lastCombatStart = 0,
  combatSuggestionGiven = false,
  enabled = true, -- Can be toggled with /tsadot toggle
}

TSA.DoTimerBridge = dotBridge

-- ============================================
-- DETECTION
-- ============================================

local function DetectDoTimer()
  if DoTimer_Timers then
    dotBridge.doTimerDetected = true
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[TerrorSquadAI]|r Detectado DoTimer - Sugerencias de DoTs activadas")
    return true
  end
  return false
end

-- ============================================
-- DOT DATABASE BY CLASS
-- ============================================

local IMPORTANT_DOTS = {
  WARLOCK = {
    {name = "Corruption", priority = 1, minDuration = 18},
    {name = "Corrupción", priority = 1, minDuration = 18},
    {name = "Curse of Agony", priority = 2, minDuration = 24},
    {name = "Maldición de agonía", priority = 2, minDuration = 24},
    {name = "Immolate", priority = 3, minDuration = 15},
    {name = "Inmolar", priority = 3, minDuration = 15},
    {name = "Siphon Life", priority = 2, minDuration = 30},
    {name = "Succionar vida", priority = 2, minDuration = 30},
  },
  PRIEST = {
    {name = "Shadow Word: Pain", priority = 1, minDuration = 18},
    {name = "Palabra de las Sombras: dolor", priority = 1, minDuration = 18},
    {name = "Vampiric Embrace", priority = 2, minDuration = 60},
    {name = "Abrazo vampírico", priority = 2, minDuration = 60},
  },
  DRUID = {
    {name = "Moonfire", priority = 1, minDuration = 12},
    {name = "Fuego lunar", priority = 1, minDuration = 12},
    {name = "Insect Swarm", priority = 2, minDuration = 12},
    {name = "Enjambre de insectos", priority = 2, minDuration = 12},
    {name = "Rip", priority = 1, minDuration = 12},
    {name = "Desgarrar", priority = 1, minDuration = 12},
  },
  HUNTER = {
    {name = "Serpent Sting", priority = 1, minDuration = 15},
    {name = "Picadura de serpiente", priority = 1, minDuration = 15},
  },
  ROGUE = {
    {name = "Rupture", priority = 1, minDuration = 10},
    {name = "Ruptura", priority = 1, minDuration = 10},
    {name = "Garrote", priority = 2, minDuration = 18},
  },
}

-- ============================================
-- CHECK ACTIVE DOTS ON TARGET
-- ============================================

local function GetActiveDotsOnTarget()
  if not DoTimer_Timers then return {} end
  
  local target = UnitName("target")
  if not target then return {} end
  
  local activeDots = {}
  
  if DoTimer_Timers[target] then
    for spellName, dotData in pairs(DoTimer_Timers[target]) do
      local endTime = dotData[1]
      local duration = dotData[2]
      local timeLeft = endTime - GetTime()
      
      if timeLeft > 0 then
        table.insert(activeDots, {
          name = spellName,
          timeLeft = timeLeft,
          duration = duration,
        })
      end
    end
  end
  
  return activeDots
end

-- ============================================
-- ANALYZE DOTS AND SUGGEST
-- ============================================

local function AnalyzeDotsAndSuggest()
  if not dotBridge.enabled then return end
  if not dotBridge.doTimerDetected then return end
  if not UnitExists("target") then return end
  if UnitIsDead("target") then return end
  
  local now = GetTime()
  
  -- Anti-spam: Don't suggest too often
  if now - dotBridge.lastSuggestionTime < dotBridge.SUGGESTION_COOLDOWN then
    return
  end
  
  -- Only suggest on bosses or elite mobs (to avoid spam on trash)
  local classification = UnitClassification("target")
  if classification ~= "worldboss" and classification ~= "rareelite" and classification ~= "elite" then
    return -- Skip trash mobs
  end
  
  local _, myClass = UnitClass("player")
  local myDots = IMPORTANT_DOTS[myClass]
  
  if not myDots then return end -- Class doesn't have important DoTs
  
  local activeDots = GetActiveDotsOnTarget()
  local missingDots = {}
  
  -- Check which important DoTs are missing
  for i = 1, table.getn(myDots) do
    local dotInfo = myDots[i]
    local found = false
    
    for j = 1, table.getn(activeDots) do
      local activeDot = activeDots[j]
      if activeDot.name == dotInfo.name then
        found = true
        break
      end
    end
    
    if not found then
      table.insert(missingDots, dotInfo)
    end
  end
  
  -- Suggest missing DoTs (only highest priority)
  if table.getn(missingDots) > 0 then
    -- Sort by priority
    table.sort(missingDots, function(a, b) return a.priority < b.priority end)
    
    local topMissing = missingDots[1]
    
    -- Send suggestion to TerrorMeter for visual display
    if TerrorMeter and TerrorMeter.integration then
      if TerrorMeter.integration.ReceiveSquadAISuggestion then
        local suggestion = {
          type = "APPLY_DOT",
          priority = "INFO",
          message = "Aplica " .. topMissing.name,
        }
        TerrorMeter.integration.ReceiveSquadAISuggestion(suggestion)
      end
    end
    
    dotBridge.lastSuggestionTime = now
  end
end

-- ============================================
-- COMBAT DETECTION
-- ============================================

local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entered combat
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Left combat
combatFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

combatFrame:SetScript("OnEvent", function()
  if event == "PLAYER_REGEN_DISABLED" then
    -- Entered combat
    dotBridge.lastCombatStart = GetTime()
    dotBridge.combatSuggestionGiven = false
    
  elseif event == "PLAYER_REGEN_ENABLED" then
    -- Left combat
    dotBridge.combatSuggestionGiven = false
    
  elseif event == "PLAYER_TARGET_CHANGED" then
    -- New target - check DoTs after a short delay
    if UnitExists("target") and not UnitIsDead("target") then
      -- Only suggest at start of combat (first 10 seconds) or if cooldown expired
      local timeSinceCombatStart = GetTime() - dotBridge.lastCombatStart
      local timeSinceLastSuggestion = GetTime() - dotBridge.lastSuggestionTime
      
      if timeSinceCombatStart < 10 or timeSinceLastSuggestion > dotBridge.SUGGESTION_COOLDOWN then
        -- Delay check by 2 seconds to let player apply DoTs first
        local checkFrame = CreateFrame("Frame")
        local elapsed = 0
        checkFrame:SetScript("OnUpdate", function()
          elapsed = elapsed + arg1
          if elapsed >= 2 then
            AnalyzeDotsAndSuggest()
            this:SetScript("OnUpdate", nil)
          end
        end)
      end
    end
  end
end)

-- ============================================
-- PERIODIC CHECK (EVERY 15 SECONDS)
-- ============================================

local periodicFrame = CreateFrame("Frame")
local periodicElapsed = 0
periodicFrame:SetScript("OnUpdate", function()
  periodicElapsed = periodicElapsed + arg1
  
  if periodicElapsed >= 15 then -- Check every 15 seconds
    periodicElapsed = 0
    
    -- Only check if in combat
    if UnitAffectingCombat("player") then
      AnalyzeDotsAndSuggest()
    end
  end
end)

-- ============================================
-- INITIALIZATION
-- ============================================

local function Initialize()
  DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[TerrorSquadAI]|r DoTimer Bridge cargado")
  
  -- Detect DoTimer after a short delay
  local initFrame = CreateFrame("Frame")
  initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  initFrame:SetScript("OnEvent", function()
    DetectDoTimer()
    this:UnregisterAllEvents()
  end)
end

Initialize()

-- ============================================
-- SLASH COMMANDS
-- ============================================

SLASH_TSADOT1 = "/tsadot"
SlashCmdList["TSADOT"] = function(msg)
  if msg == "toggle" then
    dotBridge.enabled = not dotBridge.enabled
    local status = dotBridge.enabled and "|cFF00FF00Activadas|r" or "|cFFFF0000Desactivadas|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[DoTimer Bridge]|r Sugerencias de DoTs: " .. status)
    
  elseif msg == "status" then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[DoTimer Bridge]|r Status:")
    DEFAULT_CHAT_FRAME:AddMessage("  DoTimer: " .. (dotBridge.doTimerDetected and "|cFF00FF00Detectado|r" or "|cFFFF0000No encontrado|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  Sugerencias: " .. (dotBridge.enabled and "|cFF00FF00Activadas|r" or "|cFFFF0000Desactivadas|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  Cooldown: " .. dotBridge.SUGGESTION_COOLDOWN .. " segundos")
    
    -- Show active DoTs on current target
    if UnitExists("target") then
      local activeDots = GetActiveDotsOnTarget()
      if table.getn(activeDots) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("  DoTs activos en " .. UnitName("target") .. ":")
        for i = 1, table.getn(activeDots) do
      local dot = activeDots[i]
          DEFAULT_CHAT_FRAME:AddMessage(string.format("    %s: %.1fs restantes", dot.name, dot.timeLeft))
        end
      else
        DEFAULT_CHAT_FRAME:AddMessage("  No hay DoTs activos en el objetivo")
      end
    end
    
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[DoTimer Bridge]|r Comandos:")
    DEFAULT_CHAT_FRAME:AddMessage("  /tsadot toggle - Activar/desactivar sugerencias de DoTs")
    DEFAULT_CHAT_FRAME:AddMessage("  /tsadot status - Ver estado y DoTs activos")
  end
end
