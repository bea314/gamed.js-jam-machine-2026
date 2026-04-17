extends CharacterBody2D

@export var speed: float = 80.0
## Si ya está a esta distancia o menos del jugador, no empuja más hacia el centro.
## Evita el "balanceo": seguir acelerando contra el colisionador hace que move_and_slide deslice y el input vuelva a empujar al centro.
@export var stop_distance: float = 28.0
@export var target: Node2D = null
@export var attack_damage: int = 5
@export var attack_cooldown: float = 0.5
## Daño melee (distancia centro-centro). El jugador no colisiona físicamente con enemigos.
@export var attack_range: float = 40.0
@export var max_health: int = 30

var _attack_timer: float = 0.0
var _current_health: int = 0


func _ready() -> void:
	add_to_group("enemies")
	_current_health = max_health


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)

	_ensure_target()
	if target == null:
		return

	var to_target := target.global_position - global_position
	var dist_sq := to_target.length_squared()
	var stop_sq := stop_distance * stop_distance
	if dist_sq <= stop_sq:
		velocity = Vector2.ZERO
	else:
		velocity = to_target.normalized() * speed
	move_and_slide()

	if _attack_timer <= 0.0:
		_try_damage_player_in_range()


func _try_damage_player_in_range() -> void:
	if target == null:
		return
	var dist_sq := global_position.distance_squared_to(target.global_position)
	var r := attack_range
	if dist_sq > r * r:
		return
	var health: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
	if health:
		health.take_damage(attack_damage)
		_attack_timer = attack_cooldown


func _ensure_target() -> void:
	if target != null and is_instance_valid(target):
		return
	target = null
	var node := get_tree().get_first_node_in_group("player")
	if node is Node2D:
		target = node as Node2D


func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	_current_health = maxi(_current_health - amount, 0)
	if _current_health == 0:
		queue_free()
