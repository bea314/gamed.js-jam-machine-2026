extends CanvasLayer

const MENU_PATH := "res://Ecenes/Menu/Menu.tscn"

@onready var _settings: GameSettings = get_node("/root/SettingsManager") as GameSettings
@onready var _main_buttons: Control = $Root/MainButtonsFree
@onready var _options_menu: CanvasLayer = $OptionsMenu
@onready var _resume_button: BaseButton = $Root/MainButtonsFree/ResumeButton/ClickArea
@onready var _options_button: BaseButton = $Root/MainButtonsFree/OptionsButton/ClickArea
@onready var _main_menu_button: BaseButton = $Root/MainButtonsFree/MainMenuButton/ClickArea
@onready var _exit_button: BaseButton = $Root/MainButtonsFree/ExitButton/ClickArea
@onready var _close_pause_button: BaseButton = $Root/MainButtonsFree/ClosePauseButton/ClickArea

@onready var pause_menu_sound: AudioStreamPlayer = $Pause_Menu
const PAUSE_ENTER = preload("uid://cqw2v5rk8txgg")
const PAUSE_OUT = preload("uid://du3t7dpj11dty")

const OPTION_ENTER = preload("uid://dy2u244hlpdq7")
const OPTION_EXIT = preload("uid://3u2gkut4ygea")

@export_group("Nav sounds")
@export var nav_sound_file: Array[AudioStream] = []

var _last_nav_control: Control


func _ready() -> void:
	visible = false

	_resume_button.pressed.connect(_on_resume_pressed)
	_close_pause_button.pressed.connect(_on_resume_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)
	_options_menu.closed.connect(_on_options_menu_closed)
	for c: Control in [
		_resume_button,
		_close_pause_button,
		_options_button,
		_main_menu_button,
		_exit_button,
	]:
		c.focus_entered.connect(_on_pause_control_focus_entered.bind(c))
		c.mouse_entered.connect(_on_pause_control_mouse_entered.bind(c))


func _set_main_menu_visible(show_main: bool) -> void:
	_main_buttons.visible = show_main
	if show_main:
		_options_menu.force_hide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game"):
		return
	# Sin esto, la repetición automática de tecla (hold / echo) alterna abrir↔cerrar cada frame.
	if event is InputEventKey and event.echo:
		return
	if _is_game_over_blocking():
		return
	if _options_menu.visible:
		_options_menu.hide_panel()
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
	_last_nav_control = null
	_resume_button.grab_focus()


func close_pause() -> void:
	_options_menu.force_hide()
	_main_buttons.visible = true
	visible = false
	get_tree().paused = false
	_last_nav_control = null

	pause_menu_sound.stream = PAUSE_OUT
	pause_menu_sound.play()


func _on_options_menu_closed() -> void:
	_main_buttons.visible = true
	_options_button.grab_focus()

	pause_menu_sound.stream = OPTION_EXIT
	pause_menu_sound.play()


func _on_resume_pressed() -> void:
	close_pause()


func _on_options_pressed() -> void:
	_main_buttons.visible = false
	_options_menu.show_panel()

	pause_menu_sound.stream = OPTION_ENTER
	pause_menu_sound.play()


func _on_main_menu_pressed() -> void:
	_go_to_scene(MENU_PATH)


func _on_exit_pressed() -> void:
	pause_menu_sound.stream = PAUSE_OUT
	pause_menu_sound.play()
	get_tree().quit()


func _go_to_scene(path: String) -> void:
	var tree := get_tree()
	tree.paused = false
	visible = false
	tree.change_scene_to_file(path)


func _on_pause_control_focus_entered(which: Control) -> void:
	if not visible:
		return
	if (
		_last_nav_control != null
		and _last_nav_control != which
		and nav_sound_file.size() > 0
	):
		pause_menu_sound.stream = nav_sound_file.pick_random()
		pause_menu_sound.play()
	else:
		pause_menu_sound.stream = PAUSE_ENTER
		pause_menu_sound.play()
	_last_nav_control = which


func _on_pause_control_mouse_entered(which: Control) -> void:
	if not visible:
		return
	pause_menu_sound.stream = PAUSE_ENTER
	pause_menu_sound.play()
	_last_nav_control = which
