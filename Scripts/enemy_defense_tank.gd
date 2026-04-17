extends "res://Scripts/enemy_basic.gd"

@export var defense_flat: int = 4
@export var defense_multiplier: float = 0.6
## Rect ~82×64: suele ir ~56; el básico hereda 28. Se copia a `stop_distance` del padre.
@export var tank_stop_distance: float = 56.0
@export var tank_attack_range: float = 64.0


func _ready() -> void:
	super()
	stop_distance = tank_stop_distance
	attack_range = tank_attack_range


func take_damage(amount: int) -> void:
	if amount <= 0:
		return

	# Flat armor + percentage mitigation: this enemy is tankier.
	var reduced := maxi(amount - defense_flat, 1)
	var final_damage := maxi(int(round(reduced * defense_multiplier)), 1)
	_current_health = maxi(_current_health - final_damage, 0)
	if _current_health == 0:
		queue_free()
