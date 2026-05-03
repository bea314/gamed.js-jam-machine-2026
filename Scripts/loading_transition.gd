extends Node
## Coordinador entre escenas pesadas y `loading_screen.tscn`.
const LOADING_SCENE: PackedScene = preload("res://Ecenes/UI/loading_screen.tscn")

var next_scene_path: String = ""


func goto_scene(path: String) -> void:
	next_scene_path = path
	get_tree().change_scene_to_packed(LOADING_SCENE)


func clear_pending() -> void:
	next_scene_path = ""
