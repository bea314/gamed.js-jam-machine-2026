extends CharacterBody2D

@export var speed: float = 170.0
@onready var mesh_sistem: Node2D = $Mesh_Sistem

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	
	direction.x = Input.get_action_strength("Mover_derecha") - Input.get_action_strength("Mover_izquierda")
	direction.y = Input.get_action_strength("Mover_abajo") - Input.get_action_strength("Mover_arriba")
	
	direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()

	# Detección de caminar
	if is_walking():
		mesh_sistem.Change_State("Walk")
	else:
		mesh_sistem.Change_State("Idle")
		

func is_walking() -> bool:
	return velocity.length() > 0.1
	
