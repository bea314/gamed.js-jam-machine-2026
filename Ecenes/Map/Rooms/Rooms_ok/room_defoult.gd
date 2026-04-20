extends Node2D

signal room_transition_requested(target_coords: Vector2i, side: String)
var current_coords: Vector2i = Vector2i.ZERO

@onready var door_up = $Doors/DoorPos_Up
@onready var door_down = $Doors/DoorPos_Down
@onready var door_left = $Doors/DoorPos_Left
@onready var door_right = $Doors/DoorPos_Right

func setup(neighbors: Array, my_coords: Vector2i) -> void:
	current_coords = my_coords
	# Lógica de show/hide que ya tienes...
	door_up.visible = "up" in neighbors
	door_down.visible = "down" in neighbors
	door_left.visible = "left" in neighbors
	door_right.visible = "right" in neighbors
	# Asegúrate de activar/desactivar colisiones aquí también como vimos antes

# --- SEÑALES ---
func _on_door_pos_up_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): room_transition_requested.emit(current_coords + Vector2i.UP, "up")

func _on_door_pos_down_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): room_transition_requested.emit(current_coords + Vector2i.DOWN, "down")

func _on_door_pos_left_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): room_transition_requested.emit(current_coords + Vector2i.LEFT, "left")

func _on_door_pos_right_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"): room_transition_requested.emit(current_coords + Vector2i.RIGHT, "right")
