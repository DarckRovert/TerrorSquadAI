# TerrorSquadAI

**Módulo de IA Avanzado para Gestión de Escuadrones y Toma de Decisiones en Combate**

> **Versión 2.2.0** - Completamente reconstruido y optimizado para WoW Vanilla 1.12 (Turtle WoW)
> 🇯🇵 **NUEVO:** Soporte completo para cliente en español

## 🎯 Descripción General

TerrorSquadAI es un addon sofisticado de World of Warcraft diseñado para Turtle WoW (Vanilla 1.12) que proporciona gestión de escuadrones impulsada por inteligencia artificial avanzada, análisis de combate en tiempo real y coordinación táctica para contenido tanto PvP como PvE.

Creado por **DarckRovert (elnazzareno)** para el clan **El Sequito del Terror**.

## ⚠️ Nota Importante - Versión 2.2.0

Esta versión ha sido **completamente reconstruida** para garantizar compatibilidad total con WoW Vanilla 1.12:
- ✅ Todos los módulos recreados desde cero
- ✅ APIs modernas reemplazadas por equivalentes de Vanilla
- ✅ Sistema de comandos completamente nuevo
- ✅ Optimizado para rendimiento en Vanilla
- ⚠️ Algunos comportamientos pueden diferir de versiones anteriores

## Características

### Sistema de IA Principal
- **Análisis de Amenazas en Tiempo Real**: Monitorea continuamente las situaciones de combate y calcula niveles de amenaza
- **Escenarios de Combate Predictivos**: Sistema inspirado en aprendizaje automático que aprende del historial de combates
- **Sugerencias Estratégicas**: Recomendaciones dinámicas basadas en las condiciones actuales de combate
- **Detección de Escenarios**: Identifica automáticamente el tipo de combate (Jefe, PvP, Mazmorra, etc.)

### Integración con BigWigs
- **Comunicación Bidireccional**: Se integra perfectamente con BigWigs para mecánicas de jefes
- **Seguimiento Automático de Habilidades**: Monitorea y predice habilidades de jefes
- **Alertas Mejoradas**: Convierte advertencias de BigWigs en sugerencias estratégicas accionables
- **Sincronización de Temporizadores**: Comparte temporizadores de jefes entre miembros del escuadrón

### Coordinación de Escuadrón
- **Comunicación Sincronizada**: Intercambio de datos en tiempo real entre todos los usuarios del addon
- **Sistema de Objetivos Prioritarios**: Coordina el fuego concentrado en todo el escuadrón
- **Gestión de Formaciones**: Formaciones tácticas (Dispersa, Compacta, Línea, Móvil)
- **Análisis de Efectividad del Escuadrón**: Evalúa la composición y sinergia del grupo
- **Anuncios de Presencia**: Detección automática de otros usuarios del addon

### Sistema de Alertas
- **Alertas Personalizables**: Notificaciones críticas personalizadas
- **Visualización Basada en Prioridad**: Muestra primero las alertas más importantes
- **Retroalimentación Visual y Auditiva**: Múltiples tipos de alertas con opciones de sonido
- **Perfiles de Alertas**: Guarda y carga diferentes configuraciones de alertas

### Overlay Táctico
- **Estado de Combate en Tiempo Real**: Visualización en vivo de amenaza, escenario e información del escuadrón
- **Medidor de Efectividad del Escuadrón**: Representación visual del rendimiento del grupo
- **Contador de Miembros Conectados**: Muestra cuántos miembros del escuadrón están usando el addon

## Instalación

1. Descarga o clona este repositorio
2. Copia la carpeta `TerrorSquadAI` a tu directorio `World of Warcraft\Interface\AddOns`
3. Reinicia World of Warcraft o recarga la interfaz (`/reload`)
4. El addon se inicializará automáticamente al iniciar sesión

## 🎮 Comandos

Usa `/tsa` o `/terrorsquad` seguido de:

### Comandos Principales
- **`help`** - Mostrar lista completa de comandos
- **`toggle`** - Activar/desactivar sistema de IA
- **`status`** - Mostrar estado del addon (versión, módulos, amenaza)

### Marcado y Objetivos
- **`marker toggle`** - Activar/desactivar marcado automático de objetivos
- **`focus next`** - Siguiente objetivo de fuego concentrado
- **`focus clear`** - Limpiar objetivo de fuego concentrado
- **`target next`** - Cambiar al siguiente objetivo inteligente
- **`target prev`** - Cambiar al objetivo anterior

### Coordinación Táctica
- **`ping <tipo>`** - Enviar ping táctico al escuadrón
  - Tipos: `atacar`, `defender`, `ayuda`, `peligro`, `reagrupar`, `retirada`, `posicion`
