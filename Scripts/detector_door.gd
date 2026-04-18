extends StaticBody2D

@onready var raycast_detector: RayCast2D = $Raycast_Detector
@onready var point_spawn: Marker2D = $"../Point_Spawn"

var _triggered: bool = false


func _physics_process(_delta: float) -> void:
	if _triggered or not raycast_detector.is_colliding():
		return
	var hit: Object = raycast_detector.get_collider()
	if hit == null:
		return
	var hit_node := hit as Node
	if hit_node == null:
		return
	var col: Node = hit_node.get_parent()
	if col == null:
		return
	# Asignar el destino al sistema de puertas (Marker2D).
	col.Path_TOGO = point_spawn
	_triggered = true
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(col) and col.Path_TOGO != null:
		queue_free()
