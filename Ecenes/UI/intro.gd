extends Node2D

const SKIP_FONT := preload("res://Recursos/KOMTXKBI.ttf")
const INTRO_VIDEO_PATH := "res://Recursos/Textures/intro/bug in the machine intro.ogv"
const INTRO_START_SECONDS := 2.0

@onready var _video: VideoStreamPlayer = $VideoLayer/VideoStreamPlayer
@onready var _fade: ColorRect = $FadeLayer/Fade

var _exiting: bool = false


func _ready() -> void:
	_setup_skip_button()
	_video.stream = load(INTRO_VIDEO_PATH) as VideoStream
	_video.finished.connect(_on_video_finished)
	_video.play()
	await get_tree().process_frame
	_video.stream_position = INTRO_START_SECONDS


func _on_video_finished() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 1.0)
	await tw.finished
	_go_to_game()


func _setup_skip_button() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

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

	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.anchor_top = 0.0
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
	_video.stop()
	_go_to_game()


func _go_to_game() -> void:
	if _exiting:
		return
	_exiting = true
	get_tree().change_scene_to_file("res://Ecenes/level.tscn")
