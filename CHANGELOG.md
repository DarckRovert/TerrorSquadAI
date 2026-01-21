# 📋 TerrorSquadAI - Changelog

Historial de cambios y versiones de TerrorSquadAI.

---

## 🔧 Versión 4.1.1 - Stability Release (Enero 2026)

### 🎯 Cambio Principal
**Estabilidad total y limpieza de código**. Auditoría completa de funcionalidad, verificación de todos los checkboxes, y organización del proyecto.

### 🛠️ Mejoras

| Cambio | Descripción |
|--------|-------------|
| **Auditoría completa** | Verificados 14 módulos para asegurar que checkboxes controlen funcionalidad real |
| **SetPoint fix** | Corregido error en `EnemyCooldowns.lua` línea 158 |
| **Config:Toggle()** | Agregada función faltante para abrir/cerrar config |
| **Comando /tsa config** | Agregado comando para abrir configuración |
| **Limpieza** | Archivos no usados movidos a `Modules/_unused` |

### 🐛 Bugs Corregidos

| Módulo | Bug |
|--------|-----|
| `EnemyCooldowns` | Error de SetPoint con argumentos incompletos |
| `Config` | Función Toggle() no existía |
| `Commands` | Faltaba comando `/tsa config` |

---

## 🌟 Versión 4.1.0 - Guild Ready (Enero 2026)

### 🎯 Cambio Principal
**Estabilidad y pulido**. Esta versión se enfocó en corrección de bugs.

### 🐛 Bugs Corregidos

| Módulo | Bug |
|--------|-----|
| `AlertSystem` | Aceptaba solo tablas, ahora acepta strings también |
| `WarLogistics` | Llamaba a función inexistente `ScheduleTask` |
| `EnemyCooldowns` | Acceso a nil después de limpiar `bar.data` |
| `TacticalRadar` | Evento `PLAYER_FOCUS_CHANGED` no existe en Vanilla |
| `AIEngine` | División por cero en cálculos de salud/maná |
| `ThreatAnalysis` | División por cero en `SafeHealthPercent` |
| `ThreatPredictor` | División por cero en cálculos de amenaza |
| `SmartTargeting` | Múltiples divisiones por cero corregidas |


---

## ⚔️ Versión 4.0.0 - Warlord's Command (Enero 2026)

### 🎯 Cambio Principal
**Expansión masiva para PvP y Contenido Turtle WoW**. 6 módulos nuevos enfocados en inteligencia enemiga y soporte específico para el servidor custom.

### 🆕 Nuevos Módulos

#### Phase 1: PvP Dominance
| Módulo | Descripción |
|--------|-------------|
| **EnemyCooldowns** | Rastrea habilidades enemigas críticas (Blink, Ice Block, Vanish) via Combat Log. Muestra barras de tiempo. |
| **TacticalRadar** | HUD 3D que muestra la dirección de objetivos (Líder, Focus, Target) que están fuera de tu campo de visión. |
| **KillFeed** | Sistema de mensajes de muerte estilizados ("shooter style") con sonidos de racha. |

#### Phase 2: Turtle WoW PvE
| Módulo | Descripción |
|--------|-------------|
| **TurtleCore** | Sistema base para cargar módulos específicos de zonas custom. |
| **EmeraldSanctum** | Timers y alertas para la raid Emerald Sanctum (Solnius, Dreamscythe). |
| **LowerKarazhan** | Detección de mecánicas peligrosas en Lower Karazhan Halls. |

#### Phase 3: Logistics
| Módulo | Descripción |
|--------|-------------|
| **WarLogistics** | Escanea tu inventario al entrar en instancias y te avisa si te faltan reactivos o consumibles esenciales. |

### 🛠️ Cambios Técnicos
- Actualizado a Lua 5.0 compliant (`string.find` en lugar de `string.match` en nuevos módulos).
- Optimización del Core para carga condicional de módulos de Turtle WoW.

---

## 🚀 Versión 3.0.0 - Enhancement Suite (Enero 2026)

### 🎯 Cambio Principal

**8 nuevos módulos** que añaden funcionalidades avanzadas para PvP y PvE.

### 🆕 Nuevos Módulos

#### Phase 1: Quick Wins
| Módulo | Descripción |
|--------|-------------|
| **DeathWatcher** | Auto-target cuando tu objetivo muere. Usa SmartTargeting para encontrar el mejor siguiente objetivo. |
| **CriticalHealthMonitor** | Alertas cuando healers o tanks bajan de 30% HP. Escanea el grupo/raid cada 0.5 segundos. |

#### Phase 2: PvP Enhancements
| Módulo | Descripción |
|--------|-------------|
| **PvPScorecard** | Estadísticas completas de PvP: kills, deaths, assists, K/D ratio, rachas, enemigos más matados. Guarda stats de por vida. |
| **CastingBarHook** | Hook al TargetFrameSpellBar para detectar casts enemigos. Alerta en spells prioritarios (heals, CC). |