- **`formation <tipo>`** - Cambiar formación del escuadrón
  - Tipos: `linea`, `circulo`, `cuna`, `dispersion`

### Información y Utilidades
- **`cooldowns`** - Mostrar cooldowns del escuadrón (listos y en recarga)
- **`macros generate`** - Generar macros para tu clase
- **`gnomo toggle`** - Activar/desactivar modo furia gnómica (PvP)
- **`panel toggle`** - Mostrar/ocultar panel de estado

### Ejemplos
```
/tsa help
/tsa status
/tsa ping atacar
/tsa formation linea
/tsa cooldowns
/tsa macros generate
```

## Configuración

Accede al panel de configuración con `/tsai config` para personalizar:

### Configuración General
- Activar/Desactivar Sistema de IA
- Activar/Desactivar Sistema de Alertas
- Activar/Desactivar Sincronización de Escuadrón
- Activar/Desactivar Integración con BigWigs

### Comportamiento de la IA
- **Agresividad** (0-100%): Controla qué tan agresivas son las recomendaciones de la IA
- **Defensividad** (0-100%): Influye en la prioridad de sugerencias defensivas
- **Prioridad de Coordinación** (0-100%): Enfatiza la coordinación del escuadrón sobre acciones individuales

## 📦 Módulos

### Módulos Core
- **Core.lua** - Inicialización principal y sistema de registro de módulos
- **Commands.lua** - Sistema completo de comandos slash `/tsa`
- **AIEngine.lua** - Motor de IA y toma de decisiones en combate
- **ThreatAnalysis.lua** - Evaluación de amenazas en tiempo real
- **PredictiveSystem.lua** - Sistema predictivo de combate
- **StrategicSuggestions.lua** - Recomendaciones estratégicas dinámicas

### Módulos de Integración
- **BigWigsIntegration.lua** - Integración con BigWigs para mecánicas de jefes
- **AlertSystem.lua** - Sistema de alertas personalizables
- **CommunicationSync.lua** - Sincronización entre miembros del escuadrón
- **SquadCoordination.lua** - Coordinación táctica avanzada

### Módulos Mejorados (Fase 1-6) - ✨ NUEVOS en v2.0
- **AutoMarker.lua** - Marcado automático de objetivos prioritarios
- **CooldownTracker.lua** - Rastreador de cooldowns importantes del escuadrón
- **GnomoFury.lua** - Modo furia gnómica para PvP con kill streaks
- **TacticalPings.lua** - Sistema de pings tácticos (7 tipos)
- **StatusPanel.lua** - Panel de estado en tiempo real (movible)
- **FocusFireCoordinator.lua** - Coordinador de fuego concentrado
- **InterruptCoordinator.lua** - Coordinador de interrupciones con cola
- **PositionOptimizer.lua** - Optimizador de posicionamiento (4 formaciones)
- **ResourceMonitor.lua** - Monitor de HP/mana del escuadrón
- **ThreatPredictor.lua** - Predictor de amenaza con tendencias
- **VoiceCommands.lua** - Sistema de comandos de voz (10 comandos)
- **MacroGenerator.lua** - Generador automático de macros por clase
- **PerformanceTracker.lua** - Rastreador de rendimiento del addon
- **SmartTargeting.lua** - Sistema de targeteo inteligente con prioridades

### Módulos de UI
- **UI.lua** - Interfaz de usuario principal y overlay táctico
- **Config.lua** - Panel de configuración
- **UITheme.lua** - Temas visuales personalizables

## Cómo Funciona

1. **Detección de Combate**: El addon detecta automáticamente cuando entras en combate
2. **Análisis de Escenario**: Identifica el tipo de encuentro (Jefe, PvP, Mazmorra, etc.)
3. **Cálculo de Amenaza**: Monitorea continuamente los niveles de amenaza basándose en salud, enemigos y aliados
4. **Análisis Estratégico**: Genera recomendaciones basadas en la situación actual
5. **Sincronización de Escuadrón**: Comparte datos con otros usuarios del addon en tu grupo
6. **Visualización de Alertas**: Muestra información crítica y sugerencias a través del sistema de alertas

## Optimización para PvP

TerrorSquadAI está específicamente optimizado para combate PvP:
- Detecta escenarios PvP (Escaramuza, Campo de Batalla, PvP Mundial)
- Proporciona sugerencias de objetivos específicas por clase
- Coordina ventanas de daño explosivo
- Recomienda retiradas tácticas cuando estás en inferioridad numérica
- Rastrea habilidades y patrones de jugadores enemigos

## Sinergia con BigWigs

Cuando BigWigs está instalado:
- Se conecta automáticamente al sistema de mensajes de BigWigs
- Convierte advertencias de jefes en sugerencias estratégicas
- Predice habilidades próximas basándose en patrones
- Comparte información de temporizadores en todo el escuadrón
- Mejora la coordinación de banda

