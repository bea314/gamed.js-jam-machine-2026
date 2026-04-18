extends StaticBody2D

@onready var raycast_detector: RayCast2D = $Raycast_Detector
@onready var point_spawn: Marker2D = $"../Point_Spawn"

func _physics_process(delta):
	if raycast_detector.is_colliding():
		var col_obtenida = raycast_detector.get_collider()
		var col = col_obtenida.get_parent()
		
			# Asignar el Path con seguridad
		col.Path_TOGO = point_spawn
		await get_tree().create_timer(1.0).timeout
		
		if col.Path_TOGO != null:
			print("Se elimino la deteccion")
			queue_free()
