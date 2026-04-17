extends Node2D

@onready var doors_points: Node2D = $"../Doors_Points"

@onready var point_2: Marker2D = $POINT_2
@onready var point_4: Marker2D = $POINT_4
@onready var point_1: Marker2D = $POINT_1
@onready var point_3: Marker2D = $POINT_3

const ROOM_COMUN_2 = preload("uid://djnypdxm07xxi")

var rooms_list : Array = []
var Position_list_used : Array = []

func _ready() -> void:
	rooms_list = [point_2, point_1, point_3, point_4]
	
func Instanciar_Room():
	var no_usados = rooms_list.filter(func(e):
		return not Position_list_used.has(e)
	)

	if no_usados.is_empty():
		return null

	# Elegimos un punto aún no usado
	var pick = no_usados.pick_random()
	Position_list_used.append(pick)
	
	if pick == point_1:
		doors_points.GENERATE_DEFOULT_DOOR(1)
	elif pick == point_2:
		doors_points.GENERATE_DEFOULT_DOOR(2)
	elif pick == point_3:
		doors_points.GENERATE_DEFOULT_DOOR(3)
	elif pick == point_4:
		doors_points.GENERATE_DEFOULT_DOOR(4)
	
	# Instanciación
	var instancia_room = ROOM_COMUN_2.instantiate()
	var ecena_level = get_tree().current_scene.get_node("LevelGeneratorMap")
	
	# 1. Lo agregás al punto elegido
	pick.add_child(instancia_room)
	
	var obtener_door_poins_instancia = instancia_room.get_node("Doors_Points")
	
	if pick == point_1:
		obtener_door_poins_instancia.GENERATE_DEFOULT_DOOR(3)
	elif pick == point_2:
		obtener_door_poins_instancia.GENERATE_DEFOULT_DOOR(4)
	elif pick == point_3:
		obtener_door_poins_instancia.GENERATE_DEFOULT_DOOR(1)
	elif pick == point_4:
		obtener_door_poins_instancia.GENERATE_DEFOULT_DOOR(2)
	
	# 2. Guardás su transform global
	var global_xform = instancia_room.global_transform

	# 3. Movés al nivel final
	ecena_level.add_child(instancia_room)

	# 4. Restaurás la posición exacta
	instancia_room.global_transform = global_xform

	return instancia_room
	
