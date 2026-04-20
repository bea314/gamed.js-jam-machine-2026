extends Node2D

@onready var point_1: Marker2D = $POINT_1
@onready var point_2: Marker2D = $POINT_2
@onready var point_3: Marker2D = $POINT_3
@onready var point_4: Marker2D = $POINT_4

@onready var current_room: Node2D = $".." # Asume que el nodo padre es la room
@onready var doors_points: Node2D = $"../Doors_Points"

var rooms_list: Array[Marker2D] = []
var ROOM_USED: Array[Marker2D] = []

const ROOM_DEFOULT = preload("uid://7twtc5bcs0h1")

var ROOMs_Posibles = [ROOM_DEFOULT]

func ADD_ROOM_USED(Lugar_Ocupado : int):
	if Lugar_Ocupado == 1:
		ROOM_USED.append(point_1)
	elif Lugar_Ocupado == 2:
		ROOM_USED.append(point_2)
	elif Lugar_Ocupado == 3:
		ROOM_USED.append(point_3)
	elif Lugar_Ocupado == 4:
		ROOM_USED.append(point_4)

func ADD_ROOM(Lugar_de_instancia :int):
	var get_level_generator = get_parent().get_parent()
	#var Pick_ROOM = ROOMs_Posibles.pick_random()
	var instancia_ROOM = ROOM_DEFOULT.instantiate()
	var lugar_contrario: int
	
	if Lugar_de_instancia == 1:
		get_level_generator.add_child(instancia_ROOM)
		instancia_ROOM.global_position = point_1.global_position
		lugar_contrario = 3
	elif Lugar_de_instancia == 2:
		get_level_generator.add_child(instancia_ROOM)
		instancia_ROOM.global_position = point_2.global_position
		lugar_contrario = 4
	elif Lugar_de_instancia == 3:
		get_level_generator.add_child(instancia_ROOM)
		instancia_ROOM.global_position = point_3.global_position
		lugar_contrario = 1
	elif Lugar_de_instancia == 4:
		get_level_generator.add_child(instancia_ROOM)
		instancia_ROOM.global_position = point_4.global_position
		lugar_contrario = 2
