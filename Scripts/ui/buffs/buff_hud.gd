extends CanvasLayer
class_name BuffHud

const DAMAGE_ITEM_SCENE := preload("res://Ecenes/Player/Buffs/BuffHudDamageItem.tscn")
const SPEED_ITEM_SCENE := preload("res://Ecenes/Player/Buffs/BuffHudSpeedItem.tscn")

@export var icon_size_multiplier: float = 0.8
@export var slot_size: float = 48.0
@export var slot_separation: int = 10

@onready var _slots: HBoxContainer = $Root/BuffRow

var _buff_runtime: BuffRuntimeComponent = null
var _items: Dictionary = {}
var _scene_by_type: Dictionary = {
	BuffType.DAMAGE: DAMAGE_ITEM_SCENE,
	BuffType.SPEED: SPEED_ITEM_SCENE,
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

	_refresh_all_counts()
	_buff_runtime.buff_applied.connect(_on_buff_applied)
	_buff_runtime.buff_stack_changed.connect(_on_buff_stack_changed)
	_buff_runtime.stacks_reset.connect(_on_stacks_reset)


func _create_item_if_missing(buff_type: String) -> BuffHudItem:
	var item: BuffHudItem = _items.get(buff_type, null) as BuffHudItem
	if item == null:
		var item_scene: PackedScene = _scene_by_type.get(buff_type, null) as PackedScene
		if item_scene == null:
			return null
		item = item_scene.instantiate() as BuffHudItem
		if item == null:
			return null
		_apply_item_style(item)
		_slots.add_child(item)
		_items[buff_type] = item
	return item


func _refresh_all_counts() -> void:
	if _buff_runtime == null:
		return
	_set_item_count(BuffType.DAMAGE, _buff_runtime.get_stack_value(BuffType.DAMAGE))
	_set_item_count(BuffType.SPEED, _buff_runtime.get_stack_value(BuffType.SPEED))


func _set_item_count(buff_type: String, value: int) -> void:
	if not _is_supported_buff_type(buff_type):
		return
	if value <= 0:
		_remove_item(buff_type)
		return
	var item := _create_item_if_missing(buff_type)
	if item == null:
		return
	item.set_stack_count(value)


func _on_buff_applied(buff_type: String, stack_value: int, applied_amount: int, _wasted_amount: int) -> void:
	if not _is_supported_buff_type(buff_type):
		return
	var item := _create_item_if_missing(buff_type)
	if item == null:
		return
	if applied_amount > 0:
		item.play_pop("+%d" % applied_amount, Color(0.49, 1.0, 0.58, 1.0))


func _on_buff_stack_changed(buff_type: String, stack_value: int) -> void:
	if not _is_supported_buff_type(buff_type):
		return
	_set_item_count(buff_type, stack_value)


func _on_stacks_reset() -> void:
	_refresh_all_counts()


func _apply_item_style(item: BuffHudItem) -> void:
	item.icon_scale = icon_size_multiplier
	item.slot_size = slot_size


func _remove_item(buff_type: String) -> void:
	var item: BuffHudItem = _items.get(buff_type, null) as BuffHudItem
	if item == null:
		return
	_items.erase(buff_type)
	item.queue_free()


func _is_supported_buff_type(buff_type: String) -> bool:
	return buff_type == BuffType.DAMAGE or buff_type == BuffType.SPEED
