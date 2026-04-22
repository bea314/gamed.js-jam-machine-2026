extends CharacterBody2D

# Health test: T = 10 damage, Y = 10 heal (requires HealthComponent).

const _GAME_OVER_SCENE := preload("res://Ecenes/UI/GameOverScreen.tscn")

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
## Tinte mientras el dash está activo (i-frames del dash).
@export var dash_tint: Color = Color(0.78, 0.92, 1.0, 1.0)

@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon_manager: WeaponManager = $WeaponPivot/WeaponManager
@onready var weapon_hud: CanvasLayer = $WeaponHud
@onready var _health: HealthComponent = $HealthComponent
@onready var _dash: PlayerDashComponent = $PlayerDash
@onready var _dash_visual: CanvasItem = $Mesh_Sistem

var _mesh: MeshInstance2D
var _invuln_flicker_time: float = 0.0

## Disparos reales acumulados (mismo frame = varios inputs → un solo “ráfaga” para el loop).
var _weapon_fire_pulses_pending: int = 0
var _attack_visual_on: bool = false
## Si hubo disparo en los últimos N fotogramas del sprite de ataque: completar una vuelta más antes de cortar.
var _attack_finish_one_more_loop: bool = false
const _ATTACK_TAIL_FRAME_COUNT: int = 7

var damage_taken_sounds : Array = [
	preload("uid://coyglljuokcsa"),
	preload("uid://l4we4u0qsif0"),
	preload("uid://bun5wb6ulnlkt"),
	preload("uid://bs3558b1p8osa"),
	preload("uid://dcceo8pdk53jl"),
	preload("uid://c52ajm48xm1f8")
]
@onready var audio_player: AudioStreamPlayer = $Audio_Player

var _game_over_shown: bool = false

func _ready() -> void:
	_mesh = get_node_or_null("Mesh") as MeshInstance2D
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")

	if _health:
		_health.died.connect(_on_health_died)
		_health.damage_taken.connect(_on_damage_taken)

	weapon_hud.setup(weapon_manager)
	weapon_manager.setup(self)
	weapon_manager.weapon_actually_fired.connect(_on_weapon_actually_fired)


func _on_weapon_actually_fired() -> void:
	_weapon_fire_pulses_pending += 1


func _on_health_died() -> void:
	if _game_over_shown:
		return
	_game_over_shown = true
	var go := _GAME_OVER_SCENE.instantiate()
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_parent()
	if host != null:
		host.add_child(go)
	else:
		get_tree().root.add_child(go)
	go.show_game_over()


func _on_damage_taken(_amount: int, hit_from_global: Vector2) -> void:
	_invuln_flicker_time = 0.0
	audio_player.stream = damage_taken_sounds.pick_random()
	audio_player.play()
	_attack_visual_on = false
	_attack_finish_one_more_loop = false
	mesh_sistem.reset_attack_loop_tracking()
	mesh_sistem.Change_State("Take_Damage")

	if hit_from_global != Vector2.ZERO:
		var away := global_position - hit_from_global
		if away.length_squared() > 0.0001:
			velocity += away.normalized() * hit_knockback_speed


func _sync_invuln_flicker(delta: float) -> void:
	if _dash != null and _dash.is_dashing():
		_invuln_flicker_time = 0.0
		if _dash_visual != null:
			_dash_visual.modulate = dash_tint
		return
	if _health == null:
		return
	if not _health.is_invulnerable():
		_invuln_flicker_time = 0.0
		if _dash_visual != null:
			_dash_visual.modulate = Color.WHITE
		if _mesh != null:
			_mesh.modulate = Color.WHITE
		return
	_invuln_flicker_time += delta
	var half_p: float = maxf(hit_invuln_flicker_half_period, 0.016)
	var phase := int(floor(_invuln_flicker_time / half_p)) % 2
	var c := hit_flash_tint if phase == 0 else Color.WHITE
	if _mesh != null:
		_mesh.modulate = c
	elif _dash_visual != null:
		_dash_visual.modulate = c


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
	
	# SISTEMA WEAPON PIVOT ============ (Rotacion de armas mediante el mouse)
	if to_mouse.length_squared() > 0.0001:
		weapon_pivot.rotation = to_mouse.angle()
		
		# Evitar que el arma quede "patas arriba" cuando apuntas a la izquierda
		if abs(weapon_pivot.rotation) > PI/2:
			weapon_pivot.scale.y = -1
			mesh_sistem.scale.x = -1.2
		else:
			weapon_pivot.scale.y = 1
			mesh_sistem.scale.x = 1.2
	# ========================
	
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


