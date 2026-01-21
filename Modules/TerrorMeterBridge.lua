-- TerrorSquadAI <-> TerrorMeter Bridge
-- Receives real threat/DPS data from TerrorMeter and provides intelligent suggestions

local TSA = TerrorSquadAI
if not TSA then return end

-- Bridge state
local bridge = {
  terrorMeterDetected = false,
  lastThreatData = {},
  lastDPSData = {},
  raidThreatData = {}, -- Threat data from all raid members
  suggestions = {},
  lastSuggestionTime = 0,
  SUGGESTION_COOLDOWN = 5, -- Don't spam suggestions
}

TSA.TerrorMeterBridge = bridge

-- Integration channel
local INTEGRATION_CHANNEL = "TerrorEcosystem"

-- Register communication channel
if RegisterAddonMessagePrefix then
  RegisterAddonMessagePrefix(INTEGRATION_CHANNEL)
end

-- ============================================
-- DETECTION
-- ============================================

local function DetectTerrorMeter()
  if TerrorMeter then
    bridge.terrorMeterDetected = true
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[TerrorSquadAI]|r Detectado TerrorMeter - Integración activada")
    return true
  end
  return false
end

-- ============================================
-- RECEIVE DATA FROM TERRORMETER
-- ============================================

-- Called by TerrorMeter to send threat data
function TSA.ReceiveThreatData(threatData, dpsData)
  if not threatData then return end
  
  bridge.lastThreatData = threatData
  bridge.lastDPSData = dpsData or {}
  
  -- Store in raid threat data
  if threatData.player then
    bridge.raidThreatData[threatData.player] = {
      threat = threatData.threat,
      threatPercent = threatData.threatPercent,
      dps = dpsData and dpsData.dps or 0,
      timestamp = GetTime(),
    }
  end
  
  -- Analyze and generate suggestions
  AnalyzeThreatSituation(threatData, dpsData)
end

-- ============================================
-- INTELLIGENT THREAT ANALYSIS
-- ============================================

function AnalyzeThreatSituation(threatData, dpsData)
  if not threatData then return end
  
  local now = GetTime()
  if now - bridge.lastSuggestionTime < bridge.SUGGESTION_COOLDOWN then
    return -- Don't spam suggestions
  end
  
  local myName = UnitName("player")
  local _, myClass = UnitClass("player")
  local myThreatPercent = threatData.threatPercent or 0
  local myDPS = dpsData and dpsData.dps or 0
  local tank = threatData.tank
  
  -- Don't suggest anything if I'm the tank
  if tank == myName then return end
  
  local suggestion = nil
  
  -- CRITICAL: About to pull aggro (>90%)
  if myThreatPercent > 90 then
    suggestion = {
      type = "REDUCE_THREAT",
      priority = "CRITICAL",
      message = string.format("¡REDUCE TU THREAT! Estás al %.0f%% del tank. ", myThreatPercent) .. GetThreatReductionAdvice(myClass),
    }
  
  -- WARNING: Getting close (70-90%)
  elseif myThreatPercent > 70 then
    suggestion = {
      type = "REDUCE_THREAT",
      priority = "WARNING",
      message = string.format("Cuidado con el threat (%.0f%%). ", myThreatPercent) .. GetThreatReductionAdvice(myClass),
    }
  
  -- SAFE: Low threat, can increase DPS
  elseif myThreatPercent < 50 and myDPS > 0 then
    -- Check if tank has solid aggro
    if tank and IsTankStable() then
      suggestion = {
        type = "INCREASE_DPS",
        priority = "INFO",
        message = string.format("Threat seguro (%.0f%%). Puedes aumentar DPS.", myThreatPercent),
      }
    end
  end
  
  -- Send suggestion
  if suggestion then
    SendSuggestion(suggestion)
    bridge.lastSuggestionTime = now
  end
end

-- Get class-specific threat reduction advice
function GetThreatReductionAdvice(class)
  local advice = {
    WARRIOR = "Usa Challenging Shout si tienes.",
    ROGUE = "Usa Feint para reducir threat.",
    MAGE = "Deja de castear por 3 segundos.",
    WARLOCK = "Usa Soulshatter si está disponible.",
    HUNTER = "Usa Feign Death.",
    PRIEST = "Reduce healing/damage por un momento.",
    PALADIN = "Cancela Blessing of Salvation si puedes.",
    DRUID = "Reduce DPS temporalmente.",
    SHAMAN = "Reduce DPS temporalmente.",
  }
  
  return advice[class] or "Reduce DPS temporalmente."
end

-- Check if tank has stable aggro
function IsTankStable()
  local tank = bridge.lastThreatData.tank
  if not tank then return false end
  
  local tankData = bridge.raidThreatData[tank]
  if not tankData then return false end
  
  -- Tank is stable if they have significantly more threat than others
  local secondHighest = 0
  for player, data in pairs(bridge.raidThreatData) do
    if player ~= tank and data.threat > secondHighest then
      secondHighest = data.threat
    end
  end
  
  if tankData.threat > secondHighest * 1.5 then
    return true -- Tank has 50% more threat than next highest
  end
  
  return false
end

-- ============================================
-- SEND SUGGESTIONS
-- ============================================

