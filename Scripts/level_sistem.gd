extends Node2D

var Level_Points : int = 0


@onready var room_comun_01: Node2D = $RoomComun01

func _ready() -> void:
	var Points_Level_1 : int = randi_range(10,15)
	Level_Points = Points_Level_1  # <-- !WARNING PASARLE VALORES SEGUN EL NIVEL DE LA PARTIDA
	Generate_Level()
	
func Generate_Level():
	room_comun_01.Presupuesto_Doors = Level_Points
	room_comun_01.Generate_ramal_Rooms()