func _physics_process(delta: float) -> void:
	if _dash:
		_dash.tick(delta)

	if _dash != null and Input.is_action_just_pressed("dash"):
		var move_in := Input.get_vector("Mover_izquierda", "Mover_derecha", "Mover_arriba", "Mover_abajo")
		var to_mouse := get_global_mouse_position() - global_position
		var aim_dir := Vector2.RIGHT
		if to_mouse.length_squared() > 0.0001:
			aim_dir = to_mouse.normalized()
		var dash_dir := move_in
		if dash_dir.length_squared() < 0.0001:
			dash_dir = aim_dir
		_dash.try_dash(dash_dir)

	if _dash != null and _dash.is_dashing():
		velocity = _dash.get_dash_velocity()
		move_and_slide()
		_attack_visual_on = false
		_attack_finish_one_more_loop = false
		if mesh_sistem:
			mesh_sistem.reset_attack_loop_tracking()
			mesh_sistem.Change_State("Walk")
		return

	var direction := Input.get_vector("Mover_izquierda", "Mover_derecha", "Mover_arriba", "Mover_abajo")
	var target_velocity := direction * speed
	if direction == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	else:
		var accel := acceleration
		if velocity.dot(direction) < 0.0:
			accel *= turn_acceleration_multiplier
		velocity = velocity.move_toward(target_velocity, accel * delta)
	move_and_slide()

	# SISTEMA DE CHOQUE CONTRA ITEMS ============= # TEST
	#Este sitema permite mover los items en el suelo
	for i in get_slide_collision_count():
		var colision = get_slide_collision(i)
		var objeto = colision.get_collider()
	
		# Si lo que chocamos es un RigidBody2D (la pelota)
		if objeto is RigidBody2D and objeto.is_in_group("Item"):
			# Le aplicamos un impulso en la dirección del choque
			# 'velocity' es la velocidad de tu jugador
			objeto.apply_central_impulse(colision.get_normal() * -velocity.length() * 0.5)
	# ===============================
	
	# Visual de ataque: solo tras disparo/melee real; mismo frame = un solo loop; disparo en últimos 7 frames del sprite = una vuelta más.
	if not mesh_sistem.In_Animation_Stun:
		var fire_pulses := _weapon_fire_pulses_pending
		_weapon_fire_pulses_pending = 0

		if fire_pulses > 0:
			_attack_visual_on = true
			if mesh_sistem.is_attack_sprite_showing():
				var total_f: int = mesh_sistem.get_attack_frame_total()
				var idx: int = mesh_sistem.get_attack_frame_index()
				if total_f > 0 and idx >= total_f - _ATTACK_TAIL_FRAME_COUNT:
					_attack_finish_one_more_loop = true

		if _attack_visual_on:
			if mesh_sistem.tick_attack_loop_wrapped():
				if _attack_finish_one_more_loop:
					_attack_finish_one_more_loop = false
				elif fire_pulses > 0:
					pass
				else:
					_attack_visual_on = false

		if _attack_visual_on:
			mesh_sistem.Change_State("Attack", is_walking())
		else:
			mesh_sistem.reset_attack_loop_tracking()
			if is_walking():
				mesh_sistem.Change_State("Walk")
			else:
				mesh_sistem.Change_State("Idle")
		




func is_walking() -> bool:
	return velocity.length() > 0.1
	
