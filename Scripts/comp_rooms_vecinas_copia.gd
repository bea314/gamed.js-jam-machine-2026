extends Node2D

@onready var ray_cas_arriba: RayCast2D = $RayCas_Arriba
@onready var ray_cas_abajo: RayCast2D = $RayCas_Abajo
@onready var ray_cas_izquierda: RayCast2D = $RayCas_Izquierda
@onready var ray_cas_derecha: RayCast2D = $RayCas_Derecha

@onready var room_comun_02: Node2D = $".."


func _physics_process(_delta: float) -> void:
	procesar_raycast(ray_cas_arriba, "POINT_3")
	procesar_raycast(ray_cas_abajo, "POINT_1")
	procesar_raycast(ray_cas_derecha, "POINT_4")
	procesar_raycast(ray_cas_izquierda, "POINT_2")
	
func procesar_raycast(ray: RayCast2D, point_name: String):
	if not ray.is_colliding():
		return
	
	var collider = ray.get_collider()
	if collider == null:
		return
	
	# Subimos al nodo padre (muy importante)
	var room = collider.get_parent()
	if room == null:
		return
	
	if not room.is_in_group("Room"):
		return
	
	# Validar que exista el nodo
	if not room.has_node("Spwan_ROOMS_POINTS"):
		return
	
	var spawner = room.get_node("Spwan_ROOMS_POINTS")
	
	if not spawner.has_node(point_name):
		return
	
	var point = spawner.get_node(point_name)
	
	# Validar que exista la variable
	if "ROOM_USED" in spawner:
		spawner.ROOM_USED.append(point)
