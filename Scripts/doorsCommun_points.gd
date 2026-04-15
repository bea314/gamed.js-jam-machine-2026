extends Node2D

var Door_Positions : Array = [Vector2(-348.0,0.0),Vector2(348.0,0.0),Vector2(0.0,227.0),Vector2(0.0,-227.0)]
var Rotation_vertical : float = 0.0 # Rotacion Vertical
var Rotation_Horizontal : float = -90.0 # Rotacion Horizontal

const DOOR_COMUN = preload("uid://bwm3em15iefgi")

var cant_Doors : int

var positions_used: Array = []

func Generate_Door(Type: String, presupuesto_ind: int):
	var instancia_door_generate
	if Type == "Commun":
		instancia_door_generate = DOOR_COMUN.instantiate()
		add_child(instancia_door_generate)

		var pick_position = null
		
		while true:
			pick_position = Door_Positions.pick_random()

			if not positions_used.has(pick_position):
				instancia_door_generate.position = pick_position
				positions_used.append(pick_position)
				break
			# Si la posición estaba usada → sigue buscando otra
		
		
		if instancia_door_generate.position.x != 0:
			instancia_door_generate.rotation_degrees = Rotation_vertical
		else:
			instancia_door_generate.rotation_degrees = Rotation_Horizontal
		
		instancia_door_generate.Presupuesto_Room_ind = presupuesto_ind
		instancia_door_generate.presupuesto_mark()
