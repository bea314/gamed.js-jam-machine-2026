extends CharacterBody2D

## Jefe nivel 1: ráfagas, ≤50 % cadencia↑, AoE con telegrafía, movimiento lento con IA, ráfaga al morir.

@export var detection_range: float = 440.0
@export var projectile_scene: PackedScene
@export var aoe_scene: PackedScene
@export var muzzle_offset: float = 24.0

@export var line_burst_count: int = 5
@export var line_burst_damage: int = 5
@export var line_burst_gap: float = 0.12
@export var line_burst_cooldown: float = 0.9
@export var line_burst_cooldown_enraged: float = 0.48

@export var enrage_hp_threshold: float = 0.5

@export var aoe_interval_min: float = 5.0
@export var aoe_interval_max: float = 7.0
@export var aoe_damage: int = 14
@export var aoe_radius: float = 50.0
## Dónde aparece el centro del círculo: 0 = bajo el jefe, 1 = sobre el jugador (intermedio acerca la zona al jugador).
@export_range(0.0, 1.0) var aoe_center_toward_player: float = 0.68

@export var death_burst_count: int = 8
@export var death_burst_damage: int = 6

@export var hit_flash_tint: Color = Color(1.0, 0.55, 0.55, 1.0)
@export var hit_invuln_flicker_half_period: float = 0.05

# --- Movimiento: acercarse / alejarse y strafe; sin gravedad (top-down). ---
@export var move_speed: float = 32.0
@export var move_speed_enraged: float = 40.0
## Si el jugador está más lejos, el jefe avanza hacia un anillo de combate.
@export var keep_distance_max: float = 230.0
## Si se acerca mucho, retrocede un poco.
@export var keep_distance_min: float = 100.0
## Fuerza del “orbitado” (tangencial) a distancia intermedia.
@export var strafe_strength: float = 0.55
@export var adjust_radial: float = 0.3
@export_range(0.0, 1.0) var intro_entry_toward_player: float = 0.45
@export var intro_entry_stop_distance: float = 12.0
@export var attack_recover_time: float = 0.25

@onready var _health: HealthComponent = $HealthComponent as HealthComponent
@onready var _mesh: Node2D = $Mesh
@onready var _sprite: AnimatedSprite2D = $Mesh/AnimatedSprite2D as AnimatedSprite2D

enum BossState {
	DORMANT,
	INTRO_REVEAL,
	MOVE,
	ATTACK_WINDUP,
	ATTACK_SHOOT,
	RECOVER,
	DEAD,
}

const ANIM_INTRO_REVEAL := "intro_reveal"
const ANIM_MOVE_LOOP := "move_loop"
const ANIM_ATTACK_WINDUP := "attack_windup"
const ANIM_ATTACK_SHOOT_LOOP := "attack_shoot_loop"

var _dead: bool = false
var _target: Node2D = null
var _burst_left: int = 0
var _burst_gap_timer: float = 0.0
var _line_burst_cd: float = 0.0
var _aoe_cd: float = 0.0
var _strafe_t: float = 0.0
var _state: BossState = BossState.DORMANT
var _entry_point: Vector2 = Vector2.ZERO
var _entry_point_valid: bool = false
var _recover_timer: float = 0.0

var _hit_flash := HitFlashState.new()


func _ready() -> void:
	add_to_group("enemies")
	_setup_sprite_animations()
	if projectile_scene == null:
		projectile_scene = load("res://Ecenes/Enemies/EnemyProjectile.tscn") as PackedScene
	if aoe_scene == null:
		aoe_scene = load("res://Ecenes/Enemies/BossGroundAoe.tscn") as PackedScene
	_line_burst_cd = 0.0
	_schedule_next_aoe()
	if _health:
		_health.died.connect(_on_health_died)
		_health.damage_taken.connect(_on_health_damage_visual)
	if _sprite:
		_sprite.animation_finished.connect(_on_sprite_animation_finished)


func _on_health_damage_visual(_amount: int, _hit_from_global: Vector2) -> void:
	_hit_flash.on_damage_taken(_health)


func _process(delta: float) -> void:
	if _dead or _mesh == null:
		return
	var base := Color(1.12, 0.92, 0.92) if _is_enraged() else Color.WHITE
	_hit_flash.process_frame(
		delta,
		_health,
		_mesh as CanvasItem,
		base,
		hit_flash_tint,
		hit_invuln_flicker_half_period
	)


