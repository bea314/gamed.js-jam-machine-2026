extends Control
class_name BuffHudItem

@export var icon_scale: float = 0.8:
	set(value):
		_icon_scale = maxf(value, 0.1)
		_update_icon_size()
	get:
		return _icon_scale

@export var slot_size: float = 48.0:
	set(value):
		_slot_size = maxf(value, 24.0)
		_update_minimum_size()
	get:
		return _slot_size

@onready var _icon: TextureRect = $Icon
@onready var _stack_label: Label = $StackLabel
@onready var _pop_label: Label = $PopLabel

var _icon_scale: float = 0.8
var _slot_size: float = 48.0
var _pop_tween: Tween = null


func _ready() -> void:
	_update_minimum_size()
	_update_icon_size()


func set_icon(texture: Texture2D) -> void:
	if _icon != null:
		_icon.texture = texture


func set_stack_count(value: int) -> void:
	if _stack_label == null:
		return
	_stack_label.text = "x%d" % maxi(value, 0)


func play_pop(text: String, color: Color) -> void:
	if _pop_label == null:
		return
	if _pop_tween != null and _pop_tween.is_running():
		_pop_tween.kill()
	_pop_label.text = text
	_pop_label.modulate = Color(color.r, color.g, color.b, 1.0)
	_pop_label.position = Vector2(12.0, -9.0)
	_pop_label.visible = true
	_pop_tween = create_tween()
	_pop_tween.set_parallel(true)
	_pop_tween.tween_property(_pop_label, "position:y", -19.0, 0.28)
	_pop_tween.tween_property(_pop_label, "modulate:a", 0.0, 0.28)
	_pop_tween.set_parallel(false)
	_pop_tween.tween_callback(func() -> void:
		if _pop_label != null:
			_pop_label.visible = false
	)


func _update_minimum_size() -> void:
	var side: float = _slot_size
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
