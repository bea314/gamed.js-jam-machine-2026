extends Node2D

# SISTSTEMA EN PROGRESO HASTA QUE SE DEFINA EL ARTE !TEST
# necesitamos el arte para todo pero mientras usaremos place Holder
# para empezar

var is_Open_Door : bool = false

@onready var mesh_door: MeshInstance2D = $Mesh_Door
var color_Clocet : Color = Color(0.702, 0.369, 0.369, 1.0)
var color_open : Color = Color(0.256, 0.559, 0.279, 1.0)

@onready var spawn_player_point: Marker2D = $"../Spawn_playerPOINT"
var PATH_GO : Marker2D

@onready var muestra_path: Label = $Muestra_path

func _ready() -> void:
	Anim_Open_Door(false)

func Anim_Open_Door(open : bool):
	if open: # SI NECEITAMOS ABRIR LA PUERTA
		mesh_door.modulate = color_open
		is_Open_Door = true
	else:
		mesh_door.modulate = color_Clocet
		is_Open_Door = false

func mostrar_path(texto :String):
	muestra_path.text = texto
