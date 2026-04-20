extends Node

## Sala donde está el jugador. Entidades hostiles con `META_HOSTILE_ROOM` solo persiguen / dañan
## si esa referencia coincide con `active_room`. Sin meta: comportamiento anterior (siempre activos).

const META_HOSTILE_ROOM: StringName = &"hostile_room"

var active_room: Node2D = null


func set_active_room(room: Node2D) -> void:
	active_room = room


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
	return room == active_room
