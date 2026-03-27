# El Ecosistema del Terror - Manual de Inteligencia Colectiva
> **Versión del Documento:** 9.3.0 [God-Tier]
> **Arquitecto:** DarckRovert / Elnazzareno
> **Núcleo:** TerrorSquadAI + WCS_Brain

## 🌐 ¿Qué es el Ecosistema?
No has instalado addons separados. Has instalado una **Red Neural de Combate** de 10 piezas construida a medida para Turtle WoW.
Estos componentes interactúan en tiempo real mediante canales de comunicación ocultos para sincronizar la información táctica, la sanación, y la economía de toda la banda.

---

## 🗺️ Diagrama de Arquitectura de la Mente de Enjambre (SquadMind)

```mermaid
graph TD
    %% Estilos
    classDef core fill:#2C0000,stroke:#FF0000,stroke-width:2px,color:#fff;
    classDef combat fill:#4B0082,stroke:#9370DB,stroke-width:2px,color:#fff;
    classDef intel fill:#003366,stroke:#00BFFF,stroke-width:2px,color:#fff;
    classDef ui fill:#004d00,stroke:#00ff00,stroke-width:2px,color:#fff;
    classDef extern fill:#404040,stroke:#808080,stroke-width:1px,color:#fff;

    %% Nodos Core
    TSAI["🧠 TerrorSquadAI<br/>(Comandante Táctico)"]:::core
    WCS["🔮 WCS_Brain<br/>(Vínculo Maestro)"]:::core

    %% Nodos Combate
    TM["📊 TerrorMeter<br/>(Sistema Nervioso / Threat)"]:::combat
    HB["💚 HealBot<br/>(Soporte Vital)"]:::combat
    BW["👁️ BigWigs + TerrorLink<br/>(Detección Jefes)"]:::combat
    DT["⏱️ DoTimer<br/>(Reloj Biológico)"]:::combat

    %% Nodos Inteligencia & Logística
    AUX["💰 aux-addon<br/>(Mercado & Logística)"]:::intel
    ATLAS["🗺️ Atlas-TW<br/>(Estrategia Dungeon)"]:::intel
    PFQ["📜 pfQuest<br/>(Inteligencia de Entorno)"]:::intel

    %% Nodos UI
    PFUI["🖥️ pfUI<br/>(HUD Premium)"]:::ui

    %% Conexiones principales
    WCS <==>|OnPlayerAction / Sugerencias| TSAI
    
    %% Conexiones con Combat
    TM ==>|Datos de DPS y Amenaza| TSAI
    TM ==>|Alerta de Agro (ToT)| HB
    BW ==>|Timers de Habilidades| TSAI
    BW -.->|Avisos en Interfaz| HB
    DT ==>|Falta de DoTs| WCS
    
    %% Conexiones Tácticas
    TSAI ==>|Prioridades de Sanación| HB
    TSAI ==>|Alertas Tácticas| PFUI
    
    %% Conexiones de Inteligencia
    PFQ -.->|Rutas Tácticas| ATLAS
    AUX -.->|Stock del Banco Clan| WCS

    %% Jugadores conectados
    SquadA(("🎮 Jugador A<br/>(Tanque)")):::extern
    SquadB(("🎮 Jugador B<br/>(Healer)")):::extern
    SquadC(("🎮 Jugador C<br/>(Warlock)")):::extern

    %% Conexión de Red Séquito
    SquadA -.->|TerrorNet SYNC| TSAI
    SquadB -.->|TerrorNet SYNC| TSAI
    SquadC -.->|TerrorNet SYNC| TSAI
```

---

## 🧩 Los 10 Componentes del Ecosistema

| Componente | Rol en el Ecosistema | Integración Principal |
|:---|:---|:---|
| **1. TerrorSquadAI** | **El Cerebro:** Comandante central. Toma decisiones grupales, sugiere estrategias y maneja la pizarra holográfica (`/board`). | Se comunica con todos. |
| **2. WCS_Brain** | **El Vínculo Maestro:** Automatiza la toma de decisiones por clase (especializado en Warlock) basándose en telemetría de grupo. | Habla con `TerrorSquadAI`. |
| **3. TerrorMeter** | **El Sistema Nervioso:** Monitorea la amenaza exacta matemáticamente y previene Wipes deteniendo el DPS con alertas. | Avisa a `TSAI` y `HealBot`. |
| **4. HealBot** | **El Soporte Vital:** Sistema Sanador. Muestra cuadros rojos de alerta cuando un aliado tiene el Aggro peligroso. | Escucha a `TerrorMeter` y `BigWigs`. |
| **5. BigWigs** | **Los Ojos:** Mediante el *TerrorLink*, detecta los lanzamientos de jefes e informa al cerebro para coordinar defensas grupales. | Avisa a `TerrorSquadAI`. |
| **6. DoTimer** | **El Reloj Biológico:** Rastreo y optimización de DoTs cruzados en los enemigos. | Habla con `WCS_Brain`. |
| **7. pfUI**| **La Interfaz Visual:** Provee el marco unificado para proyectar nuestra información táctica sin desorden. | Hub central. |
| **8. pfQuest** | **La Guía de Campo:** Traducido al español (Séquito Edition) para la navegación táctica de farmeo del clan. | Inteligencia Global. |
| **9. Atlas-TW** | **Mapas de Guerra:** Sincronización de mapas de Dungeons para que el Comandante trace rutas en la pizarra táctica. | Conecta con `TerrorBoard`. |
| **10. aux-addon** | **Inteligencia de Mercado:** Rastrea precios para la gestión de donaciones y préstamos en el *WCS_ClanBank*. | Conecta con `WCS_ClanBank`. |

---

## 🔗 Cómo Funciona la "Mente de Enjambre" (SquadMind)

Si estás en una Raid donde varios jugadores usan este Ecosistema:

1. **Visión Compartida (TerrorNet):**
   * El Jugador A detecta un enemigo en su radar. Automáticamente, el Jugador B lo verá en su propio radar, aunque esté a 100 yardas.

2. **Defensa Coordinada e Inmediata:**
   * El Tanque Principal activa *Muro de Escudo*. The SquadMind avisa a los demás tanques: *"Muro de Escudo activo en Tanque 1. Reserva el tuyo."*
   * *Resultado:* Cadenas de supervivencia sin saturar Discord.

3. **Prevención de Suicidios (Aggro Control):**
   * *TerrorMeter* detecta un Mago al 95% de amenaza. 
   * Le grita al Mago: *"¡ALTO AL FUEGO!"*
   * Alerta a *HealBot* de los Healers: *"¡Preparen escudos en el Mago!"*

---

> *"No pienses como un jugador, piensa como un enjambre."* — **El Séquito del Terror**
