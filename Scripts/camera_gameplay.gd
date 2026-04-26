extends Camera2D

@export var path_obj : Node2D
@export var is_follow_path : bool = true
var Map_Path : Node2D


var speed_camera_move : float = 4.5 

var modo_enfoque : bool = false

# ZOOM Pressets
var zoom_Map : Vector2 = Vector2(2.2,2.2)
var zoom_player : Vector2 = Vector2(3.0,3.0)

var _zoom_tween: Tween
var _shake_tween: Tween
var _cinematic_active: bool = false

func _process(delta: float) -> void:
	update_camera_position(delta)


func start_boss_cinematic_focus(focus_global: Vector2, start_zoom: Vector2) -> void:
	_cinematic_active = true
	is_follow_path = false
	global_position = focus_global
	if _zoom_tween != null and is_instance_valid(_zoom_tween):
		_zoom_tween.kill()
	zoom = start_zoom


func tween_zoom_from_to(start_zoom: Vector2, end_zoom: Vector2, duration: float, trans: Tween.TransitionType = Tween.TRANS_CUBIC, ease: Tween.EaseType = Tween.EASE_OUT) -> Tween:
	if _zoom_tween != null and is_instance_valid(_zoom_tween):
		_zoom_tween.kill()
	zoom = start_zoom
	_zoom_tween = create_tween()
	_zoom_tween.set_trans(trans)
	_zoom_tween.set_ease(ease)
	_zoom_tween.tween_property(self, "zoom", end_zoom, maxf(duration, 0.0))
	return _zoom_tween


func finish_boss_cinematic_focus(player: Node2D) -> void:
	_cinematic_active = false
	if player != null and is_instance_valid(player):
		path_obj = player
	is_follow_path = true


func shake_once(magnitude: float = 3.0, duration: float = 0.18) -> void:
	if magnitude <= 0.0 or duration <= 0.0:
		offset = Vector2.ZERO
		return
	if _shake_tween != null and is_instance_valid(_shake_tween):
		_shake_tween.kill()
	_shake_tween = create_tween()
	_shake_tween.tween_property(self, "offset", Vector2(randf_range(-magnitude, magnitude), randf_range(-magnitude, magnitude)), duration * 0.25)
	_shake_tween.tween_property(self, "offset", Vector2(randf_range(-magnitude, magnitude), randf_range(-magnitude, magnitude)), duration * 0.25)
	_shake_tween.tween_property(self, "offset", Vector2.ZERO, duration * 0.5)
	
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
	if _zoom_tween != null and is_instance_valid(_zoom_tween):
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	if Objet == "Player":
		_zoom_tween.tween_property(self, "zoom", zoom_player, 1.0) # 1.5 segundos
	elif Objet == "Map":
		_zoom_tween.tween_property(self, "zoom", zoom_Map, 0.8) # 1.5 segundos

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Test_Parametros"):
		modo_enfoque = !modo_enfoque
		if modo_enfoque:
			var get_player := get_tree().current_scene.get_node_or_null("Player") as Node2D
			if get_player:
				Zoom_type(true, get_player)
			else:
				modo_enfoque = false
		else:
			# Sin Map_Path (no pasaste por Indc_Player), seguir al jugador evita path_obj = null y cámara “muerta”.
			var path_map := Map_Path
			if path_map == null:
				path_map = get_tree().current_scene.get_node_or_null("Player") as Node2D
			Zoom_type(false, path_map)
			
