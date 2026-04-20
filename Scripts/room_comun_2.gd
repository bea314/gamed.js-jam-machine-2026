extends Node2D

var Presupuesto_room : int

# TIPO DE ROOOMS
const ROOMS = {
	"comun_2": {
		"scene": preload("uid://djnypdxm07xxi"),
		"cost": 1
	}
}

var list_rooms_type : Array = [ROOMS["comun_2"]]
@onready var spwan_rooms_points: Node2D = $Spwan_ROOMS_POINTS
@onready var comp_rooms_vecinas: Node2D = $Comp_Rooms_Vecinas

func _ready() -> void:
	await comp_rooms_vecinas.ready
	comp_rooms_vecinas.Detector_Raycast()
	
	var pick_cant_rooms = randi_range(1,3)
	Eleccion_Administracion_Presupuesto_Room(pick_cant_rooms)

func Eleccion_Administracion_Presupuesto_Room(Cantidad_rooms : int):
	var pick_ROOM_TYPE = list_rooms_type.pick_random()
	
	var cantidad_generar_room = Cantidad_rooms
	
	if Presupuesto_room > pick_ROOM_TYPE["cost"] and cantidad_generar_room > 0:
		Presupuesto_room -= pick_ROOM_TYPE["cost"]
		spwan_rooms_points.Instacniar_ROOM(pick_ROOM_TYPE["scene"])
		cantidad_generar_room -= 1
