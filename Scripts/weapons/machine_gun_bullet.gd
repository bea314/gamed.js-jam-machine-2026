extends "res://Scripts/weapons/bullet.gd"

## Misma composición / edición que `enemy_projectile.gd` (proyectiles hielo): `Vis` + `CircleShape2D` + ajuste por escala.

const _DEFAULT_MG_TEXTURES: Array[Texture2D] = [
	preload("res://Recursos/Textures/Ruka/Balas/bullets2.png"),
]

@export var texture_variants: Array[Texture2D] = []
@export var sprite_scale: float = 0.22
@export var collision_radius_factor: float = 0.38
@export var randomize_texture_on_spawn: bool = false
@export var auto_fit_collision_on_ready: bool = true

@onready var _vis: Sprite2D = $Vis
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if randomize_texture_on_spawn:
		_apply_random_texture()
	_vis.scale = Vector2.ONE * sprite_scale
	if auto_fit_collision_on_ready:
		_fit_collision_radius()
	_vis.rotation = direction.angle()
	super._ready()


func _apply_random_texture() -> void:
	var variants := texture_variants if not texture_variants.is_empty() else _DEFAULT_MG_TEXTURES
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
