extends Node
class_name BuffRuntimeComponent

signal buff_applied(buff_type: String, stack_value: int, applied_amount: int, wasted_amount: int)
signal buff_stack_changed(buff_type: String, stack_value: int)
signal stacks_reset()

@export var shield_amount: int = 40

var _damage_stacks: int = 0
var _speed_stacks: int = 0

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
	if _health != null and not _health.died.is_connected(_on_player_died):
		_health.died.connect(_on_player_died)
	_apply_damage_stacks()
	_apply_speed_stacks()


func apply_buff(buff_type: String, duration_override: float = -1.0, magnitude_override: float = -1.0) -> void:
	if not BuffType.ALL.has(buff_type):
		return
	if buff_type == BuffType.SHIELD:
		_apply_shield_buff(duration_override, magnitude_override)
		return
	match buff_type:
		BuffType.DAMAGE:
			var add_damage := _resolve_stack_add(duration_override, magnitude_override)
			_damage_stacks = maxi(_damage_stacks + add_damage, 0)
			_apply_damage_stacks()
			buff_stack_changed.emit(BuffType.DAMAGE, _damage_stacks)
			buff_applied.emit(BuffType.DAMAGE, _damage_stacks, add_damage, 0)
		BuffType.SPEED:
			var add_speed := _resolve_stack_add(duration_override, magnitude_override)
			_speed_stacks = maxi(_speed_stacks + add_speed, 0)
			_apply_speed_stacks()
			buff_stack_changed.emit(BuffType.SPEED, _speed_stacks)
			buff_applied.emit(BuffType.SPEED, _speed_stacks, add_speed, 0)


func has_buff(buff_type: String) -> bool:
	return get_stack_value(buff_type) > 0


func get_stack_value(buff_type: String) -> int:
	match buff_type:
		BuffType.DAMAGE:
			return _damage_stacks
		BuffType.SPEED:
			return _speed_stacks
		_:
			return 0


func get_shield_value_for_hud() -> int:
	if _health == null:
		return 0
	return _health.current_shield


func reset_stacks() -> void:
	_damage_stacks = 0
	_speed_stacks = 0
	_apply_damage_stacks()
	_apply_speed_stacks()
	buff_stack_changed.emit(BuffType.DAMAGE, _damage_stacks)
	buff_stack_changed.emit(BuffType.SPEED, _speed_stacks)
	stacks_reset.emit()


func _apply_shield_buff(duration_override: float, magnitude_override: float) -> void:
	if _health == null:
		return
	var amount := shield_amount
	if duration_override > 0.0:
		amount = maxi(int(round(duration_override)), 1)
	elif magnitude_override > 0.0:
		amount = maxi(int(round(magnitude_override)), 1)
	var before := _health.current_shield
	_health.add_shield(amount)
	var applied := maxi(_health.current_shield - before, 0)
	var wasted := maxi(amount - applied, 0)
	buff_applied.emit(BuffType.SHIELD, _health.current_shield, applied, wasted)


func _apply_damage_stacks() -> void:
	if _weapon_manager != null and _weapon_manager.has_method("set_damage_flat_bonus"):
		_weapon_manager.set_damage_flat_bonus(_damage_stacks)
	elif _weapon_manager != null and _weapon_manager.has_method("set_damage_multiplier"):
		_weapon_manager.set_damage_multiplier(1.0 + (float(_damage_stacks) * 0.1))


func _apply_speed_stacks() -> void:
	if _player != null and _player.has_method("set_movement_speed_flat_bonus"):
		_player.set_movement_speed_flat_bonus(_speed_stacks)
	elif _player != null and _player.has_method("set_speed_multiplier"):
		_player.set_speed_multiplier(1.0 + (float(_speed_stacks) * 0.1))
	if _dash != null and _dash.has_method("set_dash_speed_flat_bonus"):
		_dash.set_dash_speed_flat_bonus(_speed_stacks)
	elif _dash != null and _dash.has_method("set_dash_speed_multiplier"):
		_dash.set_dash_speed_multiplier(1.0 + (float(_speed_stacks) * 0.1))


func _resolve_stack_add(duration_override: float, magnitude_override: float) -> int:
	if duration_override > 0.0:
		return maxi(int(round(duration_override)), 1)
	if magnitude_override > 0.0:
		return maxi(int(round(magnitude_override)), 1)
	return 1


func _on_player_died() -> void:
	reset_stacks()
