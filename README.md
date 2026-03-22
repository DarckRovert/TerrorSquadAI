# TerrorSquadAI (La Mente Maestra)

TerrorSquadAI es un asistente de combate de "Próxima Generación" para WoW Vanilla. A diferencia de otros addons que solo muestran información, TerrorSquadAI **analiza** la situación y **toma decisiones** estratégicas por ti.

## 🚀 Módulos Principales

### 1. El Cerebro (Macros Dinámicas)
Permite crear una macro inteligente que cambia su función según el contexto.
*   **Comando**: `/tsai macro`
*   **Uso**: Crea una macro llamada `TSA_Brain`.
*   **Ejemplo**: Si tienes poca vida, la macro usará una Poción. Si el enemigo casteas, usará Interrumpir. Si todo está bien, usará tu rotación de daño.

### 2. Tactical HUD (Visor Holográfico)
Proyecta información crítica directamente en tu campo de visión central.
*   **Comando**: `/tsai hud`
*   **Muestra**: Alertas de BigWigs, Advertencias de Agro (TerrorMeter) y Cooldowns importantes.

### 3. Tactical Radar 2.0
Un radar vectorial que muestra la posición relativa de amenazas y aliados.
*   **Comando**: `/tsai radar`
*   **TerrorNet**: Si tus compañeros tienen el addon, verás sus objetivos y posición en tiempo real.

### 4. Enemy Cooldowns (PvP/PvE)
Rastrea las habilidades defensivas y ofensivas del enemigo (Burbujas, Cortes, Blocks).
*   Funciona en clientes Inglés y Español.

### 5. TerrorBoard v5.0 (Tactical Map) [NUEVO]
Mapa táctico holográfico con posicionamiento en tiempo real y órdenes geográficas.
*   **Acceso**: Click Derecho en el botón del minimapa o `/board`.
*   **Funciones**: Proyección transparente de zona, Blips en tiempo real (Jugador/Aliados), Marcadores de alta precisión (0.0001).

### 6. Interrupt Coordinator
Organiza cortes de hechizos en el grupo para evitar superposiciones (dos personas cortando lo mismo).

## 🎮 Comandos Principales (`/tsai`)

*   `/tsai config` - Abre el panel de configuración (Click Izquierdo en minimapa).
*   `/board` - Abre la Pizarra Táctica (Click Derecho en minimapa).
*   `/tsai status` - Muestra el estado de todos los módulos.
*   `/tsai reset` - Reinicia la IA si se comporta de forma extraña.
*   `/tsai help` - Muestra la ayuda detallada.

## 🖱️ Control de Minimapa (Lanzador Unificado)

*   **Click Izquierdo**: Configuración del Addon.
*   **Click Derecho**: Alternar Pizarra Táctica (TerrorBoard).
*   **Shift + Click Derecho**: Activar/Desactivar el Sistema de IA de Combate.

## 🌐 Terror Ecosystem

Este addon es el cerebro, pero necesita órganos:
*   **Ojos**: DoTimer (Rastreo de DoTs).
*   **Oídos**: BigWigs (Escucha a los Jefes).
*   **Nervios**: TerrorMeter (Siente la amenaza).

Cuando estos addons están instalados, TerrorSquadAI los detecta automáticamente y desbloquea funciones avanzadas (predicción de daño, rotaciones perfectas, gestión de agro).

## 🛠️ Instalación

1.  Extrae la carpeta en `Interface/AddOns/`.
2.  Asegúrate de tener también `BigWigs`, `TerrorMeter` y `DoTimer` (versiones Terror Squad).
3.  Entra al juego y escribe `/tsai`.

---
*Desarrollado para El Séquito del Terror.*
*Maximizando la eficiencia en Turtle WoW.*
