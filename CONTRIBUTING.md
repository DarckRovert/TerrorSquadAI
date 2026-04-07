# Contributing to TerrorSquadAI (Collective Intelligence) 🛡️🤖

¡Gracias por contribuir a la evolución táctica del **Séquito del Terror**! Para mantener el estándar **Diamond Tier** de **DarckRovert**, todas las contribuciones deben priorizar la precisión en la orquestación y el bajo impacto en CPU.

---

## 🛡️ Estándares Técnicos (Squad Core)

Este AddOn está optimizado para **Turtle WoW** (WoW v1.12.1). Las contribuciones DEBEN cumplir con:

1.  **Sync Priority**: No añadas funciones de red que aumenten la latencia de sincronización de marcas tácticas.
2.  **No Lua 5.1+**: El motor es Lua 5.0. Prohibido el operador `#` (usa `table.getn`).
3.  **Scan Throttling**: El motor de escaneo de banda no debe saturar el hilo principal. Usa búferes rotativos para el procesamiento de ráfagas grandes de datos de combate.
4.  **Network Efficiency**: Los paquetes de sincronización táctica DEBEN ser optimizados en tamaño para no saturar el ancho de banda del canal de hermandad/banda.

## 📐 Arquetipo de Desarrollo

Si deseas contribuir:
- **`Core.lua`**: Es el cerebro táctico. Cualquier cambio en la lógica de decisión requiere validación en encuentros de 40 jugadores.
- **`Commands.lua`**: Registro de comandos de orquestación. Asegúrate de que los comandos de líder tengan prioridad sobre los de los ayudantes.
- **`Modules/`**: Mantén la arquitectura modular para que nuevas mecánicas de jefes puedan añadirse sin alterar el núcleo.

## 💎 Proceso de Pull Request

1.  **Fork & Branch**: Trabaja en ramas descriptivas (`fix/scan-latency`, `feature/raid-pattern`).
2.  **Documentación**: Actualiza `CHANGELOG.md` antes de enviar el PR.
3.  **Branding**: Mantén los enlaces institucionales oficiales de **DarckRovert**.

---
© 2026 **DarckRovert** — El Séquito del Terror.
*Orquestando la victoria a través de la inteligencia artificial.*