function SendSuggestion(suggestion)
  if not suggestion then return end
  
  -- Display locally
  local color = "FFFFFF"
  if suggestion.priority == "CRITICAL" then
    color = "FF0000"
    PlaySound("RaidWarning")
  elseif suggestion.priority == "WARNING" then
    color = "FFFF00"
  elseif suggestion.priority == "INFO" then
    color = "00FF00"
  end
  
  -- DEFAULT_CHAT_FRAME:AddMessage("|cFF" .. color .. "[SquadAI]|r " .. suggestion.message) -- Disabled to prevent spam
  
  -- Send to TerrorMeter for display
  if TerrorMeter and TerrorMeter.integration then
    if TerrorMeter.integration.ReceiveSquadAISuggestion then
      TerrorMeter.integration.ReceiveSquadAISuggestion(suggestion)
    end
  end
  
  -- Broadcast to raid
  if UnitInRaid("player") or GetNumPartyMembers() > 0 then
    local channel = UnitInRaid("player") and "RAID" or "PARTY"
    local message = string.format("SQUADAI_SUGGEST:%s:%s", suggestion.type, suggestion.message)
    SendAddonMessage(INTEGRATION_CHANNEL, message, channel)
  end
end

-- ============================================
-- REGISTER INTEGRATION WITH TERRORMETER
-- ============================================

function TSA.RegisterIntegration(addonName, api)
  if addonName == "TerrorMeter" then
    bridge.terrorMeterDetected = true
    bridge.terrorMeterAPI = api
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[TerrorSquadAI]|r TerrorMeter registrado exitosamente")
  end
end

-- ============================================
-- PROVIDE DATA TO TERRORMETER
-- ============================================

-- TerrorMeter can call this to get AI suggestions
function TSA.GetCurrentSuggestion()
  return bridge.suggestions[1] -- Return most recent suggestion
end

-- TerrorMeter can call this to get threat predictions
function TSA.PredictThreat(playerName, seconds)
  local data = bridge.raidThreatData[playerName]
  if not data then return nil end
  
  -- Simple linear prediction based on current DPS
  local currentThreat = data.threat
  local dps = data.dps
  local predictedThreat = currentThreat + (dps * seconds)
  
  return predictedThreat
end

-- ============================================
-- ADDON MESSAGE HANDLER
-- ============================================

local function OnAddonMessage(prefix, message, channel, sender)
  if prefix ~= INTEGRATION_CHANNEL then return end
  
  -- Parse THREAT messages from TerrorMeter
  if string.find(message, "^THREAT:") then
    local parts = {}
    for part in string.gfind(message, "[^:]+") do
      table.insert(parts, part)
    end
    
    if table.getn(parts) >= 5 then
      local playerName = parts[2]
      local threat = tonumber(parts[3]) or 0
      local dps = tonumber(parts[4]) or 0
      local threatPercent = tonumber(parts[5]) or 0
      
      -- Store raid member threat data
      bridge.raidThreatData[playerName] = {
        threat = threat,
        threatPercent = threatPercent,
        dps = dps,
        timestamp = GetTime(),
      }
    end
  end
end

-- Register event handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function()
  if event == "CHAT_MSG_ADDON" then
    OnAddonMessage(arg1, arg2, arg3, arg4)
  end
end)

-- ============================================
-- ENHANCED THREAT PREDICTOR
-- ============================================

-- Override ThreatPredictor module with real data from TerrorMeter
if TSA.Modules and TSA.Modules.ThreatPredictor then
  local oldPredict = TSA.Modules.ThreatPredictor.PredictThreat
  
  TSA.Modules.ThreatPredictor.PredictThreat = function(arg1, arg2, arg3, arg4, arg5)
    -- Use TerrorMeter data if available
    if bridge.terrorMeterDetected and bridge.lastThreatData.threat then
      return bridge.lastThreatData.threat
    end
    
    -- Fall back to original prediction
    return oldPredict(arg1, arg2, arg3, arg4, arg5)
  end
end

-- ============================================
-- INITIALIZATION
-- ============================================

local function Initialize()
  DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[TerrorSquadAI]|r TerrorMeter Bridge cargado")
  
  -- Detect TerrorMeter after a short delay
  local initFrame = CreateFrame("Frame")
  initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  initFrame:SetScript("OnEvent", function()
    DetectTerrorMeter()
    this:UnregisterAllEvents()
  end)
end

Initialize()

-- ============================================
-- SLASH COMMANDS
-- ============================================

SLASH_TMBRIDGE1 = "/tmbridge"
SlashCmdList["TMBRIDGE"] = function(msg)
  if msg == "status" then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[TerrorMeter Bridge]|r Status:")
    DEFAULT_CHAT_FRAME:AddMessage("  TerrorMeter: " .. (bridge.terrorMeterDetected and "|cFF00FF00Detectado|r" or "|cFFFF0000No encontrado|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  Jugadores rastreados: " .. table.getn(bridge.raidThreatData))
    
    if bridge.lastThreatData.threat then
      DEFAULT_CHAT_FRAME:AddMessage("  Mi threat: " .. bridge.lastThreatData.threat .. " (" .. (bridge.lastThreatData.threatPercent or 0) .. "%)")
    end
  elseif msg == "data" then
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[Raid Threat Data]|r")
    for player, data in pairs(bridge.raidThreatData) do
      DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s: %d threat, %d DPS (%.1f%%)", 
        player, data.threat, data.dps, data.threatPercent or 0))
    end
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF6600[TerrorMeter Bridge]|r Comandos:")
    DEFAULT_CHAT_FRAME:AddMessage("  /tmbridge status - Ver estado de integración")
    DEFAULT_CHAT_FRAME:AddMessage("  /tmbridge data - Ver datos de threat del raid")
  end
end
