extends Node2D

@onready var ray_cas_arriba: RayCast2D = $RayCas_Arriba
@onready var ray_cas_abajo: RayCast2D = $RayCas_Abajo
@onready var ray_cas_izquierda: RayCast2D = $RayCas_Izquierda
@onready var ray_cas_derecha: RayCast2D = $RayCas_Derecha


@onready var doors_points: Node2D = $"../Doors_Points"
@onready var spwan_rooms_points: Node2D = $"../Spwan_ROOMS_POINTS"



func Detector_Raycast():
	ray_cas_arriba.force_raycast_update()
	ray_cas_abajo.force_raycast_update()
	ray_cas_izquierda.force_raycast_update()
	ray_cas_derecha.force_raycast_update()

	if ray_cas_arriba.is_colliding():
		doors_points.Add_ROOM_USED(1)
		spwan_rooms_points.ADD_ROOM_USED(1)

	if ray_cas_abajo.is_colliding():
		doors_points.Add_ROOM_USED(3)
		spwan_rooms_points.ADD_ROOM_USED(3)

	if ray_cas_izquierda.is_colliding():
		doors_points.Add_ROOM_USED(4)
		spwan_rooms_points.ADD_ROOM_USED(4)

	if ray_cas_derecha.is_colliding():
		doors_points.Add_ROOM_USED(2)
		spwan_rooms_points.ADD_ROOM_USED(2)
