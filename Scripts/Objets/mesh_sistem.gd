extends Node2D

signal death_presentation_finished

# body nodes
@onready var ruka_body: AnimatedSprite2D = $Body/Ruka_Body
@onready var ruka_attack: AnimatedSprite2D = $Body/Ruka_Attack
@onready var ruka_death: AnimatedSprite2D = $Body/Ruka_Death
@onready var ruka_damage: Sprite2D = $Body/Ruka_Damage

# Legs Nodes
@onready var idle_legs: Sprite2D = $Legs/Idle_Legs
@onready var walk_legs: AnimatedSprite2D = $Legs/Walk_Legs

@onready var legs: Node2D = $Legs
@onready var body: Node2D = $Body

@onready var anim_player: AnimationPlayer = $Anim_Player

const ATTACK_ANIM_NAME: StringName = &"attack"
const DEATH_ANIM_NAME: StringName = &"death"

var In_Animation_Stun : bool = false
## Idle | Walk | Attack | Take_Damage — evita reiniciar la animación de ataque en cada frame.
var _visual_state: String = ""
var _attack_prev_frame: int = -1
var _death_finish_emitted: bool = false

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


func _ready() -> void:
	if ruka_death:
		ruka_death.animation_finished.connect(_on_death_anim_finished)


func _on_death_anim_finished() -> void:
	_emit_death_presentation_if_needed()


func _emit_death_presentation_if_needed() -> void:
	if _death_finish_emitted:
		return
	if _visual_state != "Death" or not is_instance_valid(ruka_death) or not ruka_death.visible:
		return
	_death_finish_emitted = true
	death_presentation_finished.emit()


func _on_death_safety_timeout() -> void:
	_emit_death_presentation_if_needed()


## Devuelve true si el fotograma del sprite de ataque acaba de dar una vuelta completa (último → primero).
func tick_attack_loop_wrapped() -> bool:
	if not ruka_attack.visible:
		return false
	var f: int = ruka_attack.frame
	var wrapped: bool = _attack_prev_frame >= 0 and f < _attack_prev_frame
	_attack_prev_frame = f
	return wrapped


func Change_State(State: String, attack_use_walk_legs: bool = false) -> void:
	if State == "Idle" and not In_Animation_Stun and _visual_state != "Death":
		_visual_state = "Idle"
		reset_attack_loop_tracking()
		Reset_Sprites_Ant_avitive(body, ruka_body)
		Reset_Sprites_Ant_avitive(legs, idle_legs)
		ruka_body.play("default")
		anim_player.stop()

	elif State == "Walk" and not In_Animation_Stun and _visual_state != "Death":
		_visual_state = "Walk"
		reset_attack_loop_tracking()
		Reset_Sprites_Ant_avitive(body, ruka_body)
		Reset_Sprites_Ant_avitive(legs, walk_legs)
		ruka_body.play("default")
		walk_legs.play("default")
		anim_player.play("Walk")

	elif State == "Attack" and not In_Animation_Stun and _visual_state != "Death":
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

	elif State == "Death":
		var entering_death := _visual_state != "Death"
		_visual_state = "Death"
		In_Animation_Stun = true
		anim_player.stop()
		Reset_Sprites_Ant_avitive(body, ruka_death)
		for s in legs.get_children():
			s.visible = false
		_death_finish_emitted = false
		if not is_instance_valid(ruka_death) or ruka_death.sprite_frames == null:
			_emit_death_presentation_deferred()
		else:
			var nframes := ruka_death.sprite_frames.get_frame_count(DEATH_ANIM_NAME)
			if nframes == 0:
				_emit_death_presentation_deferred()
			else:
				if entering_death:
					ruka_death.play(DEATH_ANIM_NAME)
					# Respaldo por si `animation_finished` no se emite (comportamiento raro de motor).
					var dur: float = _estimate_death_duration_sec(ruka_death, nframes)
					get_tree().create_timer(dur + 0.2).timeout.connect(
						_on_death_safety_timeout, CONNECT_ONE_SHOT)

	elif State == "Take_Damage":
		_visual_state = "Take_Damage"
		In_Animation_Stun = true
		Reset_Sprites_Ant_avitive(body, ruka_damage)
		for s in legs.get_children():
			s.visible = false
		await get_tree().create_timer(0.6).timeout
		In_Animation_Stun = false

func _estimate_death_duration_sec(spr: AnimatedSprite2D, nframes: int) -> float:
	var sf: SpriteFrames = spr.sprite_frames
	if sf == null or nframes <= 0:
		return 0.0
	var fps: float = 10.0
	if sf.has_method("get_animation_speed"):
		fps = float(sf.get_animation_speed(DEATH_ANIM_NAME))
	if fps <= 0.0:
		fps = 10.0
	var t: float = float(nframes) / fps
	t /= maxf(spr.speed_scale, 0.01)
	return t


func _emit_death_presentation_deferred() -> void:
	call_deferred("_emit_death_presentation_immediate")


func _emit_death_presentation_immediate() -> void:
	if _death_finish_emitted:
		return
	_death_finish_emitted = true
	death_presentation_finished.emit()

func Reset_Sprites_Ant_avitive(list_node: Node2D, node_pick: Node):
	for child in list_node.get_children():
		if child != node_pick:
			child.visible = false
	
	# Aseguramos que el pick quede visible
	node_pick.visible = true
