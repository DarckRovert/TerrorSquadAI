# Arquitectura — TerrorSquadAI 🏗️

mermaid
graph TD
    CORE[TSAI Core Engine]
    PET_STATE[Pet State Monitor]
    GUARDIAN[Guardian Logic]
    UI[Control Interface]

    PET_STATE --> CORE
    GUARDIAN --> CORE
    CORE --> UI


## Componentes
- **Core.lua**: Motor de decisiones y ejecución de habilidades de mascotas.
- **Commands.lua**: Procesador de comandos de consola y chat del clan.
- **Modules/**: Contiene lógicas específicas (Guardian, Interrumpir, etc.).
