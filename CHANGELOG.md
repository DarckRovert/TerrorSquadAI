# 📋 TerrorSquadAI - Changelog

Historial de cambios y versiones de TerrorSquadAI.

---

## 🛰️ Versión 6.2.0 - 2026-03-23
### Added
- **TerrorScenes 10 slots**: Expandido de 4 a 10 slots de escena (2 filas de 5) para igualar la capacidad de RaidMark. GUI actualizado.
- **BroadcastLoad**: Nuevo método `TerrorScenes:BroadcastLoad(slot)` y comando `/tsai scene [1-10]`. Carga la escena Y la envía al raid en un solo click.
### Fixed
- **Anti-Spoof completo**: `TSAI_BOARD` ahora verifica `SenderCanControl()` antes de aplicar marcadores entrantes. `TSAI_ASSIST` verifica rango de RL real antes de cambiar permisos.

---

## 🛰️ Versión 6.1.0 - 2026-03-23
### Added
- **v6.1 Punteros en Tiempo Real**: 4 slots de color (ROJO=exclusivo RL, AZUL/VERDE/AMARILLO=Assists). Protocolo `TSAI_PTR` con throttle 33ms. Comandos: `/tsai pointer red|blue|green|yellow|off|clear`.
- **v6.2 Roster Panel**: Panel de raiders con colores de clase (9 clases). 5 roles asignables (TANK/HEAL/DPS_M/DPS_R/NONE) con sincronización via `TSAI_ROLE`. Comando: `/tsai roster`.
- **v6.3 Anti-Spoof**: `SenderCanControl()` verifica rango real del sender via `GetRaidRosterInfo()` antes de aceptar comandos de red (igual que RaidMark).
### Changed
- `TacticalMap.lua`: Añadido `RegisterPointerSync()` en `Initialize()`. Nuevas funciones: `ClaimPointer`, `ReleasePointer`, `BroadcastPointerPos`, `AddRemotePointerDot`, `GetOrCreateDot`.
- `TerrorBoard.lua`: Panel de roster integrado en `Initialize`. Nuevas funciones: `RebuildRoster`, `CycleRole`, `BuildRosterPanel`, `UpdateRosterRows`, `RefreshRosterPanel`, `SenderCanControl`.
- Locales `esES.lua` + `enUS.lua`: 14 nuevas strings para punteros y roles.
- Versión: 6.0.x → **6.1.0**.

---

## 🛰️ Versión 6.0.3 - 2026-03-23
### Fixed
- **Layout TerrorBoard**: Marco principal ampliado de 580 a 680px para acomodar la barra de escenas sin desbordamiento.
- **Panel lateral**: Ampliado a 130x310px para mostrar correctamente los 8 marcadores tácticos en 2 columnas.
- **Barra de Escenas**: Anclaje corregido a `RIGHT -> LEFT de broadcastBtn` para posicionamiento preciso.
- **Tip colisión**: Eliminado solapamiento entre el texto tutorial y la barra de escenas.

---

## 🛰️ Versión 6.0.2 - 2026-03-23
### Fixed
- **TacticalRadar**: Error `attempt to index global 'CLASS_BUTTONS' (a nil value)` en línea 274. `CLASS_BUTTONS` no existe en WoW 1.12.1. Corregido con tabla local `CLASS_COLOR` por clase + scope correcto de variable `class` + fallback para unidades no-jugador.

---

## 🛰️ Versión 6.0.0 - 2026-03-23
### Added
- **Network Throttle**: Cola de broadcast throttled (máx. 20 msgs/seg) en `TerrorBoard.lua`. Evita spam en el canal RAID al enviar marcadores masivamente.
- **TerrorScenes**: Nuevo módulo `TerrorScenes.lua`. Sistema de 4 slots de escena guardables en `SavedVariables`. Guarda/carga configuraciones completas de marcadores tácticos.
- **Assist Permissions**: Nuevo comando `/tsai assist on/off`. El RL puede delegar permisos de envío a los Assists vía `SendAddonMessage`.
- **Auto Canal**: Detección automática de canal (RAID/PARTY) antes de cada envío.
- **Locale v6.0**: Nuevas strings en `esES.lua` para escenas, permisos y feedback de red.
### Changed
- `TerrorBoard.lua`: `Broadcast()` refactorizado con cola diferida para evitar saturación de red.
- `Core.lua`: Orden de inicialización corregido: `TerrorScenes` → `TacticalMap` → `TerrorBoard`.
- `TerrorSquadAI.toc`: Versión 6.0.0, registrado `TerrorScenes.lua`.

---

## 🛰️ Versión 5.1.9 - 2026-03-22
### Fixed
- **BigWigs Hotfix**: Corregido error crítico `table index is nil` en `BigWigsIntegration.lua` provocado por timers sin llave válida. Estabilidad total en encuentros de boss.

---

## 🛰️ Versión 5.1.8 - 2026-03-22
### Fixed
- **Certificación Final "No-Error"**: Auditoría completa de todos los módulos para asegurar estabilidad total en Turtle WoW (1.12.1).
- **Sincronización de Versión**: Actualizada la versión interna en `Core.lua` y el archivo `.toc` a la v5.1.8.
- **Optimización de Coordenadas**: Verificación final de los sistemas de mapeo y blips satelitales.

---