#### Phase 3: Raid Intelligence
| Módulo | Descripción |
|--------|-------------|
| **BuffMonitor** | Escanea buffs importantes faltantes en el raid (Fort, MotW, AI, Kings, Salv). Comando `/tsa buffs` para ver estado. |
| **WipePredictor** | Analiza HP del raid, muertes recientes, estado de healers/tank para predecir wipes. Alerta cuando riesgo > 70%. |

#### Phase 4: Advanced Systems
| Módulo | Descripción |
|--------|-------------|
| **TerrorTactics** | 6 tácticas predefinidas que coordinan múltiples módulos: Alpha Focus, Healer Hunt, Scatter, Retreat, Defensive, Burst. |
| **BossTimerLite** | Timers simples para bosses de MC, Onyxia, BWL, AQ40, Naxx sin depender de BigWigs. |

### 📝 Nuevos Comandos

```
/tsa score           - Estadísticas PvP de sesión
/tsa score reset     - Reiniciar sesión
/tsa score lifetime  - Stats totales de por vida

/tsa buffs           - Ver buffs faltantes en raid

/tsa wipe            - Estado del predictor de wipe

/tsa tactic alpha    - Todos al target con Skull
/tsa tactic healer   - Priorizar healers enemigos
/tsa tactic scatter  - Dispersión para AoE
/tsa tactic retreat  - Retirada táctica
/tsa tactic burst    - Usar cooldowns ofensivos

/tsa boss            - Listar bosses disponibles
/tsa boss Ragnaros   - Iniciar timers de Ragnaros

/tsa health          - Estado del monitor de HP
/tsa autotarget      - Estado del auto-target
```

### 🛠️ Archivos Modificados

**Core.lua**
- Versión actualizada a 3.0.0
- Init order actualizado con 8 nuevos módulos
- Mensajes de inicio consolidados (menos spam)

**Commands.lua**
- Nuevos comandos para todos los módulos v3.0
- Help actualizado con categorías

**TerrorSquadAI.toc**
- Versión 3.0.0
- 8 nuevos archivos registrados

### 📊 Estadísticas v3.0

- **Módulos totales**: 33 (+ 2 bridges)
- **Módulos nuevos**: 8
- **Comandos nuevos**: 12+
- **Líneas de código nuevo**: ~2,000

---

## 🔇 Versión 2.3.0 - Sistema de Alertas Sin Spam (Enero 2026)

### 🎯 Cambio Principal

**Problema resuelto:** Spam excesivo de mensajes en el chat del grupo/raid

**Solución implementada:**
- ✅ Alertas ahora son **solo visuales y sonoras** por defecto
- ✅ Mensajes automáticos al chat del grupo/raid **desactivados**
- ✅ Sincronización entre addons sigue funcionando (invisible)
- ✅ Comandos `/tsa` funcionan correctamente

### 🛠️ Archivos Modificados

**Core.lua**
- Separación de funciones `Print()` y `Alert()`

**FocusFireCoordinator.lua**
- Usa `AlertSystem:ShowAlert()` para alertas visuales

**TacticalPings.lua**
- Mensajes de ping envueltos en condicional

---

## 🎉 Versión 2.0 - Terror Ecosystem (Enero 2026)

### 🎆 Características Principales

#### Sistema de Integraciones
- ✅ Integración con TerrorMeter (threat/DPS)
- ✅ Integración con DoTimer (DoTs)
- ✅ Integración con BigWigs (bosses)

#### Sistema de IA
- ✅ AIEngine, ThreatAnalysis, ThreatPredictor
- ✅ PredictiveSystem, StrategicSuggestions
- ✅ Sugerencias por clase

#### Coordinación
- ✅ SquadCoordination, FocusFireCoordinator
- ✅ InterruptCoordinator, AutoMarker
- ✅ TacticalPings, SmartTargeting

#### UI
- ✅ UI renovada, UITheme, StatusPanel
- ✅ Alertas visuales mejoradas

### 📊 Estadísticas v2.0
- **Módulos totales**: 27
- **Líneas de código**: ~15,000+

---

## 🌟 Versión 1.0 - Release Inicial (2025)

### Características Iniciales
- ✅ Sistema básico de comandos
- ✅ Marcado de objetivos
- ✅ Fuego concentrado básico
- ✅ Pings tácticos

---

## 📊 Changelog Summary

| Versión | Fecha | Cambios Principales |
|---------|-------|---------------------|
| 3.0.0 | Enero 2026 | 8 nuevos módulos, Terror Tactics, PvP Scorecard, Boss Timers |
| 2.3.0 | Enero 2026 | Sistema de alertas sin spam, alertas visuales |
| 2.0 | Enero 2026 | Terror Ecosystem, Integraciones, IA, 27 módulos |
| 1.0 | 2025 | Release inicial |

---

**TerrorSquadAI** - Evolucionando la coordinación táctica en WoW Vanilla

Última actualización: Enero 2026
