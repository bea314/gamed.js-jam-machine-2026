extends Node2D

@onready var spwan_rooms_points: Node2D = $Spwan_ROOMS_POINTS
@onready var doors_points: Node2D = $Doors_Points

var Presupuesto_Level : int = 14


func _ready() -> void:
	Generate_ROOM_AND_DOOR(Presupuesto_Level)

func Generate_ROOM_AND_DOOR(Presupuesto_puntos : int):
	
	var Cant_Rooms : int = 2
	
	while Presupuesto_puntos > 0 and Cant_Rooms > 0:
		await get_tree().create_timer(0.2).timeout
		spwan_rooms_points.Instanciar_Room()
		
		
		Cant_Rooms -= 1
		Presupuesto_Level -= 7
		
		
