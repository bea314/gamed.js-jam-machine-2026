extends Control

## Hover/foco: tween de modulate sobre Graphic (TextureRect, pause) o ButtonBack (Sprite2D, pareja options).
@export var texture_idle: Texture2D
@export var highlight_modulate: Color = Color(1.14, 1.16, 1.22, 1.0)
@export_range(0.03, 0.4, 0.01) var tween_duration: float = 0.14

@onready var _hit: Button = $ClickArea

var _visual: CanvasItem
var _hovering := false
var _focused := false
var _tween: Tween


func _ready() -> void:
	var graphic_rect := get_node_or_null("Graphic") as TextureRect
	var graphic_sprite := get_node_or_null("ButtonBack") as Sprite2D
	if graphic_rect:
		_visual = graphic_rect
		if texture_idle:
			graphic_rect.texture = texture_idle
	elif graphic_sprite:
		_visual = graphic_sprite
		if texture_idle:
			graphic_sprite.texture = texture_idle
	else:
		push_error("pause_menu_button_close: añade Graphic (TextureRect) o ButtonBack (Sprite2D).")
		return

	_visual.modulate = Color.WHITE
	_hit.mouse_entered.connect(_on_mouse_entered)
	_hit.mouse_exited.connect(_on_mouse_exited)
	_hit.focus_entered.connect(_on_focus_entered)
	_hit.focus_exited.connect(_on_focus_exited)


func _highlight_active() -> bool:
	return _hovering or _focused


func _refresh_visual() -> void:
	if _visual == null:
		return
	var on := _highlight_active()
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)
	var target_mod := highlight_modulate if on else Color.WHITE
	_tween.tween_property(_visual, "modulate", target_mod, tween_duration)


func _on_mouse_entered() -> void:
	_hovering = true
	_refresh_visual()


func _on_mouse_exited() -> void:
	_hovering = false
	_refresh_visual()


func _on_focus_entered() -> void:
	_focused = true
	_refresh_visual()


func _on_focus_exited() -> void:
	_focused = false
	_refresh_visual()
