extends Control
class_name TextureCheckboxButton

signal toggled(pressed: bool)

@onready var _hit: Button = $HitButton
@onready var _mark: TextureRect = $CheckboxMark


func _ready() -> void:
	_hit.toggled.connect(_on_hit_toggled)


func _on_hit_toggled(pressed: bool) -> void:
	_mark.visible = pressed
	toggled.emit(pressed)


func set_pressed_no_signal(pressed: bool) -> void:
	_hit.set_pressed_no_signal(pressed)
	_mark.visible = pressed


var button_pressed: bool:
	get:
		return _hit.button_pressed
	set(value):
		_hit.button_pressed = value
		_mark.visible = value


func grab_toggle_focus() -> void:
	_hit.grab_focus()
