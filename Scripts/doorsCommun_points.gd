extends Node2D

var Door_Positions : Array = [Vector2(-348.0,0.0),Vector2(348.0,0.0),Vector2(0.0,227.0),Vector2(0.0,-227.0)]
var Rotation_vertical : float = 0.0 # Rotacion Vertical
var Rotation_Horizontal : float = -90.0 # Rotacion Horizontal

const DOOR_COMUN = preload("uid://bwm3em15iefgi")

var cant_Doors : int

func Generate_Door(Type : String, presupuesto_ind : int):
	var instancia_door_generate
	if Type == "Commun":
		instancia_door_generate = DOOR_COMUN.instantiate()
		add_child(instancia_door_generate)
		
		var pick_position = Door_Positions.pick_random()
		instancia_door_generate.position = pick_position
		
		if instancia_door_generate.position.x != 0:
			instancia_door_generate.rotation_degrees = Rotation_vertical
		else:
			instancia_door_generate.rotation_degrees = Rotation_Horizontal
		
		instancia_door_generate.Presupuesto_Room_ind = presupuesto_ind
