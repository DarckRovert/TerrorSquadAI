# 🔗 TerrorSquadAI - Integraciones

**Versión 4.2.0** - God-Tier Visual Edition

TerrorSquadAI se integra con múltiples addons para crear un ecosistema táctico completo.

## 📋 Índice

- [Terror Ecosystem](#terror-ecosystem)
- [Integración con TerrorMeter](#integración-con-terrormeter)
- [Integración con DoTimer](#integración-con-dotimer)
- [Integración con BigWigs](#integración-con-bigwigs)
- [🆕 BossTimerLite (v3.0)](#-bosstimerlite-v30)
- [Sincronización entre Jugadores](#sincronización-entre-jugadores)
- [Configuración](#configuración)
- [Comunicación entre Jugadores (v2.3.0)](#comunicación-entre-jugadores-v230)
- [Solución de Problemas](#solución-de-problemas)

---

## 🆕 BossTimerLite (v3.0)

**Nuevo en v3.0**: Si no tienes BigWigs instalado, TerrorSquadAI ahora incluye su propio sistema de boss timers.

### ¿Qué es BossTimerLite?

Un sistema simple de timers para bosses que no requiere BigWigs:

- Timers para habilidades importantes de bosses
- Alertas 5 segundos antes de cada habilidad
- Frame movible en pantalla
- Detecta boss automáticamente por nombre

### Bosses Soportados

| Raid | Bosses |
|------|--------|
| Molten Core | Ragnaros, Majordomo, Golemagg |
| Onyxia's Lair | Onyxia |
| Blackwing Lair | Chromaggus, Nefarian |
| AQ40 | C'Thun |
| Naxxramas | Kel'Thuzad |

### Comandos

```
/tsa boss              # Listar bosses disponibles
/tsa boss Ragnaros     # Iniciar timers de Ragnaros
/tsa timer             # Alias de /tsa boss
```

### ¿BossTimerLite o BigWigs?

| Característica | BossTimerLite | BigWigs |
|----------------|---------------|---------|
| Instalación | Incluido en TerrorSquadAI | Separado |
| Bosses | 8 principales | Todos |
| Complejidad | Simple | Completo |
| Integración TSA | Nativa | Via hooks |

**Recomendación**: Usa BossTimerLite para raids casuales. Usa BigWigs para raids serios/competitivos.

---

## 🌐 Terror Ecosystem

El **Terror Ecosystem** es un conjunto de addons que trabajan juntos para proporcionar:

- **Análisis de combate en tiempo real**
- **Alertas inteligentes de threat**
- **Coordinación de raid/party**
- **Sugerencias tácticas automáticas**

### Componentes del Ecosystem

```
┌─────────────────────────────────────────────────────────────┐
│                    TERROR ECOSYSTEM                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐ │
│  │ TerrorMeter  │◄──►│TerrorSquadAI │◄──►│   BigWigs    │ │
│  │              │    │              │    │              │ │
│  │ • DPS/HPS    │    │ • IA Táctica │    │ • Boss Mods  │ │
│  │ • Threat     │    │ • Alertas    │    │ • Timers     │ │
│  │ • Sync       │    │ • Coord.     │    │ • Fases      │ │
│  └──────────────┘    └──────────────┘    └──────────────┘ │
│         ▲                    ▲                             │
│         │                    │                             │
│         │            ┌──────────────┐                      │
│         └───────────►│   DoTimer    │                      │
│                      │              │                      │
│                      │ • DoTs       │                      │
│                      │ • Debuffs    │                      │

---

## 📡 Comunicación entre Jugadores (v2.3.0)

### Sistema de Comunicación Invisible

Desde la versión 2.3.0, TerrorSquadAI separa la comunicación en dos tipos:

**1. Comunicación Invisible (Sincronización)**
- Usa canales de addon (ADDON channel)
- No aparece en el chat del grupo/raid
- Sincroniza objetivos de Focus Fire
- Sincroniza pings tácticos
- Sincroniza formaciones
- **Siempre activa** (no se puede desactivar)

**2. Mensajes Visibles (Chat)**
- Aparecen en el chat del grupo/raid
- Todos los miembros los ven
- **Desactivados por defecto** para evitar spam
- Se pueden activar con `/tsachat`

### ¿Por qué esta separación?

Antes de v2.3.0, cada alerta generaba mensajes en el chat, causando spam. Ahora:
- **Tú ves:** Alertas visuales grandes en pantalla + sonidos
- **Otros jugadores con el addon:** Reciben sincronización invisible
- **Chat del grupo:** Limpio, sin spam

### Ejemplo de Flujo

```
Jugador A (TerrorSquadAI)          Jugador B (TerrorSquadAI)
        │                                      │
        │  1. Marca objetivo "Vilemusk"       │
        │     (Focus Fire)                    │
        │                                      │
        ├────── ADDON CHANNEL ───────────►│
        │     (invisible)                     │
        │                                      │
        │                                      │  2. Recibe sincronización
        │                                      │     (invisible)
        │                                      │
        │                                      │  3. Muestra alerta visual:
        │                                      │     "🔴 FOCO: Vilemusk"
        │                                      │     (solo en su pantalla)
        │                                      │
        │                                      │
   CHAT DEL GRUPO: (vacío, sin spam)
```

### Módulos que usan Comunicación Invisible

1. **FocusFireCoordinator.lua**
   - `BroadcastTarget(name)` - Sincroniza objetivo de Focus Fire
   - Otros jugadores reciben el objetivo pero NO ven mensaje en chat

2. **TacticalPings.lua**
   - `SendPing(type, x, y)` - Sincroniza pings tácticos
   - Pings de atacar, defender, ayuda, peligro, retirada

3. **CommunicationSync.lua**
   - `SendMessage(type, data)` - Sistema general de sincronización
   - Formaciones, estrategias, cooldowns

### Código de Ejemplo

```lua
-- Antes de v2.3.0 (generaba spam)
function AnnounceTarget(name)
    SendChatMessage("[Terror Squad] FOCO: " .. name, "RAID_WARNING")
end

-- Después de v2.3.0 (sin spam)
function AnnounceTarget(name)
    -- Alerta visual solo para el jugador
    AlertSystem:ShowAlert({
        type = "critical",
        message = "FOCO: " .. name,
        sound = true
    })
    
    -- Sincronización invisible con otros addons
    CommunicationSync:SendMessage("FOCUS_TARGET", {target = name})
    
    -- Chat solo si está habilitado (desactivado por defecto)
    if TerrorSquadAI.DB.chatMessagesEnabled then
        SendChatMessage("[Terror Squad] FOCO: " .. name, "RAID_WARNING")
    end
end
```


│                      └──────────────┘                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Integración con TerrorMeter

**Módulo**: `TerrorMeterBridge.lua`

### ¿Qué es TerrorMeter?

TerrorMeter es un addon de análisis de combate que rastrea:
- DPS/HPS en tiempo real
- **Threat REAL** con multiplicadores
- Sincronización entre jugadores del raid
- Alertas visuales de threat

### Flujo de Datos

```
TerrorMeter                    TerrorSquadAI
    │                               │
    │  1. Calcula threat            │
    │     (cada 2 segundos)         │
    │                               │
    ├──────────────────────────────►│
    │  SendThreatData()             │
    │  - player                     │
    │  - threat                     │
    │  - threatPercent              │
    │  - tank                       │
    │                               │
    │                               │  2. Analiza threat
    │                               │     (ThreatAnalysis)
    │                               │
    │                               │  3. Genera sugerencias
    │                               │     (StrategicSuggestions)
    │                               │
    │                               │  4. Muestra alertas
    │                               │     (AlertSystem)
    │                               │
    │◄──────────────────────────────┤
    │  Recibe sugerencias           │
    │  (opcional)                   │
    │                               │
```

### Datos Recibidos

TerrorSquadAI recibe de TerrorMeter:

```lua
{
  player = "NombreJugador",
  threat = 5420,           -- Threat absoluto
  threatPercent = 85,      -- % vs el tank
  tank = "NombreTank",     -- Tank actual
  timestamp = GetTime()
}
```

### Alertas Generadas

Basado en el threat recibido, TerrorSquadAI genera:

| Threat % | Nivel | Alerta | Sugerencia |
|----------|-------|--------|------------|
| < 70% | 🟢 Verde | Ninguna | Continúa DPS normal |
| 70-90% | 🟡 Amarillo | "Threat Alto" | "Reduce DPS ligeramente" |
| > 90% | 🔴 Rojo | "¡THREAT CRÍTICO!" | "Usa Soulshatter" (Warlock) |

### Sugerencias por Clase

**Warlock** (Threat > 90%):
- "Usa Soulshatter para reducir threat"
- "Deja de hacer DPS por 3 segundos"

**Mage** (Threat > 90%):
- "Usa Ice Block si es necesario"
- "Reduce DPS con wand"

**Rogue** (Threat > 90%):
- "Usa Vanish para resetear threat"
- "Activa Feint"

**Warrior DPS** (Threat > 90%):
- "Cambia a Defensive Stance temporalmente"

### Comandos Relacionados

```bash
# Ver estado de integración
/tsa status

# Activar/desactivar alertas de threat
/tsa toggle

# Ver threat actual
/tmi status  # (desde TerrorMeter)
```

### Configuración

```lua
-- En TerrorSquadAI
TerrorSquadAIDB = {
  alertsEnabled = true,        -- Alertas activadas
  threatThreshold = 90,        -- Umbral de alerta (%)
  chatAlerts = false,          -- Solo alertas visuales
}
```

---

## 🎯 Integración con DoTimer

**Módulo**: `DoTimerBridge.lua`

### ¿Qué es DoTimer?

DoTimer es un addon que rastrea DoTs (Damage over Time) y debuffs en objetivos.

### Flujo de Datos

```
DoTimer                        TerrorSquadAI
    │                               │
    │  DoTimer_Timers (tabla)       │
    │  [target][spell] = {          │
    │    endTime,                   │
    │    duration                   │
    │  }                            │
    │                               │
    │◄──────────────────────────────┤
    │                               │  1. Lee DoTs activos
    │                               │     (cada 15 segundos)
    │                               │
    │                               │  2. Detecta DoTs faltantes
    │                               │     (vs base de datos)
    │                               │
    │                               │  3. Detecta DoTs expirando
    │                               │     (< 3 segundos)
    │                               │
    │                               │  4. Genera sugerencias
    │                               │     (solo DoT más importante)
    │                               │
```

### DoTs Rastreados por Clase

**Warlock**:
- Corruption (Corrupción)
- Curse of Agony (Maldición de Agonía)
- Immolate (Inmolar)
- Siphon Life (Drenar Vida)

**Priest Shadow**:
- Shadow Word: Pain (Palabra de las Sombras: Dolor)
- Vampiric Embrace (Abrazo Vampírico)

**Druid Balance**:
- Moonfire (Fuego Lunar)
- Insect Swarm (Enjambre de Insectos)

**Druid Feral**:
- Rip (Desgarrar)

**Hunter**:
- Serpent Sting (Picadura de Serpiente)

**Rogue**:
- Rupture (Ruptura)
- Garrote (Garrote)

### Sistema de Prioridades

TerrorSquadAI solo sugiere el DoT **más importante** que falta:

1. **Corruption** (Warlock) - Más importante
2. **Curse of Agony** (Warlock)
3. **Shadow Word: Pain** (Priest)
4. **Moonfire** (Druid)
5. **Serpent Sting** (Hunter)

### Controles Anti-Spam

Para evitar spam de sugerencias:

1. **Cooldown de 30 segundos** entre sugerencias
2. **Solo en bosses/elites** (no en trash mobs)
3. **Delay de 2 segundos** al cambiar de objetivo
4. **Chequeo cada 15 segundos** (no constante)
5. **Solo alertas visuales** (no mensajes en chat)

### Comandos Relacionados

```bash
# Activar/desactivar sugerencias de DoTs
/tsadot toggle

# Ver estado y DoTs activos
/tsadot status

# Ver DoTs activos (desde TerrorMeter)
/tmi dots
```

### Ejemplo de Uso

**Situación**: Warlock peleando contra Ragnaros

1. Warlock aplica Corruption
2. DoTimerBridge detecta que falta Curse of Agony
3. Después de 30s cooldown, sugiere: "Aplica Curse of Agony"
4. Warlock aplica Curse of Agony
5. Corruption está por expirar (2s restantes)
6. Alerta: "Corruption expirando en 2s"

---

## 🎯 Integración con BigWigs

**Módulo**: `BigWigsIntegration.lua`

### ¿Qué es BigWigs?

BigWigs es un addon de boss mods que proporciona:
- Timers de habilidades de boss
- Alertas de mecánicas
- Detección de fases

### Flujo de Datos

```
BigWigs                        TerrorSquadAI
    │                               │
    │  BigWigs_OnBossEnable         │
    ├──────────────────────────────►│
    │                               │  1. Boss fight iniciado
    │                               │     - Activa modo boss
    │                               │     - Ajusta estrategia
    │                               │
    │  BigWigs_StartBar             │
    ├──────────────────────────────►│
    │  (habilidad de boss)          │  2. Habilidad detectada
    │                               │     - Prepara sugerencias
    │                               │
    │  BigWigs_Message              │
    ├──────────────────────────────►│
    │  (cambio de fase)             │  3. Cambio de fase
    │                               │     - Ajusta prioridades
    │                               │
    │  BigWigs_OnBossDisable        │
    ├──────────────────────────────►│
    │                               │  4. Boss derrotado
    │                               │     - Desactiva modo boss
    │                               │
```

### Eventos Escuchados

1. **BigWigs_OnBossEnable**: Boss fight iniciado
2. **BigWigs_OnBossDisable**: Boss fight terminado
3. **BigWigs_StartBar**: Habilidad de boss iniciada
4. **BigWigs_StopBar**: Habilidad de boss terminada
5. **BigWigs_Message**: Mensaje de BigWigs (fases, etc.)

### Ajustes Estratégicos

Cuando BigWigs detecta un boss, TerrorSquadAI:

1. **Aumenta frecuencia de chequeos** (cada 1s en lugar de 2s)
2. **Prioriza alertas de threat** (más estricto)
3. **Activa sugerencias de cooldowns** defensivos
4. **Coordina interrupciones** de casteos importantes

### Ejemplo: Ragnaros

**Fase 1** (100-50% HP):
- Prioridad: Mantener DoTs
- Alertas de threat normales

**Fase 2** (50-0% HP):
- Prioridad: Burst DPS
- Alertas de threat más estrictas (umbral 85% en lugar de 90%)
- Sugerencias de cooldowns ofensivos

### Configuración

```lua
TerrorSquadAIDB = {
  bigWigsIntegration = true,   -- Integración activada
  bossMode = {
    stricterThreat = true,     -- Threat más estricto en bosses
    cooldownSuggestions = true -- Sugerir cooldowns
  }
}
```

---

## 🔄 Sincronización entre Jugadores

**Módulo**: `CommunicationSync.lua`

### Canal de Comunicación

TerrorSquadAI usa el canal de addon `"TerrorSquadAI"` para sincronizar:

- Objetivos de fuego concentrado
- Pings tácticos
- Marcas de objetivos
- Formaciones

### Datos Sincronizados

```lua
-- Fuego concentrado
{
  type = "FOCUS_TARGET",
  target = "Nombre del objetivo",
  sender = "NombreJugador"
}

-- Ping táctico
{
  type = "TACTICAL_PING",
  pingType = "attack",  -- attack, defend, retreat, etc.
  x = 123.45,
  y = 678.90,
  sender = "NombreJugador"
}

-- Marca de objetivo
{
  type = "AUTO_MARKER",
  target = "Nombre del objetivo",
  marker = 8,  -- 1-8 (Calavera, Cruz, etc.)
  sender = "NombreJugador"
}
```

### Requisitos

- Todos los jugadores deben tener TerrorSquadAI instalado
- Deben estar en el mismo raid/party
- Sincronización debe estar activada (`/tsa toggle`)

### Comandos de Sincronización

```bash
# Marcar objetivo para fuego concentrado
/tsa focus next

# Enviar ping táctico
/tsa ping attack

# Marcar objetivo automáticamente
/tsa marker toggle
```

---

## ⚙️ Configuración

### Activar/Desactivar Integraciones

```bash
# Ver estado de todas las integraciones
/tsa status

# Resultado:
# TerrorSquadAI v2.0
# Status: Enabled
# Integrations:
#   TerrorMeter: Detected ✓
#   DoTimer: Detected ✓
#   BigWigs: Detected ✓
```

### Configuración Manual

Editar `SavedVariables/TerrorSquadAI.lua`:

```lua
TerrorSquadAIDB = {
  enabled = true,
  
  -- Alertas
  alertsEnabled = true,
  chatAlerts = false,  -- Solo alertas visuales
  
  -- Sincronización
  syncEnabled = true,
  
  -- Integraciones
  bigWigsIntegration = true,
  
  -- Perfiles de alerta por clase
  alertProfiles = {
    WARLOCK = {
      threatThreshold = 90,
      dotReminders = true,
    },
    MAGE = {
      threatThreshold = 85,
      dotReminders = false,
    },
  },
}
```

---

## 🔧 Solución de Problemas

### TerrorMeter no detectado

**Síntoma**: `/tsa status` muestra "TerrorMeter: Not Found"

**Solución**:
1. Verificar que TerrorMeter esté instalado
2. Hacer `/reload` en WoW
3. Verificar que TerrorMeter esté activado en la lista de addons

### DoTimer no detectado

**Síntoma**: `/tsa status` muestra "DoTimer: Not Found"

**Solución**:
1. Verificar que DoTimer esté instalado
2. Hacer `/reload` en WoW
3. Verificar que DoTimer esté activado

### No recibo alertas de threat

**Síntoma**: No aparecen alertas visuales de threat

**Solución**:
1. Verificar que TerrorMeter esté sincronizando: `/tmi status`
2. Verificar que alertas estén activadas: `/tsa status`
3. Verificar que estés en combate
4. Verificar que tu threat sea > 70%

### Spam de sugerencias de DoTs

**Síntoma**: Demasiadas sugerencias de DoTs

**Solución**:
1. El sistema tiene cooldown de 30s, no debería hacer spam
2. Verificar que `chatAlerts = false` en configuración
3. Desactivar sugerencias de DoTs: `/tsadot toggle`

### BigWigs no detectado

**Síntoma**: `/tsa status` muestra "BigWigs: Not Found"

**Solución**:
1. Verificar que BigWigs esté instalado
2. BigWigs debe estar cargado (entra a una raid/dungeon)
3. Hacer `/reload` después de cargar BigWigs

### Sincronización no funciona

**Síntoma**: Otros jugadores no ven mis pings/marcas

**Solución**:
1. Verificar que todos tengan TerrorSquadAI instalado
2. Verificar que estén en el mismo raid/party
3. Verificar que sincronización esté activada: `/tsa status`
4. Verificar que no haya firewall bloqueando addon messages

---

## 📊 Beneficios de las Integraciones

### Con TerrorMeter

✅ **Alertas de threat en tiempo real**
- Evita pulls accidentales
- Optimiza DPS sin robar aggro
- Coordina burst DPS en raid

✅ **Sugerencias inteligentes**
- Usa Soulshatter en el momento correcto
- Reduce DPS cuando es necesario
- Maximiza DPS cuando es seguro

### Con DoTimer

✅ **Optimización de DoTs**
- Nunca olvides aplicar DoTs importantes
- Maximiza uptime de DoTs
- Aumenta DPS total en ~10-15%

✅ **Alertas de expiración**
- Reaplica DoTs antes de que expiren
- Evita downtime de DoTs

### Con BigWigs

✅ **Estrategia adaptativa**
- Ajusta prioridades según fase del boss
- Sugiere cooldowns en momentos críticos
- Coordina interrupciones

✅ **Análisis de rendimiento**
- DPS por fase (vía TerrorMeter)
- Identifica fases problemáticas

### Sincronización de Raid

✅ **Coordinación mejorada**
- Fuego concentrado sincronizado
- Pings tácticos para comunicación rápida
- Marcas automáticas de objetivos

✅ **Eficiencia aumentada**
- Menos tiempo perdido en comunicación
- Kills más rápidos
- Menos wipes

---

## 📚 Recursos

- **Documentación completa**: Ver `README.md`
- **Comandos**: Ver `COMMANDS.md`
- **Módulos**: Ver `MODULES.md`
- **FAQ**: Ver `FAQ.md`
- **Terror Ecosystem**: Ver `../TERROR_ECOSYSTEM.md`

---

**TerrorSquadAI** - Integraciones inteligentes para coordinación táctica
