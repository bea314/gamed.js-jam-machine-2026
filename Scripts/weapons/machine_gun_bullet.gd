extends "res://Scripts/weapons/bullet.gd"

func _ready() -> void:
	# `direction` is already set on the same frame, before the node enters the tree.
	if has_node("Vis") and $Vis is CanvasItem:
		$Vis.rotation = direction.angle()
	super._ready()
