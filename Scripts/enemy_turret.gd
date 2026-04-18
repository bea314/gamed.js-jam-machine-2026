extends StaticBody2D

## Torre fija: ráfaga en línea (5 balas seguidas hacia el jugador). Vida ≤30 %: círculo cada 2 s. Muerte: ráfaga radial.

@export var detection_range: float = 440.0
@export var projectile_scene: PackedScene

@export var muzzle_offset: float = 24.0

# --- Ataque principal: 5 proyectiles seguidos en línea (misma dirección hacia el jugador) ---
@export var line_burst_count: int = 5
@export var line_burst_damage: int = 4
@export var line_burst_gap: float = 0.12
## Tras completar la tanda de 5, tiempo hasta la siguiente tanda.
@export var line_burst_cooldown: float = 0.85

# --- Vida ≤30 %: ataque circular (proyectiles en 360°) ---
@export var low_hp_threshold: float = 0.3
@export var low_hp_circle_cooldown: float = 2.0
@export var low_hp_circle_count: int = 12
@export var low_hp_circle_damage: int = 5

# --- Muerte: ráfaga radial ---
@export var death_burst_count: int = 5
@export var death_burst_damage: int = 5

@onready var _health: HealthComponent = $HealthComponent as HealthComponent

var _dead: bool = false
var _target: Node2D = null

var _burst_left: int = 0
var _burst_gap_timer: float = 0.0
var _line_burst_cd: float = 0.0
var _low_hp_circle_cd: float = 0.0
var _was_low_hp: bool = false


func _ready() -> void:
	add_to_group("enemies")
	if projectile_scene == null:
		projectile_scene = load("res://Ecenes/Enemies/EnemyProjectile.tscn") as PackedScene
	_line_burst_cd = 0.0
	_low_hp_circle_cd = low_hp_circle_cooldown
	if _health:
		_health.died.connect(_on_health_died)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_ensure_target()

	_line_burst_cd = maxf(_line_burst_cd - delta, 0.0)

	var low := _is_low_hp()
	if low and not _was_low_hp:
		_low_hp_circle_cd = 0.0
	_was_low_hp = low

	if low:
		_low_hp_circle_cd = maxf(_low_hp_circle_cd - delta, 0.0)

	var in_range := false
	if _target != null and is_instance_valid(_target):
		var d_sq := global_position.distance_squared_to(_target.global_position)
		in_range = d_sq <= detection_range * detection_range

	if not in_range:
		_burst_left = 0
		return

	# Encadenar tandas de 5 disparos en línea hacia el jugador.
	if _burst_left == 0 and _line_burst_cd <= 0.0:
		_burst_left = maxi(line_burst_count, 1)
		_burst_gap_timer = 0.0

	_process_line_burst(delta)

	if low and _low_hp_circle_cd <= 0.0:
		_fire_radial_burst(low_hp_circle_count, low_hp_circle_damage)
		_low_hp_circle_cd = low_hp_circle_cooldown


func _is_low_hp() -> bool:
	if _health == null:
		return false
	var max_h := maxi(_health.max_health, 1)
	return float(_health.current_health) / float(max_h) <= low_hp_threshold


## Dirección hacia la posición global del jugador (un solo punto de mira).
func _aim_at_player() -> Vector2:
	if _target == null or not is_instance_valid(_target):
		return Vector2.RIGHT
	var player_point := _target.global_position
	var d := player_point - global_position
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
		_line_burst_cd = line_burst_cooldown


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
	set_physics_process(false)
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
