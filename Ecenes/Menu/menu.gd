extends Control

@onready var _settings: GameSettings = get_node("/root/SettingsManager") as GameSettings

@onready var _main_buttons: VBoxContainer = $CenterContainer/MainVBox/MainButtons
@onready var _options_panel: VBoxContainer = $CenterContainer/MainVBox/OptionsPanel
@onready var _new_game_button: Button = $CenterContainer/MainVBox/MainButtons/NewGameButton
@onready var _options_button: Button = $CenterContainer/MainVBox/MainButtons/OptionsButton
@onready var _credits_button: Button = $CenterContainer/MainVBox/MainButtons/CreditsButton
@onready var _exit_button: Button = $CenterContainer/MainVBox/MainButtons/ExitButton
@onready var _music_slider: HSlider = $CenterContainer/MainVBox/OptionsPanel/MusicRow/MusicSlider
@onready var _sfx_slider: HSlider = $CenterContainer/MainVBox/OptionsPanel/SFXRow/SFXSlider
@onready var _fullscreen_check: CheckButton = $CenterContainer/MainVBox/OptionsPanel/FullscreenCheck
@onready var _back_button: Button = $CenterContainer/MainVBox/OptionsPanel/BackButton


func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_credits_button.pressed.connect(_on_credits_pressed)
	_exit_button.pressed.connect(_on_exit_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	_music_slider.value = _settings.music_volume
	_sfx_slider.value = _settings.sfx_volume
	_fullscreen_check.button_pressed = _settings.fullscreen

	_options_panel.visible = false


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://Ecenes/Level_test.tscn")


func _on_options_pressed() -> void:
	_main_buttons.visible = false
	_options_panel.visible = true


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Ecenes/Menu/Credits.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	_options_panel.visible = false
	_main_buttons.visible = true


func _on_music_changed(value: float) -> void:
	_settings.set_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	_settings.set_sfx_volume(value)


func _on_fullscreen_toggled(pressed: bool) -> void:
	_settings.set_fullscreen(pressed)
