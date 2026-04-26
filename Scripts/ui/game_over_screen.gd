extends CanvasLayer

const LEVEL_PATH := "res://Ecenes/level.tscn"
const MENU_PATH := "res://Ecenes/Menu/Menu.tscn"

@export var fade_in_duration_sec: float = 1.6
## Tras el fundido, deja el arte a full opacidad un momento antes de dar foco a los botones.
@export var image_hold_sec: float = 0.5

const _SFX_SCREEN_OPEN := preload("res://Recursos/Sound/SFXS/UX_GAME_OVER/GAME_OVER_SCREEN_OPEN.ogg")
const _SFX_SELECT_RETRY := preload("res://Recursos/Sound/SFXS/UX_GAME_OVER/GAME_OVER_SELECT_RETRY.ogg")
const _SFX_SELECT_MAIN_MENU := preload("res://Recursos/Sound/SFXS/UX_GAME_OVER/GAME_OVER_SELECT_MAIN_MENU.ogg")

const _HOVER_SFX: Array[AudioStream] = [
	preload("res://Recursos/Sound/SFXS/UX_GAME_OVER/GAME_OVER_UI_HOVER_01.ogg"),
	preload("res://Recursos/Sound/SFXS/UX_GAME_OVER/GAME_OVER_UI_HOVER_02.ogg"),
	preload("res://Recursos/Sound/SFXS/UX_GAME_OVER/GAME_OVER_UI_HOVER_03.ogg"),
]

@onready var _root: Control = $Root
@onready var _retry_button: Button = $Root/CenterContainer/MainVBox/RetryButton
@onready var _menu_button: Button = $Root/CenterContainer/MainVBox/MainMenuButton
@onready var _audio_music: AudioStreamPlayer = $Audio_Music
@onready var _audio_sfxs: AudioStreamPlayer = $Audio_Sfxs


func _enter_tree() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	visible = false
	_retry_button.pressed.connect(_on_retry_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_retry_button.mouse_entered.connect(_on_game_over_hover)
	_menu_button.mouse_entered.connect(_on_game_over_hover)


func show_game_over() -> void:
	if visible:
		return
	get_tree().paused = true
	_root.modulate = Color(1, 1, 1, 0)
	visible = true
	_play_sfx(_SFX_SCREEN_OPEN)
	_audio_music.play()
	var tw: Tween = create_tween()
	tw.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(_root, "modulate", Color(1, 1, 1, 1), maxf(0.05, fade_in_duration_sec))
	await tw.finished
	if image_hold_sec > 0.0 and is_instance_valid(self) and is_inside_tree():
		var hold := create_tween()
		hold.tween_interval(image_hold_sec)
		await hold.finished
	if is_instance_valid(_retry_button) and is_inside_tree():
		_retry_button.grab_focus()


func _play_sfx(stream: AudioStream) -> void:
	_audio_sfxs.stream = stream
	_audio_sfxs.play()


func _on_game_over_hover() -> void:
	_play_sfx(_HOVER_SFX.pick_random())


func _go_to_scene(path: String) -> void:
	var tree := get_tree()
	tree.paused = false
	# Si el overlay está en `root`, `change_scene` no lo elimina; hay que quitarlo a mano.
	if is_inside_tree() and get_parent() == tree.root:
		visible = false
		tree.root.remove_child(self)
		queue_free()
	tree.change_scene_to_file(path)


func _on_retry_pressed() -> void:
	_play_sfx(_SFX_SELECT_RETRY)
	_go_to_scene(LEVEL_PATH)


func _on_menu_pressed() -> void:
	_play_sfx(_SFX_SELECT_MAIN_MENU)
	_go_to_scene(MENU_PATH)
