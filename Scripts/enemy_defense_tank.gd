extends "res://Scripts/enemy_basic.gd"

## Rect ~82×64: suele ir ~56; el básico hereda 28. Se copia a `stop_distance` del padre.
@export var tank_stop_distance: float = 56.0
@export var tank_attack_range: float = 64.0


func _ready() -> void:
	super()
	stop_distance = tank_stop_distance
	attack_range = tank_attack_range
