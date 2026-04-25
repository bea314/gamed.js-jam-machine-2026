extends Node2D

signal room_transition_requested(target_coords: Vector2i, side: String)

const ENEMY_BASIC := preload("res://Ecenes/Enemies/EnemyBasic.tscn")
const ENEMY_TURRET := preload("res://Ecenes/Enemies/EnemyTurret.tscn")
const ENEMY_DEFENSE := preload("res://Ecenes/Enemies/EnemyDefenseTank.tscn")
const ENEMY_BOSS_N1 := preload("res://Ecenes/Enemies/EnemyBossNivel1.tscn")

const _SFX_DOOR_TRAP: Array[AudioStream] = [
	preload("res://Recursos/Sound/SFXS/PUERTA/the_door_is_close.ogg"),
	preload("res://Recursos/Sound/SFXS/PUERTA/your_traped.ogg"),
]
const _CHANCE_DOOR_TRAP_SFX := 1.0 / 3.0
const BOSS_ENTRANCE_CINEMATIC := preload("res://Scripts/boss_entrance_cinematic.gd")

## Posiciones locales alrededor del centro de la sala (spawn de básicos).
const SPAWN_RING_6: Array[Vector2] = [
	Vector2(-110, -20), Vector2(110, -20), Vector2(-70, 90),
	Vector2(70, 90), Vector2(0, -100), Vector2(0, 100),
]
const SPAWN_FIVE_AROUND_TURRET: Array[Vector2] = [
	Vector2(-100, 30), Vector2(100, 30), Vector2(-60, 100),
	Vector2(60, 100), Vector2(0, 115),
]
## 2 tanques defensa (atrás / laterales) + 3 básicos al frente
const SPAWN_TWO_DEFENSE: Array[Vector2] = [
	Vector2(-130, -40), Vector2(130, -40),
]
const SPAWN_THREE_SMALL: Array[Vector2] = [
	Vector2(-70, 85), Vector2(0, 95), Vector2(70, 85),
]

@export_group("Puertas — interacción")
@export var door_collision_size: Vector2 = Vector2(88, 14)
@export var door_collision_inset: float = 44.0
@export var door_spawn_inset: float = 72.0
@export_group("Boss Entrance Cinematic")
@export var enable_boss_entrance_cinematic: bool = true
@export var debug_skip_boss_cinematic: bool = false
@export var debug_fast_boss_cinematic: bool = false
@export var cinematic_fade_out_duration: float = 0.4
@export var cinematic_sleep_hold_duration: float = 0.6
@export var cinematic_fade_in_duration: float = 0.8
@export var cinematic_zoom_start: Vector2 = Vector2(2.0, 2.0)
@export var cinematic_zoom_end: Vector2 = Vector2(1.0, 1.0)
@export var cinematic_zoom_duration: float = 0.8
@export var cinematic_use_zoom_reveal: bool = false
@export var cinematic_shake_magnitude: float = 3.0
@export var cinematic_shake_duration: float = 0.18
@export var cinematic_qa_speed_multiplier: float = 3.0
@export var cinematic_wake_sfx: AudioStream

var current_coords: Vector2i = Vector2i.ZERO
var _neighbors: Array = []
var _locks_exits: bool = false
var room_cleared: bool = true
var _hostiles_alive: int = 0
var _trap_close_sfx_done: bool = false
var _level_generator: Node = null
var _is_boss_room: bool = false
var _boss_intro_played: bool = false
var _boss_intro_running: bool = false
var _boss_defeated: bool = false
var _boss_spawn_local_pos: Vector2 = Vector2.ZERO
var _boss_instance: Node2D = null

@onready var door_up = $Doors/DoorPos_Up
@onready var door_down = $Doors/DoorPos_Down
@onready var door_left = $Doors/DoorPos_Left
@onready var door_right = $Doors/DoorPos_Right


