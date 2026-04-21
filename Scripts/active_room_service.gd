extends Node

## Sala donde está el jugador. Entidades hostiles con `META_HOSTILE_ROOM` solo persiguen / dañan
## si esa referencia coincide con `active_room`. Sin meta: comportamiento anterior (siempre activos).

const META_HOSTILE_ROOM: StringName = &"hostile_room"

## Tras cruzar a otra sala, los bichitos hostiles (heladidos roboticos) vinculados a esa sala no actúan durante este tiempo
## (p. ej. el tween de zoom de la cámara ~1 s).
@export var room_entry_hostile_delay: float = 1.15

signal active_room_changed(room: Node2D)

var active_room: Node2D = null
var _room_entry_grace: float = 0.0


func set_active_room(room: Node2D) -> void:
	var prev: Node2D = active_room
	active_room = room
	if (
		prev != null
		and is_instance_valid(prev)
		and room != null
		and is_instance_valid(room)
		and prev != room
	):
		_room_entry_grace = room_entry_hostile_delay
	active_room_changed.emit(room)


func _process(delta: float) -> void:
	_room_entry_grace = maxf(_room_entry_grace - delta, 0.0)


func bind_hostile_to_room(agent: Node, room: Node2D) -> void:
	if agent == null:
		return
	agent.set_meta(META_HOSTILE_ROOM, room)


func hostile_may_act(agent: Node) -> bool:
	if agent == null or not is_instance_valid(agent):
		return false
	if not agent.has_meta(META_HOSTILE_ROOM):
		return true
	var room: Node2D = agent.get_meta(META_HOSTILE_ROOM) as Node2D
	if room == null or not is_instance_valid(room):
		return true
	# Escenas de prueba sin `set_active_room`: no acotar (comportamiento anterior).
	if active_room == null or not is_instance_valid(active_room):
		return true
	if room != active_room:
		return false
	if _room_entry_grace > 0.0:
		return false
	return true
