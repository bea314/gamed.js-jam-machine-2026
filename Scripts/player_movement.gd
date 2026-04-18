extends CharacterBody2D

# Health test: T = 10 damage, Y = 10 heal (requires HealthComponent).

@export var speed: float = 170.0
@onready var mesh_sistem: Node2D = $Mesh_Sistem
## Píxeles/s^2 hacia la velocidad objetivo (subir = más ágil al arrancar).
@export var acceleration: float = 820.0
## Píxeles/s^2 al soltar input (bajar = más inercia al frenar).
@export var deceleration: float = 360.0
## Más aceleración cuando el input va contra la velocidad (huir / girar rápido).
@export var turn_acceleration_multiplier: float = 1.9
## Impulso al recibir golpe (alejándose del origen del daño).
@export var hit_knockback_speed: float = 110.0
## Color del parpadeo al recibir daño (vuelve a blanco).
@export var hit_flash_tint: Color = Color(1.0, 0.55, 0.55, 1.0)
## Medio ciclo blanco↔tinte durante `HealthComponent` i-frames (acoplado a `is_invulnerable`).
@export var hit_invuln_flicker_half_period: float = 0.05

@onready var weapon_manager: Node = $WeaponManager
@onready var weapon_hud: CanvasLayer = $WeaponHud
@onready var _mesh: MeshInstance2D = $Mesh
@onready var _health: HealthComponent = $HealthComponent

var _invuln_flicker_time: float = 0.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")

	if _health:
		_health.died.connect(_on_health_died)
		_health.damage_taken.connect(_on_damage_taken)

	weapon_hud.setup(weapon_manager)
	weapon_manager.setup(self)


func _on_health_died() -> void:
	print("Player died (test placeholder)")


func _on_damage_taken(_amount: int, hit_from_global: Vector2) -> void:
	_invuln_flicker_time = 0.0
	if hit_from_global != Vector2.ZERO:
		var away := global_position - hit_from_global
		if away.length_squared() > 0.0001:
			velocity += away.normalized() * hit_knockback_speed


func _sync_invuln_flicker(delta: float) -> void:
	if _mesh == null or _health == null:
		return
	if not _health.is_invulnerable():
		_invuln_flicker_time = 0.0
		_mesh.modulate = Color.WHITE
		return
	_invuln_flicker_time += delta
	var half_p: float = maxf(hit_invuln_flicker_half_period, 0.016)
	var phase := int(floor(_invuln_flicker_time / half_p)) % 2
	_mesh.modulate = hit_flash_tint if phase == 0 else Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if _health == null:
		return
	match event.physical_keycode:
		KEY_T:
			_health.take_damage(10)
		KEY_Y:
			_health.heal(10)


func _process(delta: float) -> void:
	_sync_invuln_flicker(delta)

	var to_mouse := get_global_mouse_position() - global_position
	var aim_direction := Vector2.RIGHT
	if to_mouse.length_squared() > 0.0001:
		aim_direction = to_mouse.normalized()

	if Input.is_action_just_pressed("weapon_next"):
		weapon_manager.next_weapon()
	if Input.is_action_just_pressed("weapon_prev"):
		weapon_manager.prev_weapon()
	if Input.is_action_just_pressed("weapon_1"):
		weapon_manager.set_weapon(0)
	if Input.is_action_just_pressed("weapon_2"):
		weapon_manager.set_weapon(1)
	if Input.is_action_just_pressed("weapon_3"):
		weapon_manager.set_weapon(2)
	if Input.is_action_just_pressed("weapon_4"):
		weapon_manager.set_weapon(3)
	if Input.is_action_just_pressed("reload"):
		weapon_manager.reload()

	weapon_manager.fire(
		aim_direction,
		Input.is_action_pressed("attack"),
		Input.is_action_just_pressed("attack")
	)


func _physics_process(_delta: float) -> void:
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

	# Detección de caminar
	if is_walking():
		mesh_sistem.Change_State("Walk")
	else:
		mesh_sistem.Change_State("Idle")
		

func is_walking() -> bool:
	return velocity.length() > 0.1
	
