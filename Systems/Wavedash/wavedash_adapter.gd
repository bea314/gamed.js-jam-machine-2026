extends Node

var _sdk: Node = null
var _queued_unlock_ids: Array[String] = []


func _ready() -> void:
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


func _is_sdk_available() -> bool:
	return _sdk != null and is_instance_valid(_sdk)
