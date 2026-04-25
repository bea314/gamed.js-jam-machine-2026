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

# REFERECNIAS NODOS FADE ON/OUT
@onready var pantalla_negra: ColorRect = $Pantalla_Negra
@onready var anim: AnimationPlayer = $Pantalla_Negra/Anim


var interact_sounds : Array = [
	preload("uid://bg3t7v510agae"),
	preload("uid://csxs8xt3nbl6l"),
	preload("uid://ciyg5mfmsbm46"),
	preload("uid://dyqakihhko1sl"),
	preload("uid://cpkbnkjid8ffk"),
	preload("uid://ce67uaa41r2lw")
]

const MENU_ENTER = preload("uid://bevpc4b70fpvx")
const MENU_EXIT = preload("uid://t0pwodsktgbw")


@onready var audio_sfxs: AudioStreamPlayer = $Audio_Sfxs
@onready var audio_music: AudioStreamPlayer = $Audio_Music

const MAIN_MENU_INTRO = preload("uid://31lw0x3j1gsn")
const MAIN_MENU = preload("uid://bi2pf0sx5p0yq")

func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_new_game_button.mouse_entered.connect(_on_mouse_entered_new_game)
	_options_button.pressed.connect(_on_options_pressed)
	_options_button.mouse_entered.connect(_on_mouse_entered_options)
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

# NEW GAME BUTTON ==============
func _on_new_game_pressed() -> void:
	anim.play("Fade_enter")
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Ecenes/level.tscn")

func _on_mouse_entered_new_game():
	audio_sfxs.stream = interact_sounds.pick_random()
	audio_sfxs.play()
# =============

# OPTIONS BUTTON ==============
func _on_options_pressed() -> void:
	_main_buttons.visible = false
	_options_panel.visible = true
	audio_sfxs.stream = MENU_ENTER
	audio_sfxs.play()

func _on_mouse_entered_options():
	audio_sfxs.stream = interact_sounds.pick_random()
	audio_sfxs.play()
# =============
# CREDITS BUTTON==============
func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://Ecenes/Menu/Credits.tscn")

# =============
# Exit BUTTON ==============
func _on_exit_pressed() -> void:
	get_tree().quit()
# =============

func _on_back_pressed() -> void:
	_options_panel.visible = false
	_main_buttons.visible = true
	audio_sfxs.stream = MENU_EXIT
	audio_sfxs.play()

func _on_music_changed(value: float) -> void:
	_settings.set_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	_settings.set_sfx_volume(value)


func _on_fullscreen_toggled(pressed: bool) -> void:
	_settings.set_fullscreen(pressed)


func _on_audio_music_finished() -> void:
	#Asignamos el stream
	audio_music.stream = MAIN_MENU
	
	#Reproducimos de nuevo
	audio_music.play()
	
	audio_music.stream.loop = true
	
	# Desconectamos la señal para que no vuelva a entrar aquí
	if audio_music.finished.is_connected(_on_audio_music_finished):
		audio_music.finished.disconnect(_on_audio_music_finished)
		
