extends CharacterBody2D

@export var speed: float = 80.0
@export var target: Node2D = null
@export var attack_damage: int = 5
@export var attack_cooldown: float = 0.5

var _attack_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(_attack_timer - delta, 0.0)

	_ensure_target()
	if target == null:
		return

	var direction := global_position.direction_to(target.global_position)
	velocity = direction * speed
	move_and_slide()

	if _attack_timer <= 0.0:
		_try_damage_from_slide_collisions()


func _try_damage_from_slide_collisions() -> void:
	var count := get_slide_collision_count()
	for i in count:
		var collision := get_slide_collision(i)
		if collision == null:
			continue
		var collider := collision.get_collider()
		if collider == null or not collider.is_in_group("player"):
			continue
		var health: HealthComponent = collider.get_node_or_null("HealthComponent") as HealthComponent
		if health:
			health.take_damage(attack_damage)
			_attack_timer = attack_cooldown
		return


func _ensure_target() -> void:
	if target != null and is_instance_valid(target):
		return
	target = null
	var node := get_tree().get_first_node_in_group("player")
	if node is Node2D:
		target = node as Node2D
