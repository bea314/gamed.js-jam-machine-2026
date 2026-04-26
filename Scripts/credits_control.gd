extends Control

@onready var anim_logo: AnimationPlayer = $Logo/Anim_Logo
@onready var logo: TextureRect = $Logo

@export var scroll_speed: float = 100.0
var inicio : bool = false

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	logo.visible = true
	anim_logo.play("Inicio")
	await get_tree().create_timer(2.0).timeout
	inicio = true
	
func _process(delta: float) -> void:
	if inicio:
		position.y -= scroll_speed * delta
	
	
