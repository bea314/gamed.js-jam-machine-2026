extends CharacterBody2D

@export var speed: float = 80.0
@export var target: Node2D = null

func _ready() -> void:
	add_to_group("enemies")

func _physics_process(_delta: float) -> void:
	_ensure_target()
	if target == null:
		return

	var direction := global_position.direction_to(target.global_position)
	velocity = direction * speed
	move_and_slide()

func _ensure_target() -> void:
	if target != null and is_instance_valid(target):
		return
	target = null
	var node := get_tree().get_first_node_in_group("player")
	if node is Node2D:
		target = node as Node2D
