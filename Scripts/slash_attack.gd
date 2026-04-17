extends Area2D

## Short-lived melee hitbox. Damages bodies that implement `take_damage` (e.g. enemies).
## Tune duration and shape in the scene; tune damage via export or inspector.
## collision_mask must include the enemy physics layer (project: "enemy" = bit 2 = 4) or overlaps won't occur.

@export var damage: int = 10
@export var lifetime: float = 0.15

var _hit_bodies: Dictionary = {}


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _on_body_entered(body: Node) -> void:
	if body == null or not is_instance_valid(body):
		return
	if body.is_in_group("player"):
		return
	if _hit_bodies.has(body):
		return
	if not body.has_method("take_damage"):
		return

	_hit_bodies[body] = true
	body.call("take_damage", damage)
