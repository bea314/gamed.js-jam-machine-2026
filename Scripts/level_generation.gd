class_name LevelGeneration
extends Node2D

# --- CONFIGURACIÓN ---
@export var room_scene: PackedScene
@export var total_rooms_goal: int = 8
@export var room_separation: Vector2 = Vector2(710, 400)
## Entrega actual: una sola “plantilla” de run; sube este valor y amplía `LEVEL_GENERATION_PROFILES` cuando haya más niveles.
@export_range(1, 1, 1) var run_level_index: int = 1
@export var use_profile_room_count: bool = true
## Al activarlo, el jefe queda en la sala **contigua** a la inicial (a la derecha) para probar sin recorrer el mapa. Desactívalo al terminar el debug.
@export var debug_boss_room_beside_start: bool = false
## Celda del jefe en modo debug (derecha de `(0,0)`; hay puerta hacia ella).
const DEBUG_BOSS_NEIGHBOUR_CELL: Vector2i = Vector2i(1, 0)
const MAX_RUN_LEVEL: int = 1
const LEVEL_GENERATION_PROFILES := {
	1: {
		"room_count": 8,
		"boss_room_kind": RoomKind.BOSS_NIVEL_1,
		"normal_cycle": [
			RoomKind.COMBAT_EASY_6,
			RoomKind.MID_TURRET,
			RoomKind.TURRET_PLUS_BASICS,
			RoomKind.DEFENSE_TWO_PLUS_THREE,
		],
	},
}

var dungeon_data: Dictionary = {}
var instantiated_rooms: Dictionary = {}
var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## Aristas entre celdas vecinas selladas al entrar en una sala de combate (puertas sincronizadas).
var _edge_sealed: Dictionary = {}
## Evita reentrar en otra transición al solapar la puerta de spawn el mismo fotograma (ping-pong).
var _next_door_transition_ms: int = 0
const _DOOR_TRANSITION_COOLDOWN_MS := 180
var _active_level_profile: Dictionary = {}

func _ready() -> void:
	_apply_level_generation_contract(run_level_index)
	randomize()
	generate_dungeon()
	render_dungeon_visuals()

# --- FASE 1: LÓGICA ---
func generate_dungeon():
	dungeon_data.clear()
	add_room_data(Vector2i(0, 0), "start")
	
	while dungeon_data.size() < total_rooms_goal:
		var keys = dungeon_data.keys()
		var random_origin = keys[randi() % keys.size()]
		var direction = directions.pick_random()
		var new_coords = random_origin + direction
		add_room_data(new_coords, "normal")
	if debug_boss_room_beside_start:
		# Asegura una sala pegada a la de inicio para pruebas del jefe (puede sumar una celda al total).
		add_room_data(DEBUG_BOSS_NEIGHBOUR_CELL, "normal")
	_assign_room_kinds()

func add_room_data(coords: Vector2i, type: String) -> bool:
	if not dungeon_data.has(coords):
		dungeon_data[coords] = {"type": type, "room_kind": ""}
		return true
	return false

func _assign_room_kinds() -> void:
	var cycle: Array[String] = _get_profile_cycle()
	var boss_cell: Vector2i
	if debug_boss_room_beside_start and dungeon_data.has(DEBUG_BOSS_NEIGHBOUR_CELL):
		boss_cell = DEBUG_BOSS_NEIGHBOUR_CELL
	else:
		boss_cell = _boss_cell_farthest_from_start()
	var idx := 0
	var coords_list: Array = dungeon_data.keys()
	coords_list.sort_custom(func(a, b): return _vec2i_sort(a, b))
	for c in coords_list:
		var cell: Vector2i = c
		if cell == Vector2i.ZERO:
			dungeon_data[cell]["room_kind"] = RoomKind.START
		elif cell == boss_cell:
			dungeon_data[cell]["room_kind"] = _get_profile_boss_kind()
		else:
			dungeon_data[cell]["room_kind"] = cycle[idx % cycle.size()]
			idx += 1