## Red de Escuadrón

Cuando múltiples miembros del escuadrón usan TerrorSquadAI:
- Detección automática de presencia
- Análisis de amenazas compartido
- Prioridad de objetivos coordinada
- Sugerencias estratégicas sincronizadas
- Intercambio de datos de combate en tiempo real

## Rendimiento

TerrorSquadAI está diseñado para ser ligero:
- Manejo eficiente de eventos
- Intervalos de actualización optimizados
- Huella de memoria mínima
- Sin impacto en el rendimiento del juego

## Compatibilidad

- **Versión del Juego**: Vanilla WoW 1.12 (Turtle WoW)
- **Dependencias Opcionales**: BigWigs, pfQuest
- **Funciona con**: Todas las clases y especializaciones
- **Tipos de Grupo**: Solo, Grupo (5 jugadores), Banda (40 jugadores)

## Desarrollo Futuro

- Mejoras en el modelo de aprendizaje automático
- Estrategias PvP adicionales
- Predicciones mejoradas de mecánicas de jefes
- Opciones de sonidos de alerta personalizados
- Integración con más addons
- Seguimiento estadístico avanzado

## Soporte

Para problemas, sugerencias o comentarios:
- Contacta a DarckRovert en el juego (elnazzareno)
- Miembros del gremio El Sequito del Terror

## 🔧 Notas Técnicas - Versión 2.1.0

### Cambios de Compatibilidad con Vanilla 1.12
Esta versión incluye correcciones extensivas para compatibilidad total con WoW 1.12:

**APIs Reemplazadas:**
- `UnitGUID()` → Sistema custom `GetUnitID()` (nombre:nivel)
- `UnitIsGroupLeader()` → `IsRaidLeader()` / `IsPartyLeader()`
- Operador `#` → `table.getn()`
- Operador `%` → `math.mod()`
- `COMBAT_LOG_EVENT_UNFILTERED` → `CHAT_MSG_COMBAT_HOSTILE_DEATH`
- Sintaxis condicional de macros removida (no compatible con 1.12)

**Módulos Recreados:**
Los siguientes 14 módulos fueron completamente recreados desde cero para v2.0:
- AutoMarker, CooldownTracker, GnomoFury, TacticalPings, StatusPanel
- FocusFireCoordinator, InterruptCoordinator, PositionOptimizer
- ResourceMonitor, ThreatPredictor, VoiceCommands
- MacroGenerator, PerformanceTracker, SmartTargeting

**Limitaciones Conocidas:**
- PerformanceTracker usa `gcinfo()` para memoria total (no por addon)
- Macros generados usan icono por defecto (editable manualmente)
- GetUnitID puede tener colisiones con mobs idénticos (mismo nombre/nivel)

### Estructura de Archivos
```
TerrorSquadAI/
├── Core.lua                    # Sistema principal
├── Commands.lua                # Comandos /tsa
├── TerrorSquadAI.toc          # Archivo de configuración
├── Locales/                    # Traducciones
│   ├── esES.lua
│   └── enUS.lua
├── Modules/                    # Módulos funcionales
│   ├── [Core Systems]
│   ├── [Enhanced Features]
│   └── [UI]
├── Modules_backup/             # Respaldos de archivos originales
└── _OLD_SCRIPTS/              # Scripts de reparación (pueden borrarse)
```

**Carpetas que pueden eliminarse:**
- `_OLD_SCRIPTS/` - Scripts de PowerShell/Python usados durante la reparación
- `Modules_backup/` - Respaldos de módulos corruptos originales (mantener por seguridad)

## 📊 Estado del Proyecto

**Versión Actual:** 2.1.0  
**Estado:** ✅ Funcional - En fase de testing  
**Última Actualización:** Enero 2026  
**Compatibilidad:** WoW Vanilla 1.12 (Turtle WoW)

## 🐛 Reporte de Bugs

Si encuentras algún problema:
1. Anota el mensaje de error exacto
2. Describe qué estabas haciendo cuando ocurrió
3. Contacta a DarckRovert en el juego (elnazzareno)
4. Miembros del gremio El Sequito del Terror

## 👥 Créditos

**Autor Original:** DarckRovert (elnazzareno)  
**Clan:** El Sequito del Terror  
**Versión:** 2.1.0  
**Juego:** Turtle WoW (Vanilla 1.12)  
**Reconstrucción v2.1:** Enero 2026

## 📜 Licencia

Creado para El Sequito del Terror. Libre para usar y modificar.

---

**¡Viva El Sequito del Terror!**  
**¡Por la gloria del PvP y la dominación total!** ⚔️
