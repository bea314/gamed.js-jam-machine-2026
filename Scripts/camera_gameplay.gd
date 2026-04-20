extends Camera2D

@export var path_obj : Node2D
@export var is_follow_path : bool = true
var Map_Path : Node2D


var speed_camera_move : float = 4.5 

var modo_enfoque : bool = false

# ZOOM Pressets
var zoom_Map : Vector2 = Vector2(2.2,2.2)
var zoom_player : Vector2 = Vector2(3.0,3.0)

func _process(delta: float) -> void:
	if is_follow_path:
		if path_obj:
			var position_objet = path_obj.global_position
			global_position = global_position.lerp(position_objet, speed_camera_move * delta)
	
func Zoom_type(modo_enf : bool, get_phath : Node2D):
	if modo_enf:
		modo_enfoque = true
		tween_animation_zoom("Player")
		path_obj = get_phath
	else:
		modo_enfoque = false
		tween_animation_zoom("Map")
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
		if modo_enfoque:
			var get_player = get_tree().current_scene.get_node("Player")
			Zoom_type(modo_enfoque, get_player)
		else:
			Zoom_type(modo_enfoque, Map_Path)
			
