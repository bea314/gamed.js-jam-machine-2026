extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal shield_changed(current_shield: int, max_shield: int)
## `hit_from_global` es la posición del atacante (o Vector2.ZERO si no aplica); sirve para knockback.
signal damage_taken(amount: int, hit_from_global: Vector2)
## Daño absorbido por escudo (no quita vida). Para feedback en HUD sin animación de hurt.
signal shield_damage_taken(amount: int, hit_from_global: Vector2)
signal died()

@export var max_health: int = 100
@export var max_shield: int = 100
## Segundos de invulnerabilidad tras recibir daño (0 = desactivado).
@export var hit_invulnerability_duration: float = 0.12
@export var damage_taken_multiplier: float = 1.0

var current_health: int
var current_shield: int = 0
var _invuln_remaining: float = 0.0


func _ready() -> void:
	current_health = max_health
	# Escudo y vida comparten tope para evitar sobrellenado de escudo.
	max_shield = max_health
	current_shield = mini(current_shield, max_shield)
	_emit_health_changed()
	_emit_shield_changed()


func _process(delta: float) -> void:
	_invuln_remaining = maxf(_invuln_remaining - delta, 0.0)
	if _invuln_remaining <= 0.0:
		set_process(false)


func is_invulnerable() -> bool:
	return _invuln_remaining > 0.0


## Invulnerabilidad sin recibir golpe (p. ej. dash). Se acumula con el tiempo ya activo.
func grant_invulnerability(duration: float) -> void:
	if duration <= 0.0:
		return
	_invuln_remaining = maxf(_invuln_remaining, duration)
	set_process(true)


func set_damage_taken_multiplier(multiplier: float) -> void:
	damage_taken_multiplier = maxf(multiplier, 0.01)


func take_damage(amount: int, hit_from_global: Vector2 = Vector2.ZERO) -> void:
	if amount <= 0:
		return
	if hit_invulnerability_duration > 0.0 and _invuln_remaining > 0.0:
		return

	var scaled_amount := maxi(int(round(float(amount) * damage_taken_multiplier)), 1)
	var pending_damage: int = scaled_amount
	var absorbed_by_shield: int = 0

	if current_shield > 0:
		var shield_before: int = current_shield
		current_shield = maxi(current_shield - pending_damage, 0)
		absorbed_by_shield = shield_before - current_shield
		pending_damage -= absorbed_by_shield
		_emit_shield_changed()

	if pending_damage <= 0:
		if absorbed_by_shield > 0:
			shield_damage_taken.emit(absorbed_by_shield, hit_from_global)
		if hit_invulnerability_duration > 0.0:
			_invuln_remaining = hit_invulnerability_duration
			set_process(true)
		return

	var before: int = current_health
	current_health = maxi(current_health - pending_damage, 0)
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


func add_shield(amount: int) -> void:
	if amount <= 0:
		return
	current_shield = mini(current_shield + amount, max_shield)
	_emit_shield_changed()


func clear_shield() -> void:
	current_shield = 0
	_emit_shield_changed()


func _emit_health_changed() -> void:
	health_changed.emit(current_health, max_health)


func _emit_shield_changed() -> void:
	shield_changed.emit(current_shield, max_shield)
