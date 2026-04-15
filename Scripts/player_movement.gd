extends CharacterBody2D

@export var speed: float = 170.0

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")

func _physics_process(_delta: float) -> void:
	# Izquierda/derecha, arriba/abajo (acciones en project.godot)
	var direction := Input.get_vector("Mover_izquierda", "Mover_derecha", "Mover_arriba", "Mover_abajo")
	velocity = direction * speed
	move_and_slide()
