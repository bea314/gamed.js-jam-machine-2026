extends Node

@onready var base_melody: AudioStreamPlayer = $Base_Melody
@onready var melody_random: AudioStreamPlayer = $Melody_random

const MELODY_I = preload("uid://jvi8ud4uksfq")
const MELODY_II = preload("uid://d3xdsa042rh8n")
const MELODY_III = preload("uid://cm70gtycgq1gr")

var list_pistas : Array = [MELODY_I,MELODY_II,MELODY_III]

func _ready() -> void:
	base_melody.play()
	melody_random.play()

func _on_melody_random_finished() -> void:
	melody_random.stream = list_pistas.pick_random()
	melody_random.play()
