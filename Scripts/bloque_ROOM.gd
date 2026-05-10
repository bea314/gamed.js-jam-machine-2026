extends StaticBody2D


func Collicion_Mode(IS_ACTIVE: bool) -> void: # ACTIVA Y DESACTIVA COLLICIONES
	# WARNING : SIRVE PARA LA OPTIMISACION
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).disabled = not IS_ACTIVE
