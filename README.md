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

## Arte y contenido (lista de trabajo)

- Protagonista (cucaracha), mapa, enemigos, obstáculos, puertas, aparatos destructibles.
- Armas (idealmente **manos separadas** como assets para animar).
- Intro, UI y menús.
- Animaciones: caminar, usar armas, coger buffs/armas, daño, muerte.

## Proyecto técnico

- Motor: **Godot 4.6**
- Carpeta de escenas: `Ecenes/` (convención actual del repo)
- Scripts: `Scripts/`

## Cómo abrir el proyecto

1. Instala [Godot 4.6](https://godotengine.org/) (o la versión indicada en `project.godot`).
2. Abre Godot → **Import** → selecciona la carpeta del proyecto → **Import & Edit**.
3. Ejecuta la escena de prueba desde el editor (p. ej. `Ecenes/Level_test.tscn` según tu configuración).

---

*Documento vivo: actualiza victoria/derrota, número de niveles y armas cuando el diseño cierre.*
