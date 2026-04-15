extends Node2D

@onready var doors_points: Node2D = $Doors_Points
@onready var level_rooms: Node2D = $".."
@onready var Esta_Conectado : bool = false

# TIPOS DE ROOMS
const ROOM_COMUN_01 = preload("uid://0c71s8qxmeg4")

var Presupuesto_Doors : int


func _ready() -> void:
	Generate_Doors()

func Generate_ramal_Rooms(Presupuesto_Room : int):
	Generate_Doors()
	
	#for R : Node2D in level_rooms:
		#

func Generate_Doors():
	var cant_Rooms_Pick : int = randi_range(2,3)
	doors_points.cant_Doors = cant_Rooms_Pick
	
	while doors_points.cant_Doors > 0:
		doors_points.Generate_Door("Commun")
		doors_points.cant_Doors -= 1
