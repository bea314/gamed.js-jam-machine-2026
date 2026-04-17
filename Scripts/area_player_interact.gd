extends Area2D
@onready var doors_commun: Node2D = $".."

func _on_body_entered_connect(body: Node2D) -> void:
	if body.is_in_group("Player"):
		var Path_tp = doors_commun.PATH_GO
		if not Path_tp:
			print(Path_tp)
			return
		
		body.global_position = Path_tp.global_position
