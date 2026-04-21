extends CanvasLayer

const LEVEL_PATH := "res://Ecenes/level.tscn"
const MENU_PATH := "res://Ecenes/Menu/Menu.tscn"

@onready var _root: Control = $Root
@onready var _retry_button: Button = $Root/CenterContainer/MainVBox/RetryButton
@onready var _menu_button: Button = $Root/CenterContainer/MainVBox/MainMenuButton
@onready var _audio_music: AudioStreamPlayer = $Audio_Music


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_retry_button.pressed.connect(_on_retry_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)


func show_game_over() -> void:
	if visible:
		return
	get_tree().paused = true
	visible = true
	_audio_music.play()
	_retry_button.grab_focus()


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
	_go_to_scene(LEVEL_PATH)


func _on_menu_pressed() -> void:
	_go_to_scene(MENU_PATH)
