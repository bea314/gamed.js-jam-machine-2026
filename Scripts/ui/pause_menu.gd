extends CanvasLayer

const MENU_PATH := "res://Ecenes/Menu/Menu.tscn"

@onready var _settings: GameSettings = get_node("/root/SettingsManager") as GameSettings
@onready var _title_label: Control = $Root/CenterContainer/MainVBox/TitleLabel
@onready var _hint_label: Control = $Root/CenterContainer/MainVBox/HintLabel
@onready var _main_buttons: VBoxContainer = $Root/CenterContainer/MainVBox/MainButtons
@onready var _options_panel: VBoxContainer = $Root/CenterContainer/MainVBox/OptionsPanel
@onready var _resume_button: BaseButton = $Root/CenterContainer/MainVBox/MainButtons/ResumeButton
@onready var _options_button: BaseButton = $Root/CenterContainer/MainVBox/MainButtons/OptionsButton
@onready var _main_menu_button: BaseButton = $Root/CenterContainer/MainVBox/MainButtons/MainMenuButton
@onready var _exit_button: BaseButton = $Root/CenterContainer/MainVBox/MainButtons/ExitButton
@onready var _music_slider: HSlider = $Root/CenterContainer/MainVBox/OptionsPanel/MusicRow/MusicSlider
@onready var _sfx_slider: HSlider = $Root/CenterContainer/MainVBox/OptionsPanel/SFXRow/SFXSlider
@onready var _fullscreen_check: CheckButton = $Root/CenterContainer/MainVBox/OptionsPanel/FullscreenCheck
@onready var _back_button: BaseButton = $Root/CenterContainer/MainVBox/OptionsPanel/BackButton

@onready var pause_menu_sound: AudioStreamPlayer = $Pause_Menu
const PAUSE_ENTER = preload("uid://cqw2v5rk8txgg")
const PAUSE_OUT = preload("uid://du3t7dpj11dty")

const OPTION_ENTER = preload("uid://dy2u244hlpdq7")
const OPTION_EXIT = preload("uid://3u2gkut4ygea")

@export_group("Nav sounds")
@export var nav_sound_file: Array[AudioStream] = []


func _ready() -> void:
	visible = false
	_options_panel.visible = false

	_resume_button.pressed.connect(_on_resume_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	_music_slider.value = _settings.music_volume
	_sfx_slider.value = _settings.sfx_volume
	_fullscreen_check.button_pressed = _settings.fullscreen


func _set_main_menu_visible(show_main: bool) -> void:
	_title_label.visible = show_main
	_hint_label.visible = show_main
	_main_buttons.visible = show_main
	_options_panel.visible = not show_main


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game"):
		return
	# Sin esto, la repetición automática de tecla (hold / echo) alterna abrir↔cerrar cada frame.
	if event is InputEventKey and event.echo:
		return
	if _is_game_over_blocking():
		return
	if _options_panel.visible:
		_close_options()
		get_viewport().set_input_as_handled()
		return
	if visible:
		close_pause()
	else:
		open_pause()
	get_viewport().set_input_as_handled()


func _is_game_over_blocking() -> bool:
	var p := get_parent()
	if p == null:
		return false
	for c in p.get_children():
		if c.name == "GameOverScreen" and c is CanvasLayer and (c as CanvasLayer).visible:
			return true
	return false


func open_pause() -> void:
	if _is_game_over_blocking():
		return
	get_tree().paused = true
	visible = true
	_set_main_menu_visible(true)
	_resume_button.grab_focus()

	pause_menu_sound.stream = PAUSE_ENTER
	pause_menu_sound.play()

func close_pause() -> void:
	_set_main_menu_visible(true)
	visible = false
	get_tree().paused = false

	pause_menu_sound.stream = PAUSE_OUT
	pause_menu_sound.play()

func _close_options() -> void:
	_set_main_menu_visible(true)
	_options_button.grab_focus()

	pause_menu_sound.stream = OPTION_EXIT
	pause_menu_sound.play()

func _on_resume_pressed() -> void:
	close_pause()


func _on_options_pressed() -> void:
	_set_main_menu_visible(false)
	_back_button.grab_focus()

	pause_menu_sound.stream = OPTION_ENTER
	pause_menu_sound.play()

func _on_back_pressed() -> void:
	_close_options()


func _on_main_menu_pressed() -> void:
	_go_to_scene(MENU_PATH)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_music_changed(value: float) -> void:
	_settings.set_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	_settings.set_sfx_volume(value)


func _on_fullscreen_toggled(pressed: bool) -> void:
	_settings.set_fullscreen(pressed)


func _go_to_scene(path: String) -> void:
	var tree := get_tree()
	tree.paused = false
	visible = false
	tree.change_scene_to_file(path)

func mouse_focus():
	if nav_sound_file.size() > 0:
		pause_menu_sound.stream = nav_sound_file.pick_random()
		pause_menu_sound.play()


func _on_resume_button_mouse_entered() -> void:
	mouse_focus()


func _on_options_button_mouse_entered() -> void:
	mouse_focus()


func _on_main_menu_button_mouse_entered() -> void:
	mouse_focus()


func _on_exit_button_mouse_entered() -> void:
	mouse_focus()


func _on_back_button_mouse_entered() -> void:
	mouse_focus()
