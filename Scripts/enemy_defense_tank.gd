extends "res://Scripts/enemy_basic.gd"

## Rect ~82×64: suele ir ~56; el básico hereda 28. Se copia a `stop_distance` del padre.
@export var tank_stop_distance: float = 56.0
@export var tank_attack_range: float = 64.0
## Un poco mayor que el alcance del golpe: empieza el wind-up antes del contacto.
@export var tank_detection_range: float = 88.0
## Golpes discretos con telegrafía clara entre uno y otro.
@export var tank_wind_up_duration: float = 0.35


func _ready() -> void:
	super()
	stop_distance = tank_stop_distance
	attack_range = tank_attack_range
	detection_range = tank_detection_range
	wind_up_duration = tank_wind_up_duration
	attack_continuous = false
