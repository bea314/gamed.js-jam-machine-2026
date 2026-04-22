extends Node2D

## Zona de daño: aviso traslúcido, opcional acercamiento al jugador en telegrafía, impacto un poco más visible.

@export var damage: int = 14
@export var damage_radius: float = 100.0
## Tiempo de “telegrafía” antes del golpe.
@export var telegraph_duration: float = 1.5
## Durante el aviso, se desplaza hacia el jugador a esta velocidad (px/s); 0 = fijo.
@export var telegraph_homing_speed: float = 88.0
## Tiempo de visual de impacto tras el daño antes de borrarse.
@export var impact_after_duration: float = 0.28
## Aviso: color suave, traslúcido.
@export var telegraph_modulate: Color = Color(0.95, 0.55, 0.5, 0.38)
## Impacto: un poco más rojo, sigue traslúcido (no sólido).
@export var impact_modulate: Color = Color(0.88, 0.22, 0.2, 0.52)
@export var impact_scale_mul: float = 1.06

var _ended_telegraph: bool = false
var _draw_radius: float
var _draw_color: Color


func _ready() -> void:
	z_index = 2
	_draw_radius = damage_radius
	_draw_color = telegraph_modulate
	queue_redraw()
	var t0 := get_tree().create_timer(telegraph_duration)
	t0.timeout.connect(_on_telegraph_finished)
	set_process(telegraph_homing_speed > 0.0)


func _draw() -> void:
	draw_circle(Vector2.ZERO, _draw_radius, _draw_color)


func _process(delta: float) -> void:
	if _ended_telegraph or telegraph_homing_speed <= 0.0:
		return
	if not ActiveRoomService.hostile_may_act(self):
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null or not is_instance_valid(p):
		return
	var to_p := p.global_position - global_position
	var len_to := to_p.length()
	if len_to < 0.5:
		return
	var step: float = minf(len_to, telegraph_homing_speed * delta)
	global_position += to_p * (step / len_to)


func _on_telegraph_finished() -> void:
	_ended_telegraph = true
	set_process(false)
	_draw_radius = damage_radius * impact_scale_mul
	_draw_color = impact_modulate
	queue_redraw()
	_apply_damage()
	var t1 := get_tree().create_timer(impact_after_duration)
	t1.timeout.connect(queue_free)


func _apply_damage() -> void:
	if not ActiveRoomService.hostile_may_act(self):
		return
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null or not is_instance_valid(p):
		return
	if global_position.distance_squared_to(p.global_position) > damage_radius * damage_radius:
		return
	var hc := p.get_node_or_null("HealthComponent") as HealthComponent
	if hc == null:
		return
	hc.take_damage(damage, global_position)
