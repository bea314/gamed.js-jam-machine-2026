extends Camera2D

@export var path_obj : Node2D
@export var is_follow_path : bool = true
var speed_camera_move : float = 2.5 

var modo_enfoque : bool = false

# ZOOM Pressets
var zoom_Map : Vector2 = Vector2(2.2,2.2)
var zoom_player : Vector2 = Vector2(3.0,3.0)
func _ready() -> void:
	Zoom_type()

func _process(delta: float) -> void:
	if is_follow_path:
		var position_objet = path_obj.global_position
		
		global_position = global_position.lerp(position_objet, speed_camera_move * delta)
	
func Zoom_type():
	var get_phath
	if modo_enfoque:
		tween_animation_zoom("Player")
		get_phath = get_tree().current_scene.get_node("Player")
		path_obj = get_phath
	else:
		tween_animation_zoom("Map")
		get_phath = get_tree().current_scene.get_node("Level_Rooms")
		path_obj = get_phath

func tween_animation_zoom(Objet : String):
	var tween = get_tree().create_tween()
	if Objet == "Player":
		tween.tween_property(self, "zoom", zoom_player, 1.0) # 1.5 segundos
	elif Objet == "Map":
		tween.tween_property(self, "zoom", zoom_Map, 0.8) # 1.5 segundos

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Test_Parametros"):
		modo_enfoque = !modo_enfoque
		Zoom_type()
