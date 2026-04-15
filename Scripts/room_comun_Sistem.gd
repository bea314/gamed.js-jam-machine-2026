extends Node2D

@onready var doors_points: Node2D = $Doors_Points
@onready var level_rooms: Node2D = $".."

@export var Esta_Conectado : bool = false

# TIPOS DE ROOMS
const ROOM_COMUN_01 = preload("uid://0c71s8qxmeg4")

var Presupuesto_Doors : int

func Generate_ramal_Rooms():
	var cant_Rooms_Pick: int = randi_range(2, 3)
	print("Cantidad:", cant_Rooms_Pick)

	doors_points.cant_Doors = cant_Rooms_Pick

	var presupuesto_dividido = Presupuesto_Doors / doors_points.cant_Doors

	while doors_points.cant_Doors > 0:
		doors_points.Generate_Door("Commun", presupuesto_dividido)
		doors_points.cant_Doors -= 1
