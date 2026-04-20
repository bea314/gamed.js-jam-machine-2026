extends Node2D

# --- CONFIGURACIÓN ---
@export var room_scene: PackedScene
@export var room_separation: Vector2 = Vector2(700, 400) 

# Referencia al nodo que tiene la lógica (ajusta si es necesario)
@onready var generator = $".."

var instantiated_rooms: Dictionary = {}

func _ready() -> void:
	generator.generate_dungeon()
	render_dungeon_visuals()

func render_dungeon_visuals() -> void:
	instantiated_rooms.clear()
	for child in get_children():
		if child.name != "DungeonGenerator":
			child.queue_free()
			
	# Aquí es donde obtenemos los datos
	var data = generator.dungeon_data
	
	# 1. Instanciar todas las habitaciones
	for coords in data.keys():
		var new_room = room_scene.instantiate()
		new_room.position = Vector2(coords.x * room_separation.x, coords.y * room_separation.y)
		
		add_child(new_room)
		instantiated_rooms[coords] = new_room

	if instantiated_rooms.has(Vector2i.ZERO):
		ActiveRoomService.set_active_room(instantiated_rooms[Vector2i.ZERO])

	# 2. Configurar puertas (Setup)
	for coords in instantiated_rooms.keys():
		var room_node = instantiated_rooms[coords]
	
		# 1. Calculamos el array de vecinos (Primer argumento)
		var neighbors = []
		if data.has(coords + Vector2i.UP):    neighbors.append("up")
		if data.has(coords + Vector2i.DOWN):  neighbors.append("down")
		if data.has(coords + Vector2i.LEFT):  neighbors.append("left")
		if data.has(coords + Vector2i.RIGHT): neighbors.append("right")
	
		# 2. Llamamos a la función con los DOS argumentos
		if room_node.has_method("setup"):
		# Le pasamos: 1. El array de strings, 2. El Vector2i de coordenadas
			room_node.setup(neighbors, coords)
