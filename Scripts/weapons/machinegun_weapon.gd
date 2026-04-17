extends WeaponBase

@export var bullet_scene: PackedScene
@export var bullet_speed: float = 650.0
@export var reload_time: float = 1.6
@export var spread_degrees: float = 5.0


func try_fire(owner_node: Node2D, aim_direction: Vector2) -> void:
	if not can_fire or is_reloading:
		return
	if current_ammo <= 0:
		return
	if bullet_scene == null:
		return

	var aim := aim_direction.normalized()
	var half_spread := deg_to_rad(spread_degrees) * 0.5
	var offset := randf_range(-half_spread, half_spread)

	var bullet := bullet_scene.instantiate() as Area2D
	bullet.global_position = owner_node.global_position
	bullet.set("direction", aim.rotated(offset))
	bullet.set("damage", damage)
	bullet.set("speed", bullet_speed)
	bullet.set("damage_origin", owner_node.global_position)
	owner_node.get_tree().current_scene.add_child(bullet)

	current_ammo -= 1
	_emit_ammo()
	weapon_fired.emit()
	_start_fire_cooldown()


func try_reload() -> void:
	start_standard_reload(reload_time)
