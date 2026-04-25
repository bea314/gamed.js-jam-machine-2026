extends RigidBody2D

@export var fuerza_empuje: float = 100.0 
@onready var anim_gun: AnimationPlayer = $Anim_gun

@onready var ammu_pistol_sprite: AnimatedSprite2D = $ammu_Pistol_Sprite
@onready var expolocion: AnimatedSprite2D = $Expolocion
@onready var explocion_light: PointLight2D = $Explocion_light

var Fuerza_Launch: float = 800
var distancia_separacion: float = 65.0 # La distancia para que no se solapen

func _ready() -> void:
	linear_damp = 4.0 
	angular_damp = 3.0 
	
	var player = get_tree().current_scene.get_node("Player")
	
	# 1. Calculamos la dirección hacia el mouse desde el jugador
	var mouse_pos = get_global_mouse_position()
	var direccion_al_mouse = (mouse_pos - player.global_position).normalized()
	
	# 2. Posicionamos el objeto alejado del jugador en esa dirección
	global_position = player.global_position + (direccion_al_mouse * distancia_separacion)
	
	Launch()
	Explocion()
	
func Launch():
	var mouse_pos = get_global_mouse_position()
	# Ahora la dirección se calcula desde su nueva posición ya separada
	var direccion = (mouse_pos - global_position).normalized()
	
	apply_central_impulse(direccion * Fuerza_Launch)

func Explocion():
	ammu_pistol_sprite.play("default")
	await get_tree().create_timer(0.8).timeout
	ammu_pistol_sprite.visible = false
	expolocion.visible = true
	explocion_light.enabled = true
	expolocion.play("default")
	await get_tree().create_timer(0.5).timeout
	# ACA IRIA SISTEME DE DAÑO YU COLICION 
	
	queue_free()
	


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		# Empuje corregido para que afecte al RigidBody al chocar
		var direccion = (global_position - body.global_position).normalized()
		apply_central_impulse(direccion * fuerza_empuje)
		anim_gun.play("Empuje")
