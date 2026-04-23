extends "res://Scripts/door_animated_sprites.gd"

# Conector procedural: estados visuales hasta enlazar lógica definitiva.

@onready var mostra_path: Label = _resolve_label()


func _resolve_label() -> Label:
	var n := get_node_or_null("Mostra_path") as Label
	if n:
		return n
	return get_node("Muestra_path") as Label


func _ready() -> void:
	super._ready()
	DOOR_STATE_Visual(3)


func DOOR_STATE_Visual(door_state: int) -> void:
	match door_state:
		1:
			snap_fully_closed()
			mostra_path.visible = false
		2:
			snap_fully_open()
			mostra_path.visible = false
		3:
			snap_to_frame(2)
			mostra_path.text = "??"
			mostra_path.visible = true
