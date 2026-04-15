extends CharacterBody2D

@export var speed: float = 170.0

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	
	# Inputs Movimioento
	direction.x = Input.get_action_strength("Mover_derecha") - Input.get_action_strength("Mover_izquierda")
	direction.y = Input.get_action_strength("Mover_abajo") - Input.get_action_strength("Mover_arriba")
	
	# Normalizar diagonal
	direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()
