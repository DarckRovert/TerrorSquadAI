# 📦 TerrorSquadAI - Módulos

TerrorSquadAI está construido con una arquitectura modular que permite funcionalidades especializadas y fácil mantenimiento.

**Versión 6.3.0** - 45+ módulos activos + Bridges God-Tier

## 📋 Índice

- [Estadísticas de Módulos](#estadísticas-de-módulos)
- [🆕 Táctica v6.x (RaidMark Evolution)](#-táctica-v6x-raidmark-evolution)
- [🆕 Módulos v4.0 (Warlord's Command)](#-módulos-v40-warlords-command)
- [🆕 Módulos v3.0 (Nuevos)](#-módulos-v30-nuevos)
- [Módulos Principales](#módulos-principales)
- [Módulos de Inteligencia](#módulos-de-inteligencia)
- [Módulos de Coordinación](#módulos-de-coordinación)
- [Módulos de Integración](#módulos-de-integración)
- [Módulos de UI](#módulos-de-ui)
- [Módulos de Utilidades](#módulos-de-utilidades)
- [Arquitectura](#arquitectura)

---

## 📊 Estadísticas de Módulos

| Categoría | Cantidad |
|-----------|----------|
| **Total módulos activos** | 39 |
| **Bridges de integración** | 2 |
| **Módulos v4.0 (nuevos)** | 6 |
| **Módulos v3.0 (nuevos)** | 8 |
| **Líneas de código** | ~20,000+ |

### Desglose por Categoría

- **Core Systems**: 9 módulos
- **Enhanced Features**: 14 módulos
- **v4.0 New Features**: 6 módulos
- **v3.0 New Features**: 8 módulos
- **Integration Bridges**: 2 módulos (TerrorMeter, DoTimer)
- **UI**: 2 módulos

---

## 🆕 Módulos v4.0 (Warlord's Command)

### TerrorBoard.lua [GOD-TIER]
**Pizarra Táctica de Alta Definición**

- **Función**: Interfaz visual para posicionamiento estratégico en raid.
- **Características**:
  - Estética "Glass Obsidian" con efectos de escaneo holográfico.
  - Sistema de celdas con "Corner Brackets" reactivos.
  - Sincronización en tiempo real con otros miembros de la raid.
  - Action Bar consolidada para gestión rápida.
- **Acceso**: Click Derecho en botón de Minimapa o `/board`.

### EnemyCooldowns.lua
**Rastreador de Cooldowns Enemigos (PvP)**

- **Función**: Muestra cuándo enemigos cercanos usan habilidades clave
- **Características**:
  - Detecta Blink, Ice Block, Divine Shield, Vanish, etc.
  - Muestra barras de tiempo visuales sobre su estado
  - Alerta de oportunidad ("Mago sin Blink")
- **Configuración**: `/tsa config` (Toggle EnemyCD)
- **Tecnología**: Combat Log Parsing (pattern matching seguro Lua 5.0)

---

### TacticalRadar.lua
**HUD Táctico 3D**

- **Función**: Flechas direccionales en pantalla hacia objetivos
- **Características**:
  - Rastrea: Target actual, Líder de grupo, Focus
  - Indica dirección si están fuera de la pantalla
  - Colores únicos por tipo de objetivo
- **Configuración**: `/tsa config` (Toggle Radar)
- **Matemáticas**: Trigonometría con `GetPlayerMapPosition` y `GetPlayerFacing`

---

### KillFeed.lua
**Feed de Asesinatos Estilizado**

- **Función**: Mensajes gratificantes al matar enemigos
- **Características**:
  - Estilo shooter: `[Tú] 🔫 [Enemigo]`
  - Sonidos de racha
  - Mensajes para muertes aliadas
- **Configuración**: `/tsa config` (Toggle KillFeed)

---

### TurtleModules/Core.lua
**Soporte Nativo Turtle WoW**

- **Función**: Loader inteligente para módulos custom
- **Características**:
  - Detecta zonas custom de Turtle WoW
  - Carga módulos específicos solo cuando es necesario

---

### EmeraldSanctum.lua
**Módulo Raid: Emerald Sanctum**

- **Función**: Timers y alertas para bosses de ES
- **Bosses**:
  - **Solnius & Dreamscythe**: Alertas de Aliento, Miedo, Coletazo
- **Configuración**: Automático al entrar en zona

---

### WarLogistics.lua
**Logística de Guerra**

- **Función**: Asegura que el escuadrón esté preparado
- **Características**:
  - Alerta al visitar vendors si faltan componentes
  - Check automático al entrar a raid/instance
  - Rastrea: Velas, Polvo, Shards, Vendas, Pociones
- **Configuración**: `/tsa config` (Toggle Logistics)

---

## 🆕 Módulos v3.0 (Nuevos)

### DeathWatcher.lua
**Auto-Target cuando tu objetivo muere**

- **Función**: Detecta cuando tu target muere y automáticamente busca el siguiente objetivo
- **Características**:
  - Usa SmartTargeting para encontrar el mejor objetivo
  - Delay configurable antes de cambiar target
  - Solo activo en combate (configurable)
  - Alerta visual cuando cambia de objetivo
- **Comandos**: `/tsa autotarget`, `/tsa autotarget toggle`
- **Eventos**: UNIT_HEALTH, CHAT_MSG_COMBAT_HOSTILE_DEATH

---

### CriticalHealthMonitor.lua
**Alertas de salud crítica del grupo**

- **Función**: Alerta cuando healers o tanks bajan de 30% HP
- **Características**:
  - Escanea grupo/raid cada 0.5 segundos
  - Prioriza healers (Priest, Paladin, Druid, Shaman)
  - Prioriza tanks (Warriors)
  - Cooldown de alertas por jugador (5s)
  - Alertas visuales y sonoras
- **Comandos**: `/tsa health`
- **Umbrales**: 30% crítico, 50% advertencia (para roles prioritarios)

---

### PvPScorecard.lua
**Estadísticas completas de PvP**

- **Función**: Rastrea y muestra estadísticas de PvP
- **Características**:
  - Kills, deaths, assists
  - K/D ratio y KDA
  - Kill streaks (racha actual y mejor)
  - Enemigos más matados (top 3)
  - Estadísticas de sesión y de por vida (lifetime)
  - Guarda en SavedVariables
- **Comandos**: `/tsa score`, `/tsa score reset`, `/tsa score lifetime`
- **Eventos**: CHAT_MSG_COMBAT_HOSTILE_DEATH, CHAT_MSG_COMBAT_HONOR_GAIN, PLAYER_DEAD

---

### CastingBarHook.lua
**Detección de casts enemigos**

- **Función**: Hook al TargetFrameSpellBar para detectar casts del target
- **Características**:
  - Detecta cuando el target está casteando
  - Obtiene nombre del spell
  - Alerta en spells prioritarios (heals, CC, big damage)
  - Integra con InterruptCoordinator
- **Comandos**: `/tsa cast` (status)
- **Spells prioritarios**: Heal, Greater Heal, Flash Heal, Polymorph, Fear, Pyroblast, etc.

---

### BuffMonitor.lua
**Monitor de buffs del raid**

- **Función**: Escanea y muestra buffs importantes faltantes
- **Características**:
  - Escanea cada 10 segundos (configurable)
  - Detecta buffs faltantes: Fort, MotW, AI, Kings, Salv, Spirit
  - Muestra quién necesita qué buff
  - Versiones en español e inglés de los spells
- **Comandos**: `/tsa buffs`
- **Buffs rastreados**:
  - Priest: Fortitude, Divine Spirit, Shadow Protection
  - Druid: Mark of the Wild, Thorns
  - Mage: Arcane Intellect
  - Paladin: Blessings (Might, Kings, Wisdom, Salvation)

---

### WipePredictor.lua
**Predictor de wipes**

- **Función**: Analiza estado del raid para predecir wipes
- **Características**:
  - Analiza HP promedio del raid (0-30 puntos de riesgo)
  - Cuenta muertes recientes (0-30 puntos)
  - Verifica HP del tank (0-20 puntos)
  - Verifica estado de healers (0-20 puntos)
  - Alerta cuando riesgo > 70%
  - Alerta crítica cuando riesgo > 90%
- **Comandos**: `/tsa wipe`
- **Fórmula de riesgo**: health_factor + death_factor + tank_factor + healer_factor (0-100%)

---

### TerrorTactics.lua
**Sistema de tácticas coordinadas**

- **Función**: Tácticas predefinidas que coordinan múltiples módulos
- **Tácticas disponibles**:
  | Táctica | Descripción |
  |---------|-------------|
  | `alpha` | Todos al target marcado con Skull |
  | `healer` | Priorizar healers enemigos |
  | `scatter` | Dispersión para evitar AoE |
  | `retreat` | Retirada táctica, reagrupar |
  | `defensive` | Postura defensiva, proteger healers |
  | `burst` | Usar todos los cooldowns ofensivos |
- **Comandos**: `/tsa tactic <nombre>`, `/tsa tactic` (lista)
- **Integra con**: AutoMarker, FocusFireCoordinator, TacticalPings, PositionOptimizer, SmartTargeting

---

### BossTimerLite.lua
**Timers de bosses sin BigWigs**

- **Función**: Timers simples para bosses comunes
- **Características**:
  - No requiere BigWigs
  - Detecta boss por nombre del target
  - Timers con advertencia 5s antes
  - Alertas visuales y sonoras
  - Frame movible
- **Comandos**: `/tsa boss`, `/tsa boss <nombre>`
- **Bosses soportados**:
  | Raid | Bosses |
  |------|--------|
  | MC | Ragnaros, Majordomo, Golemagg |
  | Onyxia | Onyxia |
  | BWL | Chromaggus, Nefarian |
  | AQ40 | C'Thun |
  | Naxx | Kel'Thuzad |

---

## 🎯 Módulos Principales

### AIEngine.lua
**Motor de Inteligencia Artificial**

- **Función**: Cerebro del addon, toma decisiones tácticas en tiempo real
- **Características**:
  - Análisis de situación de combate
  - Evaluación de prioridades de objetivos
  - Generación de sugerencias tácticas
  - Aprendizaje de patrones de combate
- **Comandos relacionados**: `/tsa status`, `/tsa toggle`

### AlertSystem.lua
**Sistema de Alertas Visuales y Sonoras**

- **Función**: Gestiona todas las alertas del addon
- **Características**:
  - Alertas visuales en pantalla
  - Alertas sonoras
  - Sistema de prioridades
  - Control anti-spam (30s cooldown)
  - Solo alertas visuales (chat desactivado por defecto)
- **Comandos relacionados**: `/tsachat`

### Config.lua
**Sistema de Configuración**

- **Función**: Gestiona configuraciones del addon
- **Variables guardadas**:
  - `TerrorSquadAIDB` - Base de datos principal
  - `TerrorSquadAICharDB` - Configuración por personaje (incluye PvP stats)

---

## 🧠 Módulos de Inteligencia

### PredictiveSystem.lua
- Predicción de threat futuro, daño entrante, recursos

### ThreatAnalysis.lua
- Análisis de threat del raid/party
- Integración con TerrorMeter

### ThreatPredictor.lua
- Predice threat futuro basado en DPS actual

### StrategicSuggestions.lua
- Sugerencias tácticas por clase

---

## 🤝 Módulos de Coordinación

### SquadCoordination.lua
- Coordinación de acciones entre miembros

### FocusFireCoordinator.lua
- Fuego concentrado coordinado
- Comandos: `/tsa focus next`, `/tsa focus clear`

### InterruptCoordinator.lua
- Coordinación de interrupciones (compatible WoW 1.12)

### AutoMarker.lua
- Marcado automático de objetivos

### TacticalPings.lua
- 7 tipos de pings tácticos

### SmartTargeting.lua
- Targeteo inteligente con prioridades

---

## 🔗 Módulos de Integración

### TerrorMeterBridge.lua
- Integración bidireccional con TerrorMeter
- **Nota**: No usa RegisterModule (bridge pattern)

### DoTimerBridge.lua
- Integración con DoTimer para DoTs
- **Nota**: No usa RegisterModule (bridge pattern)

### BigWigsIntegration.lua
- Integración con BigWigs para boss fights

### CommunicationSync.lua
- Sincronización de datos entre jugadores

---

## 🎨 Módulos de UI

### UI.lua
- Interfaz gráfica principal

### UITheme.lua
- Sistema de temas (Dark, Light, Custom)

### StatusPanel.lua
- Panel de estado en tiempo real

---

## 🛠️ Módulos de Utilidades

### CooldownTracker.lua
- Rastrea cooldowns importantes

### MacroGenerator.lua
- Genera macros por clase

### GnomoFury.lua
- Kill streaks y estadísticas PvP

### PerformanceTracker.lua
- Monitoreo de rendimiento

### ResourceMonitor.lua
- Monitor de recursos (mana, energía)

### PositionOptimizer.lua
- Sugerencias de posicionamiento

### VoiceCommands.lua
- Comandos de voz

---

## 🏗️ Arquitectura

### Orden de Inicialización (Core.lua)

```
1. UITheme
2. Core modules (AI, Threat, Predictive, Strategic, BigWigs, Alert, Comm, Squad)
3. Enhanced features (AutoMarker, Cooldown, GnomoFury, Pings, Panel, Focus, Interrupt, Position, Resource, Threat, Voice, Macro, Performance, SmartTarget)
4. v3.0 modules (DeathWatcher ... BossTimerLite)
5. v4.0 modules (EnemyCooldowns, TacticalRadar, KillFeed, TurtleCore, WarLogistics)
6. UI, Config
```

### Bridges (no en init order)

Los bridges `TerrorMeterBridge` y `DoTimerBridge` se auto-inicializan y no usan `RegisterModule()` porque verifican si el addon externo existe antes de activarse.

---

## 📊 Conteo Final de Módulos

```
Módulos con RegisterModule(): 33
Bridges sin RegisterModule(): 2
────────────────────────────
Total archivos Modules/:     35
```

---

**TerrorSquadAI v3.0.0** - Sistema modular de coordinación táctica para WoW Vanilla
