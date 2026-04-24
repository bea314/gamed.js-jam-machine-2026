extends Camera2D

@export var path_obj : Node2D
@export var is_follow_path : bool = true
@export var auto_start_follow_player: bool = true
@export var enable_manual_toggle_debug: bool = true
@export var room_follow_half_extents: Vector2 = Vector2(250.0, 140.0)
var Map_Path : Node2D


var speed_camera_move : float = 4.5 

var modo_enfoque : bool = false

# ZOOM Pressets
var zoom_Map : Vector2 = Vector2(2.2,2.2)
var zoom_player : Vector2 = Vector2(3.0,3.0)

var _zoom_tween: Tween

func _ready() -> void:
	make_current()
	if ActiveRoomService.has_signal("active_room_changed"):
		ActiveRoomService.active_room_changed.connect(_on_active_room_changed)
	if auto_start_follow_player:
		call_deferred("initialize_camera_flow")


func initialize_camera_flow() -> void:
	var player := get_player_target()
	if player == null:
		return
	Zoom_type(true, player)


func get_player_target() -> Node2D:
	var scene := get_tree().current_scene
	if scene:
		var by_name := scene.get_node_or_null("Player") as Node2D
		if by_name:
			return by_name
	var by_group := get_tree().get_first_node_in_group("Player") as Node2D
	return by_group


func get_active_room_bounds() -> Rect2:
	var active_room := ActiveRoomService.active_room
	if active_room == null or not is_instance_valid(active_room):
		return Rect2()
	if active_room.has_method("get_camera_follow_bounds"):
		return active_room.get_camera_follow_bounds()
	return Rect2(active_room.global_position - room_follow_half_extents, room_follow_half_extents * 2.0)


func update_camera_position(delta: float) -> void:
	if not is_follow_path or path_obj == null:
		return
	var target_position := path_obj.global_position
	var player := get_player_target()
	if player != null and path_obj == player:
		var room_bounds := get_active_room_bounds()
		if room_bounds.size != Vector2.ZERO:
			target_position.x = clampf(target_position.x, room_bounds.position.x, room_bounds.end.x)
			target_position.y = clampf(target_position.y, room_bounds.position.y, room_bounds.end.y)
	global_position = global_position.lerp(target_position, speed_camera_move * delta)


func _process(delta: float) -> void:
	update_camera_position(delta)
	
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
	if not enable_manual_toggle_debug:
		return
	if Input.is_action_just_pressed("Test_Parametros"):
		modo_enfoque = !modo_enfoque
		if modo_enfoque:
			var get_player := get_player_target()
			if get_player:
				Zoom_type(true, get_player)
			else:
				modo_enfoque = false
		else:
			# Sin Map_Path (no pasaste por Indc_Player), seguir al jugador evita path_obj = null y cámara “muerta”.
			var path_map := Map_Path
			if path_map == null:
				path_map = ActiveRoomService.active_room
			if path_map == null:
				path_map = get_player_target()
			Zoom_type(false, path_map)


func _on_active_room_changed(room: Node2D) -> void:
	Map_Path = room
	if not modo_enfoque:
		return
	var player := get_player_target()
	if player:
		Zoom_type(true, player)
			
