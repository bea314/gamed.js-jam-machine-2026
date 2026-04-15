extends Node2D

@onready var doors_points: Node2D = $Doors_Points
@onready var level_rooms: Node2D = $".."

@export var Esta_Conectado : bool = false

# TIPOS DE ROOMS
const ROOM_COMUN_01 = preload("uid://0c71s8qxmeg4")

var Presupuesto_Doors : int

func Generate_ramal_Rooms(): # Genera la puertas y les otorga un presupuesto
	var cant_Rooms_Pick : int = randi_range(2,3)
	doors_points.cant_Doors = cant_Rooms_Pick
	
	var cant_doors_ins = doors_points.cant_Doors
	
	# Control Presupuesto ===============
	var presupuesto_dividido_una_parte = Presupuesto_Doors / cant_doors_ins
	# ===================================
	
	while cant_doors_ins > 0:
		doors_points.Generate_Door("Commun", presupuesto_dividido_una_parte)
		cant_doors_ins -= 1
