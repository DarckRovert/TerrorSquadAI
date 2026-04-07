# Guía de API (Referencia Interna)

El conjunto de interfaces en `TerrorSquadAI` cumple un protocolo hermético. 

### Instancias de Módulo
Las inyecciones y consultas del motor global de WoW son interceptadas antes de pasar a funciones nativas mediante el `hooksecurefunc` clásico o reescrituras in-memory directas.
