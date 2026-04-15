extends Control

@onready var _back_button: Button = $CenterContainer/MainVBox/BackButton


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Ecenes/Menu/Menu.tscn")
