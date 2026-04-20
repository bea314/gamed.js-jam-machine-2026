extends Node2D

@onready var room_comun_01: Node2D = $".."

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

func Add_ROOM_USED():
	pass

func Instanciar_Room():
	
	var no_usados = rooms_list.filter(func(e):
		return not Position_list_used.has(e)
	)

	if no_usados.is_empty():
		return null

	# Elegimos un punto aún no usado
	var pick = no_usados.pick_random()
	Position_list_used.append(pick)
	
