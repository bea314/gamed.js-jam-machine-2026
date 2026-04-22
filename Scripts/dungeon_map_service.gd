extends Node

## Tracks which dungeon grid cells exist and which the player has visited (roguelike-style fog).

signal exploration_updated

var _cells: Dictionary = {} ## Vector2i -> true
var _known: Dictionary = {} ## Vector2i -> true
var _boss_cell: Vector2i
var _has_boss_cell: bool = false
var _start_cell: Vector2i
var _has_start_cell: bool = false


func _ready() -> void:
	ActiveRoomService.active_room_changed.connect(_on_active_room_changed)


func register_from_generator(dungeon_data: Dictionary) -> void:
	_cells.clear()
	_known.clear()
	_has_boss_cell = false
	_has_start_cell = false
	for k in dungeon_data.keys():
		if k is Vector2i:
			_cells[k] = true
			var data: Dictionary = dungeon_data[k]
			var kind: String = str(data.get("room_kind", ""))
			if kind == RoomKind.BOSS_NIVEL_1:
				_boss_cell = k
				_has_boss_cell = true
			if kind == RoomKind.START:
				_start_cell = k
				_has_start_cell = true
	mark_known(Vector2i.ZERO)


func mark_known(coords: Vector2i) -> void:
	if not _cells.has(coords):
		return
	if _known.has(coords):
		return
	_known[coords] = true
	exploration_updated.emit()


func has_room_at(coords: Vector2i) -> bool:
	return _cells.has(coords)


func is_known(coords: Vector2i) -> bool:
	return _known.has(coords)


func get_player_room_coords() -> Vector2i:
	var room: Node2D = ActiveRoomService.active_room
	if room == null or not is_instance_valid(room):
		return Vector2i.ZERO
	var c: Variant = room.get("current_coords")
	if c is Vector2i:
		return c
	return Vector2i.ZERO


func get_boss_room_coords() -> Vector2i:
	return _boss_cell


func has_boss_room() -> bool:
	return _has_boss_cell


func get_start_room_coords() -> Vector2i:
	return _start_cell


func has_start_room() -> bool:
	return _has_start_cell


func get_grid_bounds() -> Rect2i:
	if _cells.is_empty():
		return Rect2i(0, 0, 0, 0)
	var min_x := 2147483647
	var min_y := min_x
	var max_x := -2147483648
	var max_y := max_x
	for c in _cells.keys():
		var cell: Vector2i = c
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _on_active_room_changed(room: Node2D) -> void:
	if room == null or not is_instance_valid(room):
		return
	var c: Variant = room.get("current_coords")
	if c is Vector2i:
		mark_known(c)
