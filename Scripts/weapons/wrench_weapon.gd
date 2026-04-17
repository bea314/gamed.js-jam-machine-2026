extends WeaponBase

@export var melee_scene: PackedScene


func try_fire(owner_node: Node2D, aim_direction: Vector2) -> void:
	if not can_fire or is_reloading:
		return
	if melee_scene == null:
		return

	var hitbox := melee_scene.instantiate()
	owner_node.get_tree().current_scene.add_child(hitbox)
	hitbox.set("damage", damage)
	hitbox.call("activate", owner_node, aim_direction)

	weapon_fired.emit()
	_start_fire_cooldown()


func try_reload() -> void:
	pass
