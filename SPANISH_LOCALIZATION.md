# 🌐 Sistema de Localización Español

## TerrorSquadAI v2.2.0 - Soporte para Cliente Español

### 🎯 Descripción

TerrorSquadAI ahora incluye un sistema completo de localización que permite que el addon funcione perfectamente con el cliente de WoW en español. El sistema traduce automáticamente los nombres de hechizos del español al inglés para que todos los módulos funcionen correctamente.

### ✨ Características

- **Traducción Automática**: Convierte nombres de hechizos español→inglés en tiempo real
- **100+ Hechizos**: Base de datos completa con traducciones para todas las clases
- **Detección Automática**: Detecta el idioma del cliente y activa el sistema solo si es necesario
- **Sin Configuración**: Funciona automáticamente, no requiere configuración manual
- **Hooks Inteligentes**: Intercepta llamadas a funciones de la API para traducir nombres
- **Caché de Rendimiento**: Sistema de caché para optimizar traducciones frecuentes

### 📚 Hechizos Traducidos

El sistema incluye traducciones para:

#### Guerrero (Warrior)
- Temeridad, Muro de escudo, Represalia, Deseo de muerte, Golpes arrolladores
- Golpe con escudo, Golpe heroico, Golpe mortal, Sed de sangre, Ejecutar

#### Paladín (Paladin)
- Escudo divino, Imposición de manos, Bendición de protección
- Martillo de la justicia, Favor divino, Luz sagrada, Destello de luz

#### Cazador (Hunter)
- Fuego rápido, Ira bestial, Disuasión, Fingir muerte
- Intimidación, Disparo de dispersión, Trampa de hielo

#### Pícaro (Rogue)
- Evasión, Ráfaga de hojas, Subidón de adrenalina
- Sangre fría, Preparación, Patada, Golpe bajo

#### Sacerdote (Priest)
- Infusión de poder, Concentración interna, Custodia contra el miedo
- Grito psíquico, Sanar, Sanación superior, Sanación rápida

#### Chamán (Shaman)
- Sed de sangre, Rapidez de la naturaleza, Maestría elemental
- Tótem de conexión a tierra, Golpe de tormenta, Descarga de la Tierra

#### Mago (Mage)
- Bloque de hielo, Evocación, Combustión, Presencia de ánimo
- Reajuste de Escarcha, Contrahechizo, Polimorfia, Pirobola

#### Brujo (Warlock)
- Espiral de la muerte, Aullido de terror, Amplificar maldición
- Conflagrar, Bloqueo de hechizo, Descarga de las Sombras

#### Druida (Druid)
- Corteza, Rapidez de la naturaleza, Tranquilidad
- Regeneración frenética, Restablecimiento rápido, Toque de sanación

### 🛠️ Comandos de Diagnóstico

#### `/tsailocale [hechizo]`
Verifica el sistema de localización y traduce un hechizo específico.

**Ejemplos:**
```
/tsailocale
/tsailocale Escudo divino
/tsailocale Evasión
```

**Salida:**
- Idioma del cliente detectado
- Estado del sistema de localización
- Número de hechizos en la base de datos
- Traducción del hechizo especificado

#### `/tsaispells [filtro]`
Lista todos los hechizos traducidos. Opcionalmente filtra por texto.

**Ejemplos:**
```
/tsaispells
/tsaispells escudo
/tsaispells heal
```

**Salida:**
- Lista de hechizos en formato: Español -> Inglés
- Máximo 20 resultados por consulta
- Ordenados alfabéticamente

### 💻 Archivos del Sistema

#### `TerrorSquadAI_SpellLocalization.lua`
Base de datos de traducciones con:
- Diccionario completo Español→Inglés
- Función `TerrorSquadAI_TranslateSpell()`
- Función `TerrorSquadAI_GetSpanishName()` (inversa)
- Función `TerrorSquadAI_IsSpanishClient()`

#### `TerrorSquadAI_Patch.lua`
Sistema de hooks que:
- Intercepta `GetSpellName()` para traducir nombres
- Intercepta `UnitBuff()` y `UnitDebuff()` para buffs/debuffs
- Hook de `CooldownTracker:OnSpellCast()`
- Hook de `InterruptCoordinator:OnSpellcastStart()`
- Hook de `InterruptCoordinator:OnChannelStart()`
- Registra comandos de diagnóstico

### ⚙️ Cómo Funciona

1. **Detección**: Al cargar, el sistema detecta si el cliente está en español usando `GetLocale()`

2. **Activación**: Si es cliente español, activa los hooks automáticamente

3. **Traducción**: Cuando un módulo solicita un nombre de hechizo:
   - El hook intercepta la llamada
   - Busca el nombre en la base de datos
   - Devuelve el nombre en inglés si existe traducción
   - Devuelve el nombre original si no hay traducción

4. **Procesamiento**: Los módulos procesan el hechizo con el nombre en inglés

### 🐛 Solución de Problemas

#### El addon no detecta hechizos
1. Verifica que el cliente esté en español: `/tsailocale`
2. Verifica que el hechizo esté en la base de datos: `/tsaispells [nombre]`
3. Si falta, puedes agregarlo editando `TerrorSquadAI_SpellLocalization.lua`

#### Los cooldowns no se rastrean
1. Verifica que el sistema esté activo: `/tsailocale`
2. Verifica los hooks: Deberías ver mensajes al cargar el addon
3. Reinicia el juego si es necesario

#### Las interrupciones no se coordinan
1. Verifica que el hechizo enemigo esté traducido: `/tsaispells [nombre]`
2. Verifica que tu habilidad de interrupción esté traducida

### ➕ Agregar Nuevos Hechizos

Para agregar un hechizo que falta:

1. Abre `TerrorSquadAI_SpellLocalization.lua`
2. Encuentra la sección de tu clase
3. Agrega una línea:
   ```lua
   TerrorSquadAI_SpellDB["Nombre en Español"] = "English Name"
   ```
4. Guarda y reinicia el juego

**Ejemplo:**
```lua
-- Agregar un hechizo de Mago
TerrorSquadAI_SpellDB["Nova de Escarcha"] = "Frost Nova"
```

### 📊 Estado del Sistema

**Versión:** 2.2.0
**Hechizos Traducidos:** 100+
**Clases Soportadas:** Todas (Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Mage, Warlock, Druid)
**Estado:** Completamente funcional

### 📝 Notas Técnicas

- Compatible con WoW Vanilla 1.12 (Turtle WoW)
- Usa Lua 5.0 (versión de Vanilla)
- No afecta el rendimiento (hooks optimizados)
- Sistema de caché para traducciones frecuentes
- Funciona con BigWigs y otros addons

---

**Creado por:** DarckRovert (elnazzareno)
**Para:** El Sequito del Terror
**Fecha:** Enero 2026
