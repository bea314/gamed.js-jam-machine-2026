extends Control

const _FILL_KNOWN := Color(0.32, 0.36, 0.4, 0.95)
const _FILL_UNKNOWN := Color(0.06, 0.07, 0.09, 0.92)
const _CURRENT := Color(0.45, 0.72, 0.98, 1.0)
const _PLAYER_DOT := Color(1.0, 0.88, 0.25, 1.0)
const _BORDER := Color(0.12, 0.13, 0.16, 1.0)
## Mismo criterio que el punto del jugador: marca sala inicio y sala jefe.
const _ROOM_MARK_RED := Color(0.9, 0.22, 0.2, 1.0)


func _ready() -> void:
	DungeonMapService.exploration_updated.connect(queue_redraw)
	ActiveRoomService.active_room_changed.connect(_on_active_room_changed_map)
	resized.connect(queue_redraw)
	queue_redraw()


func _on_active_room_changed_map(_room: Node2D) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.045, 0.05, 0.98))
	var bounds: Rect2i = DungeonMapService.get_grid_bounds()
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return

	var pad := 3.0
	var gw: float = maxf(size.x - pad * 2.0, 1.0)
	var gh: float = maxf(size.y - pad * 2.0, 1.0)
	var cells_x: int = bounds.size.x
	var cells_y: int = bounds.size.y
	var cs: float = minf(gw / float(cells_x), gh / float(cells_y))
	var ox: float = pad + (gw - cs * float(cells_x)) * 0.5
	var oy: float = pad + (gh - cs * float(cells_y)) * 0.5

	var player_cell: Vector2i = DungeonMapService.get_player_room_coords()

	for iy in range(cells_y):
		for ix in range(cells_x):
			var world: Vector2i = Vector2i(bounds.position.x + ix, bounds.position.y + iy)
			if not DungeonMapService.has_room_at(world):
				continue
			var r := Rect2(ox + float(ix) * cs, oy + float(iy) * cs, cs - 1.0, cs - 1.0)
			var explored: bool = DungeonMapService.is_known(world)
			var is_current: bool = world == player_cell
			if is_current:
				draw_rect(r, _CURRENT)
			elif explored:
				draw_rect(r, _FILL_KNOWN)
			else:
				draw_rect(r, _FILL_UNKNOWN)
			draw_rect(r, _BORDER, false, 1.0)

	var marked: Array[Vector2i] = []
	if DungeonMapService.has_start_room():
		marked.append(DungeonMapService.get_start_room_coords())
	if DungeonMapService.has_boss_room():
		var bcell: Vector2i = DungeonMapService.get_boss_room_coords()
		if bcell not in marked:
			marked.append(bcell)
	for cmark: Vector2i in marked:
		_draw_red_room_mark(cmark, bounds, ox, oy, cells_x, cells_y, cs)

	var pc_ix: int = player_cell.x - bounds.position.x
	var pc_iy: int = player_cell.y - bounds.position.y
	if pc_ix >= 0 and pc_ix < cells_x and pc_iy >= 0 and pc_iy < cells_y:
		var pr := Rect2(ox + float(pc_ix) * cs, oy + float(pc_iy) * cs, cs - 1.0, cs - 1.0)
		var d: float = maxf(cs * 0.22, 3.0)
		var center: Vector2 = pr.get_center()
		draw_circle(center, d, _PLAYER_DOT)


func _draw_red_room_mark(
	world: Vector2i, bounds: Rect2i, ox: float, oy: float, cells_x: int, cells_y: int, cs: float
) -> void:
	if not DungeonMapService.has_room_at(world):
		return
	var ix: int = world.x - bounds.position.x
	var iy: int = world.y - bounds.position.y
	if ix < 0 or ix >= cells_x or iy < 0 or iy >= cells_y:
		return
	var r := Rect2(ox + float(ix) * cs, oy + float(iy) * cs, cs - 1.0, cs - 1.0)
	var d: float = maxf(cs * 0.22, 3.0)
	draw_circle(r.get_center(), d, _ROOM_MARK_RED)
