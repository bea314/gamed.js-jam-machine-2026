extends Control

@onready var _main_buttons: VBoxContainer = $CenterContainer/MainVBox/MainButtons
@onready var _options_panel: VBoxContainer = $CenterContainer/MainVBox/OptionsPanel
@onready var _new_game_button: Button = $CenterContainer/MainVBox/MainButtons/NewGameButton
@onready var _options_button: Button = $CenterContainer/MainVBox/MainButtons/OptionsButton
@onready var _music_slider: HSlider = $CenterContainer/MainVBox/OptionsPanel/MusicRow/MusicSlider
@onready var _sfx_slider: HSlider = $CenterContainer/MainVBox/OptionsPanel/SFXRow/SFXSlider
@onready var _fullscreen_check: CheckButton = $CenterContainer/MainVBox/OptionsPanel/FullscreenCheck
@onready var _back_button: Button = $CenterContainer/MainVBox/OptionsPanel/BackButton


func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_options_button.pressed.connect(_on_options_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	_music_slider.value = SettingsManager.music_volume
	_sfx_slider.value = SettingsManager.sfx_volume
	_fullscreen_check.button_pressed = SettingsManager.fullscreen

	_options_panel.visible = false


func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://Ecenes/Level_test.tscn")


func _on_options_pressed() -> void:
	_main_buttons.visible = false
	_options_panel.visible = true


func _on_back_pressed() -> void:
	_options_panel.visible = false
	_main_buttons.visible = true


func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)


func _on_fullscreen_toggled(pressed: bool) -> void:
	SettingsManager.set_fullscreen(pressed)
