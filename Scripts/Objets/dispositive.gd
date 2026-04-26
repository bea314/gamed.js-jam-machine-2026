extends StaticBody2D

var HP : int = 20

# Referencias nodods
@onready var anim_disp: AnimationPlayer = $ANIM_Disp

func take_damage(amount: int):
	if HP >= 0:
		HP -= amount
		Comp_HP()
		anim_disp.play("take_damage")
		
func Comp_HP(): # COMPORBAR VIDA
	if HP <= 0:
		queue_free()
