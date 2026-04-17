extends Area2D

@export var damage: int = 1
## Half-angle of the cone (total arc = 2 × esto): triángulo con vértice en el origen local +X.
@export var cone_half_angle_deg: float = 38.0
@export var sector_radius: float = 80.0
## Segundos que se mantiene visible el triángulo (el daño se aplica al instante).
@export var visual_duration: float = 0.14

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


func _build_triangle_verts() -> PackedVector2Array:
	var half_r := deg_to_rad(cone_half_angle_deg)
	# Triángulo: vértice en origen, base como arco de dos puntos (cono / "triángulo" de área).
	return PackedVector2Array([
		Vector2.ZERO,
		Vector2(cos(-half_r), sin(-half_r)) * sector_radius,
		Vector2(cos(half_r), sin(half_r)) * sector_radius
	])


func _ready() -> void:
	# Por encima del suelo y del jugador (z típico 0–10) para que el cono se vea.
	z_index = 48
	z_as_relative = false

	# layer 1 (world): must be non-zero so enemy bodies (mask includes world) pair with this Area2D.
	collision_layer = 1
	collision_mask = 4
	monitorable = false
	monitoring = true
	damage = _configure_damage
	damage_origin = _configure_origin
	global_position = _configure_pos
	global_rotation = _configure_aim.angle()

	body_entered.connect(_on_body_entered)

	var verts := _build_triangle_verts()

	var cp := get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if cp:
		cp.polygon = verts
	var vis := get_node_or_null("BlastVisual") as Polygon2D
	if vis:
		vis.polygon = verts
		vis.z_index = 1
		vis.z_as_relative = false
		vis.color = Color(1.0, 0.78, 0.2, 0.62)
	_outline_triangle(verts)


func _outline_triangle(verts: PackedVector2Array) -> void:
	if verts.size() < 3:
		return
	var line := Line2D.new()
	line.z_index = 2
	line.z_as_relative = false
	line.width = 2.5
	line.default_color = Color(1.0, 0.95, 0.45, 0.95)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var closed := verts.duplicate()
	closed.append(verts[0])
	line.points = closed
	add_child(line)


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
	# Mantener el triángulo visible lo suficiente para leerlo (antes: 1 frame ≈ invisible).
	if visual_duration > 0.0:
		await get_tree().create_timer(visual_duration).timeout
	queue_free()
