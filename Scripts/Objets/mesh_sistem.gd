extends Node2D

# body nodes
@onready var ruka_body: AnimatedSprite2D = $Body/Ruka_Body

# Legs Nodes
@onready var idle_legs: Sprite2D = $Legs/Idle_Legs
@onready var walk_legs: AnimatedSprite2D = $Legs/Walk_Legs

@onready var legs: Node2D = $Legs
@onready var body: Node2D = $Body

@onready var anim_player: AnimationPlayer = $Anim_Player


func Change_State(State : String):
	if State == "Idle":
		Reset_Sprites_Ant_avitive(body, ruka_body)
		Reset_Sprites_Ant_avitive(legs,idle_legs)
		ruka_body.play("default")
		anim_player.stop()
		
	elif State == "Walk":
		Reset_Sprites_Ant_avitive(body, ruka_body)
		Reset_Sprites_Ant_avitive(legs,walk_legs)
		ruka_body.play("default")
		walk_legs.play("default")
		anim_player.play("Walk")

func Reset_Sprites_Ant_avitive(list_node: Node2D, node_pick: Node):
	for child in list_node.get_children():
		if child != node_pick:
			child.visible = false
	
	# Aseguramos que el pick quede visible
	node_pick.visible = true
