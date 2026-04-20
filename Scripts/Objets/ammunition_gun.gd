extends RigidBody2D

@export var fuerza_empuje: float = 100.0 
@onready var anim_gun: AnimationPlayer = $Anim_gun

func _ready() -> void:
	# Esto hace que se frene solo gradualmente
	linear_damp = 4.0 
	# También frenamos la rotación para que no gire para siempre
	angular_damp = 3.0 

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		var direccion = (global_position - body.global_position).normalized()
		apply_central_impulse(direccion * fuerza_empuje)
		anim_gun.play("Empuje")
