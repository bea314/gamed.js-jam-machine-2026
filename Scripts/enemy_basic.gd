extends CharacterBody2D

@export var speed: float = 80.0
## Si ya está a esta distancia o menos del jugador, no empuja más hacia el centro.
## Evita el "balanceo": seguir acelerando contra el colisionador hace que move_and_slide deslice y el input vuelva a empujar al centro.
@export var stop_distance: float = 28.0
@export var target: Node2D = null
@export var attack_damage: int = 5
## Entre ticks de daño (continuo) o entre pulsos (modo pulse).
@export var attack_cooldown: float = 0.22
## Tras conectar un golpe, el enemigo frena ~0,1–0,2 s (velocidad casi nula) para dar ventana al jugador.
@export var attack_recovery_duration: float = 0.15
## Daño melee (distancia centro-centro). El jugador no colisiona físicamente con enemigos.
@export var attack_range: float = 40.0
## Radio mínimo para poder iniciar la secuencia de ataque (detección). Debe ser ≥ `attack_range` para telegrafía antes del contacto.
@export var detection_range: float = 56.0
## Tiempo telegráfico antes del primer daño al entrar en rango (0 = sin wind-up).
@export var wind_up_duration: float = 0.12
## Si es true: un solo wind-up al entrar en contacto y luego daño en intervalos cortos mientras siga el rango.
## Si es false: cada golpe es un pulso con wind-up de nuevo tras recuperación (más legible en tanques).
@export var attack_continuous: bool = true

var _attack_timer: float = 0.0
var _attack_recovery_timer: float = 0.0
var _wind_up_timer: float = 0.0
var _was_in_attack_range: bool = false
## En modo continuo: tras el primer impacto no se repite wind-up hasta salir de `attack_range`.
var _continuous_first_hit_done: bool = false

@onready var _health: HealthComponent = $HealthComponent as HealthComponent


func _ready() -> void:
	add_to_group("enemies")
	if _health:
		_health.died.connect(_on_health_died)


func _physics_process(delta: float) -> void:
	var prev_recovery := _attack_recovery_timer
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_attack_recovery_timer = maxf(_attack_recovery_timer - delta, 0.0)
	var recovery_just_ended := prev_recovery > 0.0 and _attack_recovery_timer <= 0.0

	_ensure_target()
	if target == null:
		return

	var dist_sq := global_position.distance_squared_to(target.global_position)
	var det_r := maxf(detection_range, attack_range)
	var det_sq := det_r * det_r
	var atk_sq := attack_range * attack_range
	var in_detection := dist_sq <= det_sq
	var in_attack := dist_sq <= atk_sq

	if not in_detection:
		_reset_attack_telegraph()

	if _attack_recovery_timer > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	var stop_sq := stop_distance * stop_distance
	if dist_sq <= stop_sq:
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * speed
	move_and_slide()

	if not in_detection:
		return

	if attack_continuous:
		_process_attack_continuous(delta, in_attack)
	else:
		_process_attack_pulse(delta, in_attack, recovery_just_ended)


func _reset_attack_telegraph() -> void:
	_wind_up_timer = 0.0
	_was_in_attack_range = false
	_continuous_first_hit_done = false


func _process_attack_continuous(delta: float, in_attack: bool) -> void:
	if not in_attack:
		_wind_up_timer = 0.0
		_was_in_attack_range = false
		_continuous_first_hit_done = false
		return

	var entered := not _was_in_attack_range
	_was_in_attack_range = true

	if entered and not _continuous_first_hit_done and wind_up_duration > 0.0:
		_wind_up_timer = wind_up_duration

	if _wind_up_timer > 0.0:
		_wind_up_timer = maxf(_wind_up_timer - delta, 0.0)
		return

	if _attack_timer > 0.0:
		return

	_apply_damage_to_player()


func _process_attack_pulse(delta: float, in_attack: bool, recovery_just_ended: bool) -> void:
	if not in_attack:
		_wind_up_timer = 0.0
		_was_in_attack_range = false
		return

	var entered := not _was_in_attack_range
	_was_in_attack_range = true

	if recovery_just_ended or entered:
		if wind_up_duration > 0.0:
			_wind_up_timer = wind_up_duration

	if _wind_up_timer > 0.0:
		_wind_up_timer = maxf(_wind_up_timer - delta, 0.0)
		return

	if _attack_timer > 0.0:
		return

	_apply_damage_to_player()


func _apply_damage_to_player() -> void:
	if target == null:
		return
	var dist_sq := global_position.distance_squared_to(target.global_position)
	if dist_sq > attack_range * attack_range:
		return
	var health: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
	if health == null:
		return
	health.take_damage(attack_damage, global_position)
	_attack_timer = attack_cooldown
	_attack_recovery_timer = attack_recovery_duration
	if attack_continuous:
		_continuous_first_hit_done = true


func _ensure_target() -> void:
	if target != null and is_instance_valid(target):
		return
	target = null
	var node := get_tree().get_first_node_in_group("player")
	if node is Node2D:
		target = node as Node2D


func take_damage(amount: int, hit_from_global: Vector2 = Vector2.ZERO) -> void:
	if _health == null:
		return
	_health.take_damage(amount, hit_from_global)


func _on_health_died() -> void:
	queue_free()
