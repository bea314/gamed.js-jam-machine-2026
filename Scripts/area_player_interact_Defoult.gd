extends Area2D

@onready var doors_commun: Node2D = $".."

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		var obten_path = doors_commun.Path_TOGO
		body.global_position = obten_path.global_position
