extends Node
class_name BuffRuntimeComponent

signal buff_applied(buff_type: String, duration: float, magnitude: float)
signal buff_expired(buff_type: String)

@export var damage_duration: float = 10.0
@export var speed_duration: float = 10.0

@export var damage_multiplier: float = 1.3
@export var shield_amount: int = 40
@export var speed_multiplier: float = 1.25

var _remaining: Dictionary = {}
var _active: Dictionary = {}
var _total: Dictionary = {}

var _player: Node = null
var _weapon_manager: Node = null
var _health: HealthComponent = null
var _dash: PlayerDashComponent = null


func _ready() -> void:
	_player = get_parent()
	_health = _player.get_node_or_null("HealthComponent") as HealthComponent
	_dash = _player.get_node_or_null("PlayerDash") as PlayerDashComponent
	if _player != null:
		_weapon_manager = _player.get_node_or_null("WeaponPivot/WeaponManager")
	set_process(false)


func apply_buff(buff_type: String, duration_override: float = -1.0, magnitude_override: float = -1.0) -> void:
	if not BuffType.ALL.has(buff_type):
		return
	if buff_type == BuffType.SHIELD:
		_apply_shield_buff(magnitude_override)
		return
	var duration := _default_duration(buff_type)
	if duration_override > 0.0:
		duration = duration_override
	var magnitude := _default_magnitude(buff_type)
	if magnitude_override > 0.0:
		magnitude = magnitude_override
	_activate_effect(buff_type, magnitude)
	_remaining[buff_type] = duration
	_total[buff_type] = duration
	_active[buff_type] = magnitude
	set_process(true)
	buff_applied.emit(buff_type, duration, magnitude)


func has_buff(buff_type: String) -> bool:
	return _remaining.get(buff_type, 0.0) > 0.0


func get_remaining_time(buff_type: String) -> float:
	return float(_remaining.get(buff_type, 0.0))


func get_total_time(buff_type: String) -> float:
	return float(_total.get(buff_type, 0.0))


func _process(delta: float) -> void:
	var still_active := false
	for buff_type in _remaining.keys():
		var left := maxf(float(_remaining[buff_type]) - delta, 0.0)
		_remaining[buff_type] = left
		if left <= 0.0:
			_deactivate_effect(str(buff_type))
			_remaining.erase(buff_type)
			_total.erase(buff_type)
			_active.erase(buff_type)
			buff_expired.emit(str(buff_type))
		else:
			still_active = true
	set_process(still_active)


func _apply_shield_buff(magnitude_override: float) -> void:
	if _health == null:
		return
	var amount: int = shield_amount
	if magnitude_override > 0.0:
		amount = maxi(int(round(magnitude_override)), 1)
	_health.add_shield(amount)
	buff_applied.emit(BuffType.SHIELD, 0.0, float(amount))


func _activate_effect(buff_type: String, magnitude: float) -> void:
	match buff_type:
		BuffType.DAMAGE:
			if _weapon_manager != null and _weapon_manager.has_method("set_damage_multiplier"):
				_weapon_manager.set_damage_multiplier(magnitude)
		BuffType.SPEED:
			if _player != null and _player.has_method("set_speed_multiplier"):
				_player.set_speed_multiplier(magnitude)
			if _dash != null and _dash.has_method("set_dash_speed_multiplier"):
				_dash.set_dash_speed_multiplier(magnitude)


func _deactivate_effect(buff_type: String) -> void:
	match buff_type:
		BuffType.DAMAGE:
			if _weapon_manager != null and _weapon_manager.has_method("set_damage_multiplier"):
				_weapon_manager.set_damage_multiplier(1.0)
		BuffType.SPEED:
			if _player != null and _player.has_method("set_speed_multiplier"):
				_player.set_speed_multiplier(1.0)
			if _dash != null and _dash.has_method("set_dash_speed_multiplier"):
				_dash.set_dash_speed_multiplier(1.0)


func _default_duration(buff_type: String) -> float:
	match buff_type:
		BuffType.DAMAGE:
			return damage_duration
		BuffType.SPEED:
			return speed_duration
		_:
			return 0.0


func _default_magnitude(buff_type: String) -> float:
	match buff_type:
		BuffType.DAMAGE:
			return damage_multiplier
		BuffType.SPEED:
			return speed_multiplier
		_:
			return 1.0
