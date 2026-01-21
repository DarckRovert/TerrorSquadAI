-- PerformanceTracker.lua - Rastreador de Rendimiento del Addon

local PT = {}
TerrorSquadAI:RegisterModule("PerformanceTracker", PT)

-- Estado
PT.metrics = {
    memoryUsage = 0,
    cpuUsage = 0,
    updateCount = 0,
    eventCount = 0,
    messagesSent = 0,
    messagesReceived = 0,
}

PT.history = {
    memory = {},
    cpu = {},
    events = {},
}

PT.lastUpdate = 0
PT.updateInterval = 5
PT.maxHistorySize = 60

-- Configuración
PT.config = {
    enabled = true,
    trackMemory = true,
    trackCPU = true,
    trackEvents = true,
    warnHighUsage = true,
    memoryThreshold = 524288, -- KB (512 MB - umbral realista para WoW con múltiples addons)
    cpuThreshold = 100, -- Actualizaciones (aumentado para reducir falsos positivos)
}

function PT:Initialize()
    self:RegisterEvents()
    self:StartTracking()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[TerrorSquadAI]|r PerformanceTracker inicializado", 1, 0.84, 0)
end

function PT:RegisterEvents()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:SetScript("OnEvent", function()
        if event == "ADDON_LOADED" and arg1 == addonName then
            PT:OnAddonLoaded()
        end
        PT.metrics.eventCount = PT.metrics.eventCount + 1
    end)
end

function PT:StartTracking()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function()
        local now = GetTime()
        if now - PT.lastUpdate >= PT.updateInterval then
            PT:Update()
            PT.lastUpdate = now
        end
    end)
end

function PT:OnAddonLoaded()
    -- Inicializar tracking con APIs compatibles WoW 1.12
    self.metrics.memoryUsage = gcinfo()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[Performance]|r Tracker activo (usando gcinfo para memoria)", 0.5, 1, 0.5)
end

function PT:Update()
    if not self.config.enabled then return end
    
    self.metrics.updateCount = self.metrics.updateCount + 1
    
    if self.config.trackMemory then
        self:UpdateMemoryUsage()
    end
    
    if self.config.trackCPU then
        self:UpdateCPUUsage()
    end
    
    self:RecordHistory()
    self:CheckThresholds()
end

function PT:UpdateMemoryUsage()
    -- gcinfo() devuelve memoria total de Lua en KB (compatible WoW 1.12)
    self.metrics.memoryUsage = gcinfo()
end

function PT:UpdateCPUUsage()
    -- CPU profiling no disponible en WoW 1.12
    -- Rastrear actividad por número de actualizaciones como proxy
    -- Desactivado: no hay métrica real de CPU en WoW 1.12
    self.metrics.cpuUsage = 0
end

function PT:RecordHistory()
    local now = GetTime()
    
    -- Registrar memoria
    table.insert(self.history.memory, {
        time = now,
        value = self.metrics.memoryUsage
    })
    
    -- Registrar CPU
    table.insert(self.history.cpu, {
        time = now,
        value = self.metrics.cpuUsage
    })
    
    -- Registrar eventos
    table.insert(self.history.events, {
        time = now,
        value = self.metrics.eventCount
    })
    
    -- Mantener tamaño máximo
    while table.getn(self.history.memory) > self.maxHistorySize do
        table.remove(self.history.memory, 1)
    end
    while table.getn(self.history.cpu) > self.maxHistorySize do
        table.remove(self.history.cpu, 1)
    end
    while table.getn(self.history.events) > self.maxHistorySize do
        table.remove(self.history.events, 1)
    end
end

function PT:CheckThresholds()
    if not self.config.warnHighUsage then return end
    
    -- Advertir uso alto de memoria
    if self.metrics.memoryUsage > self.config.memoryThreshold then
        local lastWarn = self.lastMemoryWarn or 0
        if GetTime() - lastWarn > 60 then
            self.lastMemoryWarn = GetTime()
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF8800[Performance]|r Uso alto de memoria: %.2f MB", self.metrics.memoryUsage / 1024), 1, 0.5, 0)
        end
    end
    
    -- Advertir uso alto de CPU
    -- Desactivado: no hay métrica real de CPU en Vanilla
    if false and self.metrics.cpuUsage > self.config.cpuThreshold then
        local lastWarn = self.lastCPUWarn or 0
        if GetTime() - lastWarn > 60 then
            self.lastCPUWarn = GetTime()
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF8800[Performance]|r Uso alto de actualizaciones: %d", self.metrics.updateCount), 1, 0.5, 0)
        end
    end
end

function PT:GetMetrics()
    return {
        memory = self.metrics.memoryUsage,
        cpu = self.metrics.cpuUsage,
        updates = self.metrics.updateCount,
        events = self.metrics.eventCount,
        messagesSent = self.metrics.messagesSent,
        messagesReceived = self.metrics.messagesReceived,
    }
end

function PT:GetAverageMemory()
    if table.getn(self.history.memory) == 0 then return 0 end
    
    local total = 0
    for _, entry in ipairs(self.history.memory) do
        total = total + entry.value
    end
    
    return total / table.getn(self.history.memory)
end

function PT:GetAverageCPU()
    if table.getn(self.history.cpu) == 0 then return 0 end
    
    local total = 0
    for _, entry in ipairs(self.history.cpu) do
        total = total + entry.value
    end
    
    return total / table.getn(self.history.cpu)
end

function PT:GetPeakMemory()
    if table.getn(self.history.memory) == 0 then return 0 end
    
    local peak = 0
    for _, entry in ipairs(self.history.memory) do
        if entry.value > peak then
            peak = entry.value
        end
    end
    
    return peak
end

