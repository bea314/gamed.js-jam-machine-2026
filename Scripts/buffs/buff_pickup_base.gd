@tool
extends RigidBody2D
class_name BuffPickupBase

@export var buff_type: String = BuffType.DAMAGE
@export var duration_override: float = -1.0
@export var magnitude_override: float = -1.0
@export var rotate_speed: float = 1.2
@export var bob_amplitude: float = 3.0
@export var bob_speed: float = 2.8
## Si es <= 0, el pickup no desaparece solo (ej. limpieza al vencer al jefe final de la run)
@export var auto_despawn_time: float = 0.0
@export var push_force: float = 100.0
@export var push_on_enter: bool = false
@export var push_when_fully_overlapped: bool = true
@export_range(0.2, 1.0, 0.05) var full_overlap_ratio: float = 0.4
@export var follow_player_push_lerp: float = 2.6
@export var min_player_speed_to_push: float = 115.0
@export var push_speed_scale: float = 0.28
@export var heavy_linear_damp: float = 10.0
@export var pickup_action: StringName = &"pickup_item"
@export var hint_text: String = "Pulsa E"
@export var hint_bob_amplitude: float = 1.5
@export var hint_bob_speed: float = 3.0
@export var hint_alpha_base: float = 0.45
@export var hint_alpha_pulse: float = 0.25
var _pickup_radius_internal: float = 10.0
@export var pickup_radius: float = 10.0:
	set(value):
		_pickup_radius_internal = maxf(value, 1.0)
		_apply_pickup_radius_to_shape()
		_configure_pickup_radius_visual()
	get:
		return _pickup_radius_internal
@export var show_pickup_radius: bool = true
@export var pickup_radius_color: Color = Color(0.65, 0.95, 1.0, 0.28)
@export var pickup_radius_width: float = 1.5
@export_range(8, 96, 1) var pickup_radius_segments: int = 40
@export var auto_radius_from_sprite: bool = false
@export var auto_radius_padding: float = 2.0

@onready var _visual: Node2D = $VisualRoot
@onready var _pickup_area: Area2D = $Area_Collicion_Interact
@onready var _pickup_area_shape: CollisionShape2D = $Area_Collicion_Interact/CollisionShape2D
@onready var _hint_root: Node2D = $PickupHintRoot
@onready var _hint_label: Label = $PickupHintRoot/HintLabel
@onready var _pickup_radius_line: Line2D = $PickupRadiusVisual
var _base_visual_y: float = 0.0
var _bob_t: float = 0.0
var _player_in_range: Node2D = null
var _hint_t: float = 0.0
var _hint_base_y: float = 0.0


func _ready() -> void:
	linear_damp = heavy_linear_damp
	angular_damp = 3.0
	if auto_radius_from_sprite:
		_fit_pickup_radius_to_sprite()
	_apply_pickup_radius_to_shape()
	_configure_pickup_radius_visual()

	if Engine.is_editor_hint():
		if _hint_root != null:
			_hint_root.visible = false
		return

	_pickup_area.body_entered.connect(_on_area_body_entered)
	_pickup_area.body_exited.connect(_on_area_body_exited)
	if _visual != null:
		_base_visual_y = _visual.position.y
	if _hint_root != null:
		_hint_base_y = _hint_root.position.y
		_hint_root.visible = false
	if _hint_label != null:
		_hint_label.text = hint_text
	if auto_despawn_time > 0.0:
		get_tree().create_timer(auto_despawn_time).timeout.connect(_on_auto_despawn, CONNECT_ONE_SHOT)


func _process(delta: float) -> void:
	if _visual == null:
		return
	_bob_t += delta
	_visual.rotation += rotate_speed * delta
	_visual.position.y = _base_visual_y + sin(_bob_t * bob_speed) * bob_amplitude
	_update_hint(delta)


func _physics_process(_delta: float) -> void:
	if _player_in_range == null and _pickup_area != null:
		for body in _pickup_area.get_overlapping_bodies():
			var node := body as Node2D
			if node != null and (node.is_in_group("Player") or node.is_in_group("player")):
				_player_in_range = node
				break
	_push_from_player_overlap(_delta)
	if _player_in_range == null:
		return
	if Input.is_action_just_pressed(pickup_action):
		_pickup(_player_in_range)


func _update_hint(delta: float) -> void:
	if _hint_root == null or not _hint_root.visible:
		return
	_hint_t += delta
	_hint_root.position.y = _hint_base_y + sin(_hint_t * hint_bob_speed) * hint_bob_amplitude
	var alpha := clampf(hint_alpha_base + sin(_hint_t * (hint_bob_speed * 0.8)) * hint_alpha_pulse, 0.1, 0.95)
	_hint_root.modulate = Color(1.0, 1.0, 1.0, alpha)


func _on_area_body_entered(body: Node2D) -> void:
	if body == null:
		return
	if not (body.is_in_group("Player") or body.is_in_group("player")):
		return
	_player_in_range = body
	if _hint_root != null:
		_hint_root.visible = true
	if push_on_enter and push_force > 0.0:
		var direction := (global_position - body.global_position).normalized()
		apply_central_impulse(direction * push_force)


func _on_area_body_exited(body: Node2D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if _hint_root != null:
			_hint_root.visible = false


func _push_from_player_overlap(delta: float) -> void:
	if not push_when_fully_overlapped:
		return
	var player := _player_in_range as CharacterBody2D
	if player == null:
		return
	var overlap_dist := pickup_radius * full_overlap_ratio
	if global_position.distance_to(player.global_position) > overlap_dist:
		return
	if player.velocity.length() < min_player_speed_to_push:
		return
	var target_velocity := player.velocity * push_speed_scale
	var weight := clampf(follow_player_push_lerp * delta, 0.0, 1.0)
	linear_velocity = linear_velocity.lerp(target_velocity, weight)


func _configure_pickup_radius_visual() -> void:
	if _pickup_radius_line == null:
		return
	_pickup_radius_line.visible = show_pickup_radius
	_pickup_radius_line.default_color = pickup_radius_color
	_pickup_radius_line.width = pickup_radius_width
	var shape := _pickup_area_shape.shape as CircleShape2D
	if shape == null:
		return
	var points := PackedVector2Array()
	var segments := maxi(pickup_radius_segments, 8)
	for i in range(segments + 1):
		var t := TAU * float(i) / float(segments)
		points.append(Vector2(cos(t), sin(t)) * shape.radius)
	_pickup_radius_line.points = points


func _apply_pickup_radius_to_shape() -> void:
	if _pickup_area_shape == null:
		return
	var shape := _pickup_area_shape.shape as CircleShape2D
	if shape == null:
		return
	shape.radius = _pickup_radius_internal


func _fit_pickup_radius_to_sprite() -> void:
	var sprite := _visual.get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null or sprite.texture == null:
		return
	var size := sprite.texture.get_size() * sprite.scale
	var candidate := maxf(size.x, size.y) * 0.5 + auto_radius_padding
	pickup_radius = maxf(candidate, 1.0)


func _pickup(player: Node2D) -> void:
	if player == null:
		return
	var runtime := player.get_node_or_null("BuffRuntimeComponent")
	if runtime != null and runtime.has_method("apply_buff"):
		runtime.apply_buff(buff_type, duration_override, magnitude_override)
		queue_free()


func _on_auto_despawn() -> void:
	if is_inside_tree():
		queue_free()
