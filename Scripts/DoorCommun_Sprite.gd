extends Node2D

# SISTSTEMA EN PROGRESO HASTA QUE SE DEFINA EL ARTE !TEST
# necesitamos el arte para todo pero mientras usaremos place Holder
# para empezar

var is_Open_Door : bool = false

@onready var mesh_door: MeshInstance2D = $Mesh_Door
var color_Clocet : Color = Color(0.702, 0.369, 0.369, 1.0)
var color_open : Color = Color(0.256, 0.559, 0.279, 1.0)
var color_for_open : Color = Color(0.839, 0.778, 0.191, 1.0)

@onready var spawn_player_point: Marker2D = $"../Spawn_playerPOINT"
var PATH_GO : Marker2D

@onready var mostra_path: Label = $Mostra_path

func _ready() -> void:
	DOOR_STATE_Visual(3)
	
func DOOR_STATE_Visual(Door_STATE : int): # 1 closet, 2 open, 3 ?
	if Door_STATE == 1:
		mesh_door.modulate = color_Clocet
		mostra_path.visible = false
	elif Door_STATE == 2:
		mesh_door.modulate = color_open
		mostra_path.visible = false
	elif Door_STATE == 3:
		mesh_door.modulate = color_for_open
		mostra_path.text = "??"
		mostra_path.visible = true
