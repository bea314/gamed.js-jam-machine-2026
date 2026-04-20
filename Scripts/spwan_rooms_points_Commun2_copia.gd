extends Node2D

# PUNTOS SPAWN
@onready var point_2: Marker2D = $POINT_2
@onready var point_4: Marker2D = $POINT_4
@onready var point_1: Marker2D = $POINT_1
@onready var point_3: Marker2D = $POINT_3

var rooms_list : Array = []
var ROOM_USED : Array = []

@onready var doors_points: Node2D = $"../Doors_Points"

func _ready() -> void:
	rooms_list = [point_1, point_2, point_3, point_4]

func Instacniar_ROOM(ROOM : PackedScene):
	await get_tree().create_timer(0.5).timeout
	
	var no_usados = rooms_list.filter(func(e):
		return not ROOM_USED.has(e)
	)

	if no_usados.is_empty():
		return null

	# Elegimos un punto aún no usado
	var pick = no_usados.pick_random()
	ROOM_USED.append(pick)
	
	var Instanciar_room = ROOM.instantiate()
	
	pick.add_child(Instanciar_room)
	
	var get_door_generate_new_room = Instanciar_room.get_node("Doors_Points")
	
	if pick == point_1:
		get_door_generate_new_room.GENERATE_DOOR(3)
		doors_points.GENERATE_DEFOULT_DOOR(1)
	elif pick == point_2:
		get_door_generate_new_room.GENERATE_DOOR(4)
		doors_points.GENERATE_DEFOULT_DOOR(2)
	elif pick == point_3:
		get_door_generate_new_room.GENERATE_DOOR(1)
		doors_points.GENERATE_DEFOULT_DOOR(3)
	elif pick == point_4:
		get_door_generate_new_room.GENERATE_DOOR(2)
		doors_points.GENERATE_DEFOULT_DOOR(4)
	
	
