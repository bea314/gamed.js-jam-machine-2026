extends Control

## Solo intercambio visual. El clic real lo recibe $ClickArea (tamaño = este Control).
@export var texture_idle: Texture2D
@export var texture_hover: Texture2D

@onready var _graphic: TextureRect = $Graphic
@onready var _hit: Button = $ClickArea


func _ready() -> void:
	if texture_idle:
		_graphic.texture = texture_idle
	_hit.mouse_entered.connect(_on_hover_in)
	_hit.mouse_exited.connect(_on_hover_out)


func _on_hover_in() -> void:
	if texture_hover:
		_graphic.texture = texture_hover


func _on_hover_out() -> void:
	if texture_idle:
		_graphic.texture = texture_idle
