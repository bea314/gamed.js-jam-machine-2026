extends Node2D

@onready var door_pos_2: Marker2D = $DOOR_Pos2
@onready var door_pos_4: Marker2D = $DOOR_Pos4
@onready var door_pos_3: Marker2D = $DOOR_Pos3
@onready var door_pos_1: Marker2D = $DOOR_Pos1

const DOORS_COMMUN_CONNECT = preload("uid://c7fqcn6qoujmc")
const DOORS_COMMUN = preload("uid://d2kbhr3pflg3i")

var rooms_list: Array[Marker2D] = []
var ROOM_USED: Array[Marker2D] = []

@onready var comp_rooms_vecinas: Node2D = $"../Comp_Rooms_Vecinas"

func _ready() -> void:
	rooms_list = [door_pos_1, door_pos_2, door_pos_3, door_pos_4]

func Add_ROOM_USED(Lugares : int):
	if Lugares == 1:
		ROOM_USED.append(door_pos_1)
	elif Lugares == 2:
		ROOM_USED.append(door_pos_2)
	elif Lugares == 3:
		ROOM_USED.append(door_pos_3)
	elif Lugares == 4:
		ROOM_USED.append(door_pos_4)
	
	comp_rooms_vecinas.queue_free()

func Generate_DOOR(pos : int):
	var instancia_DOOR = DOORS_COMMUN.instantiate()
	
	if pos == 1:
		door_pos_1.add_child(instancia_DOOR)
		instancia_DOOR.rotation_degrees = -90
	elif pos == 2:
		door_pos_1.add_child(instancia_DOOR)
		instancia_DOOR.rotation_degrees = 0
	elif pos == 3:
		door_pos_1.add_child(instancia_DOOR)
		instancia_DOOR.rotation_degrees = 90
	elif pos == 4:
		door_pos_1.add_child(instancia_DOOR)
		instancia_DOOR.rotation_degrees = -180
		
	instancia_DOOR.lado_door = pos
	print(instancia_DOOR.lado_door)

func Generate_Random_DOOR(DOOR_TYPE : PackedScene):
	var disponibles = rooms_list.filter(func(m): return not ROOM_USED.has(m))

	if disponibles.is_empty():
		return
	
	var marker = disponibles.pick_random()
	
	var instancia_DOOR = DOOR_TYPE.instantiate()
	var pos 
	if marker == door_pos_1:
		marker.add_child(instancia_DOOR)
		instancia_DOOR.rotation_degrees = -90
		pos = 1
	elif marker == door_pos_2:
		marker.add_child(instancia_DOOR)
		instancia_DOOR.rotation_degrees = 0
		pos = 2
	elif marker == door_pos_3:
		marker.add_child(instancia_DOOR)
		instancia_DOOR.rotation_degrees = 90
		pos = 3
	elif marker == door_pos_4:
		marker.add_child(instancia_DOOR)
		instancia_DOOR.rotation_degrees = -180
		pos = 4
	
	Add_ROOM_USED(pos)
	
	instancia_DOOR.lado_door = pos
	print(instancia_DOOR.lado_door)
