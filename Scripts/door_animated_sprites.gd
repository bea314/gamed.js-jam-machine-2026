extends Node2D

const FRAME_TIME := 0.07

const FRAMES: Array[Texture2D] = [
	preload("res://Recursos/Textures/Map/Puertas/closed door.png"),
	preload("res://Recursos/Textures/Map/Puertas/open door1.png"),
	preload("res://Recursos/Textures/Map/Puertas/open door2.png"),
	preload("res://Recursos/Textures/Map/Puertas/open door3.png"),
	preload("res://Recursos/Textures/Map/Puertas/open door4.png"),
	preload("res://Recursos/Textures/Map/Puertas/open door5.png"),
]

@onready var _sprite: Sprite2D = $DoorSprite
@onready var _placeholder: MeshInstance2D = $Mesh_Door

var _tween: Tween


func _ready() -> void:
	if _placeholder:
		_placeholder.visible = false
	_sprite.centered = true
	_apply_frame(0)
	_sprite.scale = Vector2(0.32, 0.32)


func snap_to_frame(idx: int) -> void:
	_kill_tween()
	_apply_frame(idx)


func snap_fully_closed() -> void:
	snap_to_frame(0)


func snap_fully_open() -> void:
	snap_to_frame(FRAMES.size() - 1)


func play_open() -> void:
	_kill_tween()
	_tween = create_tween()
	for i in range(FRAMES.size()):
		_tween.tween_callback(_apply_frame.bind(i))
		if i < FRAMES.size() - 1:
			_tween.tween_interval(FRAME_TIME)


func play_close() -> void:
	_kill_tween()
	_tween = create_tween()
	for i in range(FRAMES.size() - 1, -1, -1):
		_tween.tween_callback(_apply_frame.bind(i))
		if i > 0:
			_tween.tween_interval(FRAME_TIME)


func _apply_frame(idx: int) -> void:
	idx = clampi(idx, 0, FRAMES.size() - 1)
	_sprite.texture = FRAMES[idx]


func _kill_tween() -> void:
	if _tween != null and is_instance_valid(_tween):
		_tween.kill()
	_tween = null
