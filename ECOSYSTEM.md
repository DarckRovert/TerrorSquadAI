# El Ecosistema del Terror - Manual de Inteligencia Colectiva

> **Versión del Documento:** 1.0
> **Arquitecto:** DarckRovert / Elnazzareno
> **Núcleo:** TerrorSquadAI v5.0

## 🌐 ¿Qué es el Ecosistema?
No has instalado 4 addons separados. Has instalado una **Red Neural de Combate**.
Estos cuatro componentes (TerrorSquadAI, BigWigs, TerrorMeter, DoTimer) han sido modificados o enlazados para "hablar" entre sí en tiempo real, creando una inteligencia superior a la suma de sus partes.

---

## 🧩 Los Cuatro Componentes

### 1. El Cerebro: TerrorSquadAI (TSAI)
Es el comandante central. Toma decisiones, sugiere estrategias, maneja el radar y coordina a los otros addons.
*   **Rol:** Toma de decisiones y visualización (HUD/Radar).
*   **Comunicaciones:** Recibe datos de todos y emite órdenes.

### 2. Los Ojos: BigWigs + TerrorLink
BigWigs ya no es solo un avisador de jefes. Con el plugin `TerrorLink`, se convierte en los ojos tácticos de la IA.
*   **Función:** Detecta habilidades del jefe antes de que ocurran.
*   **Integración:** Envía temporizadores al Cerebro. Si BigWigs dice "Explosión inminente", TSAI ordena "¡Escudos!".

### 3. El Sistema Nervioso: TerrorMeter (Threat)
Más allá de medir daño, este addon ahora actúa como un regulador de seguridad.
*   **Función:** Monitorea la amenaza (aggro) de cada miembro del escuadrón.
*   **Integración:** Si tu amenaza sube peligrosamente, alerta a TSAI. TSAI entonces te grita en pantalla y, si eres tanque, avisa a los otros tanques.

### 4. El Reloj Biológico: DoTimer
Controla los tiempos de los perjuicios (DoTs) en el enemigo.
*   **Función:** Rastrea maldiciones, sangrados y venenos.
*   **Integración:** Informa a TSAI de qué debuffs faltan. TSAI coordina con los Brujos/Sacerdotes para reaplicarlos sin superponerse.

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
