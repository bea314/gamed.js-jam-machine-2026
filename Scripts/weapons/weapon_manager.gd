extends Node
class_name WeaponManager

signal weapon_changed(
	weapon_name: String,
	current_ammo: int,
	reserve_ammo: int,
	magazine_size: int,
	is_reloading: bool
)

@export var wrench_scene: PackedScene
@export var revolver_scene: PackedScene
@export var shotgun_scene: PackedScene
@export var machinegun_scene: PackedScene

var weapons: Array[WeaponBase] = []
var current_index: int = 0
var owner_player: Node2D


func setup(player: Node2D) -> void:
	owner_player = player

	var wrench := wrench_scene.instantiate() as WeaponBase
	var revolver := revolver_scene.instantiate() as WeaponBase
	var shotgun := shotgun_scene.instantiate() as WeaponBase
	var machinegun := machinegun_scene.instantiate() as WeaponBase

	weapons = [wrench, revolver, shotgun, machinegun]

	for w in weapons:
		add_child(w)
		w.ammo_changed.connect(_on_ammo_changed)
		w.reload_started.connect(_emit_weapon_changed)
		w.reload_finished.connect(_emit_weapon_changed)

	_emit_weapon_changed()


func current_weapon() -> WeaponBase:
	return weapons[current_index]


func fire(aim_direction: Vector2, pressed: bool, just_pressed: bool) -> void:
	var weapon := current_weapon()
	if weapon == null:
		return

	if weapon.automatic:
		if pressed:
			weapon.try_fire(owner_player, aim_direction)
	else:
		if just_pressed:
			weapon.try_fire(owner_player, aim_direction)


func reload() -> void:
	current_weapon().try_reload()


func next_weapon() -> void:
	if not _can_switch_weapons():
		return
	current_index = (current_index + 1) % weapons.size()
	_emit_weapon_changed()


func prev_weapon() -> void:
	if not _can_switch_weapons():
		return
	current_index = (current_index - 1 + weapons.size()) % weapons.size()
	_emit_weapon_changed()


func set_weapon(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return
	if not _can_switch_weapons():
		return
	current_index = index
	_emit_weapon_changed()


func _can_switch_weapons() -> bool:
	var w := current_weapon()
	# Melee (no magazine): always allow. Ranged: block while reloading.
	return w.magazine_size <= 0 or not w.is_reloading


func _on_ammo_changed(_current: int, _reserve: int) -> void:
	_emit_weapon_changed()


func _emit_weapon_changed() -> void:
	var w := current_weapon()
	weapon_changed.emit(
		w.weapon_name,
		w.current_ammo,
		w.reserve_ammo,
		w.magazine_size,
		w.is_reloading
	)
