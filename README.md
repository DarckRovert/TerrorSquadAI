# TerrorSquadAI — v9.3.0 [God-Tier] 🛡️⚔️

**La Mente Maestra Táctica de "El Séquito del Terror"**

Sistema de IA de Squad avanzado que coordina todas las decisiones de combate del clan en tiempo real. Es el **Nexo Táctico** del ecosistema de addons: conecta a todos los jugadores, sus roles y los datos de combate en una red unificada.

- **Autor**: DarckRovert (Elnazzareno)
- **Versión**: 9.3.0 [God-Tier]
- **Compatibilidad**: Turtle WoW 1.12 (Lua 5.0)

---

## 🌐 Integración con el Ecosistema Séquito

TerrorSquadAI es la **espina dorsal** de la red de addons. Contiene 8 puentes de comunicación directa con otros addons del clan:

| Bridge | Addon destino | Función |
|--------|---------------|---------|
| `WCSBrainBridge` | WCS_Brain | Recibe sugerencias de IA del Warlock |
| `TerrorMeterBridge` | TerrorMeter | Recibe datos de DPS/amenaza |
| `HealBotBridge` | HealBot | Coordina prioridades de sanación |
| `pfUIBridge` | pfUI | Personaliza la interfaz del clan |
| `pfQuestBridge` | pfQuest | Integra seguimiento de misiones |
| `AtlasBridge` | Atlas-TW | Coordina mapas de dungeons |
| `AuxTradingBridge` | aux-addon | Monitoriza la economía del clan |
| `DoTimerBridge` | DoTimer | Integra timers de DoT |

---

## 🚀 Módulos Principales (Core Systems)

| Módulo | Función |
|--------|---------|
| `AIEngine` | Motor de IA táctica en tiempo real |
| `ThreatAnalysis` | Análisis de amenaza del raid/party |
| `PredictiveSystem` | Predicción de threat, daño y recursos |
| `StrategicSuggestions` | Sugerencias tácticas por clase y situación |
| `BigWigsIntegration` | Integración nativa con BigWigs Bossmods |
| `AlertSystem` | Alertas visuales y sonoras anti-spam |
| `CommunicationSync` | Sincronización de datos entre jugadores |
| `SquadCoordination` | Coordinación de acciones entre miembros |

---

## 🧠 Módulos de Inteligencia y Coordinación

- **AutoMarker** — Marcado automático de objetivos con raid marks
- **CooldownTracker** — Rastrea cooldowns importantes del grupo
- **FocusFireCoordinator** — Fuego concentrado coordinado (`/tsa focus next`)
- **InterruptCoordinator** — Coordinación de interrupciones (Lua 5.0 compatible)
- **PositionOptimizer** — Sugerencias de posicionamiento táctico
- **SmartTargeting** — Targeteo inteligente con prioridades por clase
- **TacticalPings** — 7 tipos de pings tácticos en el mapa
- **ThreatPredictor** — Predice threat futuro basado en DPS actual

---

## 🆕 Módulos v3.0 — Conciencia de Situación

- **DeathWatcher** — Auto-target cuando tu objetivo muere (`/tsa autotarget`)
- **CriticalHealthMonitor** — Alertas cuando Tanks/Healers bajan de 30% HP
- **PvPScorecard** — K/D, KDA, kill streaks, estadísticas de por vida (`/tsa score`)
- **CastingBarHook** — Detecta casts prioritarios (Heal, CC, Pyroblast...)
- **BuffMonitor** — Alerta de buffs faltantes en raid (Fort, MotW, Kings...)
- **WipePredictor** — Predictor de wipe con fórmula de riesgo 0-100% (`/tsa wipe`)
- **TerrorTactics** — 6 tácticas coordinadas (`alpha`, `burst`, `scatter`, `retreat`...)
- **BossTimerLite** — Timers de bosses sin necesidad de BigWigs (MC, BWL, Naxx...)

---

## 🌍 Módulos v4.0 — Warlord's Command

- **TerrorBoard** — Pizarra táctica holográfica con estética "Glass Obsidian" (`/board`)
- **TacticalRadar** — HUD con flechas hacia targets fuera de pantalla
- **EnemyCooldowns** — Rastrea CD enemigos PvP (Blink, Divine Shield, Vanish...)
- **KillFeed** — Feed de asesinatos estilizado con sonidos de racha
- **TerrorNet** — Red de comunicación avanzada entre miembros del clan
- **SquadMind** — Mente colectiva del escuadrón

---

## 🗺️ Módulos v7.x — Tactical Warfare

### TerrorScenes (10 Grand Slots × 4 Escenas = 40 Tácticas)
Sistema de snapshots para guardar y sincronizar posiciones del tablero táctico. Hasta **40 tácticas** almacenables organizadas en 10 bancos con sub-menú desplegable.

### TacticalMap
Motor de proyección con 4 punteros simultáneos en tiempo real (30fps).

### TerrorBoard v3.0
Pizarra interactiva de alta definición con sincronización en tiempo real hacia toda la banda.

---

## 🐢 Módulos Turtle WoW Exclusivos

- **TurtleModules/Core** — Loader inteligente para zonas custom de Turtle WoW
- **TurtleModules/EmeraldSanctum** — Alertas de bosses del Emerald Sanctum
- **TurtleModules/LowerKarazhan** — Soporte para Lower Karazhan
- **WarLogistics** — Verifica consumibles al entrar en raid (Velas, Shards, Pociones...)

---

## 📊 Estadísticas del Addon

| Métrica | Valor |
|---------|-------|
| Total módulos activos | **45+** |
| Bridges de integración | **8** |
| Localizaciones soportadas | **2** (esES/esMX + enUS) |
| Líneas de código | **~25,000+** |
| Bosses con timers | **12** (MC, Onyxia, BWL, AQ, Naxx) |

---

## 🎮 Comandos Clave

```
/tsai               — Abre el panel central de TerrorSquadAI
/tsai status        — Estado de la red Séquito y módulos
/tsai config        — Configuración avanzada de módulos
/tsa tactic alpha   — Todos al objetivo marcado con Skull
/tsa tactic burst   — Usar todos los cooldowns ofensivos
/tsa focus next     — Siguiente objetivo de fuego concentrado
/tsa wipe           — Ver predicción de wipe
/tsa score          — Ver estadísticas de PvP
/tsa buffs          — Ver buffs faltantes en el raid
/tsa boss           — Ver timers de boss activos
/board              — Abrir pizarra táctica holográfica
```

---

## 🔧 Instalación

1. Descarga el addon desde el repositorio del clan.
2. Coloca la carpeta `TerrorSquadAI` en `Interface/AddOns/`.
3. Reinicia o recarga la interfaz con `/reload`.
4. Usa `/tsai status` para verificar que todos los módulos cargan.

**Dependencias opcionales**: BigWigs, pfQuest.

---

*Creado por DarckRovert para "El Séquito del Terror" — Turtle WoW.*
*Ver `MODULES.md` para documentación detallada de cada módulo.*
*Ver `COMMANDS.md` para la lista completa de comandos.*
