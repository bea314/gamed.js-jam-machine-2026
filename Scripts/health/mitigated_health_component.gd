extends HealthComponent
class_name MitigatedHealthComponent

@export var defense_flat: int = 4
@export var defense_multiplier: float = 0.6


func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	var reduced := maxi(amount - defense_flat, 1)
	var final_damage := maxi(int(round(reduced * defense_multiplier)), 1)
	super.take_damage(final_damage)
