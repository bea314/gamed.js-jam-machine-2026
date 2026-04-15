extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal damage_taken(amount: int)
signal died()

@export var max_health: int = 100
var current_health: int


func _ready() -> void:
	current_health = max_health
	_emit_health_changed()


func take_damage(amount: int) -> void:
	if amount <= 0:
		return

	var before: int = current_health
	current_health = maxi(current_health - amount, 0)
	var applied: int = before - current_health
	_emit_health_changed()
	if applied > 0:
		damage_taken.emit(applied)

	if current_health == 0:
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0:
		return

	current_health = mini(current_health + amount, max_health)
	_emit_health_changed()


func _emit_health_changed() -> void:
	health_changed.emit(current_health, max_health)
