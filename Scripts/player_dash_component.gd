extends Node
class_name PlayerDashComponent

signal dash_started()
signal dash_ended()

@export var dash_speed: float = 480.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.48

var _dash_dir: Vector2 = Vector2.RIGHT
var _time_left: float = 0.0
var _cooldown_left: float = 0.0

var _health: HealthComponent


func _ready() -> void:
	var p := get_parent()
	assert(p is CharacterBody2D, "PlayerDashComponent must be child of CharacterBody2D")
	_health = p.get_node_or_null("HealthComponent") as HealthComponent


func tick(delta: float) -> void:
	if _time_left > 0.0:
		_time_left -= delta
		if _time_left <= 0.0:
			dash_ended.emit()
			_cooldown_left = dash_cooldown
	elif _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func is_dashing() -> bool:
	return _time_left > 0.0


func can_dash() -> bool:
	return _time_left <= 0.0 and _cooldown_left <= 0.0


func try_dash(direction: Vector2) -> bool:
	if not can_dash():
		return false
	if direction.length_squared() < 0.0001:
		return false
	_dash_dir = direction.normalized()
	_time_left = dash_duration
	if _health:
		_health.grant_invulnerability(dash_duration)
	dash_started.emit()
	return true


func get_dash_velocity() -> Vector2:
	return _dash_dir * dash_speed
