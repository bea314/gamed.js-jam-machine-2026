extends Node2D

const INTRO_PAG_1 = preload("uid://r4nswq7b661r")
const INTRO_PAG_2 = preload("uid://bg7fpgsk2k6jm")
const INTRO_PAG_3 = preload("uid://bgb73yfpr74g2")
const INTRO_PAG_4 = preload("uid://ne2bwynloqb1")
const INTRO_PAG_5 = preload("uid://bsoptid5horiw")
const INTRO_PAG_6 = preload("uid://cj2y04ckwuhcn")
const INTRO_PAG_8 = preload("uid://bfptnybjrssxe")
const INTRO_PAG_9 = preload("uid://bflqhvqnfgme6")
const INTRO_PAG_10 = preload("uid://jkhma5i5rn7e")
const INTRO_PAG_11 = preload("uid://d06i01kceuc14")
const INTRO_PAG_12 = preload("uid://csesn7mjhnwr5")
const INTRO_PAG_13 = preload("uid://cc3ivci0rk4pa")
const INTRO_PAG_14 = preload("uid://dof6sjl5oqxjp")
const INTRO_PAG_15 = preload("uid://blr8djkhv827t")


@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var fade: AnimationPlayer = $fade/fade

func _ready() -> void:
	sprite_2d.texture = INTRO_PAG_1
	await get_tree().create_timer(6.0).timeout
	sprite_2d.texture = INTRO_PAG_2
	await get_tree().create_timer(6.0).timeout
	sprite_2d.texture = INTRO_PAG_3
	await get_tree().create_timer(8.0).timeout
	sprite_2d.texture = INTRO_PAG_4
	await get_tree().create_timer(2.0).timeout
	sprite_2d.texture = INTRO_PAG_5
	await get_tree().create_timer(2.0).timeout
	sprite_2d.texture = INTRO_PAG_6
	await get_tree().create_timer(6.0).timeout
	sprite_2d.texture = INTRO_PAG_8
	await get_tree().create_timer(9.0).timeout
	sprite_2d.texture = INTRO_PAG_9
	await get_tree().create_timer(7.5).timeout
	sprite_2d.texture = INTRO_PAG_10
	await get_tree().create_timer(1.2).timeout
	sprite_2d.texture = INTRO_PAG_11
	await get_tree().create_timer(1.2).timeout
	sprite_2d.texture = INTRO_PAG_12
	await get_tree().create_timer(1.2).timeout
	sprite_2d.texture = INTRO_PAG_13
	await get_tree().create_timer(1.2).timeout
	sprite_2d.texture = INTRO_PAG_14
	await get_tree().create_timer(1.2).timeout
	sprite_2d.texture = INTRO_PAG_15
	await get_tree().create_timer(3).timeout
	fade.play("new_animation")
	await get_tree().create_timer(1).timeout
	
