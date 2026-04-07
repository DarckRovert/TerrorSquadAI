# ðŸ“ Wiki: Arquitectura 'Diamond Tier' â€” TerrorSquadAI [v1.0.4]

Estructura tÃ©cnica del motor de orquestaciÃ³n de banda mantenido por **DarckRovert**.

## ðŸ—ï¸ JerarquÃ­a del Sistema de Inteligencia (Data Hierarchy)

TerrorSquadAI opera mediante la interceptaciÃ³n de eventos de banda y la orquestaciÃ³n de red:

1.  **Hueso del Scanner (`Core.lua`)**: Escucha eventos de combate y posicionamiento de los miembros de la raid.
2.  **Motor de DecisiÃ³n TÃ¡ctica (`Modules/`)**: MÃ³dulos especÃ­ficos para cada jefe que analizan mecÃ¡nicas y sugieren marcas.
3.  **MÃ³dulo de SincronizaciÃ³n (`Commands.lua`)**: Canal de comunicaciÃ³n para la orquestaciÃ³n de marcas y alertas entre miembros.
4.  **Interface Renderer (`RaidMark_Analysis/`)**: Visualizador de auditorÃ­a de mecÃ¡nicas y rendimiento de banda.

---

## ðŸ§­ Diagrama de Flujo: OrquestaciÃ³n TÃ¡ctica v9.4

```mermaid
graph TD
    A[Evento de Banda: DaÃ±o/Skill de Jefe] --> B[Escaneo de Entorno Core.lua]
    B --> C[AnÃ¡lisis de Patrones en MÃ³dulos]
    C --> D{Â¿MecÃ¡nica CrÃ­tica?}
    D -- SÃ­ --> E[Modo de Alerta / Marcas de CC]
    D -- No --> Z[Esperar Siguiente Evento]
    E --> F[InyecciÃ³n en Canal de Banda Commands.lua]
    F --> G[RecepciÃ³n en Miembros del SÃ©quito]
    G --> H[Render de Alertas con Throttling 0.25s]
    H --> I[SincronizaciÃ³n con WCS_Brain y TerrorMeter]
```

## âš¡ Estrategias de IngenierÃ­a Diamond Tier

- **Collective Parsing**: El sistema solo decodifica eventos relevantes para la mecÃ¡nica del jefe activo, ignorando el spam de combate menor.
- **Sync Throtling**: Las marcas tÃ¡cticas se envÃ­an con un lÃ­mite de frecuencia para evitar el spam y la saturaciÃ³n del cliente 1.12.1.
- **Neutral Sync Integration**: Los datos de rendimiento de banda se integran con el ecosistema Gravity para anÃ¡lisis tÃ¡ctico global.

---
Â© 2026 **DarckRovert** â€” El SÃ©quito del Terror.
*Orquestando la victoria a travÃ©s de la inteligencia artificial.*

