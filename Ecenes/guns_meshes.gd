extends Node2D

@onready var weapon_manager: WeaponManager = $"../WeaponManager"

@onready var shot_gun: Sprite2D = $Shot_Gun
@onready var revolver: Sprite2D = $Revolver

func change_MeshGun(num_gun : int):
	if num_gun == 0:
		pass
	elif num_gun == 1:
		revolver.visible = true
		shot_gun.visible = false
	elif num_gun == 2:
		shot_gun.visible = true
		revolver.visible = false
	elif num_gun == 3:
		pass
