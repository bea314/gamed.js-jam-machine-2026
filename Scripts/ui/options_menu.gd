extends CanvasLayer

## Panel compartido: música, SFX y pantalla completa. El fondo y marcos son solo nodos en la escena (asignar texturas en el editor).
signal closed

@onready var _settings: GameSettings = get_node("/root/SettingsManager") as GameSettings
@onready var _music_slider: HSlider = $Root/MainVBox/MusicRow/MusicSlider
@onready var _sfx_slider: HSlider = $Root/MainVBox/SFXRow/SFXSlider
@onready var _fullscreen_check: TextureCheckboxButton = $Root/FullscreenCheck
@onready var _back_button: BaseButton = $Root/BackButton/ClickArea
@onready var _close_pause_button: BaseButton = $Root/ClosePauseButton/ClickArea


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_back_button.pressed.connect(hide_panel)
	_close_pause_button.pressed.connect(hide_panel)

	_music_slider.value = _settings.music_volume
	_sfx_slider.value = _settings.sfx_volume
	_fullscreen_check.set_pressed_no_signal(_settings.fullscreen)


func show_panel() -> void:
	visible = true
	_back_button.grab_focus()


func hide_panel() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func force_hide() -> void:
	visible = false


func _on_music_changed(value: float) -> void:
	_settings.set_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	_settings.set_sfx_volume(value)


func _on_fullscreen_toggled(pressed: bool) -> void:
	_settings.set_fullscreen(pressed)
