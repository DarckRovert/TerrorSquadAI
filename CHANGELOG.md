# 📋 TerrorSquadAI - Changelog

Historial de cambios y versiones de TerrorSquadAI.

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
