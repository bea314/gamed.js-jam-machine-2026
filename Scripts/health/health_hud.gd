extends CanvasLayer

const RUKA_FULL_TEXTURE: Texture2D = preload("res://Recursos/UXUI/HP y escudo/ruka full.png")
const RUKA_HALF_TEXTURE: Texture2D = preload("res://Recursos/UXUI/HP y escudo/ruka half.png")
const RUKA_HURT_TEXTURE: Texture2D = preload("res://Recursos/UXUI/HP y escudo/ruka hurt.png")
const HP_TEXTURES = [
	preload("res://Recursos/UXUI/HP y escudo/HP 1-5.png"),
	preload("res://Recursos/UXUI/HP y escudo/HP 2-5.png"),
	preload("res://Recursos/UXUI/HP y escudo/HP 3-5.png"),
	preload("res://Recursos/UXUI/HP y escudo/HP 4-5.png"),
	preload("res://Recursos/UXUI/HP y escudo/HP 5-5.png"),
]

const DAMAGE_RED := Color(0.92, 0.18, 0.16, 1.0)

@onready var _ruka_portrait: TextureRect = $Root/RukaPortrait
@onready var _hp_state: TextureRect = $Root/HPGroup/HPState
@onready var _hp_track: Control = $Root/HPGroup
@onready var _shield_clip: Control = $Root/ShieldGroup/ShieldClip
@onready var _shield_fill: TextureRect = $Root/ShieldGroup/ShieldClip/ShieldFill
@onready var _shield_track: Control = $Root/ShieldGroup
@onready var _damage_label: Label = $Root/DamagePopup/DamageLabel

var _health: HealthComponent
var _damage_tween: Tween


func _ready() -> void:
	if not _ruka_portrait or not _hp_state or not _hp_track or not _shield_clip or not _shield_fill or not _shield_track or not _damage_label:
		push_error("HealthHUD: nodos de UI no encontrados. Revisa rutas en health_hud.gd vs health_bar.tscn.")
		return

	_damage_label.visible = false
	_damage_label.modulate = DAMAGE_RED
	_damage_label.scale = Vector2.ONE

	var player := get_parent()
	if player == null:
		return

	_health = player.get_node_or_null("HealthComponent") as HealthComponent
	if _health == null:
		push_error("HealthHUD: el padre no tiene HealthComponent; la barra no se actualizará.")
		return

	_health.health_changed.connect(_on_health_changed)
	_health.shield_changed.connect(_on_shield_changed)
	_health.damage_taken.connect(_on_damage_taken)
	_hp_track.resized.connect(_on_bar_track_resized)
	_shield_track.resized.connect(_on_shield_track_resized)

	call_deferred("_sync_from_health")


func _sync_from_health() -> void:
	if _health:
		_on_health_changed(_health.current_health, _health.max_health)
		_on_shield_changed(_health.current_shield, _health.max_shield)


func _on_bar_track_resized() -> void:
	if _health:
		_on_health_changed(_health.current_health, _health.max_health)


func _on_shield_track_resized() -> void:
	if _health:
		_on_shield_changed(_health.current_shield, _health.max_shield)


func _on_health_changed(current_health: int, max_health: int) -> void:
	if max_health <= 0:
		return

	var ratio: float = clampf(float(current_health) / float(max_health), 0.0, 1.0)
	_update_portrait(ratio)
	_update_hp_state(ratio)


func _on_shield_changed(current_shield: int, max_shield: int) -> void:
	if max_shield <= 0:
		_update_shield_fill(0.0)
		return
	var ratio: float = clampf(float(current_shield) / float(max_shield), 0.0, 1.0)
	_update_shield_fill(ratio)


func _on_damage_taken(_amount: int, _hit_from_global: Vector2 = Vector2.ZERO) -> void:
	if _damage_label == null:
		return
	_damage_label.text = "-%d" % _amount
	_damage_label.visible = true
	call_deferred("_play_damage_feedback")


func _play_damage_feedback() -> void:
	if _damage_label == null:
		return
	_damage_label.pivot_offset = _damage_label.size * 0.5
	_damage_label.modulate = Color.WHITE
	_damage_label.scale = Vector2(1.2, 1.2)

	if _damage_tween:
		_damage_tween.kill()
	_damage_tween = create_tween()
	_damage_tween.set_parallel(true)
	_damage_tween.tween_property(_damage_label, "modulate", DAMAGE_RED, 0.1)
	_damage_tween.tween_property(_damage_label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_damage_tween.set_parallel(false)
	_damage_tween.tween_interval(0.22)
	_damage_tween.tween_property(
		_damage_label,
		"modulate",
		Color(DAMAGE_RED.r, DAMAGE_RED.g, DAMAGE_RED.b, 0.0),
		0.42
	)
	_damage_tween.tween_callback(func() -> void:
		if _damage_label:
			_damage_label.visible = false
			_damage_label.scale = Vector2.ONE
			_damage_label.modulate = DAMAGE_RED
	)


func _update_portrait(health_ratio: float) -> void:
	if health_ratio >= 0.8:
		_ruka_portrait.texture = RUKA_FULL_TEXTURE
	elif health_ratio >= 0.3:
		_ruka_portrait.texture = RUKA_HALF_TEXTURE
	else:
		_ruka_portrait.texture = RUKA_HURT_TEXTURE


func _update_hp_state(health_ratio: float) -> void:
	if health_ratio <= 0.0:
		_hp_state.visible = false
		return

	var hp_index: int = ceili(health_ratio * HP_TEXTURES.size()) - 1
	hp_index = clampi(hp_index, 0, HP_TEXTURES.size() - 1)
	_hp_state.texture = HP_TEXTURES[hp_index]
	_hp_state.visible = true


func _update_shield_fill(shield_ratio: float) -> void:
	var full_size := _shield_track.size
	var visible_width: float = full_size.x * shield_ratio
	_shield_clip.size = Vector2(visible_width, full_size.y)
	_shield_fill.size = full_size
	_shield_clip.visible = visible_width > 0.0