func setup(neighbors: Array, my_coords: Vector2i, room_kind: String = RoomKind.START, level_generator: Node = null) -> void:
	current_coords = my_coords
	_neighbors = neighbors.duplicate()
	_hostiles_alive = 0
	_locks_exits = false
	room_cleared = true
	_trap_close_sfx_done = false
	_level_generator = level_generator
	_is_boss_room = false
	_boss_intro_played = false
	_boss_intro_running = false
	_boss_defeated = false
	_boss_spawn_local_pos = Vector2.ZERO
	_boss_instance = null

	var enc_parent: Node2D = _ensure_encounters_root()

	match room_kind:
		RoomKind.START:
			pass
		RoomKind.COMBAT_EASY_6:
			_locks_exits = true
			room_cleared = false
			for p in SPAWN_RING_6:
				_spawn_basic(enc_parent, p)
		RoomKind.MID_TURRET:
			_locks_exits = true
			room_cleared = false
			_spawn_turret(enc_parent, Vector2(0, -55))
		RoomKind.TURRET_PLUS_BASICS:
			_locks_exits = true
			room_cleared = false
			_spawn_turret(enc_parent, Vector2(0, -95))
			for p in SPAWN_FIVE_AROUND_TURRET:
				_spawn_basic(enc_parent, p)
		RoomKind.DEFENSE_TWO_PLUS_THREE:
			_locks_exits = true
			room_cleared = false
			for p in SPAWN_TWO_DEFENSE:
				_spawn_defense(enc_parent, p)
			for p in SPAWN_THREE_SMALL:
				_spawn_basic(enc_parent, p)
		RoomKind.BOSS_NIVEL_1:
			_is_boss_room = true
			_locks_exits = true
			room_cleared = false
			_boss_spawn_local_pos = Vector2.ZERO
		_:
			pass

	if _locks_exits and _hostiles_alive <= 0 and not (_is_boss_room and not _boss_intro_played):
		room_cleared = true

	_configure_door_sides()
	_refresh_door_states(false)


func is_exit_locked() -> bool:
	return _locks_exits and not room_cleared


func refresh_door_states(animate_visual: bool = false) -> void:
	_refresh_door_states(animate_visual)


func _neighbor_cell_for_side(side: String) -> Vector2i:
	match side:
		"up":
			return current_coords + Vector2i.UP
		"down":
			return current_coords + Vector2i.DOWN
		"left":
			return current_coords + Vector2i.LEFT
		"right":
			return current_coords + Vector2i.RIGHT
		_:
			return current_coords


func _door_visual_open(side: String) -> bool:
	if not (side in _neighbors):
		return false
	var other := _neighbor_cell_for_side(side)
	if _level_generator != null and _level_generator.has_method("is_edge_sealed"):
		if _level_generator.is_edge_sealed(current_coords, other):
			return false
	return true


func _configure_door_sides() -> void:
	_try_configure_door(door_up, "up")
	_try_configure_door(door_down, "down")
	_try_configure_door(door_left, "left")
	_try_configure_door(door_right, "right")


func _try_configure_door(door: Area2D, side: String) -> void:
	if door.has_method("configure_room_side"):
		door.configure_room_side(side, door_collision_size, door_collision_inset, door_spawn_inset)


func try_play_trap_close_sfx() -> void:
	if _trap_close_sfx_done:
		return
	if not _locks_exits or room_cleared:
		return
	# En sala de boss siempre forzamos el SFX de cierre para reforzar el momento.
	if not _is_boss_room and randf() > _CHANCE_DOOR_TRAP_SFX:
		return
	_trap_close_sfx_done = true
	var stream: AudioStream = _SFX_DOOR_TRAP.pick_random()
	var player := AudioStreamPlayer.new()
	player.bus = &"SFX"
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _ensure_encounters_root() -> Node2D:
	var n := get_node_or_null("Encounters") as Node2D
	if n:
		for c in n.get_children():
			c.queue_free()
		return n
	var root := Node2D.new()
	root.name = "Encounters"
	add_child(root)
	return root


func _spawn_basic(parent: Node2D, local_pos: Vector2) -> void:
	var e := ENEMY_BASIC.instantiate() as Node2D
	parent.add_child(e)
	e.position = local_pos
	ActiveRoomService.bind_hostile_to_room(e, self)
	_register_hostile(e)


func _spawn_turret(parent: Node2D, local_pos: Vector2) -> void:
	var t := ENEMY_TURRET.instantiate() as Node2D
	parent.add_child(t)
	t.position = local_pos
	ActiveRoomService.bind_hostile_to_room(t, self)
	_register_hostile(t)


func _spawn_defense(parent: Node2D, local_pos: Vector2) -> void:
	var d := ENEMY_DEFENSE.instantiate() as Node2D
	parent.add_child(d)
	d.position = local_pos
	ActiveRoomService.bind_hostile_to_room(d, self)
	_register_hostile(d)


func _spawn_boss_n1(parent: Node2D, local_pos: Vector2) -> void:
	var b := ENEMY_BOSS_N1.instantiate() as Node2D
	parent.add_child(b)
	b.position = local_pos
	b.visible = false
	ActiveRoomService.bind_hostile_to_room(b, self)
	_register_hostile(b)
	_boss_instance = b
	var hc := b.get_node_or_null("HealthComponent") as HealthComponent
	if hc != null:
		hc.died.connect(_on_boss_defeated, CONNECT_ONE_SHOT)


