# Preguntas Frecuentes — TerrorSquadAI v9.3.0

## Uso General

**¿TerrorSquadAI requiere WCS_Brain?**
Sí. TerrorSquadAI usa el Event Manager y Resource Manager del WCS_Brain. Instala siempre el Brain primero.

**¿Funciona con todos los tipos de mascota Warlock?**
Sí: Diablillo (Imp), Víbora del Vacío (Voidwalker), Súcubo (Succubus), Felpardo (Felhunter) y Engendro Fel (Felguard). Cada uno tiene comportamientos optimizados.

**¿Cómo activo la IA automática?**
Escribe /tsa auto on. La IA tomará decisiones por tu mascota basándose en el contexto de combate.

**¿Puedo desactivar la IA para una mascota específica?**
Sí: /tsa auto off desactiva la automatización. Tu mascota responderá solo a órdenes manuales.

---

## Formaciones

**¿Qué formaciones hay disponibles?**
- delta — Triángulo ofensivo (3 mascotas atacan desde distintos flancos)
- cuña — Penetración frontal (mascotas lideran la carga)
- linea — Defensa horizontal (ideal para encuentros con múltiples enemigos)
- columna — Avance en fila (dungeons estrechos)
- caja — Protección circular (proteger a un objetivo)
- dispersion — Separación máxima (evitar AOE)

**¿Cómo cambio de formación en combate?**
/tsa formation delta — La transición ocurre en menos de 2 segundos si las mascotas están en rango.

---

## Problemas Comunes

**Mi mascota no responde a las órdenes de la IA.**
1. Verifica que /tsa auto on esté activo.
2. Asegúrate de que WCS_Brain esté cargado: /wb debe abrir el panel.
3. Usa /tsa reset para reiniciar el módulo.

**La IA envía a la mascota a atacar al objetivo equivocado.**
El sistema prioriza el objetivo del líder de raid. Si no estás en grupo, prioriza tu objetivo activo.

**¿Conflicto con otros addons de mascotas?**
Desactiva cualquier addon que use PetAttack, PetFollow o PetStay de forma automática, ya que puede causar conflictos de prioridad.

---

## Rendimiento

**¿Cuánta CPU usa TerrorSquadAI?**
Menos del 0.5% de ciclos gracias al motor de eventos compartido con WCS_Brain.

**¿Puedo usarlo en un PC de gama baja?**
Sí. El sistema adapta la frecuencia de evaluación de IA según el FPS actual del cliente.