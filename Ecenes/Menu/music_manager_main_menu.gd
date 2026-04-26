extends AudioStreamPlayer

var sync_res: AudioStreamSynchronized
var intro_dur: float = 1.9
var ya_cambio: bool = false

func _ready():
	sync_res = stream as AudioStreamSynchronized
	# Empezar con intro
	sync_res.set_sync_stream_volume(0, 0.0)
	sync_res.set_sync_stream_volume(1, -60.0)
	play()

func _process(_delta):
	if not ya_cambio:
		# Al llegar al final de la intro (1.9s)
		if get_playback_position() >= intro_dur:
			# Cambiar a la pista 2
			sync_res.set_sync_stream_volume(0, -60.0)
			sync_res.set_sync_stream_volume(1, 0.0)
			
			# Reiniciamos el reproductor para que la pista 2 
			# empiece desde su segundo 0 exactamente
			play(0.0) 
			
			ya_cambio = true
			# Al activar el loop en el archivo de audio desde la pestaña Importar,
			# Godot se encargará de repetir el bloque completo de 1m 1s.
