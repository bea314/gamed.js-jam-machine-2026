extends Node

var _sdk: Node = null
var _queued_unlock_ids: Array[String] = []
var _public_game_id := ""
var _public_env := "sandbox"
var _public_client_key := ""

const LOCAL_CONFIG_PATH := "res://Config/wavedash.local.cfg"

func _ready() -> void:
	_load_runtime_config()
	_resolve_sdk()
	if AchievementService != null and AchievementService.has_signal("achievement_unlocked"):
		AchievementService.achievement_unlocked.connect(_on_achievement_unlocked)


func _process(_delta: float) -> void:
	if _queued_unlock_ids.is_empty():
		return
	if not _is_sdk_available():
		_resolve_sdk()
		return
	_flush_queue()


func _on_achievement_unlocked(achievement_id: String) -> void:
	var definition: Dictionary = AchievementConstants.DEFINITIONS.get(achievement_id, {})
	var wavedash_id := String(definition.get("wavedash_id", ""))
	if wavedash_id.is_empty():
		return
	_queue_unlock(wavedash_id)


func _queue_unlock(wavedash_id: String) -> void:
	if wavedash_id.is_empty():
		return
	if _queued_unlock_ids.has(wavedash_id):
		return
	_queued_unlock_ids.append(wavedash_id)


func _flush_queue() -> void:
	var pending := _queued_unlock_ids.duplicate()
	for wavedash_id in pending:
		if _send_unlock_to_wavedash(wavedash_id):
			_queued_unlock_ids.erase(wavedash_id)


func _send_unlock_to_wavedash(wavedash_id: String) -> bool:
	if not _is_sdk_available():
		return false
	if _sdk.has_method("set_achievement"):
		_sdk.set_achievement(wavedash_id, true)
		if _sdk.has_method("store_stats"):
			_sdk.store_stats()
		return true
	return false


func _resolve_sdk() -> void:
	_sdk = get_node_or_null("/root/WavedashSDK")
	if _is_sdk_available():
		_try_configure_sdk()


func _is_sdk_available() -> bool:
	return _sdk != null and is_instance_valid(_sdk)


func _load_runtime_config() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(LOCAL_CONFIG_PATH)
	if err == OK:
		_public_game_id = String(cfg.get_value("wavedash", "public_game_id", "")).strip_edges()
		_public_env = String(cfg.get_value("wavedash", "public_env", "sandbox")).strip_edges()
		_public_client_key = String(cfg.get_value("wavedash", "public_client_key", "")).strip_edges()
		return

	# Optional fallback for CI/build pipelines using ProjectSettings.
	_public_game_id = String(ProjectSettings.get_setting("wavedash/public_game_id", "")).strip_edges()
	_public_env = String(ProjectSettings.get_setting("wavedash/public_env", "sandbox")).strip_edges()
	_public_client_key = String(ProjectSettings.get_setting("wavedash/public_client_key", "")).strip_edges()


func _try_configure_sdk() -> void:
	if _public_env.is_empty():
		_public_env = "sandbox"
	if _sdk.has_method("configure"):
		_sdk.configure({
			"public_game_id": _public_game_id,
			"public_env": _public_env,
			"public_client_key": _public_client_key,
		})