func on_player_entered_room(player: Node2D) -> void:
	if not _is_boss_room:
		return
	if _boss_defeated:
		return
	if _boss_intro_running:
		return
	if _boss_intro_played:
		return
	_boss_intro_running = true
	if _boss_instance == null or not is_instance_valid(_boss_instance):
		var encounters := _ensure_encounters_root()
		_spawn_boss_n1(encounters, _boss_spawn_local_pos)
	_refresh_door_states(true)
	if _level_generator != null and _level_generator.has_method("seal_all_edges_for_cell"):
		_level_generator.seal_all_edges_for_cell(current_coords)
	try_play_trap_close_sfx()
	call_deferred("_run_boss_entrance_cinematic", player)


func _run_boss_entrance_cinematic(player: Node2D) -> void:
	if not enable_boss_entrance_cinematic:
		if _boss_instance != null and _boss_instance.has_method("start_wake_sequence"):
			_boss_instance.visible = true
			_boss_instance.start_wake_sequence()
		_boss_intro_played = true
		_boss_intro_running = false
		return
	var cinematic := BOSS_ENTRANCE_CINEMATIC.new()
	cinematic.fade_out_duration = cinematic_fade_out_duration
	cinematic.sleep_hold_duration = cinematic_sleep_hold_duration
	cinematic.fade_in_duration = cinematic_fade_in_duration
	cinematic.zoom_start = cinematic_zoom_start
	cinematic.zoom_end = cinematic_zoom_end
	cinematic.zoom_duration = cinematic_zoom_duration
	cinematic.use_zoom_reveal = cinematic_use_zoom_reveal
	cinematic.shake_magnitude = cinematic_shake_magnitude
	cinematic.shake_duration = cinematic_shake_duration
	cinematic.qa_speed_multiplier = cinematic_qa_speed_multiplier
	cinematic.wake_sfx_stream = cinematic_wake_sfx
	add_child(cinematic)
	var camera := get_tree().current_scene.get_node_or_null("CameraGameplay") as Camera2D
	var music_node := get_tree().current_scene.get_node_or_null("MusicSistem")
	await cinematic.play(player, _boss_instance, camera, music_node, debug_skip_boss_cinematic, debug_fast_boss_cinematic)
	cinematic.queue_free()
	_boss_intro_played = true
	_boss_intro_running = false


func _register_hostile(node: Node) -> void:
	var hc := node.get_node_or_null("HealthComponent") as HealthComponent
	if hc == null:
		return
	_hostiles_alive += 1
	hc.died.connect(_on_hostile_died, CONNECT_ONE_SHOT)


func _on_hostile_died() -> void:
	_hostiles_alive = maxi(_hostiles_alive - 1, 0)
	if _locks_exits and _hostiles_alive <= 0:
		room_cleared = true
		if _level_generator != null and _level_generator.has_method("unseal_edges_for_cell"):
			_level_generator.unseal_edges_for_cell(current_coords)
		else:
			_refresh_door_states(true)


func _on_boss_defeated() -> void:
	_boss_defeated = true
	_boss_intro_running = false


func _refresh_door_states(animate_visual: bool = false) -> void:
	var allow_monitoring := room_cleared or not _locks_exits
	_set_door_state(door_up, "up", "up" in _neighbors, allow_monitoring, animate_visual)
	_set_door_state(door_down, "down", "down" in _neighbors, allow_monitoring, animate_visual)
	_set_door_state(door_left, "left", "left" in _neighbors, allow_monitoring, animate_visual)
	_set_door_state(door_right, "right", "right" in _neighbors, allow_monitoring, animate_visual)


func _set_door_state(door: Area2D, side: String, has_neighbor: bool, allow_monitoring: bool, animate_visual: bool) -> void:
	var visual_open := false
	if has_neighbor:
		visual_open = _door_visual_open(side)
	if door.has_method("apply_door_state"):
		door.apply_door_state(has_neighbor, allow_monitoring, visual_open, animate_visual)
	else:
		door.visible = has_neighbor
		door.monitoring = has_neighbor and allow_monitoring


func _on_door_pos_up_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if _locks_exits and not room_cleared:
		return
	room_transition_requested.emit(current_coords + Vector2i.UP, "up")


func _on_door_pos_down_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if _locks_exits and not room_cleared:
		return
	room_transition_requested.emit(current_coords + Vector2i.DOWN, "down")


func _on_door_pos_left_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if _locks_exits and not room_cleared:
		return
	room_transition_requested.emit(current_coords + Vector2i.LEFT, "left")


func _on_door_pos_right_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if _locks_exits and not room_cleared:
		return
	room_transition_requested.emit(current_coords + Vector2i.RIGHT, "right")