## 🛰️ Versión 5.1.7 - 2026-03-22
### Fixed
- **Alineación de Precisión God-Tier**: Rediseñado el marco principal a una resolución de **580x440** para eliminar desbordamientos del panel lateral.
- **HUD Optimizado**: Los controles de opacidad (+/-) se han integrado en la barra de acciones inferior para una interfaz más limpia y profesional.
- **Anclaje Pixel-Perfect**: Corregido el desplazamiento del borde táctico (cian), sincronizándolo exactamente con las coordenadas del mapa.
- **Espaciado**: Ajustado el margen interno del panel de "Activos Tácticos" para mayor claridad visual.

---

## 🛰️ Versión 5.1.6 - 2026-03-22
### Fixed
- **Sintaxis**: Corregido error crítico de carga en `TacticalMap.lua` provocado por un `return` duplicado. Estabilidad total del motor de scripting en 1.12.1.

---

## 🛰️ Versión 5.1.5 - 2026-03-22
### Fixed
- **Reconstrucción Visual God-Tier**: Corregido desbordamiento del mapa y conflictos de capas (Z-Order).
- **Jerarquía de Capas**: El mapa ahora se mantiene estrictamente al fondo (`Level 1`), mientras que los botones y el panel táctico están en niveles superiores (`Level 40+`).
- **Contenedor Holográfico**: Añadido un marco de recorte visual al `Canvas` para asegurar que el mapa no sangre fuera de la pizarra.
- **Aspect Ratio 4:3**: Forzada la resolución estática de 400x300 para evitar mapas estirados o sobredimensionados.

---

## 🛰️ Versión 5.1.4 - 2026-03-22
### Fixed
- **Motor de Mapa**: Corregido error de inicialización de tablas (nil value) en `TacticalMap.lua`. Se han restaurado las estructuras de datos necesarias para el pooling de nombres y pings tácticos.

---

## 🛰️ Versión 5.1.3 - 2026-03-22
### Fixed
- **Holographic Rendering**: Corregido un error crítico donde el motor de renderizado de 12 tiles no se inicializaba correctamente en ciertas configuraciones de UI, causando que el mapa táctico no se mostrara.
- **Coordinate Markers**: Ajustada la precisión de los marcadores para evitar pequeños desplazamientos en coordenadas extremas del mapa.

---

## 🛰️ Versión 5.0.0 - Tactical Map Evolution (Marzo 2026)

### 🎯 Cambio Principal
**Transformación a Mapa Táctico Holográfico**. La Pizarra Táctica evoluciona a un mapa de zona transparente con posicionamiento en tiempo real.

### ✨ Nuevas Funciones
| Función | Descripción |
|---------|-------------|
| **Zone Map Overlay** | Proyección transparente del mapa actual (VC, MC, BWL, etc.) directamente en la pizarra. |
| **Real-time Blips** | Seguimiento en vivo de tu posición y la de tus aliados sobre el terreno. |
| **Coordinate Markers** | Los marcadores tácticos ahora se enlazan a coordenadas geográficas reales. |
| **Safe Map Polling** | Sistema de consulta de mapas que no interfiere con el uso manual del WorldMap. |

### 🛠️ Refactor Técnico
- **Coordinate Engine** | Migración de 8x8 Grid a sistema Decimal de alta precisión (0.0001).
- **Holographic Rendering** | Motor de 12 tiles para renderizar texturas de zona en frames personalizados.

---

## 💎 Versión 4.2.0 - God-Tier Visual Remaster (Marzo 2026)

### 🎯 Cambio Principal
**Remasterización Visual Completa y Unificación de Interfaz**. Evolución estética de la Pizarra Táctica a un estándar "God-Tier" y consolidación del sistema de lanzadores.

### 🛠️ Mejoras Visuales
| Cambio | Descripción |
|--------|-------------|
| **TerrorBoard Remaster** | Rediseño total con estética "Glass Obsidian" y efectos de escaneo CRT/Holográfico. |
| **Grid de Brackets** | Sistema de esquinas tácticas iluminadas en lugar de bordes sólidos. |
| **Action Bar Pro** | Consolidación de controles en una barra de cristal inferior para mayor limpieza. |
| **Corner Brackets API** | Nueva utilidad en `UITheme` para crear esquinas tácticas en cualquier frame. |

### 🖱️ Integración de Lanzador
- **Unified Launcher**: El botón de minimapa ahora es universal.
    - Click Izquierdo: Configuración.
    - Click Derecho: Alternar Pizarra (TerrorBoard).
    - Shift + Click Derecho: Alternar Sistema de IA.
- **Redundancia Eliminada**: Se ha retirado el orbe "Tactical Core" para limpiar la UI.

### 🐛 Estabilidad 1.12.1
- **Audit de SetPoint** | Corregidos errores de posicionamiento en clientes antiguos.
- **Click Registration** | Corregido registro de clicks derechos en el minimapa.
- **Refactor GlitchEffect** | Sistema de efectos glitch ahora es estable para todos los objetos UI.

---

## 🔧 Versión 4.1.1 - Stability Release (Enero 2026)

### 🎯 Cambio Principal
**Estabilidad total y limpieza de código**. Auditoría completa de funcionalidad, verificación de todos los checkboxes, y organización del proyecto.

---

**TerrorSquadAI** - Evolucionando la coordinación táctica en WoW Vanilla

Última actualización: Marzo 2026
