extends Node2D

signal room_transition_requested(target_coords: Vector2i, side: String)

const ENEMY_BASIC := preload("res://Ecenes/Enemies/EnemyBasic.tscn")
const ENEMY_TURRET := preload("res://Ecenes/Enemies/EnemyTurret.tscn")
const ENEMY_DEFENSE := preload("res://Ecenes/Enemies/EnemyDefenseTank.tscn")
const ENEMY_BOSS_N1 := preload("res://Ecenes/Enemies/EnemyBossNivel1.tscn")

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

var current_coords: Vector2i = Vector2i.ZERO
var _neighbors: Array = []
var _locks_exits: bool = false
var room_cleared: bool = true
var _hostiles_alive: int = 0

@onready var door_up = $Doors/DoorPos_Up
@onready var door_down = $Doors/DoorPos_Down
@onready var door_left = $Doors/DoorPos_Left
@onready var door_right = $Doors/DoorPos_Right


func setup(neighbors: Array, my_coords: Vector2i, room_kind: String = RoomKind.START) -> void:
	current_coords = my_coords
	_neighbors = neighbors.duplicate()
	_hostiles_alive = 0
	_locks_exits = false
	room_cleared = true

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
			_locks_exits = true
			room_cleared = false
			_spawn_boss_n1(enc_parent, Vector2(0, -40))
		_:
			pass

	if _locks_exits and _hostiles_alive <= 0:
		room_cleared = true

	_configure_door_sides()
	_refresh_door_states()


func _configure_door_sides() -> void:
	_try_configure_door(door_up, "up")
	_try_configure_door(door_down, "down")
	_try_configure_door(door_left, "left")
	_try_configure_door(door_right, "right")


func _try_configure_door(door: Area2D, side: String) -> void:
	if door.has_method("configure_room_side"):
		door.configure_room_side(side)


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
	ActiveRoomService.bind_hostile_to_room(b, self)
	_register_hostile(b)


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
		_refresh_door_states()


func _refresh_door_states() -> void:
	var allow_transition := room_cleared or not _locks_exits
	_set_door_state(door_up, "up" in _neighbors, allow_transition)
	_set_door_state(door_down, "down" in _neighbors, allow_transition)
	_set_door_state(door_left, "left" in _neighbors, allow_transition)
	_set_door_state(door_right, "right" in _neighbors, allow_transition)


func _set_door_state(door: Area2D, has_neighbor: bool, allow_transition: bool) -> void:
	if door.has_method("apply_door_state"):
		door.apply_door_state(has_neighbor, allow_transition)
	else:
		door.visible = has_neighbor
		door.monitoring = has_neighbor and allow_transition


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