func _schedule_next_aoe() -> void:
	_aoe_cd = randf_range(aoe_interval_min, aoe_interval_max)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	var may_act := ActiveRoomService.hostile_may_act(self)
	if _state == BossState.DORMANT:
		if may_act:
			_set_state(BossState.INTRO_REVEAL)
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if not may_act:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_ensure_target()
	_strafe_t += delta

	match _state:
		BossState.INTRO_REVEAL:
			velocity = Vector2.ZERO
			move_and_slide()
			return
		BossState.RECOVER:
			_recover_timer = maxf(_recover_timer - delta, 0.0)
			velocity = Vector2.ZERO
			move_and_slide()
			if _recover_timer <= 0.0:
				_set_state(BossState.MOVE)
			return
		BossState.ATTACK_WINDUP, BossState.ATTACK_SHOOT:
			velocity = Vector2.ZERO
			move_and_slide()
		BossState.MOVE:
			_update_movement(delta)
		_:
			pass

	_line_burst_cd = maxf(_line_burst_cd - delta, 0.0)
	_aoe_cd = maxf(_aoe_cd - delta, 0.0)

	if _state == BossState.MOVE and _aoe_cd <= 0.0:
		_spawn_aoe()
		_schedule_next_aoe()

	var in_range := false
	if _target != null and is_instance_valid(_target):
		var d_sq := global_position.distance_squared_to(_target.global_position)
		in_range = d_sq <= detection_range * detection_range

	if not in_range:
		_burst_left = 0
		return

	if _state == BossState.MOVE and _line_burst_cd <= 0.0:
		_set_state(BossState.ATTACK_WINDUP)
		return

	if _state == BossState.ATTACK_SHOOT:
		_process_line_burst(delta)


