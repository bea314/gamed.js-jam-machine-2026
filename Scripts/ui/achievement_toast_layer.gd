extends CanvasLayer

@export var visible_seconds: float = 2.2

@onready var _panel: PanelContainer = $ToastPanel
@onready var _title_label: Label = $ToastPanel/Margin/VBox/Title
@onready var _message_label: Label = $ToastPanel/Margin/VBox/Message
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
	_title_label.text = "Logro detectado"
	_message_label.text = title
	_panel.visible = true
	_hide_timer.start()


func _on_hide_timeout() -> void:
	_panel.visible = false
