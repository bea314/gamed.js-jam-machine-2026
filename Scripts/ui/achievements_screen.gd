extends Control

const MENU_SCENE_PATH := "res://Ecenes/Menu/Menu.tscn"

@onready var _summary_label: Label = $Margin/MainVBox/SummaryLabel
@onready var _active_list: ItemList = $Margin/MainVBox/Columns/ActiveColumn/ActiveList
@onready var _backlog_list: ItemList = $Margin/MainVBox/Columns/BacklogColumn/BacklogList
@onready var _back_button: Button = $Margin/MainVBox/BackButton


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	if AchievementService != null and AchievementService.has_signal("progress_changed"):
		AchievementService.progress_changed.connect(_refresh_view)
	_refresh_view()


func _refresh_view() -> void:
	_refresh_summary()
	_refresh_active()
	_refresh_backlog()


func _refresh_summary() -> void:
	var unlocked := AchievementService.get_unlocked_active_count()
	var total := AchievementService.get_total_active_count()
	_summary_label.text = "Activos desbloqueados: %d/%d" % [unlocked, total]


func _refresh_active() -> void:
	_active_list.clear()
	var achievements := AchievementService.get_active_achievements()
	for row in achievements:
		var title := String(row.get("title", ""))
		var progress := int(row.get("progress", 0))
		var threshold := int(row.get("threshold", 1))
		var unlocked := bool(row.get("unlocked", false))
		var state := "DESBLOQUEADO" if unlocked else "FALTANTE"
		var line := "%s - %s (%d/%d)" % [title, state, progress, threshold]
		_active_list.add_item(line)


func _refresh_backlog() -> void:
	_backlog_list.clear()
	var backlog := AchievementService.get_backlog_achievement_ids()
	for achievement_id in backlog:
		_backlog_list.add_item("%s (TODO)" % achievement_id)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MENU_SCENE_PATH)
