extends Node2D

@onready var door_pos_2: Marker2D = $DOOR_Pos2
@onready var door_pos_4: Marker2D = $DOOR_Pos4
@onready var door_pos_3: Marker2D = $DOOR_Pos3
@onready var door_pos_1: Marker2D = $DOOR_Pos1

const DOORS_COMMUN_CONNECT = preload("res://Ecenes/Map/Doors/Doors_Commun_Connect.tscn")

@onready var point_2: Marker2D = $"../Spawn_Player_Doors/POINT_2"
@onready var point_4: Marker2D = $"../Spawn_Player_Doors/POINT_4"
@onready var point_1: Marker2D = $"../Spawn_Player_Doors/POINT_1"
@onready var point_3: Marker2D = $"../Spawn_Player_Doors/POINT_3"


func GENERATE_DEFOULT_DOOR(Lado_ROOMS : int): # PRIMERO SE GENERA ESTE 
	var Generate_Door = DOORS_COMMUN.instantiate()
	
	if Lado_ROOMS == 1:
		door_pos_1.add_child(Generate_Door)
		Generate_Door.Path_TOGO = point_1
		Generate_Door.rotation_degrees = -90
	elif Lado_ROOMS == 2:
		door_pos_2.add_child(Generate_Door)
		Generate_Door.Path_TOGO = point_2
		Generate_Door.rotation_degrees = 0
	elif Lado_ROOMS == 3:
		door_pos_3.add_child(Generate_Door)
		Generate_Door.Path_TOGO = point_3
		Generate_Door.rotation_degrees = 90
	elif Lado_ROOMS == 4:
		door_pos_4.add_child(Generate_Door)
		Generate_Door.Path_TOGO = point_4
		Generate_Door.rotation_degrees = 180
		
	var global_xform = Generate_Door.global_transform
	#var ecena_level = get_tree().current_scene.get_node("LevelGeneratorMap")
	
	#ecena_level.add_child(Generate_Door)
	
	Generate_Door.global_transform = global_xform
	
	
	
func GENERATE_DOOR(Lado_ROOMS : int):
	var Generate_Door_Connector = DOORS_COMMUN_CONNECT.instantiate()
	
	# Colocarlo temporalmente en su Marker
	match Lado_ROOMS:
		1:
			door_pos_1.add_child(Generate_Door_Connector)
			Generate_Door_Connector.rotation_degrees = -90
		2:
			door_pos_2.add_child(Generate_Door_Connector)
			Generate_Door_Connector.rotation_degrees = 0
		3:
			door_pos_3.add_child(Generate_Door_Connector)
			Generate_Door_Connector.rotation_degrees = 90
		4:
			door_pos_4.add_child(Generate_Door_Connector)
			Generate_Door_Connector.rotation_degrees = 180
	
	var global_xform = Generate_Door_Connector.global_transform
	#var ecena_level = get_tree().current_scene.get_node("LevelGeneratorMap")
	
	# Moverlo a la escena real
	#ecena_level.add_child(Generate_Door_Connector)
	await Generate_Door_Connector.ready
	
	Generate_Door_Connector.global_transform = global_xform
	
