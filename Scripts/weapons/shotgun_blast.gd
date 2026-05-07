@tool
extends Area2D

@export_group("Combate")
@export var damage: int = 1

@export_subgroup("Área del cono (vértice en origen local, abre hacia +X)")
var _cone_half_angle_deg: float = 38.0
## Half-angle of the cone (total arc = 2 × esto): triángulo con vértice en el origen local +X.
@export_range(1.0, 89.0, 0.5) var cone_half_angle_deg: float:
	get:
		return _cone_half_angle_deg
	set(v):
		_cone_half_angle_deg = v
		_queue_geometry_refresh()

var _sector_radius: float = 120.0
@export var sector_radius: float:
	get:
		return _sector_radius
	set(v):
		_sector_radius = maxf(v, 1.0)
		_queue_geometry_refresh()

@export_subgroup("Tiempo en pantalla")
## Segundos que se mantiene visible el efecto (el daño se aplica al instante).
@export var visual_duration: float = 0.14

@export_group("Vista previa")
## En el editor siempre ves relleno + borde encima del sprite. En partida usa solo la textura; activa esto solo para depuración.
@export var show_hitbox_overlay_in_game: bool = false

var damage_origin: Vector2 = Vector2.ZERO
var _damaged: Dictionary = {}

var _configure_pos: Vector2 = Vector2.ZERO
var _configure_aim: Vector2 = Vector2.RIGHT
var _configure_origin: Vector2 = Vector2.ZERO
var _configure_damage: int = 1

const ENEMY_MASK: int = 4


func configure(world_pos: Vector2, aim: Vector2, origin: Vector2, dmg: int) -> void:
	_configure_pos = world_pos
	_configure_aim = aim.normalized()
	_configure_origin = origin
	_configure_damage = dmg


func _queue_geometry_refresh() -> void:
	call_deferred("_apply_geometry")


func _build_triangle_verts() -> PackedVector2Array:
	var half_r := deg_to_rad(cone_half_angle_deg)
	return PackedVector2Array([
		Vector2.ZERO,
		Vector2(cos(-half_r), sin(-half_r)) * sector_radius,
		Vector2(cos(half_r), sin(half_r)) * sector_radius
	])


func _apply_geometry() -> void:
	if not is_inside_tree():
		return
	var verts := _build_triangle_verts()
	var cp := get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if cp:
		cp.polygon = verts
	var vis := get_node_or_null("BlastVisual") as Polygon2D
	if vis:
		vis.polygon = verts
		vis.color = Color(1.0, 0.78, 0.2, 0.62)
	var outline := get_node_or_null("BlastOutline") as Line2D
	if outline:
		outline.points = verts
		outline.closed = true
	_update_overlay_visibility()


func _update_overlay_visibility() -> void:
	var show_overlay := Engine.is_editor_hint() or show_hitbox_overlay_in_game
	var vis := get_node_or_null("BlastVisual") as Polygon2D
	if vis:
		vis.visible = show_overlay
	var outline := get_node_or_null("BlastOutline") as Line2D
	if outline:
		outline.visible = show_overlay


func _ready() -> void:
	z_index = 48
	z_as_relative = false
	_apply_geometry()

	if Engine.is_editor_hint():
		return

	collision_layer = 1
	collision_mask = 4
	monitorable = false
	monitoring = true
	damage = _configure_damage
	damage_origin = _configure_origin
	global_position = _configure_pos
	global_rotation = _configure_aim.angle()

	body_entered.connect(_on_body_entered)
	_update_overlay_visibility()


func _on_body_entered(body: Node) -> void:
	_try_damage_body(body)


func _try_damage_body(body: Node) -> void:
	if body == null or not is_instance_valid(body):
		return
	if body.is_in_group("player"):
		return
	if _damaged.has(body):
		return
	if body.has_method("take_damage"):
		_damaged[body] = true
		body.call("take_damage", damage, damage_origin)


func _apply_shape_query() -> void:
	var cp := get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if cp == null or cp.polygon.size() < 3:
		return
	var shape := ConvexPolygonShape2D.new()
	shape.points = cp.polygon
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = cp.global_transform
	params.collision_mask = ENEMY_MASK
	var space := get_world_2d().direct_space_state
	for r in space.intersect_shape(params, 32):
		var collider := r.get("collider") as Node
		if collider:
			_try_damage_body(collider)


func _apply_overlapping() -> void:
	_apply_shape_query()
	for body in get_overlapping_bodies():
		_try_damage_body(body)
	for area in get_overlapping_areas():
		if _damaged.has(area):
			continue
		if area.has_method("take_damage"):
			_damaged[area] = true
			area.call("take_damage", damage, damage_origin)


func run_blast() -> void:
	await get_tree().physics_frame
	_apply_overlapping()
	if visual_duration > 0.0:
		await get_tree().create_timer(visual_duration).timeout
	queue_free()
