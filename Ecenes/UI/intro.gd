extends Node2D

const SKIP_FONT := preload("res://Recursos/KOMTXKBI.ttf")
const INTRO_VIDEO_PATH := "res://Recursos/Textures/intro/bug in the machine intro.ogv"
const INTRO_START_SECONDS := 1.5

## Fundido de salida para evitar corte brusco de imagen y audio
const EXIT_FADE_SEC := 2.15
const EXIT_VOL_DB := -50.0
## Sube desde silencio al entrar en la escena (el menú ya baja antes del cambio).
const INTRO_AUDIO_FADE_IN_SEC := 1.15
const INTRO_AUDIO_START_DB := -38.0

const LEVEL_SCENE_PATH := "res://Ecenes/level.tscn"

@onready var _video: VideoStreamPlayer = $VideoLayer/VideoStreamPlayer
@onready var _fade: ColorRect = $FadeLayer/Fade

var _exiting: bool = false
var _intro_audio_in_tween: Tween
var _skip_root: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_video.volume_db = INTRO_AUDIO_START_DB
	_video.modulate = Color(1, 1, 1, 1)
	_setup_skip_button()
	_video.stream = load(INTRO_VIDEO_PATH) as VideoStream
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.finished.connect(_on_video_finished)
	_video.play()
	await get_tree().process_frame
	_video.stream_position = INTRO_START_SECONDS
	_intro_audio_in_tween = create_tween()
	_intro_audio_in_tween.set_trans(Tween.TRANS_QUART)
	_intro_audio_in_tween.set_ease(Tween.EASE_OUT)
	_intro_audio_in_tween.tween_property(_video, "volume_db", 0.0, INTRO_AUDIO_FADE_IN_SEC)


func _on_video_finished() -> void:
	if _exiting:
		return
	_run_exit_fade()


func _run_exit_fade() -> void:
	if _exiting:
		return
	_exiting = true
	if _intro_audio_in_tween != null and is_instance_valid(_intro_audio_in_tween):
		_intro_audio_in_tween.kill()
	_intro_audio_in_tween = null
	if _video.finished.is_connected(_on_video_finished):
		_video.finished.disconnect(_on_video_finished)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_QUART)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(_fade, "modulate:a", 1.0, EXIT_FADE_SEC)
	tw.tween_property(_video, "volume_db", EXIT_VOL_DB, EXIT_FADE_SEC)
	tw.tween_property(_video, "modulate:a", 0.0, EXIT_FADE_SEC * 0.95)
	if _skip_root != null:
		tw.tween_property(_skip_root, "modulate:a", 0.0, EXIT_FADE_SEC * 0.9)
	await tw.finished
	_video.stop()
	_go_to_level_after_intro()


## Tras `await` en el fade, el cambio de escena conviene diferir a idle (evita fallos esporádicos en Godot).
func _go_to_level_after_intro() -> void:
	call_deferred("_deferred_after_intro")


func _deferred_after_intro() -> void:
	# Tras el último fade, el árbol puede estar en stack raro; deferred + unlock evita colisiones con el candado.
	LoadingTransition.unlock_for_next_goto()
	LoadingTransition.goto_scene(LEVEL_SCENE_PATH)


func _setup_skip_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_skip_root = root

	var btn := Button.new()
	btn.text = "SKIP"
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_override(&"font", SKIP_FONT)
	btn.add_theme_font_size_override(&"font_size", 28)
	btn.add_theme_color_override(&"font_color", Color.WHITE)

	var style_normal := _make_skip_style()
	var style_hover := style_normal.duplicate() as StyleBoxFlat
	style_hover.bg_color = Color(0, 0, 0, 0.55)
	var style_pressed := style_normal.duplicate() as StyleBoxFlat
	style_pressed.bg_color = Color(0, 0, 0, 0.65)

	btn.add_theme_stylebox_override(&"normal", style_normal)
	btn.add_theme_stylebox_override(&"hover", style_hover)
	btn.add_theme_stylebox_override(&"pressed", style_pressed)

	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	btn.offset_left = -152.0
	btn.offset_right = -28.0
	btn.offset_top = 28.0
	btn.offset_bottom = 84.0

	btn.pressed.connect(_on_skip_pressed)
	root.add_child(btn)


func _make_skip_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.45)
	sb.set_border_width_all(2)
	sb.border_color = Color.WHITE
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _on_skip_pressed() -> void:
	if _exiting:
		return
	if _video.finished.is_connected(_on_video_finished):
		_video.finished.disconnect(_on_video_finished)
	_run_exit_fade()
