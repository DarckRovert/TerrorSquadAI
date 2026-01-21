# 🎮 TerrorSquadAI - Guía Completa de Comandos

**Versión 4.1.1** - Stability Release

Esta guía contiene todos los comandos disponibles en TerrorSquadAI con ejemplos de uso y casos prácticos.

## 📋 Índice

- [🆕 Configuración v4.0 (Warlord's Command)](#-configuración-v40-warlords-command)
- [🆕 Comandos v3.0 (Nuevos)](#-comandos-v30-nuevos)
- [Comandos Principales](#comandos-principales)
- [Comandos de Marcado](#comandos-de-marcado)
- [Comandos de Fuego Concentrado](#comandos-de-fuego-concentrado)
- [Comandos de Targeteo Inteligente](#comandos-de-targeteo-inteligente)
- [Comandos de Pings Tácticos](#comandos-de-pings-tácticos)
- [Comandos de Formaciones](#comandos-de-formaciones)
- [Comandos de Utilidades](#comandos-de-utilidades)
- [Comandos de Chat](#comandos-de-chat)
- [Ejemplos de Uso](#ejemplos-de-uso)
- [Macros Sugeridos](#macros-sugeridos)

---

## 🆕 Configuración v4.0 (Warlord's Command)

La mayoría de los módulos de la v4.0 son automáticos y no requieren comandos constantes. Se configuran a través del panel principal.

### Panel de Configuración
| Comando | Descripción |
|---------|-------------|
| `/tsa config` | Abrir panel de configuración general |

Desde este panel puedes activar/desactivar:
- **EnemyCooldowns**: Rastreador de CDs (Mage Blink, Paladin Bubble, etc.)
- **TacticalRadar**: Flechas 3D para objetivos
- **KillFeed**: Mensajes de muerte en pantalla
- **Turtle Modules**: Emerald Sanctum, Lower Karazhan, Logística

---

## 🆕 Comandos v3.0 (Nuevos)

### PvP Scorecard
| Comando | Descripción |
|---------|-------------|
| `/tsa score` | Ver estadísticas de PvP de la sesión actual |
| `/tsa score reset` | Reiniciar estadísticas de sesión |
| `/tsa score lifetime` | Ver estadísticas totales de por vida |
| `/tsa pvp` | Alias de `/tsa score` |

**Ejemplo de salida:**
```
=== PvP Scorecard (Sesión: 45 mins) ===
Kills: 12  Deaths: 5  Assists: 8
K/D: 2.40  KDA: 4.00
Racha actual: 3  Mejor racha: 5
HKs: 15
Enemigos más matados:
  1. PlayerName: 4 kills
  2. AnotherPlayer: 3 kills
```

---

### Buff Monitor
| Comando | Descripción |
|---------|-------------|
| `/tsa buffs` | Escanear y mostrar buffs faltantes en el raid |
| `/tsa buff` | Alias de `/tsa buffs` |

**Ejemplo de salida:**
```
=== Estado de Buffs del Raid ===
Fort: 3 sin buff
MotW: 2 sin buff
AI: 1 sin buff
```

---

### Terror Tactics
| Comando | Descripción |
|---------|-------------|
| `/tsa tactic` | Mostrar tácticas disponibles |
| `/tsa tactic alpha` | Fuego concentrado en target con Skull |
| `/tsa tactic healer` | Priorizar healers enemigos |
| `/tsa tactic scatter` | Dispersión para evitar AoE |
| `/tsa tactic retreat` | Retirada táctica |
| `/tsa tactic defensive` | Postura defensiva |
| `/tsa tactic burst` | Usar cooldowns ofensivos |
| `/tsa tactics` | Alias de `/tsa tactic` |

**Ejemplo:**
```
/tsa tactic alpha
[Tactics] Alpha Focus activada
```

---

### Boss Timers
| Comando | Descripción |
|---------|-------------|
| `/tsa boss` | Listar bosses disponibles |
| `/tsa boss Ragnaros` | Iniciar timers de Ragnaros |
| `/tsa timer` | Alias de `/tsa boss` |

**Bosses soportados:** Ragnaros, Majordomo, Golemagg, Onyxia, Chromaggus, Nefarian, C'Thun, Kel'Thuzad

---

### Wipe Predictor
| Comando | Descripción |
|---------|-------------|
| `/tsa wipe` | Ver estado del predictor de wipe |

**Ejemplo de salida:**
```
=== Wipe Predictor ===
En combate: Sí
Duración: 45 segundos
Riesgo actual: 35%
Muertes recientes: 1
```

---

### Health Monitor
| Comando | Descripción |
|---------|-------------|
| `/tsa health` | Ver estado del monitor de salud crítica |

---

### Auto-Target
| Comando | Descripción |
|---------|-------------|
| `/tsa autotarget` | Ver estado del auto-target |
| `/tsa autotarget toggle` | Activar/desactivar auto-target |
| `/tsa death` | Alias de `/tsa autotarget` |

---

## Comandos Principales

### `/tsa help`
**Descripción:** Muestra la lista completa de comandos disponibles.

**Uso:**
```
/tsa help
```

**Salida:**
```
Comandos disponibles:
/tsa toggle - Activar/desactivar IA
/tsa status - Ver estado del addon
/tsa marker toggle - Activar/desactivar marcado automático
... (lista completa)
```

---

### `/tsa toggle`
**Descripción:** Activa o desactiva el sistema de IA de TerrorSquadAI.

**Uso:**
```
/tsa toggle
```

**Salida:**
```
Sistema IA: Activado
```
o
```
Sistema IA: Desactivado
```

**Cuándo usar:**
- Cuando quieres desactivar temporalmente las sugerencias de IA
- Durante combates donde prefieres control manual total
- Para reducir uso de recursos en situaciones no críticas

---

### `/tsa status`
**Descripción:** Muestra el estado actual del addon, incluyendo versión, módulos cargados y amenaza actual.

**Uso:**
```
/tsa status
```

**Salida:**
```
=== Estado de TerrorSquadAI ===
Versión: 2.3.0
IA: Activado
Módulos cargados: 27
Amenaza actual: 45%
```

**Información mostrada:**
- **Versión:** Versión actual del addon
- **IA:** Estado del sistema de IA (Activado/Desactivado)
Alertas: Solo visuales (chat desactivado)

- **Módulos cargados:** Número de módulos activos
- **Amenaza actual:** Nivel de threat actual (si estás en combate)

---

## Comandos de Marcado

### `/tsa marker toggle`
**Descripción:** Activa o desactiva el marcado automático de objetivos prioritarios.

**Uso:**
```
/tsa marker toggle
```

**Salida:**
```
Marcado automático: Activado
```

**Cómo funciona:**
- Marca automáticamente objetivos prioritarios con iconos de raid
- Prioriza: Healers > Casters > Melee > Tanks
- Solo funciona si eres líder de raid/grupo
- Útil para coordinar fuego concentrado en PvP y PvE

**Cuándo usar:**
- En PvP para marcar healers enemigos
- En dungeons para marcar objetivos peligrosos
- En raids para coordinar DPS en adds

---

## Comandos de Fuego Concentrado

### `/tsa focus next`
**Descripción:** Encuentra y marca el siguiente objetivo prioritario para fuego concentrado.

**Uso:**
```
/tsa focus next
```

**Salida:**
```
Buscando siguiente objetivo prioritario...
[TerrorSquadAI] Nuevo objetivo de fuego concentrado: [Nombre del objetivo]
```

**Prioridades:**
1. Healers enemigos
2. Casters de alto daño
3. Melee DPS
4. Tanks

**Cuándo usar:**
- Cuando el objetivo actual muere
- Para cambiar rápidamente a un objetivo más prioritario
- En PvP para coordinar kills

---

### `/tsa focus clear`
**Descripción:** Limpia el objetivo actual de fuego concentrado.

**Uso:**
```
/tsa focus clear
```

**Salida:**
```
[TerrorSquadAI] Objetivo de fuego concentrado limpiado
```

**Cuándo usar:**
- Cuando quieres que el grupo elija sus propios objetivos
- Al terminar un combate
- Para resetear el sistema de fuego concentrado

---

## Comandos de Targeteo Inteligente

### `/tsa target next`
**Descripción:** Cambia al siguiente objetivo inteligente basado en prioridades.

**Uso:**
```
/tsa target next
```

**Salida:**
```
Cambiando a siguiente objetivo inteligente...
```

**Prioridades del sistema:**
- Objetivos con baja salud (< 30%)
- Healers
- Casters
- Objetivos marcados
- Proximidad

**Cuándo usar:**
- Para cambiar rápidamente entre objetivos en combate
- Cuando tu objetivo actual muere
- Para encontrar el objetivo más eficiente

---

### `/tsa target prev`
**Descripción:** Cambia al objetivo anterior en la lista de targeteo inteligente.

**Uso:**
```
/tsa target prev
```

**Salida:**
```
Cambiando a objetivo anterior...
```

**Cuándo usar:**
- Si pasaste de largo el objetivo que querías
- Para volver a un objetivo específico

---

## Comandos de Pings Tácticos

### `/tsa ping <tipo>`
**Descripción:** Envía un ping táctico al grupo/raid para coordinar acciones.

**Tipos disponibles:**
- `atacar` - Señala un objetivo para atacar
- `defender` - Pide defensa de una posición
- `ayuda` - Solicita ayuda inmediata
- `peligro` - Advierte de peligro
- `reagrupar` - Pide reagruparse
- `retirada` - Ordena retirada táctica
- `posicion` - Marca una posición importante

**Uso:**
```
/tsa ping atacar
/tsa ping defender
/tsa ping ayuda
/tsa ping peligro
/tsa ping reagrupar
/tsa ping retirada
/tsa ping posicion
```

**Salida:**
```
[TerrorSquadAI] Ping enviado: ATACAR
```

**Cuándo usar cada tipo:**

**Atacar:**
- Cuando encuentras un objetivo prioritario
- Para coordinar burst damage
- En PvP para focus fire

**Defender:**
- Cuando necesitas defender una bandera (WSG, AB)
- Para proteger un healer
- En dungeons para defender una posición

**Ayuda:**
- Cuando estás siendo atacado por múltiples enemigos
- Si necesitas dispel/heal urgente
- Cuando estás en peligro de morir

**Peligro:**
- Cuando detectas una emboscada
- Si ves un patrol peligroso
- Para advertir de mecánicas de boss

**Reagrupar:**
- Después de un wipe
- Para reorganizar el grupo
- Antes de un pull importante

**Retirada:**
- Cuando el combate está perdido
- Para evitar un wipe completo
- En PvP cuando estás en inferioridad numérica

**Posicion:**
- Para marcar un punto de encuentro
- Indicar dónde posicionarse para un boss
- Marcar una posición estratégica en PvP

---

## Comandos de Formaciones

### `/tsa formation <tipo>`
**Descripción:** Sugiere una formación táctica al grupo.

**Tipos disponibles:**
- `linea` - Formación en línea (para avanzar)
- `circulo` - Formación circular (para defender)
- `cuna` - Formación en cuña (para penetrar)
- `dispersion` - Formación dispersa (para AoE)

**Uso:**
```
/tsa formation linea
/tsa formation circulo
/tsa formation cuna
/tsa formation dispersion
```

**Salida:**
```
[TerrorSquadAI] Formación sugerida: LÍNEA
```

**Cuándo usar cada formación:**

**Línea:**
- Para avanzar en dungeons
- En battlegrounds para empujar
- Cuando necesitas visibilidad frontal

**Círculo:**
- Para defender una posición
- Proteger healers en el centro
- En PvP cuando estás rodeado

**Cuña:**
- Para penetrar líneas enemigas
- En PvP para romper formaciones
- Para avanzar rápidamente

**Dispersión:**
- Contra AoE enemigo
- Para evitar chain lightning
- En bosses con mecánicas de AoE

---

## Comandos de Utilidades

### `/tsa cooldowns`
**Descripción:** Muestra los cooldowns importantes del grupo (listos y en recarga).

**Uso:**
```
/tsa cooldowns
```

**Salida:**
```
=== Cooldowns del Grupo ===
LISTOS:
  [Jugador1] - Bloodlust (Shaman)
  [Jugador2] - Shield Wall (Warrior)
  
EN RECARGA:
  [Jugador3] - Divine Shield (45s restantes)
  [Jugador4] - Evocation (120s restantes)
```

**Información mostrada:**
- Cooldowns importantes listos para usar
- Cooldowns en recarga con tiempo restante
- Clase del jugador

**Cuándo usar:**
- Antes de un pull de boss
- Para coordinar cooldowns de raid
- Para saber qué recursos tienes disponibles

---

### `/tsa macros generate`
**Descripción:** Genera macros automáticos para tu clase.

**Uso:**
```
/tsa macros generate
```

**Salida:**
```
[TerrorSquadAI] Macros generados para tu clase
[TerrorSquadAI] Revisa tu panel de macros (/macro)
```

**Macros generados:**
- Macros generales (todos):
  - TSA_Toggle - Toggle del addon
  - TSA_FocusNext - Siguiente objetivo
  - TSA_Ping - Ping rápido
  
- Macros específicos por clase:
  - **Warrior:** Charge + Hamstring, Execute macro
  - **Rogue:** Sap macro, Kick + Gouge
  - **Mage:** Polymorph focus, Counterspell macro
  - **Priest:** Dispel macro, Fear macro
  - **Warlock:** Fear macro, Curse rotation
  - **Hunter:** Trap macro, Pet control
  - **Druid:** Shapeshifting macros, HoT rotation
  - **Paladin:** Blessing rotation, Cleanse macro
  - **Shaman:** Totem macros, Purge macro

**Cuándo usar:**
- Al instalar el addon por primera vez
- Cuando cambias de clase
- Para obtener macros optimizados

---

### `/tsa gnomo toggle`
**Descripción:** Activa o desactiva el modo Furia Gnómica (sistema de kill streaks para PvP).

**Uso:**
```
/tsa gnomo toggle
```

**Salida:**
```
Modo Furia Gnómica: Activado
```

**Qué hace:**
- Rastrea kills en PvP
- Muestra kill streaks (Double Kill, Triple Kill, etc.)
- Efectos visuales y sonoros
- Estadísticas de PvP

**Cuándo usar:**
- En battlegrounds
- En world PvP
- Para trackear tu rendimiento en PvP

---

### `/tsa panel toggle`
**Descripción:** Muestra u oculta el panel de estado en tiempo real.

**Uso:**
```
/tsa panel toggle
```

**Salida:**
```
Panel de estado mostrado
```
o
```
Panel de estado ocultado
```

**Información del panel:**
- Estado del addon
- Amenaza actual
- Miembros del escuadrón conectados
- Efectividad del grupo
- Escenario de combate actual

**Cuándo usar:**
- Para ver información en tiempo real durante combate
- Para monitorear el estado del grupo
- Para ocultar el panel si molesta

---

## Comandos de Chat

### `/tsachat`
**Descripción:** Activa o desactiva los mensajes de TerrorSquadAI en el chat.

**Uso:**

**NOTA v2.3.0:** Los mensajes de chat están **desactivados por defecto** para evitar spam. Las alertas visuales y sonoras siguen funcionando normalmente.

```
/tsachat
```

**Salida:**
```
[TerrorSquadAI] Mensajes en chat: Activados
```
o
```
[TerrorSquadAI] Mensajes en chat: Desactivados
```

**Qué afecta:**
- Mensajes de sugerencias de IA
- Mensajes de coordinación
- Mensajes de alertas
- **NO afecta:** Alertas visuales (siguen funcionando)

**Cuándo usar:**
- Si los mensajes generan spam
- Para limpiar el chat durante raids
- Cuando solo quieres alertas visuales

---

## Ejemplos de Uso

### Ejemplo 1: Inicio de Raid
```
/tsa status                    # Verificar que todo está activo
/tsa cooldowns                 # Ver cooldowns disponibles
/tsa panel toggle              # Mostrar panel de estado
/tsa marker toggle             # Activar marcado automático
```

### Ejemplo 2: PvP en Battleground
```
/tsa gnomo toggle              # Activar kill streaks
/tsa formation dispersion      # Formación dispersa
/tsa ping atacar               # Marcar objetivo
/tsa focus next                # Siguiente objetivo prioritario
```

### Ejemplo 3: Dungeon Run
```
/tsa marker toggle             # Marcar objetivos
/tsa formation linea           # Formación en línea
/tsa target next               # Targeteo inteligente
```

### Ejemplo 4: Boss Fight
```
/tsa cooldowns                 # Ver cooldowns disponibles
/tsa formation circulo         # Formación defensiva
/tsa ping peligro              # Advertir de mecánica
```

### Ejemplo 5: Reducir Spam
```
/tsachat                       # Desactivar mensajes en chat
/tsa panel toggle              # Ocultar panel si molesta
```

---

## Macros Sugeridos

### Macro 1: Toggle Rápido
```
/tsa toggle
```
**Uso:** Activar/desactivar IA rápidamente

---

### Macro 2: Fuego Concentrado
```
/tsa focus next
/tsa ping atacar
```
**Uso:** Marcar siguiente objetivo y avisar al grupo

---

### Macro 3: Ayuda Urgente
```
/tsa ping ayuda
/y ¡AYUDA! Necesito heal/dispel
```
**Uso:** Pedir ayuda con ping y mensaje en /y

---

### Macro 4: Retirada Táctica
```
/tsa ping retirada
/raid RETIRADA - Salgan del combate
```
**Uso:** Ordenar retirada con ping y mensaje de raid

---

### Macro 5: Información Completa
```
/tsa status
/tsa cooldowns
```
**Uso:** Ver estado completo del addon y cooldowns

---

### Macro 6: Targeteo Rápido
```
/tsa target next
/startattack
```
**Uso:** Cambiar a siguiente objetivo y atacar automáticamente

---

### Macro 7: Formación Defensiva
```
/tsa formation circulo
/tsa ping defender
```
**Uso:** Cambiar a formación defensiva y avisar

---

### Macro 8: Formación Ofensiva
```
/tsa formation cuna
/tsa ping atacar
```
**Uso:** Cambiar a formación ofensiva y atacar

---

## 💡 Tips y Trucos

### Tip 1: Combina Comandos
Puedes crear macros que combinen múltiples comandos para acciones complejas.

### Tip 2: Keybinds
Asigna keybinds a los macros más usados:
- `F1` - `/tsa focus next`
- `F2` - `/tsa target next`
- `F3` - `/tsa ping atacar`

### Tip 3: Raid Leader
Si eres raid leader, usa:
- `/tsa marker toggle` para marcar objetivos
- `/tsa formation <tipo>` para coordinar posiciones
- `/tsa ping <tipo>` para comunicar tácticas

### Tip 4: Reduce Spam
Si el chat está muy lleno:
```
/tsachat                       # Desactivar mensajes
```
Las alertas visuales seguirán funcionando.

### Tip 5: Monitoreo Constante
Deja el panel activo durante raids:
```
/tsa panel toggle
```
Puedes moverlo arrastrándolo.

---

## 🔗 Ver También

- [README.md](README.md) - Guía principal del addon
- [MODULES.md](MODULES.md) - Documentación de módulos
- [INTEGRATION.md](INTEGRATION.md) - Integraciones con otros addons
- [FAQ.md](FAQ.md) - Preguntas frecuentes
- [CHANGELOG.md](CHANGELOG.md) - Historial de cambios

---

**¡Viva El Sequito del Terror!** ⚔️
