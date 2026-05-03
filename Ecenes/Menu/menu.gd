extends Control

@onready var _settings: GameSettings = get_node("/root/SettingsManager") as GameSettings

@onready var _main_buttons: Control = $MainButtonsFree
@onready var _options_panel: VBoxContainer = $CenterContainer/MainVBox/OptionsPanel
@onready var _new_game_button: BaseButton = $MainButtonsFree/NewGameButton/ClickArea
@onready var _options_button: BaseButton = $MainButtonsFree/OptionsButton/ClickArea
@onready var _logros_button: BaseButton = $MainButtonsFree/LogrosButton/ClickArea
@onready var _credits_button: BaseButton = $MainButtonsFree/CreditsButton/ClickArea
@onready var _exit_button: BaseButton = $MainButtonsFree/ExitButton/ClickArea
@onready var _music_slider: HSlider = $CenterContainer/MainVBox/OptionsPanel/MusicRow/MusicSlider
@onready var _sfx_slider: HSlider = $CenterContainer/MainVBox/OptionsPanel/SFXRow/SFXSlider
@onready var _fullscreen_check: CheckButton = $CenterContainer/MainVBox/OptionsPanel/FullscreenCheck
@onready var _back_button: Button = $CenterContainer/MainVBox/OptionsPanel/BackButton

const NAV_SOUNDS: Array[AudioStream] = [
	preload("res://Recursos/Sound/Menus/NAV_01.ogg"),
	preload("res://Recursos/Sound/Menus/NAV_02.ogg"),
	preload("res://Recursos/Sound/Menus/NAV_03.ogg"),
	preload("res://Recursos/Sound/Menus/NAV_04.ogg"),
	preload("res://Recursos/Sound/Menus/NAV_05.ogg"),
	preload("res://Recursos/Sound/Menus/NAV_06.ogg"),
]

const MENU_ENTER = preload("uid://bevpc4b70fpvx")
const MENU_EXIT = preload("uid://t0pwodsktgbw")
const PRESS_START = preload("uid://cmm3opf6lauau")


@onready var audio_sfxs: AudioStreamPlayer = $Audio_Sfxs
@onready var audio_music: AudioStreamPlayer = $Audio_Music

const MAIN_MENU_INTRO = preload("uid://31lw0x3j1gsn")
const MAIN_MENU = preload("uid://bi2pf0sx5p0yq")
const INTRO_SCENE_PATH := "res://Ecenes/Intro/Intro.tscn"
const VICTORY_SCENE_PATH := "res://Ecenes/Menu/Victory.tscn"
const RUN_LEVEL_SCENES := {
	1: "res://Ecenes/level.tscn",
	2: "res://Ecenes/level_2.tscn",
	3: "res://Ecenes/level_3.tscn",
}


func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_new_game_button.mouse_entered.connect(mouse_focus)
	_options_button.pressed.connect(_on_options_pressed)
	_options_button.mouse_entered.connect(mouse_focus)
	_logros_button.pressed.connect(_on_logros_pressed)
	_logros_button.mouse_entered.connect(mouse_focus)
	_credits_button.pressed.connect(_on_credits_pressed)
	_credits_button.mouse_entered.connect(mouse_focus)
	_exit_button.pressed.connect(_on_exit_pressed)
	_exit_button.mouse_entered.connect(mouse_focus)
	_back_button.pressed.connect(_on_back_pressed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)

	_music_slider.value = _settings.music_volume
	_sfx_slider.value = _settings.sfx_volume
	_fullscreen_check.button_pressed = _settings.fullscreen

	_options_panel.visible = false

# NEW GAME BUTTON ==============
func _on_new_game_pressed() -> void:
	start_intro_if_any()


func start_intro_if_any() -> void:
	# AQUI PUEDES COLOCAR EL INTRO Y UN EJEMPLO DE COMO INSERTAR UNA EXCENA
	# Ejemplo: si existe intro, cargas intro; si no existe, arrancas de una en nivel 1.
	if ResourceLoader.exists(INTRO_SCENE_PATH):
		get_tree().change_scene_to_file(INTRO_SCENE_PATH)
		return
	start_run_level(1)


func start_run_level(level_index: int) -> void:
	$Start.stream = PRESS_START
	$Start.play()
	$Pantalla_Fade/AnimationPlayer.play("fade")
	await get_tree().create_timer(3.0).timeout

	

	get_tree().change_scene_to_file("res://Ecenes/UI/intro.tscn")



func on_boss_defeated_advance_level(current_level: int) -> void:
	var next_level := current_level + 1
	if next_level <= LevelGeneration.MAX_RUN_LEVEL:
		start_run_level(next_level)
		return
	show_victory_message()


func show_victory_message() -> void:
	if ResourceLoader.exists(VICTORY_SCENE_PATH):
		get_tree().change_scene_to_file(VICTORY_SCENE_PATH)
		return
	push_warning("Placeholder: mostrar mensaje de victoria final del roguelike.")

# =============

# OPTIONS BUTTON ==============
func _on_options_pressed() -> void:
	_main_buttons.visible = false
	_options_panel.visible = true
	$Start.stream = MENU_ENTER
	$Start.play()

# LOGROS / ACHIEVEMENTS ==============
func _on_logros_pressed() -> void:
	push_warning("Logros: sin escena asignada; añade la ruta en menu.gd → _on_logros_pressed().")

# CREDITS ==============
func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Ecenes/Menu/Credits.tscn")

# =============
# Exit BUTTON ==============
func _on_exit_pressed() -> void:
	get_tree().quit()
	

func _on_mouse_entered() -> void:
	mouse_focus()
# =============

func _on_back_pressed() -> void:
	_options_panel.visible = false
	_main_buttons.visible = true
	$Start.stream = MENU_EXIT
	$Start.play()

func _on_music_changed(value: float) -> void:
	_settings.set_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	_settings.set_sfx_volume(value)


func _on_fullscreen_toggled(pressed: bool) -> void:
	_settings.set_fullscreen(pressed)

func mouse_focus() -> void:
	audio_sfxs.stream = NAV_SOUNDS.pick_random()
	audio_sfxs.play()
