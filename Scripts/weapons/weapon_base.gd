extends Node
class_name WeaponBase

signal ammo_changed(current: int, reserve: int)
signal weapon_fired()
signal reload_started()
signal reload_finished()

@export var weapon_name: String = "Weapon"
@export var damage: int = 1
@export var fire_rate: float = 0.3
@export var magazine_size: int = 0
@export var reserve_ammo: int = 0
@export var automatic: bool = false

var current_ammo: int = 0
var can_fire: bool = true
var is_reloading: bool = false


func _ready() -> void:
	current_ammo = magazine_size
	_emit_ammo()


func try_fire(_owner_node: Node2D, _aim_direction: Vector2) -> void:
	pass


func try_reload() -> void:
	pass


func _start_fire_cooldown() -> void:
	can_fire = false
	var timer := get_tree().create_timer(fire_rate)
	timer.timeout.connect(func() -> void:
		can_fire = true
	)


func _emit_ammo() -> void:
	ammo_changed.emit(current_ammo, reserve_ammo)


func start_standard_reload(reload_duration: float) -> void:
	if is_reloading or magazine_size <= 0:
		return
	if current_ammo >= magazine_size:
		return
	if reserve_ammo <= 0:
		return

	is_reloading = true
	reload_started.emit()
	var timer := get_tree().create_timer(reload_duration)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(self):
			return
		var needed: int = magazine_size - current_ammo
		var to_load: int = mini(needed, reserve_ammo)
		current_ammo += to_load
		reserve_ammo -= to_load
		is_reloading = false
		_emit_ammo()
		reload_finished.emit()
	)
