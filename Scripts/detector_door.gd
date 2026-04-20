extends StaticBody2D

@onready var raycast_detector: RayCast2D = $Raycast_Detector
@onready var point_spawn: Marker2D = $"../Point_Spawn"
@onready var doors_commun: Node2D = $".."
@onready var mesh_sistem: Node2D = $"../Mesh_sistem"

var Is_Connected : bool = false

func _ready() -> void:
	raycast_detector.exclude_parent = true

func _physics_process(_delta: float) -> void:
	raycast_detector.force_raycast_update()

	if raycast_detector.is_colliding():
		var obj = raycast_detector.get_collider()
		if obj and obj.is_in_group("Door_Connect"):
			var get_padre = obj.get_parent()
			get_padre.Path_TOGO = doors_commun.point_spawn 
			Is_Connected = true
			
			if obj.Path_TOGO and doors_commun.Path_TOGO:
				queue_free()
			
			print("Se conectaron las ROOMs")
	else:
		Is_Connected = false
