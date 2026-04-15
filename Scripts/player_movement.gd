extends CharacterBody2D

# Health test: T = 10 damage, Y = 10 heal (requires HealthComponent).

@export var speed: float = 170.0

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")

	var hc := get_node_or_null("HealthComponent") as HealthComponent
	if hc:
		hc.died.connect(_on_health_died)

func _on_health_died() -> void:
	print("Player died (test placeholder)")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var hc := get_node_or_null("HealthComponent") as HealthComponent
	if hc == null:
		return
	match event.physical_keycode:
		KEY_T:
			hc.take_damage(10)
		KEY_Y:
			hc.heal(10)

func _physics_process(_delta: float) -> void:
	# Izquierda/derecha, arriba/abajo (acciones en project.godot)
	var direction := Input.get_vector("Mover_izquierda", "Mover_derecha", "Mover_arriba", "Mover_abajo")
	velocity = direction * speed
	move_and_slide()
