extends Control

## Ícono X sin variante “selected”: solo modulate + tween (sin tocar escala/pivote del TextureRect;
## el layout usa offsets negativos y escala grande; mover pivot los sacaba de pantalla).
@export var texture_idle: Texture2D
@export var highlight_modulate: Color = Color(1.14, 1.16, 1.22, 1.0)
@export_range(0.03, 0.4, 0.01) var tween_duration: float = 0.14

@onready var _graphic: TextureRect = $Graphic
@onready var _hit: Button = $ClickArea

var _hovering := false
var _focused := false
var _tween: Tween


func _ready() -> void:
	if texture_idle:
		_graphic.texture = texture_idle
	_graphic.modulate = Color.WHITE
	_hit.mouse_entered.connect(_on_mouse_entered)
	_hit.mouse_exited.connect(_on_mouse_exited)
	_hit.focus_entered.connect(_on_focus_entered)
	_hit.focus_exited.connect(_on_focus_exited)


func _highlight_active() -> bool:
	return _hovering or _focused


func _refresh_visual() -> void:
	var on := _highlight_active()
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)
	var target_mod := highlight_modulate if on else Color.WHITE
	_tween.tween_property(_graphic, "modulate", target_mod, tween_duration)


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
