# ❓ TerrorSquadAI - Preguntas Frecuentes (FAQ)

**Versión 4.2.0** - God-Tier Remaster

Respuestas a las preguntas más comunes sobre TerrorSquadAI.

## 📋 Índice

- [🆕 Novedades v3.0](#-novedades-v30)
- [General](#general)
- [Instalación](#instalación)
- [Uso Básico](#uso-básico)
- [Integraciones](#integraciones)
- [Alertas y Sugerencias](#alertas-y-sugerencias)
- [Coordinación de Raid](#coordinación-de-raid)
- [Configuración](#configuración)
- [Problemas Comunes](#problemas-comunes)
- [Rendimiento](#rendimiento)
- [Avanzado](#avanzado)

---

## 🆕 Novedades v3.0

### ¿Qué hay de nuevo en v3.0?

8 nuevos módulos que añaden:
- **Auto-target** cuando tu objetivo muere
- **PvP Scorecard** con estadísticas de kills/deaths/K+D
- **Terror Tactics** - tácticas coordinadas predefinidas
- **Boss Timers** sin depender de BigWigs
- **Buff Monitor** para ver buffs faltantes
- **Wipe Predictor** para predecir wipes en raids
- **Cast Detection** para detectar casts enemigos
- **Health Monitor** para alertas de HP crítico
- **TerrorBoard (v4.2)** - Pizarra táctica de vidrio obsidiana con unified minimap access.

### ¿Cómo accedo a la Pizarra Táctica (TerrorBoard)?

Tienes dos formas rápidas:
1. **Minimap**: Haz **Click Derecho** en el botón de TerrorSquadAI del minimapa.
2. **Chat**: Escribe el comando `/board`.

### ¿Cómo activo/desactivo la IA ahora?

Para evitar botones extra, el toggle de la IA se ha movido:
- Presiona **Shift + Click Derecho** en el botón del minimapa.

### ¿Cómo veo mis estadísticas de PvP?

```
/tsa score
```

### ¿Cómo uso las nuevas tácticas?

```
/tsa tactic alpha    # Todos al target marcado
/tsa tactic healer   # Priorizar healers
/tsa tactic scatter  # Dispersión
/tsa tactic retreat  # Retirada
```

### ¿Cómo uso los boss timers?

```
/tsa boss Ragnaros   # Iniciar timers de Ragnaros
/tsa boss            # Ver bosses disponibles
```

## 🌟 General

### ¿Qué es TerrorSquadAI?

TerrorSquadAI es un addon de coordinación táctica para WoW Vanilla que proporciona:
- **Inteligencia artificial** para sugerencias tácticas
- **Alertas de threat** en tiempo real
- **Coordinación de raid/party** (fuego concentrado, pings, formaciones)
- **Integración con otros addons** (TerrorMeter, BigWigs, DoTimer)

### ¿Es compatible con Vanilla WoW?

Sí, TerrorSquadAI está diseñado específicamente para **WoW Vanilla 1.12.1** (Turtle WoW).

### ¿Funciona en TBC o WotLK?

No, está optimizado para Vanilla. Algunas funciones podrían no funcionar en expansiones.

### ¿Es legal usar este addon?

Sí, TerrorSquadAI solo usa APIs permitidas de WoW. No automatiza acciones del jugador ni modifica archivos del juego.

### ¿Necesito otros addons?

**No es obligatorio**, pero se recomienda instalar:
- **TerrorMeter** - Para alertas de threat
- **DoTimer** - Para sugerencias de DoTs
- **BigWigs** - Para estrategias de boss

---

## 📥 Instalación

### ¿Cómo instalo TerrorSquadAI?

1. Descarga el addon
2. Extrae la carpeta `TerrorSquadAI` en `Interface/AddOns/`
3. Reinicia WoW o haz `/reload`
4. Verifica con `/tsa status`

### ¿Dónde va la carpeta del addon?

```
WoW/
└── Interface/
    └── AddOns/
        └── TerrorSquadAI/
            ├── TerrorSquadAI.toc
            ├── Core.lua
            ├── Modules/
            └── ...
```

### ¿Necesito configurar algo después de instalar?

No, TerrorSquadAI funciona con configuración por defecto. Puedes personalizarlo con comandos.

### ¿Cómo actualizo el addon?

1. Descarga la nueva versión
2. Reemplaza la carpeta `TerrorSquadAI` completa
3. Haz `/reload` en WoW

---

## 🎮 Uso Básico

### ¿Cómo activo el addon?

El addon se activa automáticamente al cargar. Verifica con:
```bash
/tsa status
```

### ¿Cómo desactivo el addon temporalmente?

```bash
/tsa toggle
```

### ¿Cuáles son los comandos principales?

```bash
/tsa help          # Ver ayuda
/tsa status        # Ver estado
/tsa toggle        # Activar/desactivar
/tsa focus next    # Marcar objetivo
/tsa ping attack   # Enviar ping
```

Ver lista completa en `COMMANDS.md`.

### ¿Cómo veo el estado de las integraciones?

```bash
/tsa status
```

Resultado:
```
TerrorSquadAI v2.0
Status: Enabled
Integrations:
  TerrorMeter: Detected ✓
  DoTimer: Detected ✓
  BigWigs: Detected ✓
```

---

## 🔗 Integraciones

### ¿Qué es el Terror Ecosystem?

Es el conjunto de addons que trabajan juntos:
- **TerrorMeter** - DPS/HPS y threat
- **TerrorSquadAI** - IA táctica y coordinación
- **DoTimer** - Rastreo de DoTs
- **BigWigs** - Boss mods

Ver documentación completa en `TERROR_ECOSYSTEM.md`.

### ¿Necesito instalar todos los addons del ecosystem?

No, TerrorSquadAI funciona solo, pero las integraciones mejoran la experiencia.

### ¿Cómo sé si TerrorMeter está conectado?

```bash
/tsa status
```

Si muestra "TerrorMeter: Detected ✓", está conectado.

### TerrorMeter muestra "Not Found", ¿qué hago?

1. Verifica que TerrorMeter esté instalado
2. Haz `/reload`
3. Verifica que TerrorMeter esté activado en la lista de addons

### ¿Cómo funciona la integración con DoTimer?

TerrorSquadAI lee los DoTs activos de DoTimer y sugiere aplicar DoTs importantes que faltan.

### ¿Puedo desactivar las sugerencias de DoTs?

Sí:
```bash
/tsadot toggle
```

### ¿Cómo funciona la integración con BigWigs?

Cuando BigWigs detecta un boss, TerrorSquadAI:
- Ajusta estrategia según fase
- Aumenta frecuencia de alertas
- Sugiere cooldowns en momentos críticos

---

## 🚨 Alertas y Sugerencias

### ¿Qué tipos de alertas genera el addon?

1. **Alertas de threat** (🔴 Rojo, 🟡 Amarillo, 🟢 Verde)
2. **Alertas de DoTs expirando** (🔵 Azul)
3. **Sugerencias tácticas** (🟢 Verde)
4. **Alertas de cooldowns** (🟣 Morado)

### ¿Las alertas aparecen en el chat?

**No por defecto**. Solo alertas visuales en pantalla. Puedes activar mensajes en chat con:
```bash
/tsachat
```

**ACTUALIZADO v2.3.0:** Los mensajes de chat están desactivados por defecto para evitar spam. La comunicación entre addons (sincronización invisible) sigue funcionando.

### ¿Qué diferencia hay entre alertas visuales y mensajes de chat?

**Alertas visuales (v2.3.0+)**:
- Aparecen en pantalla como texto grande y colorido
- Incluyen sonidos de alerta
- Solo tú las ves
- No generan spam en el chat

**Mensajes de chat (desactivados por defecto)**:
- Aparecen en el chat del grupo/raid
- Todos los miembros los ven
- Pueden generar spam

### ¿Cómo funciona la comunicación entre addons?

TerrorSquadAI se comunica con otros jugadores mediante canales invisibles de addon que no aparecen en el chat. Sincroniza objetivos (Focus Fire) y pings tácticos automáticamente.


### ¿Cómo funcionan las alertas de threat?

TerrorSquadAI recibe datos de TerrorMeter y alerta cuando tu threat es:
- **> 90%** - 🔴 Alerta crítica + sugerencia (ej: "Usa Soulshatter")
- **70-90%** - 🟡 Alerta alta + sugerencia (ej: "Reduce DPS")
- **< 70%** - 🟢 Sin alerta

### ¿Qué sugerencias da para reducir threat?

**Warlock**:
- "Usa Soulshatter"
- "Deja de hacer DPS por 3 segundos"

**Mage**:
- "Reduce DPS con wand"
- "Usa Ice Block si es necesario"

**Rogue**:
- "Usa Vanish"
- "Activa Feint"

**Warrior DPS**:
- "Cambia a Defensive Stance temporalmente"

### ¿Puedo cambiar el umbral de alerta de threat?

Sí, edita `SavedVariables/TerrorSquadAI.lua`:
```lua
TerrorSquadAIDB = {
  alertProfiles = {
    WARLOCK = {
      threatThreshold = 85,  -- Cambiar de 90 a 85
    },
  },
}
```

### ¿Las sugerencias de DoTs hacen spam?

No, tienen controles anti-spam:
- Cooldown de 30 segundos entre sugerencias
- Solo en bosses/elites (no trash)
- Solo sugiere el DoT más importante que falta

### ¿Cómo desactivo todas las alertas?

```bash
/tsa toggle
```

---

## 🤝 Coordinación de Raid

### ¿Qué es el fuego concentrado?

Sistema para marcar un objetivo prioritario y que todo el raid/party lo ataque.

```bash
/tsa focus next    # Marcar siguiente objetivo
/tsa focus clear   # Limpiar marca
```

### ¿Cómo funcionan los pings tácticos?

Envían señales visuales/sonoras al raid:

```bash
/tsa ping attack   # Atacar aquí
/tsa ping defend   # Defender aquí
/tsa ping retreat  # Retirarse
/tsa ping help     # Necesito ayuda
/tsa ping danger   # Peligro
/tsa ping gather   # Agruparse
/tsa ping move     # Moverse
```

### ¿Todos necesitan TerrorSquadAI para ver los pings?

Sí, los pings se sincronizan solo entre jugadores con TerrorSquadAI instalado.

### ¿Qué son las formaciones?

Configuraciones tácticas para el raid:

```bash
/tsa formation spread    # Dispersarse (AoE)
/tsa formation stack     # Agruparse (buffs)
/tsa formation line      # Línea (PvP)
/tsa formation circle    # Círculo (boss)
```

### ¿Las formaciones mueven a los jugadores automáticamente?

No, solo muestran sugerencias visuales. Los jugadores deben moverse manualmente.

### ¿Cómo funciona el marcado automático?

```bash
/tsa marker toggle
```

Marca objetivos automáticamente con iconos (Calavera, Cruz, etc.) según prioridad.

### ¿Puedo usar fuego concentrado en PvP?

Sí, es muy útil para coordinar focus en healers enemigos.

---

## ⚙️ Configuración

### ¿Dónde se guardan las configuraciones?

En `WTF/Account/NOMBRE/SavedVariables/TerrorSquadAI.lua`

### ¿Cómo reseteo la configuración?

1. Cierra WoW
2. Borra `SavedVariables/TerrorSquadAI.lua`
3. Inicia WoW

### ¿Puedo tener configuraciones diferentes por personaje?

Sí, las configuraciones se guardan por personaje automáticamente.

### ¿Cómo cambio el tema de la UI?

Edita `SavedVariables/TerrorSquadAI.lua`:
```lua
TerrorSquadAIDB = {
  theme = "dark",  -- "dark", "light", o "custom"
}
```

### ¿Puedo mover el panel de estado?

Sí, arrastra el panel con el mouse (debe estar desbloqueado).

---

## 🔧 Problemas Comunes

### El addon no carga

**Solución**:
1. Verifica que la carpeta esté en `Interface/AddOns/TerrorSquadAI/`
2. Verifica que `TerrorSquadAI.toc` exista
3. Haz `/reload`
4. Verifica en la lista de addons que esté activado

### Aparece error "attempt to call global X (a nil value)"

**Solución**:
1. Verifica que estés usando WoW Vanilla 1.12.1
2. Actualiza a la última versión del addon
3. Reporta el error con screenshot

### No recibo alertas de threat

**Solución**:
1. Verifica que TerrorMeter esté instalado y detectado: `/tsa status`
2. Verifica que TerrorMeter esté sincronizando: `/tmi status`
3. Verifica que estés en combate
4. Verifica que tu threat sea > 70%

### Las sugerencias de DoTs no aparecen

**Solución**:
1. Verifica que DoTimer esté instalado: `/tsa status`
2. Verifica que estés atacando un boss/elite
3. Verifica que falte un DoT importante
4. Espera 30s (cooldown anti-spam)

### Los pings no se sincronizan con el raid

**Solución**:
1. Verifica que todos tengan TerrorSquadAI instalado
2. Verifica que estén en el mismo raid/party
3. Verifica que sincronización esté activada: `/tsa status`

### El addon causa lag

**Solución**:
1. Desactiva módulos no usados
2. Reduce frecuencia de updates en configuración
3. Ver sección [Rendimiento](#rendimiento)

---

## ⚡ Rendimiento

### ¿El addon afecta el rendimiento?

TerrorSquadAI está optimizado para bajo impacto:
- Uso de CPU: < 2%
- Uso de memoria: ~5-10 MB
- FPS impact: < 1 FPS

### ¿Cómo optimizo el rendimiento?

1. Desactiva integraciones no usadas
2. Reduce frecuencia de chequeos
3. Desactiva alertas visuales complejas

### ¿Puedo ver el uso de recursos del addon?

Sí, usa el addon **PerformanceFu** o similar para monitorear.

### ¿El addon funciona bien en raids de 40 jugadores?

Sí, está optimizado para raids grandes. La sincronización usa compresión de datos.

---

## 🎓 Avanzado

### ¿Puedo crear macros con comandos del addon?

Sí, ejemplo:

```lua
/macro FocusFire
/tsa focus next
/target focus
/startattack
```

### ¿Puedo modificar el código del addon?

Sí, el addon es open source. Modifica los archivos `.lua` según necesites.

### ¿Cómo creo un nuevo módulo?

Ver `MODULES.md` sección "Desarrollo de Módulos".

### ¿Puedo integrar TerrorSquadAI con mi propio addon?

Sí, usa la API pública:

```lua
-- Enviar datos a TerrorSquadAI
if TerrorSquadAI then
  TerrorSquadAI.ReceiveThreatData(threatData, dpsData)
end
```

### ¿Cómo contribuyo al desarrollo?

1. Fork el repositorio
2. Crea una rama para tu feature
3. Haz commits con mensajes descriptivos
4. Envía pull request

### ¿Dónde reporto bugs?

Crea un issue en el repositorio con:
- Descripción del bug
- Pasos para reproducir
- Screenshot del error
- Versión del addon

### ¿Puedo traducir el addon a otro idioma?

Sí, edita los archivos de localización en `Locales/`.

### ¿Cómo activo el modo debug?

Edita `Core.lua`:
```lua
TSA.DEBUG = true
```

Luego haz `/reload`. Verás mensajes de debug en el chat.

---

## 📊 Estadísticas y Datos

### ¿El addon guarda estadísticas de combate?

Sí, guarda:
- Threat promedio por combate
- DoTs aplicados
- Pings enviados
- Objetivos marcados

### ¿Dónde veo las estadísticas?

```bash
/tsa stats
```

### ¿Puedo exportar los datos?

Sí, los datos se guardan en `SavedVariables/TerrorSquadAI.lua` en formato Lua.

---

## 🆚 Comparación con Otros Addons

### ¿TerrorSquadAI vs Omen?

**Omen**: Solo rastrea threat
**TerrorSquadAI**: Threat + sugerencias tácticas + coordinación

### ¿TerrorSquadAI vs Recount?

**Recount**: Solo DPS/HPS
**TerrorSquadAI**: IA táctica + alertas + coordinación

### ¿Puedo usar TerrorSquadAI con Omen/Recount?

Sí, son compatibles. Pero se recomienda usar TerrorMeter en lugar de Omen/Recount para mejor integración.

---

## 🆘 Soporte

### ¿Dónde obtengo ayuda?

1. Lee esta FAQ
2. Lee `README.md` y `COMMANDS.md`
3. Pregunta en el servidor de Discord
4. Crea un issue en GitHub

### ¿Hay un Discord/comunidad?

[Información de contacto aquí]

### ¿Hay tutoriales en video?

[Enlaces a videos aquí]

---

## 📚 Recursos Adicionales

- **README.md** - Guía principal
- **COMMANDS.md** - Lista completa de comandos
- **MODULES.md** - Documentación de módulos
- **INTEGRATION.md** - Guía de integraciones
- **CHANGELOG.md** - Historial de cambios
- **TERROR_ECOSYSTEM.md** - Documentación del ecosystem

---

## 🎯 Casos de Uso Específicos

### Soy DPS, ¿cómo uso el addon?

1. Instala TerrorMeter + TerrorSquadAI
2. Activa alertas de threat: `/tsa toggle`
3. En combate, sigue las sugerencias cuando tu threat sea alto
4. Usa `/tsa focus next` para coordinar con el raid

### Soy Tank, ¿cómo uso el addon?

1. Usa `/tsa marker toggle` para marcar objetivos
2. Usa `/tsa ping defend` para indicar posición
3. Monitorea threat del raid con TerrorMeter

### Soy Healer, ¿cómo uso el addon?

1. Usa `/tsa ping help` cuando necesites ayuda
2. Usa `/tsa formation spread` antes de AoE
3. Monitorea threat para evitar pulls

### Soy Raid Leader, ¿cómo uso el addon?

1. Usa `/tsa focus next` para marcar objetivos prioritarios
2. Usa `/tsa formation <tipo>` para organizar el raid
3. Usa `/tsa ping <tipo>` para comunicación rápida
4. Pide a todos instalar TerrorSquadAI para mejor coordinación

---

**TerrorSquadAI** - Coordinación táctica inteligente para WoW Vanilla

¿Tienes más preguntas? Consulta la documentación completa o contacta al soporte.