func _apply_level_generation_contract(level_index: int) -> void:
	run_level_index = clampi(level_index, 1, MAX_RUN_LEVEL)
	_active_level_profile = _get_level_profile(run_level_index)
	if use_profile_room_count:
		total_rooms_goal = int(_active_level_profile.get("room_count", total_rooms_goal))


func get_max_run_level() -> int:
	return MAX_RUN_LEVEL


func _get_level_profile(level_index: int) -> Dictionary:
	return LEVEL_GENERATION_PROFILES.get(level_index, LEVEL_GENERATION_PROFILES[1]).duplicate(true)


func _get_profile_cycle() -> Array[String]:
	var cycle_data: Array = _active_level_profile.get("normal_cycle", LEVEL_GENERATION_PROFILES[1]["normal_cycle"])
	var cycle: Array[String] = []
	for kind in cycle_data:
		cycle.append(str(kind))
	if cycle.is_empty():
		cycle = [RoomKind.COMBAT_EASY_6]
	return cycle


func _get_profile_boss_kind() -> String:
	return str(_active_level_profile.get("boss_room_kind", RoomKind.BOSS_NIVEL_1))


func _boss_cell_farthest_from_start() -> Vector2i:
	var best: Vector2i = Vector2i.ZERO
	var best_m := -1
	for c in dungeon_data.keys():
		var cell: Vector2i = c
		if cell == Vector2i.ZERO:
			continue
		var m: int = absi(cell.x) + absi(cell.y)
		if m > best_m:
			best_m = m
			best = cell
	return best

func _vec2i_sort(a: Vector2i, b: Vector2i) -> bool:
	if a.x != b.x:
		return a.x < b.x
	return a.y < b.y

# --- FASE 2: VISUALIZACIÓN ---
func render_dungeon_visuals() -> void:
	for child in get_children():
		if child is Node2D: child.queue_free()
	instantiated_rooms.clear()
	_edge_sealed.clear()
	
	# 1. Crear instancias
	for coords in dungeon_data.keys():
		var new_room = room_scene.instantiate()
		new_room.position = Vector2(coords.x * room_separation.x, coords.y * room_separation.y)
		add_child(new_room)
		instantiated_rooms[coords] = new_room
		
		# Conectar la señal de transición de la habitación al generador
		new_room.room_transition_requested.connect(_on_player_transition)

	if instantiated_rooms.has(Vector2i.ZERO):
		DungeonMapService.register_from_generator(dungeon_data)
		ActiveRoomService.set_active_room(instantiated_rooms[Vector2i.ZERO])

	# 2. Configurar puertas
	for coords in instantiated_rooms.keys():
		var room_node = instantiated_rooms[coords]
		var neighbors = []
		if dungeon_data.has(coords + Vector2i.UP):    neighbors.append("up")
		if dungeon_data.has(coords + Vector2i.DOWN):  neighbors.append("down")
		if dungeon_data.has(coords + Vector2i.LEFT):  neighbors.append("left")
		if dungeon_data.has(coords + Vector2i.RIGHT): neighbors.append("right")
		
		if room_node.has_method("setup"):
			var rk: String = str(dungeon_data[coords].get("room_kind", RoomKind.START))
			room_node.setup(neighbors, coords, rk, self)

	# Tras setup (que reinicia _player_inside_room), igual que al cruzar puerta: sala inicial.
	if instantiated_rooms.has(Vector2i.ZERO):
		var p0: Node = get_tree().get_first_node_in_group("Player")
		var start_room: Node = instantiated_rooms[Vector2i.ZERO]
		if p0 is Node2D and start_room != null and start_room.has_method("on_player_entered_room"):
			start_room.on_player_entered_room(p0 as Node2D)

# --- FASE 3: CONEXIÓN REAL ---
func _edge_key(a: Vector2i, b: Vector2i) -> String:
	if a.x < b.x or (a.x == b.x and a.y < b.y):
		return "%d,%d|%d,%d" % [a.x, a.y, b.x, b.y]
	return "%d,%d|%d,%d" % [b.x, b.y, a.x, a.y]


