extends Node2D
class_name EnemyOverheadHealthBar

## Nodo `HealthComponent` relativo al padre (el cuerpo del enemigo).
@export var health_component_path: NodePath = NodePath("HealthComponent")
## Tamaño exterior de la barra en píxeles (incluye el borde).
@export var bar_outer_size: Vector2i = Vector2i(26, 8)
## Grosor del borde negro hacia adentro (relleno rojo empieza después).
@export var border_width: int = 2
@export var fill_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var border_color: Color = Color.BLACK
## Si está activo, la barra solo aparece cuando `current_health < max_health`.
@export var only_visible_when_damaged: bool = true

var _health: HealthComponent
var _current: int = 0
var _max_hp: int = 1


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_as_relative = false
	var body := get_parent()
	if body == null:
		visible = false
		return
	_health = body.get_node_or_null(health_component_path) as HealthComponent
	if _health == null:
		push_warning("EnemyOverheadHealthBar: no hay HealthComponent en %s" % str(health_component_path))
		visible = false
		return
	_health.health_changed.connect(_on_health_changed)
	call_deferred("_initial_sync")


func _initial_sync() -> void:
	if is_instance_valid(_health):
		_on_health_changed(_health.current_health, _health.max_health)


func _on_health_changed(current_health: int, max_health: int) -> void:
	_current = current_health
	_max_hp = maxi(max_health, 1)
	if only_visible_when_damaged:
		visible = current_health < max_health
	else:
		visible = true
	queue_redraw()


func _draw() -> void:
	if not visible or _max_hp <= 0:
		return
	var bw: int = maxi(border_width, 1)
	var w: int = maxi(bar_outer_size.x, bw * 2 + 1)
	var h: int = maxi(bar_outer_size.y, bw * 2 + 1)
	var ox: float = -w * 0.5
	var oy: float = -float(h)
	draw_rect(Rect2(ox, oy, w, h), border_color)
	var iw: int = w - bw * 2
	var ih: int = h - bw * 2
	var ix: float = ox + bw
	var iy: float = oy + bw
	var ratio: float = clampf(float(_current) / float(_max_hp), 0.0, 1.0)
	var fill_w: float = floorf(float(iw) * ratio)
	if fill_w > 0.0:
		draw_rect(Rect2(ix, iy, fill_w, ih), fill_color)