function PT:GetPeakCPU()
    if table.getn(self.history.cpu) == 0 then return 0 end
    
    local peak = 0
    for _, entry in ipairs(self.history.cpu) do
        if entry.value > peak then
            peak = entry.value
        end
    end
    
    return peak
end

function PT:IncrementMessagesSent()
    self.metrics.messagesSent = self.metrics.messagesSent + 1
end

function PT:IncrementMessagesReceived()
    self.metrics.messagesReceived = self.metrics.messagesReceived + 1
end

function PT:PrintStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Performance Tracker Status ===", 1, 0.84, 0)
    
    -- Uso actual
    DEFAULT_CHAT_FRAME:AddMessage("\n|cFF00FF00Uso Actual:|r", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Memoria: %.2f MB", self.metrics.memoryUsage / 1024), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("CPU: %.2f ms", self.metrics.cpuUsage), 1, 1, 1)
    
    -- Promedios
    DEFAULT_CHAT_FRAME:AddMessage("\n|cFF00FF00Promedios:|r", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Memoria: %.2f MB", self:GetAverageMemory() / 1024), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("CPU: %.2f ms", self:GetAverageCPU()), 1, 1, 1)
    
    -- Picos
    DEFAULT_CHAT_FRAME:AddMessage("\n|cFF00FF00Picos:|r", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("Memoria: %.2f MB", self:GetPeakMemory() / 1024), 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("CPU: %.2f ms", self:GetPeakCPU()), 1, 1, 1)
    
    -- Estadísticas
    DEFAULT_CHAT_FRAME:AddMessage("\n|cFF00FF00Estadísticas:|r", 0, 1, 0)
    DEFAULT_CHAT_FRAME:AddMessage("Actualizaciones: " .. self.metrics.updateCount, 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Eventos: " .. self.metrics.eventCount, 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Mensajes enviados: " .. self.metrics.messagesSent, 1, 1, 1)
    DEFAULT_CHAT_FRAME:AddMessage("Mensajes recibidos: " .. self.metrics.messagesReceived, 1, 1, 1)
end

function PT:PrintDetailedReport()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700=== Reporte Detallado de Rendimiento ===", 1, 0.84, 0)
    
    self:PrintStatus()
    
    -- Historial reciente
    DEFAULT_CHAT_FRAME:AddMessage("\n|cFF00FF00Historial Reciente (Memoria):|r", 0, 1, 0)
    local count = math.min(5, table.getn(self.history.memory))
    for i = table.getn(self.history.memory) - count + 1, table.getn(self.history.memory) do
        if self.history.memory[i] then
            local entry = self.history.memory[i]
            local elapsed = GetTime() - entry.time
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  %.0fs atrás: %.2f MB", elapsed, entry.value / 1024), 1, 1, 1)
        end
    end
    
    -- Comparación con otros addons
    DEFAULT_CHAT_FRAME:AddMessage("\n|cFF00FF00Top 5 Addons (Memoria):|r", 0, 1, 0)
    self:PrintTopAddons()
end

function PT:PrintTopAddons()
    -- GetAddOnMemoryUsage no existe en WoW 1.12
    DEFAULT_CHAT_FRAME:AddMessage("  Comparación de addons no disponible en WoW 1.12", 1, 1, 1)
end

function PT:ResetMetrics()
    self.metrics.updateCount = 0
    self.metrics.eventCount = 0
    self.metrics.messagesSent = 0
    self.metrics.messagesReceived = 0
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Performance]|r Métricas reiniciadas", 1, 0.84, 0)
end

function PT:ClearHistory()
    self.history.memory = {}
    self.history.cpu = {}
    self.history.events = {}
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Performance]|r Historial limpiado", 1, 0.84, 0)
end

function PT:ForceGarbageCollection()
    local before = self.metrics.memoryUsage
    collectgarbage("collect")
    
    -- Esperar un momento y actualizar
    self:UpdateMemoryUsage()
    local after = self.metrics.memoryUsage
    local freed = before - after
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD700[Performance]|r Garbage collection ejecutado. Liberados: %.2f MB", freed / 1024), 1, 0.84, 0)
end

function PT:Toggle()
    self.config.enabled = not self.config.enabled
    local status = self.config.enabled and "activado" or "desactivado"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Performance]|r " .. status, 1, 0.84, 0)
end

function PT:ToggleWarnings()
    self.config.warnHighUsage = not self.config.warnHighUsage
    local status = self.config.warnHighUsage and "activadas" or "desactivadas"
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Performance]|r Advertencias " .. status, 1, 0.84, 0)
end

function PT:SetMemoryThreshold(value)
    value = math.max(1024, value)
    self.config.memoryThreshold = value
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFFD700[Performance]|r Umbral de memoria: %.2f MB", value / 1024), 1, 0.84, 0)
end

function PT:SetCPUThreshold(value)
    value = math.max(10, value)
    self.config.cpuThreshold = value
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Performance]|r Umbral de CPU: " .. value .. " ms", 1, 0.84, 0)
end

function PT:GetHealthStatus()
    local status = "BUENO"
    local color = {0, 1, 0}
    
    if self.metrics.memoryUsage > self.config.memoryThreshold * 1.5 or self.metrics.cpuUsage > self.config.cpuThreshold * 1.5 then
        status = "CRÍTICO"
        color = {1, 0, 0}
    elseif self.metrics.memoryUsage > self.config.memoryThreshold or self.metrics.cpuUsage > self.config.cpuThreshold then
        status = "ADVERTENCIA"
        color = {1, 1, 0}
    end
    
    return status, color
end

function PT:PrintHealth()
    local status, color = self:GetHealthStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFD700[Performance]|r Estado de salud: " .. status, unpack(color))
end
