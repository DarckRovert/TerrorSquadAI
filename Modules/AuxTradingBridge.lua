-- TerrorSquadAI <-> AUX-Trading Bridge
-- Integration with Sequito Trading modules (ML Patterns, Monopoly)
-- Author: DarckRovert (elnazzareno)
-- For: El Sequito del Terror

local AuxTradingBridge = {}
TerrorSquadAI:RegisterModule("AuxTradingBridge", AuxTradingBridge)

AuxTradingBridge.auxDetected = false

function AuxTradingBridge:Initialize()
    -- Check for global API exposed in aux-addon\tabs\trading\integration.lua
    if AUX_TRADING_API then
        self.auxDetected = true
        TerrorSquadAI:Debug("AuxTrading Bridge initialized - Sequito AI Economy Link")
        
        -- Register a callback for price updates if supported
        if AUX_TRADING_API.RegisterCallback then
            AUX_TRADING_API.RegisterCallback("price_update", function(item_key, price)
                AuxTradingBridge:OnPriceUpdate(item_key, price)
            end)
        end
    end
end

function AuxTradingBridge:OnPriceUpdate(item_key, price)
    -- If it's a critical raid consumable, notify the squad
    -- (Simplified logic)
    if price and price < 100000 then -- e.g. Buyout alert
        -- TerrorSquadAI:Debug("Market opportunity detected for " .. item_key)
    end
end

function AuxTradingBridge:GetMarketSummary()
    if not self.auxDetected or not AUX_TRADING_API.GetDashboardData then return nil end
    
    local data = AUX_TRADING_API.GetDashboardData()
    if data then
        return {
            dailyProfit = data.profit_today or 0,
            activeSniper = AUX_TRADING_API.IsSniperRunning()
        }
    end
    return nil
end
