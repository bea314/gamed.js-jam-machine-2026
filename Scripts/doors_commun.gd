extends Area2D

@onready var _visual: Node2D = $Mesh_sistem
@onready var _spawn: Marker2D = $SpawnMarker
@onready var _collision: CollisionShape2D = $CollisionShape2D

var _session_initialized: bool = false
var _last_allow_transition: bool = false
var _collision_shape_duplicated: bool = false


func configure_room_side(side: String) -> void:
	if _collision.shape and not _collision_shape_duplicated:
		_collision.shape = _collision.shape.duplicate()
		_collision_shape_duplicated = true
	var rect := _collision.shape as RectangleShape2D
	if rect:
		rect.size = Vector2(88, 14)
	var into_world := Vector2.ZERO
	match side:
		"up":
			into_world = Vector2(0, 1)
		"down":
			into_world = Vector2(0, -1)
		"right":
			into_world = Vector2(-1, 0)
		"left":
			into_world = Vector2(1, 0)
	var into_local := into_world.rotated(-rotation)
	_collision.position = into_local * 44.0
	_spawn.position = into_local * 72.0


func apply_door_state(has_neighbor: bool, allow_transition: bool) -> void:
	visible = has_neighbor
	monitoring = has_neighbor and allow_transition
	if not has_neighbor:
		_session_initialized = false
		return
	if not _visual.has_method("snap_to_frame"):
		return
	if not _session_initialized:
		_session_initialized = true
		if allow_transition:
			_visual.snap_fully_open()
		else:
			_visual.snap_fully_closed()
		_last_allow_transition = allow_transition
		return
	if allow_transition != _last_allow_transition:
		if allow_transition:
			_visual.play_open()
		else:
			_visual.play_close()
	_last_allow_transition = allow_transition
