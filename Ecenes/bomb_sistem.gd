extends Node

const DINAMITA = preload("res://Ecenes/Objets/Dinamita.tscn")


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Launch_Bomb"):
		var instanca_bomba = DINAMITA.instantiate()
		var current_scene = get_tree().current_scene
		current_scene.add_child(instanca_bomba)
