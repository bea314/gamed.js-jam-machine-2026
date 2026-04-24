extends Node

signal achievement_unlocked(achievement_id: String)
signal progress_changed()

var _unlocked: Dictionary = {}
var _progress: Dictionary = {}


func _ready() -> void:
	_load_state()
	if GameEvents != null and GameEvents.has_signal("event_emitted"):
		GameEvents.event_emitted.connect(_on_game_event)


func _on_game_event(event_name: StringName, _payload: Dictionary) -> void:
	if event_name == AchievementConstants.EVENT_RUN_STARTED:
		_process_run_started()
	elif event_name == &"enemy_killed":
		_process_enemy_killed()


func _process_run_started() -> void:
	var id := AchievementConstants.ID_BIENVENIDA_RUKA
	if _is_unlocked(id):
		return
	_set_progress(id, 1)
	_unlock(id)
	_save_state()


func _process_enemy_killed() -> void:
	var id := AchievementConstants.ID_PRIMERA_CHISPA
	if _is_unlocked(id):
		return
	_set_progress(id, 1)
	_unlock(id)
	_save_state()


func _unlock(achievement_id: String) -> void:
	_unlocked[achievement_id] = true
	achievement_unlocked.emit(achievement_id)
	progress_changed.emit()


func _set_progress(achievement_id: String, value: int) -> void:
	_progress[achievement_id] = maxi(value, 0)
	progress_changed.emit()


func _is_unlocked(achievement_id: String) -> bool:
	return bool(_unlocked.get(achievement_id, false))


func is_unlocked(achievement_id: String) -> bool:
	return _is_unlocked(achievement_id)


func get_progress(achievement_id: String) -> int:
	return int(_progress.get(achievement_id, 0))


func get_total_active_count() -> int:
	return AchievementConstants.ACTIVE_FOR_TEST.size()


func get_unlocked_active_count() -> int:
	var count := 0
	for achievement_id in AchievementConstants.ACTIVE_FOR_TEST:
		if _is_unlocked(String(achievement_id)):
			count += 1
	return count


func get_active_achievements() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for achievement_id in AchievementConstants.ACTIVE_FOR_TEST:
		var id := String(achievement_id)
		var definition: Dictionary = AchievementConstants.DEFINITIONS.get(id, {})
		rows.append({
			"id": id,
			"title": String(definition.get("title", id)),
			"description": String(definition.get("description", "")),
			"threshold": int(definition.get("threshold", 1)),
			"progress": get_progress(id),
			"unlocked": _is_unlocked(id),
		})
	return rows


func get_backlog_achievement_ids() -> Array[String]:
	var ids: Array[String] = []
	for item in AchievementConstants.TODO_BACKLOG:
		ids.append(String(item))
	return ids


func _save_state() -> void:
	var file := FileAccess.open(AchievementConstants.SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save achievements state.")
		return
	var data := {
		"version": AchievementConstants.SAVE_VERSION,
		"unlocked": _unlocked,
		"progress": _progress,
	}
	file.store_string(JSON.stringify(data, "\t"))


func _load_state() -> void:
	_unlocked.clear()
	_progress.clear()
	if not FileAccess.file_exists(AchievementConstants.SAVE_PATH):
		return
	var file := FileAccess.open(AchievementConstants.SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not read achievements state.")
		return
	var raw := file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	var unlocked_data: Variant = data.get("unlocked", {})
	if typeof(unlocked_data) == TYPE_DICTIONARY:
		for key in unlocked_data:
			_unlocked[String(key)] = bool(unlocked_data[key])
	var progress_data: Variant = data.get("progress", {})
	if typeof(progress_data) == TYPE_DICTIONARY:
		for key in progress_data:
			_progress[String(key)] = int(progress_data[key])
