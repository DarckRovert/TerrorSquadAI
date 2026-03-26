# El Ecosistema del Terror - Manual de Inteligencia Colectiva

> **Versión del Documento:** 1.0
> **Arquitecto:** DarckRovert / Elnazzareno
> **Núcleo:** TerrorSquadAI v5.0

## 🌐 ¿Qué es el Ecosistema?
No has instalado 4 addons separados. Has instalado una **Red Neural de Combate** de 10 piezas.
Estos diez componentes (TerrorSquadAI, WCS_Brain, BigWigs, TerrorMeter, DoTimer, pfUI, HealBot, aux-addon, pfQuest, Atlas-TW) han sido unificados para "hablar" entre sí en tiempo real.

---

## 🧩 Los Cuatro Componentes

### 1. El Cerebro: TerrorSquadAI (TSAI)
Es el comandante central. Toma decisiones, sugiere estrategias, maneja el radar y coordina a los otros addons.

### 2. El Vínculo Maestro: WCS_Brain
La integración definitiva para el control total del combate y aprendizaje mediante IA.

### 3. Los Ojos: BigWigs + TerrorLink
Detección de habilidades de jefes y fases en tiempo real.

### 4. El Sistema Nervioso: TerrorMeter (Threat)
Regulador de seguridad y monitoreo de amenaza global.

### 5. El Reloj Biológico: DoTimer
Rastreo y optimización de DoTs y debuffs.

### 6. La Interfaz: pfUI (Séquito Edition)
Visualización premium y alertas centralizadas.

### 7. El Soporte Vital: HealBot
Coordinación de sanación y monitoreo de supervivencia.

### 8. La Inteligencia de Mercado: aux-addon
Análisis de economía y alertas de trading para el clan.

### 9. La Guía de Campaña: pfQuest + Atlas-TW
Navegación táctica y sincronización de objetivos de misión.

---

## 🔗 Cómo Funciona la "Mente de Enjambre" (SquadMind)

Si estás en una Raid donde varios jugadores usan este Ecosistema:

1.  **Visión Compartida (TerrorNet):**
    *   Si el Jugador A detecta un enemigo en su radar, el Jugador B lo verá instantáneamente en su propio radar, aunque esté lejos.
    *   *Uso:* Emboscadas PvP y evitar patrullas en PvE.

2.  **Defensa Coordinada:**
    *   Si el Tanque Principal usa *Muro de Escudo*, todos los TSAI de la raid lo registran.
    *   TSAI avisará al Tanque Secundario: *"Muro de Escudo activo en Tanque 1. NO lo uses todavía"*.
    *   *Resultado:* Cadenas de defensa perfectas sin usar chat de voz.

3.  **Predicción de Amenaza:**
    *   TerrorMeter envía datos de amenaza de todos a todos. TSAI calcula quién romperá aggro en los próximos 3 segundos y avisa preventivamente.

---

## 🛠️ Comandos Globales

| Comando | Función |
| :--- | :--- |
| `/tsai config` | Abre el panel central de configuración. |
| `/tsai radar` | Activa/Desactiva el Radar Táctico 2.0. |
| `/board` | Abre la Pizarra Táctica (TerrorBoard). |
| `/tsai hud` | Activa/Desactiva los hologramas de pantalla. |
| `/terrorlink` | Verifica la conexión con BigWigs. |
| `/tmbridge status` | Verifica la conexión con TerrorMeter. |
| `/tsadot toggle` | Activa/Desactiva sugerencias inteligentes de DoTs. |
| `/tsai net` | Muestra el estado de la red global (TerrorNet). |

---

## ⚠️ Solución de Problemas

**P: ¿Por qué no veo a mis compañeros en el Radar?**
R: Asegúrate de que ellos también tienen TerrorSquadAI instalado y activado (`/tsai net` para verificar).

**P: BigWigs no avisa a la IA.**
R: Escribe `/terrorlink`. Si dice "OFF", escribe `/terrorlink` de nuevo. Asegúrate de cargar BigWigs al entrar al juego.

**P: TerrorMeter no muestra mis datos.**
R: Asegúrate de estar en un grupo o banda. La sincronización requiere un canal de grupo.

---
*Hecho para la Hermandad: El Sequito del Terror. Larga vida a Turtle WoW.*
