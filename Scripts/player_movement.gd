extends CharacterBody2D

# Health test: T = 10 damage, Y = 10 heal (requires HealthComponent).

@export var speed: float = 170.0
## Píxeles/s^2 hacia la velocidad objetivo (subir = más ágil al arrancar).
@export var acceleration: float = 820.0
## Píxeles/s^2 al soltar input (bajar = más inercia al frenar).
@export var deceleration: float = 360.0
## Más aceleración cuando el input va contra la velocidad (huir / girar rápido).
@export var turn_acceleration_multiplier: float = 1.9
@export var attack_scene: PackedScene
## Impulso al recibir golpe (alejándose del origen del daño).
@export var hit_knockback_speed: float = 110.0
## Color del parpadeo al recibir daño (vuelve a blanco).
@export var hit_flash_tint: Color = Color(1.0, 0.55, 0.55, 1.0)

@onready var attack_spawn_point: Marker2D = $AttackSpawnPoint
@onready var _mesh: MeshInstance2D = $Mesh

var _hit_modulate_tween: Tween

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")

	var hc := get_node_or_null("HealthComponent") as HealthComponent
	if hc:
		hc.died.connect(_on_health_died)
		hc.damage_taken.connect(_on_damage_taken)

func _on_health_died() -> void:
	print("Player died (test placeholder)")


func _on_damage_taken(_amount: int, hit_from_global: Vector2) -> void:
	_play_hit_flash()
	if hit_from_global != Vector2.ZERO:
		var away := global_position - hit_from_global
		if away.length_squared() > 0.0001:
			velocity += away.normalized() * hit_knockback_speed


func _play_hit_flash() -> void:
	if _mesh == null:
		return
	if _hit_modulate_tween:
		_hit_modulate_tween.kill()
	_mesh.modulate = Color.WHITE
	_hit_modulate_tween = create_tween()
	_hit_modulate_tween.tween_property(_mesh, "modulate", hit_flash_tint, 0.045)
	_hit_modulate_tween.tween_property(_mesh, "modulate", Color.WHITE, 0.055)
	_hit_modulate_tween.tween_property(_mesh, "modulate", hit_flash_tint, 0.045)
	_hit_modulate_tween.tween_property(_mesh, "modulate", Color.WHITE, 0.055)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var hc := get_node_or_null("HealthComponent") as HealthComponent
	if hc == null:
		return
	match event.physical_keycode:
		KEY_T:
			hc.take_damage(10)
		KEY_Y:
			hc.heal(10)

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		_spawn_attack()

	# Izquierda/derecha, arriba/abajo (acciones en project.godot)
	var direction := Input.get_vector("Mover_izquierda", "Mover_derecha", "Mover_arriba", "Mover_abajo")
	var target_velocity := direction * speed
	if direction == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * _delta)
	else:
		var accel := acceleration
		if velocity.dot(direction) < 0.0:
			accel *= turn_acceleration_multiplier
		velocity = velocity.move_toward(target_velocity, accel * _delta)
	move_and_slide()


func _spawn_attack() -> void:
	if attack_scene == null:
		return
	var attack_instance := attack_scene.instantiate() as Node2D
	if attack_instance == null:
		return
	attack_instance.global_position = attack_spawn_point.global_position
	attack_instance.global_rotation = attack_spawn_point.global_rotation
	get_tree().current_scene.add_child(attack_instance)
