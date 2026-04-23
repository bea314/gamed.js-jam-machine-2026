extends Area2D

@onready var _visual: Node2D = $Mesh_sistem
@onready var _spawn: Marker2D = $SpawnMarker
@onready var _collision: CollisionShape2D = $CollisionShape2D

var _session_initialized: bool = false
var _last_visual_open: bool = true
var _last_allow_monitoring: bool = true
var _collision_shape_duplicated: bool = false


func configure_room_side(
	side: String,
	collision_size: Vector2 = Vector2(88, 14),
	collision_inset: float = 44.0,
	spawn_inset: float = 72.0,
) -> void:
	if _collision.shape and not _collision_shape_duplicated:
		_collision.shape = _collision.shape.duplicate()
		_collision_shape_duplicated = true
	var rect := _collision.shape as RectangleShape2D
	if rect:
		rect.size = collision_size
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
	_collision.position = into_local * collision_inset
	_spawn.position = into_local * spawn_inset


func apply_door_state(has_neighbor: bool, allow_monitoring: bool, visual_open: bool, animate_visual_changes: bool = false) -> void:
	visible = has_neighbor
	monitoring = has_neighbor and allow_monitoring
	if not has_neighbor:
		_session_initialized = false
		return
	if not _visual.has_method("snap_to_frame"):
		return
	if not _session_initialized:
		_session_initialized = true
		if visual_open:
			_visual.snap_fully_open()
		else:
			_visual.snap_fully_closed()
		_last_visual_open = visual_open
		_last_allow_monitoring = allow_monitoring
		return
	if visual_open != _last_visual_open:
		if visual_open:
			if animate_visual_changes:
				_visual.play_open()
			else:
				_visual.snap_fully_open()
		else:
			if animate_visual_changes:
				_visual.play_close()
			else:
				_visual.snap_fully_closed()
		_last_visual_open = visual_open
	_last_allow_monitoring = allow_monitoring
