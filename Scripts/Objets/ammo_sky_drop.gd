@tool
extends Node2D

signal ammo_picked_up(kind: StringName, amount: int)

const _TEX_BULLETS := preload("res://Recursos/Textures/Ruka/Balas/bullets.png")
const _TEX_BULLETS2 := preload("res://Recursos/Textures/Ruka/Balas/bullets2.png")
const _TEX_SHOTGUN_SKY := preload("res://Recursos/Textures/Balas_SHOTGUN_PlaceHolder.png")
const _VISUAL_REVOLVER := preload("res://Ecenes/Objets/AmmoSkyDrop/bullet_pickup_visual_revolver.tscn")
const _VISUAL_SHOTGUN := preload("res://Ecenes/Objets/AmmoSkyDrop/bullet_pickup_visual_shotgun.tscn")
const _VISUAL_MACHINEGUN := preload("res://Ecenes/Objets/AmmoSkyDrop/bullet_pickup_visual_machinegun.tscn")

enum DropState {
	FALLING,
	LANDED,
	PICKED,
}

@export var ammo_kind: StringName = WeaponManager.KIND_REVOLVER
@export var pickup_amount_override: int = 0
@export_range(0.0, 4.0, 0.05) var pickup_magazine_fraction: float = 1.0
@export var pickup_min_amount: int = 3
@export var auto_despawn_time: float = 0.0
@export_range(0.0, 400.0, 1.0) var fall_height: float = 170.0
@export_range(0.05, 2.0, 0.01) var fall_duration: float = 0.45
@export_range(0.0, 64.0, 1.0) var bounce_px: float = 8.0
@export_range(0.02, 0.6, 0.01) var bounce_duration: float = 0.12

@onready var _visual_anchor: Node2D = $VisualAnchor
@onready var _shadow: Sprite2D = $Shadow
@onready var _pickup_area: Area2D = $PickupArea

var _state: DropState = DropState.FALLING
var _consumed: bool = false
var _landing_position: Vector2
var _landing_position_set: bool = false


func setup_landing_position(target_local_pos: Vector2) -> void:
	_landing_position = target_local_pos
	_landing_position_set = true


func set_ammo_kind(kind: StringName) -> void:
	ammo_kind = kind
	if is_inside_tree():
		_refresh_visual_scene()


func _ready() -> void:
	_ensure_shadow_texture()
	_refresh_visual_scene()
	_setup_pickup_collision()
	if Engine.is_editor_hint():
		return
	if auto_despawn_time > 0.0:
		get_tree().create_timer(auto_despawn_time).timeout.connect(_on_auto_despawn, CONNECT_ONE_SHOT)
	if not _landing_position_set:
		_landing_position = position
	_landing_position_set = true
	_start_fall_animation()


func _ensure_shadow_texture() -> void:
	if _shadow == null or _shadow.texture != null:
		return
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	_shadow.texture = ImageTexture.create_from_image(img)


func _setup_pickup_collision() -> void:
	if _pickup_area == null:
		return
	_pickup_area.monitoring = true
	_pickup_area.monitorable = true
	# Player.tscn usa collision_layer = 2; aseguramos detección por encima.
	_pickup_area.collision_mask = 2


func _refresh_visual_scene() -> void:
	if _visual_anchor == null:
		return
	for child in _visual_anchor.get_children():
		child.queue_free()
	var scene: PackedScene
	var randomize_bullet_texture := false
	match ammo_kind:
		WeaponManager.KIND_SHOTGUN:
			scene = _VISUAL_SHOTGUN
		WeaponManager.KIND_MACHINEGUN:
			scene = _VISUAL_MACHINEGUN
		_:
			scene = _VISUAL_REVOLVER
			randomize_bullet_texture = true
	if scene == null:
		return
	var inst := scene.instantiate() as Node2D
	if inst == null:
		return
	_visual_anchor.add_child(inst)
	if ammo_kind == WeaponManager.KIND_SHOTGUN:
		var sh_spr := inst.get_node_or_null("Sprite2D") as Sprite2D
		if sh_spr != null:
			sh_spr.texture = _TEX_SHOTGUN_SKY
	elif randomize_bullet_texture:
		var def_spr := inst.get_node_or_null("Sprite2D") as Sprite2D
		if def_spr != null:
			if Engine.is_editor_hint():
				def_spr.texture = _TEX_BULLETS
			else:
				def_spr.texture = _TEX_BULLETS2 if randf() < 0.5 else _TEX_BULLETS
	_apply_pickup_shape_from_visual(inst)


