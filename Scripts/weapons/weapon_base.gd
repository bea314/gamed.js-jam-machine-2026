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
## <= 0 significa "sin tope".
@export var reserve_ammo_max: int = -1
@export var automatic: bool = false

var current_ammo: int = 0
var can_fire: bool = true
var is_reloading: bool = false
var _damage_multiplier: float = 1.0
var _damage_flat_bonus: int = 0


func _ready() -> void:
	current_ammo = magazine_size
	_emit_ammo()


func try_fire(_owner_node: Node2D, _aim_direction: Vector2) -> void:
	pass


func try_reload() -> void:
	pass


func set_damage_multiplier(multiplier: float) -> void:
	_damage_multiplier = maxf(multiplier, 0.01)


func get_damage_multiplier() -> float:
	return _damage_multiplier


func set_damage_flat_bonus(bonus: int) -> void:
	_damage_flat_bonus = bonus


func _final_damage() -> int:
	return maxi(int(round(float(damage) * _damage_multiplier)) + _damage_flat_bonus, 1)


func _start_fire_cooldown() -> void:
	can_fire = false
	var timer := get_tree().create_timer(fire_rate)
	timer.timeout.connect(func() -> void:
		can_fire = true
	)


func _emit_ammo() -> void:
	ammo_changed.emit(current_ammo, reserve_ammo)


## Suma munición a la reserva respetando el tope. Devuelve cuánto se añadió.
func add_reserve_ammo(amount: int) -> int:
	if amount <= 0:
		return 0
	if reserve_ammo_max > 0:
		var space := maxi(reserve_ammo_max - reserve_ammo, 0)
		if space <= 0:
			return 0
		var to_add := mini(amount, space)
		reserve_ammo += to_add
		_emit_ammo()
		return to_add
	reserve_ammo += amount
	_emit_ammo()
	return amount


func is_reserve_full() -> bool:
	if reserve_ammo_max <= 0:
		return false
	return reserve_ammo >= reserve_ammo_max


func start_standard_reload(reload_duration: float) -> void:
	if is_reloading or magazine_size <= 0:
		return
	if current_ammo >= magazine_size:
		return
	if reserve_ammo <= 0:
		return

	# Aplicar carga de inmediato para que HUD / reserva reflejen el cambio al pulsar R;
	# `reload_duration` sigue bloqueando disparo y animación hasta completarse.
	var needed: int = magazine_size - current_ammo
	var to_load: int = mini(needed, reserve_ammo)
	current_ammo += to_load
	reserve_ammo -= to_load

	is_reloading = true
	_emit_ammo()
	reload_started.emit()

	var timer := get_tree().create_timer(reload_duration)
	timer.timeout.connect(func() -> void:
		if not is_instance_valid(self):
			return
		is_reloading = false
		_emit_ammo()
		reload_finished.emit()
	)
