extends Area2D

## Proyectil enemigo: daña al jugador (capa `player`), no a otros enemigos.

const PLAYER_MASK: int = 2

@export var speed: float = 380.0
@export var damage: int = 4
@export var life_time: float = 2.8

var direction: Vector2 = Vector2.RIGHT
var damage_origin: Vector2 = Vector2.ZERO
var _hit_targets: Dictionary = {}


func _ready() -> void:
	var timer := get_tree().create_timer(life_time)
	timer.timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	var space := get_world_2d().direct_space_state
	var motion := direction * speed * delta

	var point_q := PhysicsPointQueryParameters2D.new()
	point_q.position = global_position
	point_q.collision_mask = PLAYER_MASK
	point_q.collide_with_bodies = true
	point_q.collide_with_areas = false
	for ir in space.intersect_point(point_q, 8):
		if not ir.has("collider"):
			continue
		var node := ir.get("collider") as Node
		if _try_damage_player(node):
			queue_free()
			return

	var from := global_position
	var to := from + motion
	var ray := PhysicsRayQueryParameters2D.create(from, to)
	ray.collision_mask = PLAYER_MASK
	ray.collide_with_bodies = true
	ray.collide_with_areas = false
	var hit := space.intersect_ray(ray)
	if hit.has("collider"):
		var n := hit.get("collider") as Node
		if _try_damage_player(n):
			queue_free()
			return

	global_position = to


func _try_damage_player(n: Node) -> bool:
	if n == null or not is_instance_valid(n):
		return false
	if not n.is_in_group("player"):
		return false
	if _hit_targets.has(n):
		return false
	var health := n.get_node_or_null("HealthComponent") as HealthComponent
	if health == null:
		return false
	_hit_targets[n] = true
	health.take_damage(damage, damage_origin)
	return true
