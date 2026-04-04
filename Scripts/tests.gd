extends Node2D

@onready var spawn_points = $spawn_points.get_children()
@onready var characters_container = $characters

var occupied_spots: Array = []
var spawn_point_occupants: Dictionary = {}

	
func _process(delta: float) -> void:
	
	if GameEvents.continue_pressed:
		$Background.z_index = -10
		
func _ready() -> void:
	
	GameEvents.max_party_size = 3
	# NO llamar set_party aquí - se llamará automáticamente cuando agregues personajes
	occupied_spots.resize(spawn_points.size())
	occupied_spots.fill(false)
	
	# CONECTAR SEÑAL
	GameEvents.turn_changed.connect(_on_turn_changed)
	
	# DEBUG: Verificar estado inicial
	print("Estado inicial - Turno jugador: ", GameEvents.is_player_turn)
	print("Turno actual: ", GameEvents.current_turn)
	print("Turn order: ", GameEvents.turn_order)

func spawn_character(character_scene: PackedScene):
	# Verificar que la escena no sea null
	if character_scene == null:
		push_error("Error: character_scene es null - verifica las rutas de preload")
		return null
	
	# Busca el primer punto libre
	for i in range(spawn_points.size()):
		if not occupied_spots[i]:
			var character_instance = character_scene.instantiate()
			characters_container.add_child(character_instance)
			character_instance.global_position = spawn_points[i].global_position
			occupied_spots[i] = true
			spawn_point_occupants[i] = character_instance
			
			character_instance.add_to_group("Player")
			print("✅ Personaje spawnado en posición ", i)
			return character_instance
	
	push_warning("No hay posiciones libres para spawnear más personajes.")
	return null

#Liberar posición de spawn cuando se elimina un personaje
func free_spawn_position(character_node: Node):
	for i in range(spawn_points.size()):
		if occupied_spots[i]:
			# Verificar si este spawn point tiene el personaje que queremos eliminar
			if spawn_point_occupants.get(i) == character_node:
				occupied_spots[i] = false
				spawn_point_occupants.erase(i)  # ← NUEVO: Remover del registro
				print("✅ Posición de spawn ", i, " liberada")
				return
	push_warning("No se pudo encontrar la posición de spawn para liberar")

# En tu test scene script - AGREGAR ESTA FUNCIÓN
func get_occupied_spawn_positions() -> Array:
	var occupied_positions = []
	for i in range(spawn_points.size()):
		if occupied_spots[i]:
			# Verificar que el personaje aún existe y es válido
			var occupant = spawn_point_occupants.get(i)
			if occupant and is_instance_valid(occupant):
				occupied_positions.append(spawn_points[i].global_position)
				print("Spawn point ", i, " ocupado por: ", occupant.name)
			else:
				# Si el personaje murió, liberar el spawn
				occupied_spots[i] = false
				spawn_point_occupants.erase(i)
				print("Spawn point ", i, " liberado (personaje no válido)")
	return occupied_positions
	
func _on_turn_changed(is_player_turn: bool):
	if is_player_turn:
		print("--- TURNO DEL JUGADOR ACTIVADO ---")
		print("Turno actual del jugador: ", GameEvents.current_turn)
	else:
		print("--- TURNO DEL ENEMIGO ACTIVADO ---")

func _on_continue_pressed() -> void:
	visible = false
	GameEvents.continue_pressed = true
	
	# Reiniciar el sistema de turnos
	GameEvents.current_turn = 1
	GameEvents.is_player_turn = true
	print("=== JUEGO INICIADO ===")
	print("Turn order final: ", GameEvents.turn_order)
	print("Turno actual: ", GameEvents.current_turn)
	print("Active party: ", GameEvents.active_party)
