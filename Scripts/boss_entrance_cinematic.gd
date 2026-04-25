extends Node
class_name BossEntranceCinematic

signal cinematic_finished

@export var fade_out_duration: float = 0.4
@export var sleep_hold_duration: float = 0.6
@export var fade_in_duration: float = 0.8
@export var zoom_start: Vector2 = Vector2(2.0, 2.0)
@export var zoom_end: Vector2 = Vector2(1.0, 1.0)
@export var zoom_duration: float = 0.8
@export var use_zoom_reveal: bool = false
@export var shake_magnitude: float = 3.0
@export var shake_duration: float = 0.18
@export var wake_sfx_stream: AudioStream
@export var qa_speed_multiplier: float = 3.0

var _running: bool = false
var _fade_layer: ScreenFade


func play(player: Node, boss: Node2D, camera: Camera2D, music_node: Node, skip_cinematic: bool = false, fast_for_qa: bool = false) -> void:
	if _running:
		return
	_running = true

	var speed := qa_speed_multiplier if fast_for_qa else 1.0
	if skip_cinematic:
		speed = 1000.0

	_ensure_fade_layer()

	if player != null and player.has_method("set_cinematic_input_blocked"):
		player.set_cinematic_input_blocked(true)
	if player != null and player.has_method("set_gameplay_hud_visible"):
		player.set_gameplay_hud_visible(false)
	_toggle_optional_boss_hud(false)

	if music_node != null and music_node.has_method("set_ambient_muted"):
		music_node.set_ambient_muted(true)

	await _fade_layer.fade_out(_scale_time(fade_out_duration, speed), Tween.TRANS_CUBIC, Tween.EASE_IN)

	if boss != null and is_instance_valid(boss):
		boss.visible = true
		if boss.has_method("set_sleeping_for_cinematic"):
			boss.set_sleeping_for_cinematic()

	var camera_original_zoom := Vector2.ONE
	if camera != null and is_instance_valid(camera):
		camera_original_zoom = camera.zoom

	if camera != null and is_instance_valid(camera) and boss != null and is_instance_valid(boss):
		if camera.has_method("start_boss_cinematic_focus"):
			var focus_zoom := zoom_start if use_zoom_reveal else camera_original_zoom
			camera.start_boss_cinematic_focus(boss.global_position, focus_zoom)

	await get_tree().create_timer(_scale_time(sleep_hold_duration, speed)).timeout

	var zoom_tween: Tween = null
	if use_zoom_reveal and camera != null and is_instance_valid(camera) and camera.has_method("tween_zoom_from_to"):
		zoom_tween = camera.tween_zoom_from_to(
			zoom_start,
			zoom_end,
			_scale_time(zoom_duration, speed),
			Tween.TRANS_CUBIC,
			Tween.EASE_OUT
		)
	var fade_in_tween := _fade_layer.start_fade_in(_scale_time(fade_in_duration, speed), Tween.TRANS_CUBIC, Tween.EASE_OUT)
	if zoom_tween != null:
		await zoom_tween.finished
	if fade_in_tween != null:
		await fade_in_tween.finished

	_play_wake_sfx()
	if boss != null and is_instance_valid(boss) and boss.has_method("start_wake_sequence"):
		boss.start_wake_sequence()
		if shake_magnitude > 0.0 and camera != null and camera.has_method("shake_once"):
			camera.shake_once(shake_magnitude, _scale_time(shake_duration, speed))
		if boss.has_signal("wake_animation_finished"):
			await boss.wake_animation_finished
		else:
			await get_tree().create_timer(_scale_time(0.65, speed)).timeout

	if music_node != null and music_node.has_method("play_boss_theme"):
		music_node.play_boss_theme()
	_toggle_optional_boss_hud(true)

	if player != null and player.has_method("set_gameplay_hud_visible"):
		player.set_gameplay_hud_visible(true)
	if player != null and player.has_method("set_cinematic_input_blocked"):
		player.set_cinematic_input_blocked(false)

	if camera != null and camera.has_method("finish_boss_cinematic_focus"):
		camera.finish_boss_cinematic_focus(player as Node2D)

	_running = false
	cinematic_finished.emit()


func _scale_time(seconds: float, speed: float) -> float:
	return maxf(seconds / maxf(speed, 0.001), 0.0)


func _ensure_fade_layer() -> void:
	if _fade_layer != null and is_instance_valid(_fade_layer):
		return
	var current_scene := get_tree().current_scene
	if current_scene == null:
		current_scene = get_tree().root
	_fade_layer = ScreenFade.new()
	current_scene.add_child(_fade_layer)


func _play_wake_sfx() -> void:
	if wake_sfx_stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = wake_sfx_stream
	player.bus = &"SFX"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _toggle_optional_boss_hud(is_visible: bool) -> void:
	for node in get_tree().get_nodes_in_group("boss_hud"):
		if node is CanvasItem:
			(node as CanvasItem).visible = is_visible
