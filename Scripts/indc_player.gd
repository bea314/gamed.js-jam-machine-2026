extends Area2D

@onready var room_defoult: Node2D = $".."

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		var get_Camera = get_tree().current_scene.get_node("CameraGameplay")
		get_Camera.Map_Path = room_defoult
		get_Camera.Zoom_type(true,room_defoult)