func is_edge_sealed(a: Vector2i, b: Vector2i) -> bool:
	return _edge_sealed.get(_edge_key(a, b), false)


## Sella todas las puertas de una celda (p. ej. combate): cada vecino del mapa recibe arista cerrada y se refrescan todas las salas tocadas.
func seal_all_edges_for_cell(cell: Vector2i) -> void:
	var refresh_cells: Dictionary = {}
	refresh_cells[cell] = true
	for d: Vector2i in directions:
		var o: Vector2i = cell + d
		if not dungeon_data.has(o):
			continue
		_edge_sealed[_edge_key(cell, o)] = true
		refresh_cells[o] = true
	for c: Vector2i in refresh_cells.keys():
		if instantiated_rooms.has(c):
			var rn: Node = instantiated_rooms[c]
			if rn.has_method("refresh_door_states"):
				rn.refresh_door_states(true)


func unseal_edges_for_cell(cell: Vector2i) -> void:
	var to_refresh: Dictionary = {}
	to_refresh[cell] = true
	for d: Vector2i in directions:
		var o: Vector2i = cell + d
		var k: String = _edge_key(cell, o)
		if _edge_sealed.has(k):
			_edge_sealed.erase(k)
			to_refresh[o] = true
	for c: Vector2i in to_refresh.keys():
		if instantiated_rooms.has(c):
			var rn: Node = instantiated_rooms[c]
			if rn.has_method("refresh_door_states"):
				rn.refresh_door_states(true)


func _on_player_transition(target_coords: Vector2i, side: String) -> void:
	var now_ms: int = Time.get_ticks_msec()
	if now_ms < _next_door_transition_ms:
		return
	if not instantiated_rooms.has(target_coords):
		return
	_next_door_transition_ms = now_ms + _DOOR_TRANSITION_COOLDOWN_MS

	var target_room: Node = instantiated_rooms[target_coords]
	var player: Node = get_tree().get_first_node_in_group("Player")
	if player == null:
		return

	var marker_path := ""
	# Si entramos por UP, aparecemos en el marker de DOWN de la siguiente sala
	match side:
		"up":    marker_path = "Doors/DoorPos_Down/SpawnMarker"
		"down":  marker_path = "Doors/DoorPos_Up/SpawnMarker"
		"left":  marker_path = "Doors/DoorPos_Right/SpawnMarker"
		"right": marker_path = "Doors/DoorPos_Left/SpawnMarker"
		_:
			marker_path = ""

	var spawn_global: Vector2 = target_room.global_position
	var spawn_node: Node = target_room.get_node_or_null(marker_path) if marker_path != "" else null
	if spawn_node is Node2D:
		spawn_global = (spawn_node as Node2D).global_position

	ActiveRoomService.set_active_room(target_room as Node2D)
	# Diferir el teletransporte evita que el motor dispare otra puerta en la misma pila de llamadas.
	player.set_deferred(&"global_position", spawn_global)
	if target_room.has_method("on_player_entered_room"):
		target_room.on_player_entered_room(player)

	if target_room.has_method("is_exit_locked") and target_room.is_exit_locked():
		seal_all_edges_for_cell(target_coords)
		if target_room.has_method("try_play_trap_close_sfx"):
			target_room.try_play_trap_close_sfx()


# Hook de progresión: desde la intro... o un coordinador externo puedo llamar esto para arrancar cada run
func start_run_level(level_index: int) -> void:
	_apply_level_generation_contract(level_index)
	generate_dungeon()
	render_dungeon_visuals()


# Hook de progresión: cuando derrotamos al boss del nivel actual, se avanza siguiente nivel o termina run
func on_boss_defeated_advance_level() -> void:
	var next_level := run_level_index + 1
	if next_level <= MAX_RUN_LEVEL:
		start_run_level(next_level)
		return
	show_victory_message()


# Hook final: reemplaza este placeholder por cambio de escena/UI de victoria.
func show_victory_message() -> void:
	push_warning("Run completada: aqui puedes mostrar pantalla o mensaje de victoria.")
