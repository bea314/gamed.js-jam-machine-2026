extends Node2D
## Aura del escudo sobre el personaje: escala según el torso (`Ruka_Body`) y oculta al perder escudo o al morir.

@export var shield_texture: Texture2D
## Radio visual ≈ altura del torso × este factor (mismo espacio local que `Mesh_Sistem`).
@export var height_vs_torso: float = 1.12
## Alineado con `Mesh_Sistem/Body/Ruka_Body.position`.
@export var torso_offset: Vector2 = Vector2(0.0, -6.0)

@onready var _sprite: Sprite2D = $Sprite2D

var _health: HealthComponent
var _body_sprite: AnimatedSprite2D


func _ready() -> void:
	_body_sprite = get_parent().get_node_or_null("Body/Ruka_Body") as AnimatedSprite2D
	position = torso_offset
	if shield_texture != null and _sprite != null:
		_sprite.texture = shield_texture
	_refresh_scale()

	var player: Node = get_parent().get_parent()
	if player == null:
		return
	_health = player.get_node_or_null("HealthComponent") as HealthComponent
	if _health == null:
		return
	_health.shield_changed.connect(_on_shield_changed)
	_health.died.connect(_on_player_died)
	_on_shield_changed(_health.current_shield, _health.max_shield)


func _on_shield_changed(current: int, _max_shield: int) -> void:
	visible = current > 0


func _on_player_died() -> void:
	visible = false


func _refresh_scale() -> void:
	if _sprite == null or _sprite.texture == null or _body_sprite == null:
		return
	var frames: SpriteFrames = _body_sprite.sprite_frames
	if frames == null:
		return

	var anim: StringName = _body_sprite.animation
	if not frames.has_animation(anim):
		anim = &"default"

	var fc: int = frames.get_frame_count(anim)
	if fc <= 0:
		return
	var fi: int = clampi(_body_sprite.frame, 0, fc - 1)
	var tex: Texture2D = frames.get_frame_texture(anim, fi)
	if tex == null:
		return

	var body_h: float = float(tex.get_height()) * absf(_body_sprite.scale.y)
	var shield_h: float = float(_sprite.texture.get_height())
	if shield_h < 0.5:
		return
	var s: float = (body_h * height_vs_torso) / shield_h
	_sprite.scale = Vector2(s, s)
