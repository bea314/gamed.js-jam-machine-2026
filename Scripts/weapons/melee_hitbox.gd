extends Area2D

@export var damage: int = 2
@export var active_time: float = 0.12

var damage_origin: Vector2 = Vector2.ZERO
var _hit_targets: Dictionary = {}
var _active: bool = false


func _ready() -> void:
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
	# Espacio de física actualizado: mismo frame + siguiente tick.
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
