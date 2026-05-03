extends Node

@onready var base_melody: AudioStreamPlayer = $Base_Melody
# Asumo que 'melody_random' es el AudioStreamPlayer que tiene el AudioStreamSynchronizer
@onready var melody_random: AudioStreamPlayer = $Melody_random

@export var boss_theme_stream: AudioStream
var boss_theme_player: AudioStreamPlayer
var _ambient_muted: bool = false

# Los preloads se mantienen igual
const MELODY_I = preload("uid://jvi8ud4uksfq")
const MELODY_II = preload("uid://d3xdsa042rh8n")
const MELODY_III = preload("uid://cm70gtycgq1gr")

var list_pistas : Array = [MELODY_I, MELODY_II, MELODY_III]

const AMBIENT_FADE_IN_SEC := 2.0
const AMBIENT_START_DB := -48.0

func _ready() -> void:
	# Configuración del Boss Theme
	boss_theme_player = AudioStreamPlayer.new()
	boss_theme_player.name = "BossTheme"
	boss_theme_player.bus = &"Music"
	if boss_theme_stream != null:
		boss_theme_player.stream = boss_theme_stream
	add_child(boss_theme_player)
	
	# Iniciamos la música
	start_synced_music()

func start_synced_music() -> void:
	if _ambient_muted:
		return
	base_melody.volume_db = AMBIENT_START_DB
	melody_random.volume_db = AMBIENT_START_DB
	base_melody.play()
	melody_random.stream = list_pistas.pick_random()
	melody_random.play()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_QUART)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(base_melody, "volume_db", 0.0, AMBIENT_FADE_IN_SEC)
	tw.tween_property(melody_random, "volume_db", 0.0, AMBIENT_FADE_IN_SEC)

# ESTA ES LA CLAVE:
# Conecta la señal 'finished' de melody_random
func _on_melody_random_finished() -> void:
	if _ambient_muted:
		return
	
	# Cambiamos el stream internamente. 
	# El AudioStreamSynchronizer se encargará de que la nueva pista 
	# entre en el tiempo exacto (fase) de la anterior.
	var nueva_pista = list_pistas.pick_random()
	
	# Evitamos repetir la misma pista dos veces seguidas (opcional pero recomendado)
	while nueva_pista == melody_random.stream:
		nueva_pista = list_pistas.pick_random()
		
	melody_random.stream = nueva_pista
	melody_random.play()

func set_ambient_muted(muted: bool) -> void:
	_ambient_muted = muted
	if muted:
		base_melody.stop()
		melody_random.stop()
	else:
		start_synced_music()

func play_boss_theme() -> void:
	if boss_theme_player and boss_theme_player.stream:
		if not boss_theme_player.playing:
			boss_theme_player.play()
