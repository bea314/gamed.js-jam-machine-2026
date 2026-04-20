extends Node2D

@onready var spwan_rooms_points: Node2D = $Spwan_ROOMS_POINTS
@onready var doors_points: Node2D = $Doors_Points

var Presupuesto_Level : int = 14


func _ready() -> void:
	Generate_ROOM_AND_DOOR(Presupuesto_Level)
	
	# OBTENER CAMERA y selecciona este mapa como path
	var get_camera = get_tree().current_scene.get_node("CameraGameplay")
	get_camera.Map_Path = self
	get_camera.Zoom_type(false,self)

func Generate_ROOM_AND_DOOR(Presupuesto_puntos : int):
	
	var Cant_Rooms : int = 2
	
	while Presupuesto_puntos > 0 and Cant_Rooms > 0:
		await get_tree().create_timer(0.2).timeout
		spwan_rooms_points.Instanciar_Room(7)
		
		
		Cant_Rooms -= 1
		Presupuesto_Level -= 7
