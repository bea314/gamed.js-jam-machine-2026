extends Node
## Coordinador entre escenas pesadas y `loading_screen.tscn`.
const LOADING_SCENE: PackedScene = preload("res://Ecenes/UI/loading_screen.tscn")
const MENU_SCENE_PATH := "res://Ecenes/Menu/Menu.tscn"

var next_scene_path: String = ""
var _transition_locked: bool = false
var _last_requested_path: String = ""


func goto_scene(path: String) -> void:
	if _transition_locked:
		push_warning("LoadingTransition: transición ya en curso; se ignora goto_scene(%s)." % path)
		return
	if path.is_empty():
		push_error("LoadingTransition: path vacío.")
		_fallback_change_scene(MENU_SCENE_PATH)
		return
	_transition_locked = true
	next_scene_path = path
	_last_requested_path = path
	# Diferir el cambio a loading evita carreras con `load_threaded_request` / lectura de `next_scene_path`.
	call_deferred("_deferred_go_loading_screen")


func _deferred_go_loading_screen() -> void:
	if not is_inside_tree():
		return
	var target := next_scene_path
	var err: int = get_tree().change_scene_to_packed(LOADING_SCENE)
	if err != OK:
		push_warning(
			"LoadingTransition: loading_screen no entró (%s); intento destino directo: %s"
			% [error_string(err), target]
		)
		if not target.is_empty() and ResourceLoader.exists(target):
			err = get_tree().change_scene_to_file(target)
	if err != OK:
		push_error(
			"LoadingTransition: transición fallida (%s); vuelvo al menú."
			% error_string(err)
		)
		clear_pending()
		get_tree().change_scene_to_file(MENU_SCENE_PATH)


func _deferred_change_scene_to_file(path: String) -> void:
	if not is_inside_tree():
		return
	var err: int = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error(
			"LoadingTransition: change_scene_to_file(%s) err=%s; menú."
			% [path, error_string(err)]
		)
		get_tree().change_scene_to_file(MENU_SCENE_PATH)


func clear_pending() -> void:
	next_scene_path = ""
	_transition_locked = false


## Solo desbloquea la transición (p. ej. intro → nivel) sin borrar la última ruta solicitada.
func unlock_for_next_goto() -> void:
	_transition_locked = false


func get_pending_or_last_scene_path() -> String:
	if not next_scene_path.is_empty():
		return next_scene_path
	return _last_requested_path


func _fallback_change_scene(target_path: String) -> void:
	clear_pending()
	var safe_path := target_path if ResourceLoader.exists(target_path) else MENU_SCENE_PATH
	call_deferred("_deferred_change_scene_to_file", safe_path)
