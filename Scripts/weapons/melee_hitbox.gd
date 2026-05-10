@tool
extends Area2D

@export_group("Combate")
@export var damage: int = 2

@export_subgroup("Área del rectángulo (hacia +X del origen del Area2D)")
var _hitbox_size: Vector2 = Vector2(44, 22)
@export var hitbox_size: Vector2:
	get:
		return _hitbox_size
	set(v):
		_hitbox_size = Vector2(maxf(v.x, 1.0), maxf(v.y, 1.0))
		_queue_geometry_refresh()

var _hitbox_center_offset: Vector2 = Vector2(18, 0)
## Centro del golpe respecto al origen local (equivale a la posición de CollisionShape2D).
@export var hitbox_center_offset: Vector2:
	get:
		return _hitbox_center_offset
	set(v):
		_hitbox_center_offset = v
		_queue_geometry_refresh()

@export_subgroup("Ventana activa")
@export var active_time: float = 0.12

@export_group("Vista previa")
## En editor: relleno y borde encima del sprite. En partida solo la textura salvo que actives esto para depurar.
@export var show_hitbox_overlay_in_game: bool = false

var damage_origin: Vector2 = Vector2.ZERO
var _hit_targets: Dictionary = {}
var _active: bool = false


func _queue_geometry_refresh() -> void:
	call_deferred("_apply_geometry")


func _build_rect_verts() -> PackedVector2Array:
	var half := hitbox_size * 0.5
	var c := hitbox_center_offset
	return PackedVector2Array([
		c + Vector2(-half.x, -half.y),
		c + Vector2(half.x, -half.y),
		c + Vector2(half.x, half.y),
		c + Vector2(-half.x, half.y)
	])


func _apply_geometry() -> void:
	if not is_inside_tree():
		return
	var verts := _build_rect_verts()
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs:
		cs.position = hitbox_center_offset
		var rect := cs.shape as RectangleShape2D
		if rect == null:
			rect = RectangleShape2D.new()
			cs.shape = rect
		rect.size = hitbox_size
	var vis := get_node_or_null("HitboxVisual") as Polygon2D
	if vis:
		vis.polygon = verts
		vis.color = Color(0.35, 0.92, 0.98, 0.52)
	var outline := get_node_or_null("HitboxOutline") as Line2D
	if outline:
		outline.points = verts
		outline.closed = true
	_update_overlay_visibility()


func _update_overlay_visibility() -> void:
	var show_overlay := Engine.is_editor_hint() or show_hitbox_overlay_in_game
	var vis := get_node_or_null("HitboxVisual") as Polygon2D
	if vis:
		vis.visible = show_overlay
	var outline := get_node_or_null("HitboxOutline") as Line2D
	if outline:
		outline.visible = show_overlay


func _ready() -> void:
	z_index = 48
	z_as_relative = false
	_apply_geometry()

	if Engine.is_editor_hint():
		return

	set_physics_process(false)
	monitoring = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func activate(owner_node: Node2D, dir: Vector2) -> void:
	damage_origin = owner_node.global_position
	var d := dir
	if d.length_squared() < 0.0001:
		d = Vector2.RIGHT
	d = d.normalized()
	global_position = owner_node.global_position + d * 22.0
	rotation = d.angle()
	_active = true
	set_physics_process(true)
	get_tree().create_timer(active_time).timeout.connect(_end)
	call_deferred("_kick_initial_hits")


func _kick_initial_hits() -> void:
	await get_tree().physics_frame
	_collect_hits()
	await get_tree().physics_frame
	_collect_hits()


func _end() -> void:
	_active = false
	set_physics_process(false)
	queue_free()


func _physics_process(_delta: float) -> void:
	if _active:
		_collect_hits()


func _collect_hits() -> void:
	for body in get_overlapping_bodies():
		_on_body_entered(body)
	for area in get_overlapping_areas():
		_on_area_entered(area)


func _on_body_entered(body: Node) -> void:
	if body == null or not is_instance_valid(body):
		return
	if body.is_in_group("player"):
		return
	if _hit_targets.has(body):
		return
	if body.has_method("take_damage"):
		_hit_targets[body] = true
		body.call("take_damage", damage, damage_origin)


func _on_area_entered(area: Area2D) -> void:
	if area == null or not is_instance_valid(area):
		return
	if _hit_targets.has(area):
		return
	if area.has_method("take_damage"):
		_hit_targets[area] = true
		area.call("take_damage", damage, damage_origin)
