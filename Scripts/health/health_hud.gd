extends CanvasLayer

@onready var _bar_fill: ColorRect = $Root/RightStack/BarTrack/BarFill
@onready var _bar_track: Control = $Root/RightStack/BarTrack
@onready var _damage_label: Label = $Root/RightStack/DamageRow/DamageLabel
@onready var _health_label: Label = $Root/RightStack/HealthLabel

var _health: HealthComponent
var _damage_tween: Tween


func _ready() -> void:
	if not _bar_fill or not _bar_track or not _damage_label or not _health_label:
		push_error("HealthHUD: nodos de UI no encontrados. Revisa rutas en health_hud.gd vs health_bar.tscn.")
		return

	_damage_label.visible = false

	var player := get_parent()
	if player == null:
		return

	_health = player.get_node_or_null("HealthComponent") as HealthComponent
	if _health == null:
		push_error("HealthHUD: el padre no tiene HealthComponent; la barra no se actualizará.")
		return

	_health.health_changed.connect(_on_health_changed)
	_health.damage_taken.connect(_on_damage_taken)
	_bar_track.resized.connect(_on_bar_track_resized)

	call_deferred("_sync_from_health")


func _sync_from_health() -> void:
	if _health:
		_on_health_changed(_health.current_health, _health.max_health)


func _on_bar_track_resized() -> void:
	if _health:
		_on_health_changed(_health.current_health, _health.max_health)


func _on_health_changed(current_health: int, max_health: int) -> void:
	if max_health <= 0:
		return

	var ratio: float = clampf(float(current_health) / float(max_health), 0.0, 1.0)
	var w: float = _bar_track.size.x * ratio
	_bar_fill.size = Vector2(w, _bar_track.size.y)

	_health_label.text = "%d/%d" % [current_health, max_health]
	_position_damage_label(w)


func _on_damage_taken(_amount: int) -> void:
	if _damage_label == null:
		return
	_damage_label.text = "-%d" % _amount
	_damage_label.visible = true
	_damage_label.modulate.a = 1.0
	call_deferred("_refresh_damage_label_position")


func _refresh_damage_label_position() -> void:
	_position_damage_label(_bar_fill.size.x)

	if _damage_tween:
		_damage_tween.kill()
	_damage_tween = create_tween()
	_damage_tween.tween_interval(0.35)
	_damage_tween.tween_property(_damage_label, "modulate:a", 0.0, 0.45)
	_damage_tween.tween_callback(func() -> void:
		if _damage_label:
			_damage_label.visible = false
	)


func _position_damage_label(fill_width: float) -> void:
	var row: Control = _damage_label.get_parent() as Control
	if row == null:
		return
	_damage_label.position.x = clampf(
		fill_width - _damage_label.size.x * 0.5,
		0.0,
		maxf(0.0, row.size.x - _damage_label.size.x)
	)
	_damage_label.position.y = 0.0
