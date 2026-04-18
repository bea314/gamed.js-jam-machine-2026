extends Node2D
class_name EnemyTurretRingVisual

## Anillo de la onda expansiva (solo dibujo).

var ring_radius: float = 0.0
var active: bool = false


func _draw() -> void:
	if not active or ring_radius <= 2.0:
		return
	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 72, Color(1, 0.38, 0.12, 0.62), 3.0, true)
