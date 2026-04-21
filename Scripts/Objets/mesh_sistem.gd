extends Node2D

# body nodes
@onready var ruka_body: AnimatedSprite2D = $Body/Ruka_Body
@onready var ruka_attack: AnimatedSprite2D = $Body/Ruka_Attack
@onready var ruka_damage: Sprite2D = $Body/Ruka_Damage

# Legs Nodes
@onready var idle_legs: Sprite2D = $Legs/Idle_Legs
@onready var walk_legs: AnimatedSprite2D = $Legs/Walk_Legs

@onready var legs: Node2D = $Legs
@onready var body: Node2D = $Body

@onready var anim_player: AnimationPlayer = $Anim_Player

const ATTACK_ANIM_NAME: StringName = &"attack"

var In_Animation_Stun : bool = false
## Idle | Walk | Attack | Take_Damage — evita reiniciar la animación de ataque en cada frame.
var _visual_state: String = ""
var _attack_prev_frame: int = -1

func reset_attack_loop_tracking() -> void:
	_attack_prev_frame = -1


func is_attack_sprite_showing() -> bool:
	return ruka_attack.visible


func get_attack_frame_index() -> int:
	return ruka_attack.frame


func get_attack_frame_total() -> int:
	if ruka_attack.sprite_frames == null:
		return 0
	return ruka_attack.sprite_frames.get_frame_count(ATTACK_ANIM_NAME)


## Devuelve true si el fotograma del sprite de ataque acaba de dar una vuelta completa (último → primero).
func tick_attack_loop_wrapped() -> bool:
	if not ruka_attack.visible:
		return false
	var f: int = ruka_attack.frame
	var wrapped: bool = _attack_prev_frame >= 0 and f < _attack_prev_frame
	_attack_prev_frame = f
	return wrapped


func Change_State(State: String, attack_use_walk_legs: bool = false) -> void:
	if State == "Idle" and not In_Animation_Stun:
		_visual_state = "Idle"
		reset_attack_loop_tracking()
		Reset_Sprites_Ant_avitive(body, ruka_body)
		Reset_Sprites_Ant_avitive(legs, idle_legs)
		ruka_body.play("default")
		anim_player.stop()

	elif State == "Walk" and not In_Animation_Stun:
		_visual_state = "Walk"
		reset_attack_loop_tracking()
		Reset_Sprites_Ant_avitive(body, ruka_body)
		Reset_Sprites_Ant_avitive(legs, walk_legs)
		ruka_body.play("default")
		walk_legs.play("default")
		anim_player.play("Walk")

	elif State == "Attack" and not In_Animation_Stun:
		var entering_attack := _visual_state != "Attack"
		_visual_state = "Attack"
		Reset_Sprites_Ant_avitive(body, ruka_attack)
		if attack_use_walk_legs:
			Reset_Sprites_Ant_avitive(legs, walk_legs)
			walk_legs.play("default")
			anim_player.play("Walk")
		else:
			Reset_Sprites_Ant_avitive(legs, idle_legs)
			anim_player.stop()
		if entering_attack:
			ruka_attack.play("attack")

	elif State == "Take_Damage":
		_visual_state = "Take_Damage"
		In_Animation_Stun = true
		Reset_Sprites_Ant_avitive(body, ruka_damage)
		for s in legs.get_children():
			s.visible = false
		await get_tree().create_timer(0.6).timeout
		In_Animation_Stun = false

func Reset_Sprites_Ant_avitive(list_node: Node2D, node_pick: Node):
	for child in list_node.get_children():
		if child != node_pick:
			child.visible = false
	
	# Aseguramos que el pick quede visible
	node_pick.visible = true
