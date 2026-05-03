extends Node2D

const SKIP_FONT := preload("res://Recursos/KOMTXKBI.ttf")

const INTRO_PAG_1 = preload("uid://r4nswq7b661r")
const INTRO_PAG_2 = preload("uid://bg7fpgsk2k6jm")
const INTRO_PAG_3 = preload("uid://bgb73yfpr74g2")
const INTRO_PAG_4 = preload("uid://ne2bwynloqb1")
const INTRO_PAG_5 = preload("uid://bsoptid5horiw")
const INTRO_PAG_6 = preload("uid://cj2y04ckwuhcn")
const INTRO_PAG_8 = preload("uid://bfptnybjrssxe")
const INTRO_PAG_9 = preload("uid://bflqhvqnfgme6")
const INTRO_PAG_10 = preload("uid://jkhma5i5rn7e")
const INTRO_PAG_11 = preload("uid://d06i01kceuc14")
const INTRO_PAG_12 = preload("uid://csesn7mjhnwr5")
const INTRO_PAG_13 = preload("uid://cc3ivci0rk4pa")
const INTRO_PAG_14 = preload("uid://dof6sjl5oqxjp")
const INTRO_PAG_15 = preload("uid://blr8djkhv827t")


@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var fade: AnimationPlayer = $fade/fade
@onready var _audio: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	_setup_skip_button()
	sprite_2d.texture = INTRO_PAG_1
	await get_tree().create_timer(6.0).timeout
	sprite_2d.texture = INTRO_PAG_2
	await get_tree().create_timer(6.0).timeout
	sprite_2d.texture = INTRO_PAG_3
	await get_tree().create_timer(8.0).timeout
	sprite_2d.texture = INTRO_PAG_4
	await get_tree().create_timer(2.0).timeout
	sprite_2d.texture = INTRO_PAG_5
	await get_tree().create_timer(2.0).timeout
	sprite_2d.texture = INTRO_PAG_6
	await get_tree().create_timer(6.0).timeout
	sprite_2d.texture = INTRO_PAG_8
	await get_tree().create_timer(9.0).timeout
	sprite_2d.texture = INTRO_PAG_9
	await get_tree().create_timer(7.5).timeout
	sprite_2d.texture = INTRO_PAG_10
	await get_tree().create_timer(1.2).timeout
	sprite_2d.texture = INTRO_PAG_11
	await get_tree().create_timer(1.2).timeout
	sprite_2d.texture = INTRO_PAG_12
	await get_tree().create_timer(1.2).timeout
	sprite_2d.texture = INTRO_PAG_13
	await get_tree().create_timer(1.2).timeout
	sprite_2d.texture = INTRO_PAG_14
	await get_tree().create_timer(1.2).timeout
	sprite_2d.texture = INTRO_PAG_15
	await get_tree().create_timer(3).timeout
	fade.play("new_animation")
	await get_tree().create_timer(1).timeout
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
	_audio.stop()
	_go_to_game()


func _go_to_game() -> void:
	get_tree().change_scene_to_file("res://Ecenes/level.tscn")
