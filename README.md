# Jam_RL

Roguelike / dungeon-crawler en **Godot 4** donde controlas a una **cucaracha** infiltrada en la máquina de helados de un local de comida rápida (estilo McDonald’s). Tu objetivo es **caos y destrucción**: tienes que **romper el entorno y los sistemas más rápido de lo que la IA de la máquina puede reparar los daños**.

## Idea central (pitch)

En la reunión quedó definida la fantasía principal: una cucaracha que se mete dentro de la máquina de helados para **joder todo**. La tensión viene del contrarreloj contra la **IA reparadora**: si no destruyes lo suficiente a tiempo, el sistema se “cura” y te corta el avance.

La cucaracha lleva una **mochila** llena de artilugio pesado para destrozar la instalación: granadas, ametralladora, escopeta recortada, etc. **En cada run**, cada vez que sacas un arma de la mochila, **lo que te toca es aleatorio** — no sabes si saldrá lo mismo que la vez anterior.

## Condiciones de victoria y derrota (borrador de diseño)

- **Victoria:** derrotar al jefe final (IA / núcleo de la “máquina generativa”).
- **Derrota:** te matan los enemigos.

## Objetivos por run

- **Meta principal:** destruir la máquina de helados **más rápido** de lo que se auto-repara.
- **Progreso:** en una run hay que destruir **entre 1 y 3 dispositivos** concretos para pasar de nivel.
- **Final:** enfrentamiento contra el **núcleo / IA** de la máquina.

## Estructura (borrador)

- **3 niveles** tipo mazmorra (interior de la máquina / local).
- **Menú principal** y **menú de pausa** (pendiente de implementación en el proyecto).

## Mecánicas (borrador)

- Combate con **arma principal** + **3 armas extra** y **3 buffs** (detalle sujeto a iteración).
- Armas extra sacadas de la mochila con **resultado random por uso / por extracción** según el diseño actual.
- Sistema de combate actualmente en fase inicial, enfocado en validar:
  - **enemigo base**
  - **salud**
  - **daño**
  - **ataque básico**

## Estado actual del prototipo

Actualmente el proyecto está plantando la base jugable del combate con implementaciones iniciales para pruebas:

- **Enemigo básico** de prueba representado visualmente como un **cuadrado rojo**.
- **Sistema de salud** inicial para manejar vida máxima y vida actual.
- **Sistema de daño** para reducir salud y detectar derrota.
- **Sistema de ataque básico** para conectar al jugador con el daño hacia enemigos.

> Estas implementaciones son una base técnica para testeo y podrán expandirse más adelante con armas, comportamiento enemigo, efectos, animaciones y variantes de combate.

## Sistemas implementados / en prueba

### Enemigo básico
- Primer enemigo para probar el loop de combate.
- Placeholder visual simple con forma de cuadrado rojo.
- Sirve como base para movimiento, recepción de daño y muerte.

### Sistema de salud
- Manejo de `current_health` y `max_health`.
- Preparado para mostrar HUD / barra de vida.
- Base para futuras curaciones, mejoras y buffs.

### Sistema de daño
- Permite que entidades reciban daño.
- Reduce la salud de forma controlada.
- Evita que la vida baje de `0`.
- Activa lógica de derrota o muerte al llegar a cero.

### Sistema de ataque básico
- Primer ataque funcional orientado a pruebas.
- Enfocado en validar el flujo:
  - atacar
  - golpear
  - aplicar daño
  - eliminar enemigo
- La estructura apunta a permitir expansión futura hacia varias armas, pero por ahora se mantiene simple.

### Creación de mapas y salas
Existe un prototipo de generación de salas en `Ecenes/Map/` para probar niveles con **presupuesto** y **puertas aleatorias**.  
`Level_Rooms.tscn` genera un presupuesto inicial, la sala común abre entre **2 y 3 puertas**, y cada una recibe una parte de ese valor. Las puertas aparecen en lados aleatorios de la sala sin repetir posición en la misma generación.  
Actualmente este sistema sirve para testear la lógica base del mapa procedural.

## Arte y contenido (lista de trabajo)

- Protagonista (cucaracha), mapa, enemigos, obstáculos, puertas, aparatos destructibles.
- Armas (idealmente **manos separadas** como assets para animar).
- Intro, UI y menús.
- Animaciones: caminar, usar armas, coger buffs/armas, daño, muerte.
- HUD de salud y feedback visual de combate.

## Proyecto técnico

- Motor: **Godot 4.6**
- Carpeta de escenas: `Ecenes/` (convención actual del repo)
- Scripts: `Scripts/`

## Cómo abrir el proyecto

1. Instala [Godot 4.6](https://godotengine.org/) (o la versión indicada en `project.godot`).
2. Abre Godot → **Import** → selecciona la carpeta del proyecto → **Import & Edit**.
3. Ejecuta la escena de prueba desde el editor (p. ej. `Ecenes/Level_test.tscn` según tu configuración).

## Próximos pasos sugeridos

- Mejorar el comportamiento del enemigo base.
- Conectar HUD de salud con el jugador.
- Definir si el sistema de ataque evolucionará a:
  - un arma única, o
  - varias armas / ataques con comportamiento distinto.
- Agregar feedback visual y/o sonoro al recibir daño.
- Empezar pruebas con progresión, dispositivos destruibles y presión de autorreparación de la máquina.

---

*Documento vivo: actualiza victoria/derrota, número de niveles, sistemas de combate y estructura de armas cuando el diseño cierre.*