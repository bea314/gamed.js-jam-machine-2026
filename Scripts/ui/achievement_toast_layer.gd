extends CanvasLayer

@export var visible_seconds: float = 2.2

@onready var _panel: PanelContainer = $ToastPanel
@onready var _icon_rect: TextureRect = $ToastPanel/Margin/HBox/Icon
@onready var _title_label: Label = $ToastPanel/Margin/HBox/VBox/Title
@onready var _message_label: Label = $ToastPanel/Margin/HBox/VBox/Message
@onready var _hide_timer: Timer = $HideTimer


func _ready() -> void:
	_panel.visible = false
	_hide_timer.one_shot = true
	_hide_timer.wait_time = maxf(visible_seconds, 0.5)
	_hide_timer.timeout.connect(_on_hide_timeout)
	if AchievementService != null and AchievementService.has_signal("achievement_unlocked"):
		AchievementService.achievement_unlocked.connect(_on_achievement_unlocked)


func _on_achievement_unlocked(achievement_id: String) -> void:
	var definition: Dictionary = AchievementConstants.DEFINITIONS.get(achievement_id, {})
	var title := String(definition.get("title", achievement_id))
	var description := String(definition.get("description", ""))
	var icon_path := String(definition.get("icon_path", "")).strip_edges()
	_title_label.text = title
	_message_label.text = description
	_apply_achievement_icon(icon_path)
	_panel.visible = true
	_hide_timer.start()


func _on_hide_timeout() -> void:
	_panel.visible = false


func _apply_achievement_icon(icon_path: String) -> void:
	if icon_path.is_empty():
		_icon_rect.texture = null
		_icon_rect.modulate = Color(0.35, 0.35, 0.35, 1.0)
		return
	if not ResourceLoader.exists(icon_path):
		_icon_rect.texture = null
		_icon_rect.modulate = Color(0.35, 0.35, 0.35, 1.0)
		return
	_icon_rect.texture = load(icon_path) as Texture2D
	_icon_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