func _apply_pickup_shape_from_visual(visual: Node) -> void:
	if _pickup_area == null or visual == null or not visual.is_inside_tree():
		return
	var tmpl: Area2D = visual.get_node_or_null("PickupTemplate") as Area2D
	if tmpl == null:
		return
	var src_cs: CollisionShape2D = tmpl.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if src_cs == null or src_cs.shape == null:
		return
	var target_cs: CollisionShape2D = _pickup_area.get_node("CollisionShape2D") as CollisionShape2D
	if target_cs == null:
		return
	target_cs.shape = src_cs.shape.duplicate()
	target_cs.global_transform = src_cs.global_transform
	tmpl.queue_free()


func _start_fall_animation() -> void:
	_state = DropState.FALLING
	position = _landing_position + Vector2(0.0, -fall_height)
	if _shadow != null:
		_shadow.modulate.a = 0.25
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", _landing_position, fall_duration)
	tween.finished.connect(_on_primary_fall_finished, CONNECT_ONE_SHOT)


func _on_primary_fall_finished() -> void:
	if _consumed:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	var up_y := _landing_position.y - bounce_px
	tween.tween_property(self, "position:y", up_y, bounce_duration * 0.45)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", _landing_position.y, bounce_duration * 0.55)
	tween.finished.connect(_on_landed, CONNECT_ONE_SHOT)


func _on_landed() -> void:
	if _consumed:
		return
	_state = DropState.LANDED
	if _shadow != null:
		_shadow.modulate.a = 0.45
	# Si el jugador ya estaba encima durante la caída, forzamos intento de pickup.
	if _pickup_area != null:
		for body in _pickup_area.get_overlapping_bodies():
			var node := body as Node2D
			if node == null:
				continue
			_on_pickup_area_body_entered(node)
			if _consumed:
				return


func _on_pickup_area_body_entered(body: Node2D) -> void:
	if _consumed or _state != DropState.LANDED:
		return
	if not (body is CharacterBody2D):
		return
	if not (body.is_in_group("player") or body.is_in_group("Player")):
		return
	_try_pickup(body)


func _try_pickup(player: Node2D) -> void:
	var manager := player.get_node_or_null("WeaponPivot/WeaponManager") as WeaponManager
	if manager == null:
		return
	var amount := _resolve_amount(manager)
	if amount <= 0:
		return
	var added := manager.add_ammo_for_kind(ammo_kind, amount)
	if added <= 0:
		return
	_consumed = true
	_state = DropState.PICKED
	_notify_reserve_pickup(player, ammo_kind, added)
	ammo_picked_up.emit(ammo_kind, added)
	queue_free()


func _notify_reserve_pickup(player: Node2D, kind: StringName, amount: int) -> void:
	var hud := player.get_node_or_null("WeaponHud")
	if hud != null and hud.has_method("show_reserve_ammo_pickup"):
		hud.show_reserve_ammo_pickup(kind, amount)


func _resolve_amount(manager: WeaponManager) -> int:
	if pickup_amount_override > 0:
		return pickup_amount_override
	var mag: int = manager.get_magazine_size_for_kind(ammo_kind)
	if mag <= 0:
		return pickup_min_amount
	var by_fraction: int = int(round(float(mag) * maxf(pickup_magazine_fraction, 0.0)))
	return maxi(by_fraction, pickup_min_amount)


func _on_auto_despawn() -> void:
	if _consumed:
		return
	queue_free()