## IA: mantiene distancias, acerca si le pillas lejos, retrocede si te pones bajo, strafe a media distancia.
func _update_movement(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var to_p := _target.global_position - global_position
	var dist: float = to_p.length()
	if dist < 1.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var to_player := to_p / dist
	var tangent := Vector2(-to_player.y, to_player.x)
	var spd := move_speed_enraged if _is_enraged() else move_speed
	var v := Vector2.ZERO
	if dist > keep_distance_max:
		# Muy lejos: cerrar, con una tangente suave para no ir en línea recta toda la vida
		var blend_t := 0.15 * sin(_strafe_t * 1.4)
		v = (to_player + tangent * blend_t).normalized() * spd
	elif dist < keep_distance_min:
		# Demasiado cerca: apartarse (predominio radial hacia afuera)
		v = -to_player * spd * 0.8
	else:
		# Zona cómoda: strafe (orbita) con pequeña corrección hacia anillo ideal
		var ideal: float = (keep_distance_min + keep_distance_max) * 0.5
		var err: float = dist - ideal
		var radial: Vector2 = to_player * signf(err) * adjust_radial
		var side: float = sin(_strafe_t * 0.95)
		v = tangent * side * strafe_strength * spd + radial * spd
		if v.length_squared() < 0.25:
			v = tangent * spd * 0.35
		else:
			v = v.normalized() * spd
	velocity = v
	move_and_slide()


func _is_enraged() -> bool:
	if _health == null:
		return false
	var max_h := maxi(_health.max_health, 1)
	return float(_health.current_health) / float(max_h) <= enrage_hp_threshold


func _line_cooldown_after_burst() -> float:
	if _is_enraged():
		return line_burst_cooldown_enraged
	return line_burst_cooldown


func _set_state(next: BossState) -> void:
	_state = next
	match _state:
		BossState.DORMANT:
			_set_intro_idle_frame()
		BossState.INTRO_REVEAL:
			_play_anim(ANIM_INTRO_REVEAL)
		BossState.MOVE:
			_play_anim(ANIM_MOVE_LOOP)
		BossState.ATTACK_WINDUP:
			_play_anim(ANIM_ATTACK_WINDUP)
		BossState.ATTACK_SHOOT:
			_play_anim(ANIM_ATTACK_SHOOT_LOOP)
			_burst_left = maxi(line_burst_count, 1)
			_burst_gap_timer = 0.0
		BossState.RECOVER:
			_recover_timer = attack_recover_time
			_play_anim(ANIM_MOVE_LOOP)
		BossState.DEAD:
			pass


func _play_anim(anim_name: StringName) -> void:
	if _sprite == null:
		return
	if _sprite.sprite_frames == null:
		return
	if not _sprite.sprite_frames.has_animation(anim_name):
		return
	if _sprite.animation == anim_name and _sprite.is_playing():
		return
	_sprite.play(anim_name)


func _set_intro_idle_frame() -> void:
	if _sprite == null:
		return
	var frames := _sprite.sprite_frames
	if frames == null:
		return
	if not frames.has_animation(ANIM_INTRO_REVEAL):
		return
	_sprite.play(ANIM_INTRO_REVEAL)
	_sprite.stop()
	_sprite.frame = 0


func _on_sprite_animation_finished() -> void:
	if _state == BossState.INTRO_REVEAL:
		_set_state(BossState.MOVE)
	elif _state == BossState.ATTACK_WINDUP:
		_set_state(BossState.ATTACK_SHOOT)


func _setup_sprite_animations() -> void:
	if _sprite == null:
		return
	var frames := SpriteFrames.new()
	_add_animation(frames, ANIM_INTRO_REVEAL, _build_paths("res://Recursos/Textures/Enemies/Boss/Aparición/boss reveal", 1, 18), false, 12.0)
	_add_animation(frames, ANIM_MOVE_LOOP, _build_paths("res://Recursos/Textures/Enemies/Boss/Aparición/boss reveal", 8, 12), true, 10.0)
	_add_animation(frames, ANIM_ATTACK_WINDUP, _build_paths("res://Recursos/Textures/Enemies/Boss/Aparición/boss reveal", 8, 14), false, 14.0)
	_add_animation(frames, ANIM_ATTACK_SHOOT_LOOP, _build_paths("res://Recursos/Textures/Enemies/Boss/Disparando/boss shooting", 1, 13), true, 14.0)
	_sprite.sprite_frames = frames
	_sprite.centered = true
	_set_intro_idle_frame()


func _add_animation(frames: SpriteFrames, name: StringName, paths: Array[String], loop: bool, fps: float) -> void:
	frames.add_animation(name)
	frames.set_animation_loop(name, loop)
	frames.set_animation_speed(name, fps)
	for path in paths:
		var tex := load(path) as Texture2D
		if tex != null:
			frames.add_frame(name, tex)


func _build_paths(base: String, start_idx: int, end_idx: int) -> Array[String]:
	var out: Array[String] = []
	for idx in range(start_idx, end_idx + 1):
		out.append("%s%d.png" % [base, idx])
	return out


func _spawn_aoe() -> void:
	if aoe_scene == null:
		return
	var aoe := aoe_scene.instantiate() as Node2D
	if aoe == null:
		return
	aoe.set("damage", aoe_damage)
	aoe.set("damage_radius", aoe_radius)
	if has_meta(ActiveRoomService.META_HOSTILE_ROOM):
		ActiveRoomService.bind_hostile_to_room(aoe, get_meta(ActiveRoomService.META_HOSTILE_ROOM) as Node2D)
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root
	scene_root.add_child(aoe)
	var place := global_position
	if _target != null and is_instance_valid(_target):
		place = global_position.lerp(_target.global_position, aoe_center_toward_player)
	aoe.global_position = place


func _aim_at_player() -> Vector2:
	if _target == null or not is_instance_valid(_target):
		return Vector2.RIGHT
	var d := _target.global_position - global_position
	if d.length_squared() < 0.0001:
		return Vector2.RIGHT
	return d.normalized()


func _process_line_burst(delta: float) -> void:
	if _burst_left <= 0:
		return
	_burst_gap_timer -= delta
	if _burst_gap_timer > 0.0:
		return
	_spawn_projectile(_aim_at_player(), line_burst_damage)
	_burst_left -= 1
	if _burst_left > 0:
		_burst_gap_timer = line_burst_gap
	else:
		_line_burst_cd = _line_cooldown_after_burst()
		_set_state(BossState.RECOVER)


func _spawn_projectile(dir: Vector2, dmg: int) -> void:
	_spawn_projectile_at(global_position, dir, dmg)


func _ensure_target() -> void:
	if _target != null and is_instance_valid(_target):
		return
	_target = null
	var node := get_tree().get_first_node_in_group("player")
	if node is Node2D:
		_target = node as Node2D


func take_damage(amount: int, hit_from_global: Vector2 = Vector2.ZERO) -> void:
	if _health == null:
		return
	_health.take_damage(amount, hit_from_global)


func _on_health_died() -> void:
	_dead = true
	_state = BossState.DEAD
	set_physics_process(false)
	velocity = Vector2.ZERO
	_fire_radial_burst(death_burst_count, death_burst_damage)
	queue_free()


func _fire_radial_burst(count: int, dmg: int) -> void:
	if projectile_scene == null:
		return
	var n := maxi(count, 1)
	var center := global_position
	for i in n:
		var ang := TAU * float(i) / float(n)
		_spawn_projectile_at(center, Vector2.from_angle(ang), dmg)


func _spawn_projectile_at(origin_global: Vector2, dir: Vector2, dmg: int) -> void:
	if projectile_scene == null:
		return
	var p := projectile_scene.instantiate() as Area2D
	var d := dir.normalized()
	p.set("direction", d)
	p.set("damage", dmg)
	p.set("damage_origin", origin_global)
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_tree().root
	scene_root.add_child(p)
	p.global_position = origin_global + d * muzzle_offset
	if has_meta(ActiveRoomService.META_HOSTILE_ROOM):
		ActiveRoomService.bind_hostile_to_room(p, get_meta(ActiveRoomService.META_HOSTILE_ROOM) as Node2D)
