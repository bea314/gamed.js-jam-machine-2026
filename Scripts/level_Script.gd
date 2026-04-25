extends Node

var en_pausa := false
var menu_pausa
var transicion := false   # evita doble ejecución
const MENU_PAUSE = preload("uid://bgxipalyvbmig")

func _input(event):
	if event.is_action_pressed("Esq") and not transicion:
		
		transicion = true      # bloquear este frame
		if not en_pausa:
			menu_pausa = MENU_PAUSE.instantiate()
			add_child(menu_pausa)
			get_tree().paused = true
		else:
			menu_pausa.queue_free()
			

		# desbloquear después de *dos frames* (necesario por pausa)
		await get_tree().process_frame
		await get_tree().process_frame
		transicion = false
