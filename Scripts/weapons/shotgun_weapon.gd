extends WeaponBase

@export var blast_scene: PackedScene
@export var muzzle_offset: float = 18.0
@export var reload_time: float = 1.4


func try_fire(owner_node: Node2D, aim_direction: Vector2) -> void:
	if not can_fire or is_reloading:
		return
	if current_ammo <= 0:
		return
	if blast_scene == null:
		return

	var aim := aim_direction.normalized()
	var blast := blast_scene.instantiate() as Area2D
	if blast.has_method("configure"):
		blast.call(
			"configure",
			owner_node.global_position + aim * muzzle_offset,
			aim,
			owner_node.global_position,
			damage
		)
	owner_node.get_tree().current_scene.add_child(blast)
	if blast.has_method("run_blast"):
		blast.call_deferred("run_blast")

	current_ammo -= 1
	_emit_ammo()
	weapon_fired.emit()
	_start_fire_cooldown()


func try_reload() -> void:
	start_standard_reload(reload_time)
