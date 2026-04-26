extends Control
class_name BuffHudItem

@export var icon_scale: float = 0.8:
	set(value):
		_icon_scale = maxf(value, 0.1)
		_update_icon_size()
	get:
		return _icon_scale

@export var ring_radius: float = 22.0:
	set(value):
		_ring_radius = maxf(value, 2.0)
		_update_minimum_size()
		queue_redraw()
	get:
		return _ring_radius

@export var ring_width: float = 4.0:
	set(value):
		_ring_width = maxf(value, 1.0)
		queue_redraw()
	get:
		return _ring_width

@export var ring_color: Color = Color(0.16, 0.85, 0.35, 1.0):
	set(value):
		_ring_color = value
		queue_redraw()
	get:
		return _ring_color

@onready var _icon: TextureRect = $Icon

var _progress: float = 1.0
var _icon_scale: float = 0.8
var _ring_radius: float = 22.0
var _ring_width: float = 4.0
var _ring_color: Color = Color(0.16, 0.85, 0.35, 1.0)


func _ready() -> void:
	_update_minimum_size()
	_update_icon_size()


func set_icon(texture: Texture2D) -> void:
	if _icon != null:
		_icon.texture = texture


func set_progress(normalized_value: float) -> void:
	_progress = clampf(normalized_value, 0.0, 1.0)
	queue_redraw()


func _update_minimum_size() -> void:
	var side: float = (_ring_radius * 2.0) + _ring_width + 4.0
	custom_minimum_size = Vector2(side, side)
	if is_inside_tree():
		size = custom_minimum_size
		_update_icon_size()


func _update_icon_size() -> void:
	if _icon == null:
		return
	var base_side: float = maxf(min(size.x, size.y), custom_minimum_size.x)
	var target_side: float = maxf(base_side * _icon_scale, 2.0)
	_icon.custom_minimum_size = Vector2(target_side, target_side)
	_icon.size = _icon.custom_minimum_size


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var arc_radius: float = minf(size.x, size.y) * 0.5 - _ring_width
	var points: int = max(24, int(96 * _progress))
	if points <= 1 or _progress <= 0.0:
		return
	var start_angle: float = -PI * 0.5
	var end_angle: float = start_angle + (TAU * _progress)
	draw_arc(center, arc_radius, start_angle, end_angle, points, _ring_color, _ring_width, true)
