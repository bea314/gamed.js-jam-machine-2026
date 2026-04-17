extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
## `hit_from_global` es la posición del atacante (o Vector2.ZERO si no aplica); sirve para knockback.
signal damage_taken(amount: int, hit_from_global: Vector2)
signal died()

@export var max_health: int = 100
## Segundos de invulnerabilidad tras recibir daño (0 = desactivado).
@export var hit_invulnerability_duration: float = 0.12

var current_health: int
var _invuln_remaining: float = 0.0


func _ready() -> void:
	current_health = max_health
	_emit_health_changed()


func _process(delta: float) -> void:
	_invuln_remaining = maxf(_invuln_remaining - delta, 0.0)
	if _invuln_remaining <= 0.0:
		set_process(false)


func is_invulnerable() -> bool:
	return _invuln_remaining > 0.0


func take_damage(amount: int, hit_from_global: Vector2 = Vector2.ZERO) -> void:
	if amount <= 0:
		return
	if hit_invulnerability_duration > 0.0 and _invuln_remaining > 0.0:
		return

	var before: int = current_health
	current_health = maxi(current_health - amount, 0)
	var applied: int = before - current_health
	_emit_health_changed()
	if applied > 0:
		damage_taken.emit(applied, hit_from_global)
		if hit_invulnerability_duration > 0.0:
			_invuln_remaining = hit_invulnerability_duration
			set_process(true)

	if current_health == 0:
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0:
		return

	current_health = mini(current_health + amount, max_health)
	_emit_health_changed()


func _emit_health_changed() -> void:
	health_changed.emit(current_health, max_health)
