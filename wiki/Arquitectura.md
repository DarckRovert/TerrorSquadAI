# Arquitectura: TerrorSquadAI

Este documento establece la estructura interna modular de **TerrorSquadAI**.

## Principios Híbridos (Séquito-Tier)
El módulo ha sido aislado y perfilado para evitar advertencias "Too Many Upvalues" por los estrictos márgenes del VM Lua 5.0 clásico. Se mantiene latencia baja en la caché de tablas para asegurar la renderización en tiempo real junto con el Bridge de IA local.

Todo cambio estructural se registra y consolida a través de Gravity y el ecosistema unificado GitHub de [DarckRovert](https://github.com/DarckRovert). 
