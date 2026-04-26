extends CanvasLayer
class_name BuffHud

const BUFF_HUD_ITEM_SCENE := preload("res://Ecenes/Player/Buffs/BuffHudItem.tscn")
const ICON_DAMAGE := preload("res://Recursos/Textures/Map/Buffos/damage buff.png")
const ICON_SPEED := preload("res://Recursos/Textures/Map/Buffos/speed buff.png")

@export var icon_size_multiplier: float = 0.8
@export var ring_radius: float = 22.0
@export var ring_width: float = 4.0
@export var slot_separation: int = 10

@onready var _slots: HBoxContainer = $Root/BuffRow

var _buff_runtime: BuffRuntimeComponent = null
var _items: Dictionary = {}
var _icon_by_type: Dictionary = {
	BuffType.DAMAGE: ICON_DAMAGE,
	BuffType.SPEED: ICON_SPEED,
}


func _ready() -> void:
	_slots.add_theme_constant_override("separation", slot_separation)
	var player: Node = get_parent()
	if player == null:
		return
	_buff_runtime = player.get_node_or_null("BuffRuntimeComponent") as BuffRuntimeComponent
	if _buff_runtime == null:
		push_warning("BuffHud: no se encontro BuffRuntimeComponent en el player.")
		return

	_buff_runtime.buff_applied.connect(_on_buff_applied)
	_buff_runtime.buff_expired.connect(_on_buff_expired)
	for buff_type in BuffType.ALL:
		if _buff_runtime.has_buff(buff_type):
			_on_buff_applied(buff_type, _buff_runtime.get_total_time(buff_type), 1.0)
	set_process(true)


func _process(_delta: float) -> void:
	if _buff_runtime == null:
		return
	for buff_type in _items.keys():
		var item: BuffHudItem = _items[buff_type] as BuffHudItem
		if item == null:
			continue
		var total: float = _buff_runtime.get_total_time(str(buff_type))
		var remaining: float = _buff_runtime.get_remaining_time(str(buff_type))
		if total <= 0.0:
			item.set_progress(0.0)
		else:
			item.set_progress(remaining / total)


func _on_buff_applied(buff_type: String, _duration: float, _magnitude: float) -> void:
	if buff_type == BuffType.SHIELD:
		return
	var item: BuffHudItem = _items.get(buff_type, null) as BuffHudItem
	if item == null:
		item = BUFF_HUD_ITEM_SCENE.instantiate() as BuffHudItem
		if item == null:
			return
		_apply_item_style(item)
		var icon: Texture2D = _icon_by_type.get(buff_type, null) as Texture2D
		item.set_icon(icon)
		_slots.add_child(item)
		_items[buff_type] = item

	var total: float = _buff_runtime.get_total_time(buff_type)
	var remaining: float = _buff_runtime.get_remaining_time(buff_type)
	if total <= 0.0:
		item.set_progress(1.0)
	else:
		item.set_progress(remaining / total)


func _on_buff_expired(buff_type: String) -> void:
	var item: BuffHudItem = _items.get(buff_type, null) as BuffHudItem
	if item == null:
		return
	_items.erase(buff_type)
	item.queue_free()


func _apply_item_style(item: BuffHudItem) -> void:
	item.icon_scale = icon_size_multiplier
	item.ring_radius = ring_radius
	item.ring_width = ring_width
