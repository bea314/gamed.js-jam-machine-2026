extends Control

@onready var options: Button = $CenterContainer/Buttons/Options
@onready var options_menu: CenterContainer = $Options

func _ready() -> void:
	options.connect("pressed", Callable(self,"Pressed_Options"))

# BUTTONS OPTIONS ======================
func Pressed_Options():
	pass
 
