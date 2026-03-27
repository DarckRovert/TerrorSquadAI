# Módulos de TerrorSquadAI v9.3.0

## Motor Principal

| Módulo | Archivo | Descripción |
|---|---|---|
| **Core** | TerrorSquadAI.lua | Punto de entrada, inicialización y orquestación |
| **State Machine** | TSA_StateMachine.lua | 8 estados de comportamiento con transiciones |
| **Decision Engine** | TSA_Decisions.lua | Árbol de decisiones para selección de acciones |
| **Formation** | TSA_Formations.lua | 6 formaciones tácticas con transición suave |
| **Target** | TSA_Targeting.lua | Priorización de objetivos en PvP y PvE |

## Integración

| Módulo | Archivo | Descripción |
|---|---|---|
| **Brain Bridge** | TSA_BrainBridge.lua | Comunicación con WCS_Brain |
| **Raid Sync** | TSA_RaidSync.lua | Sincronización con líder de raid |
| **Group Coord** | TSA_GroupCoord.lua | Coordinación entre múltiples mascotas |

## Estadísticas y Diagnóstico

| Módulo | Archivo | Descripción |
|---|---|---|
| **Stats** | TSA_Stats.lua | Recopilación de métricas de mascotas |
| **Logger** | TSA_Logger.lua | Log eventos para diagnóstico |
| **Dashboard** | TSA_Dashboard.lua | Vista de rendimiento en tiempo real |

## Localización

| Módulo | Archivo | Descripción |
|---|---|---|
| **ES Local** | locale_es.lua | Cadenas en español |
| **EN Local** | locale_en.lua | Cadenas en inglés (fallback) |

## Interfaz de Usuario

| Módulo | Archivo | Descripción |
|---|---|---|
| **Main Panel** | TSA_UI.lua | Panel principal |
| **Commands** | TSA_Commands.lua | Registro de comandos de chat |
| **Config** | TSA_Config.lua | Pantalla de configuración |