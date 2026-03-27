# Integración del Ecosistema — TerrorSquadAI v9.3.0

## Dependencias

| Addon | Tipo | Uso |
|---|---|---|
| **WCS_Brain** | Requerido | EventManager, ResourceManager, State global |
| **TerrorMeter** | Opcional | Métricas de DPS de mascotas en el medidor |
| **BigWigs** | Opcional | Cambio automático de formación en eventos de boss |
| **HealBot** | Opcional | Prioridad de soporte a healers en peligro |

## Diagrama de Flujo

`
[COMBAT_LOG_EVENT]
        │
        ▼
[WCS_Brain EventManager]  ← throttle 0.1s
        │
        ▼
[TerrorSquadAI Decision Engine]
        │
    ┌───┴───┐
    │       │
    ▼       ▼
[Pet AI] [Formation]
    │
    ▼
[TerrorMeter] → Actualiza DPS de mascota
`

## API Pública de Integración

### Desde otro addon, puedes llamar:

`lua
-- Forzar un modo de IA
TerrorSquadAI:SetMode("defensivo")

-- Consultar el modo actual
local modo = TerrorSquadAI:GetMode()

-- Obtener estadísticas de mascota
local stats = TerrorSquadAI:GetPetStats()
-- Retorna: { damage = n, heals = n, uptime = n, deaths = n }
`

## Eventos que TerrorSquadAI publica

| Evento | Cuándo | Parámetros |
|---|---|---|
| TSA_MODE_CHANGED | Al cambiar de modo | (oldMode, newMode) |
| TSA_FORMATION_CHANGED | Al cambiar formación | (newFormation) |
| TSA_PET_DIED | Al morir mascota | (petType, cause) |