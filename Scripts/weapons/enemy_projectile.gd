extends Area2D

## Proyectil enemigo: daña al jugador (capa `player`), no a otros enemigos.

const PLAYER_MASK: int = 2

const _DEFAULT_ICE_TEXTURES: Array[Texture2D] = [
	preload("res://Recursos/Textures/Enemies/balas/bullet1.png"),
	preload("res://Recursos/Textures/Enemies/balas/bullet2.png"),
	preload("res://Recursos/Textures/Enemies/balas/bullet3.png"),
]

@export var speed: float = 380.0
@export var damage: int = 4
@export var life_time: float = 2.8
## Si está vacío, se usan las texturas por defecto de `balas/` y una se elige al azar por proyectil.
@export var texture_variants: Array[Texture2D] = []
@export var sprite_scale: float = 0.22
## Radio de colisión ≈ este factor × mitad del lado mayor del sprite (tras escalar).
@export var collision_radius_factor: float = 0.38
## Desactiva para usar solo la textura del nodo `Vis` (la que ves en el editor).
@export var randomize_texture_on_spawn: bool = true
## Desactiva para ajustar el `CollisionShape2D` a mano; si está activo, `_ready()` recalcula el radio.
@export var auto_fit_collision_on_ready: bool = true

@onready var _vis: Sprite2D = $Vis
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var direction: Vector2 = Vector2.RIGHT
var damage_origin: Vector2 = Vector2.ZERO
var _hit_targets: Dictionary = {}


func _ready() -> void:
	if randomize_texture_on_spawn:
		_apply_random_texture()
	_vis.scale = Vector2.ONE * sprite_scale
	if auto_fit_collision_on_ready:
		_fit_collision_radius()
	_vis.rotation = direction.angle()
	var timer := get_tree().create_timer(life_time)
	timer.timeout.connect(queue_free)


func _apply_random_texture() -> void:
	var variants := texture_variants if not texture_variants.is_empty() else _DEFAULT_ICE_TEXTURES
	if variants.is_empty():
		return
	_vis.texture = variants[randi() % variants.size()]


func _fit_collision_radius() -> void:
	var tex := _vis.texture
	if tex == null:
		return
	var half_major: float = maxf(tex.get_width(), tex.get_height()) * 0.5 * sprite_scale
	var circle := _collision_shape.shape as CircleShape2D
	if circle:
		circle.radius = half_major * collision_radius_factor


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
	if not ActiveRoomService.hostile_may_act(self):
		return false
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
