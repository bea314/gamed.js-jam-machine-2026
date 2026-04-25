extends CanvasLayer

var Get_Music_current_scene

func _ready() -> void:
	Get_Music_current_scene = get_tree().current_scene
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Esq"):
		get_tree().paused = false
		queue_free()
