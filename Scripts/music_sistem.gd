extends Node

@onready var base_melody: AudioStreamPlayer = $Base_Melody
@onready var melody_random: AudioStreamPlayer = $Melody_random
@export var boss_theme_stream: AudioStream
var boss_theme_player: AudioStreamPlayer
var _ambient_muted: bool = false

const MELODY_I = preload("uid://jvi8ud4uksfq")
const MELODY_II = preload("uid://d3xdsa042rh8n")
const MELODY_III = preload("uid://cm70gtycgq1gr")

var list_pistas : Array = [MELODY_I,MELODY_II,MELODY_III]

func _ready() -> void:
	boss_theme_player = AudioStreamPlayer.new()
	boss_theme_player.name = "BossTheme"
	boss_theme_player.bus = &"Music"
	if boss_theme_stream != null:
		boss_theme_player.stream = boss_theme_stream
	add_child(boss_theme_player)
	base_melody.play()
	melody_random.play()

func _on_melody_random_finished() -> void:
	if _ambient_muted:
		return
	melody_random.stream = list_pistas.pick_random()
	melody_random.play()


func set_ambient_muted(muted: bool) -> void:
	_ambient_muted = muted
	if muted:
		base_melody.stop()
		melody_random.stop()
		return
	if not base_melody.playing:
		base_melody.play()
	if not melody_random.playing:
		melody_random.stream = list_pistas.pick_random()
		melody_random.play()


func play_boss_theme() -> void:
	if boss_theme_player == null:
		return
	if boss_theme_player.stream == null:
		return
	if not boss_theme_player.playing:
		boss_theme_player.play()
