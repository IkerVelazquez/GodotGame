extends Node2D

@onready var player_spawn_point = $PlayerSpawnPoint
@onready var enemy_spawn_point = $EnemySpawnPoint
@onready var characters_container = $Characters

var player_instance: Node2D = null
var enemy_instance: Node2D = null

# Precargar las escenas (ajusta las rutas según tu proyecto)
@onready var player_scene = preload("res://Characters/james_axe_1.tscn")  # Tu personaje existente
@onready var enemy_scene = preload("res://Characters/zombie_enemy.tscn")  # El enemigo modificado

func _ready() -> void:
	$ColorRect.position = Vector2(-1920,-1080)
	GlobalData.mouse_disable = false
	
	GameEvents.max_party_size = 1  # Solo un jugador
	
	# CONECTAR SEÑAL
	GameEvents.turn_changed.connect(_on_turn_changed)
	
	# SPAWNEAR PERSONAJES AUTOMÁTICAMENTE
	spawn_characters()
	
	await get_tree().create_timer(0.5).timeout
	$ColorRect.position = Vector2(-982,-256)
# Función para spawnear todos los personajes
func spawn_characters():
	# Spawnear jugador
	player_instance = spawn_player(player_scene)
	
	# Spawnear enemigo
	enemy_instance = spawn_enemy(enemy_scene)
	

# Spawnear jugador en posición fija
func spawn_player(character_scene: PackedScene) -> Node2D:
	if character_scene == null:
		return null
	
	var player = character_scene.instantiate()
	characters_container.add_child(player)
	player.global_position = player_spawn_point.global_position
	player.add_to_group("Player")
	
	# OBTENER EL TIPO DEL PERSONAJE Y CONFIGURAR EL PARTY
	var player_type = _get_player_type(player)
	_setup_party(player_type)
	return player

# NUEVA FUNCIÓN: Obtener el tipo del personaje automáticamente
func _get_player_type(player_node: Node) -> String:
	# Método 1: Si el personaje tiene una propiedad "type"
	if player_node.has_method("get_type"):
		return player_node.get_type()
	elif "type" in player_node:
		return player_node.type
	
	# Método 2: Buscar propiedad exportada
	for property in player_node.get_property_list():
		if property.name == "type" and property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			return player_node.get("type")
	
	# Método 3: Usar el nombre del script o nodo como fallback
	var script_path = player_node.get_script().resource_path if player_node.get_script() else ""
	if "ninja" in script_path.to_lower() or "ninja" in player_node.name.to_lower():
		return "ninja"
	elif "melee" in script_path.to_lower() or "melee" in player_node.name.to_lower():
		return "melee"
	elif "ranger" in script_path.to_lower() or "ranger" in player_node.name.to_lower():
		return "ranger"
	else:
		# Método 4: Usar el nombre de la clase
		return player_node.get_class()

# NUEVA FUNCIÓN: Configurar el party con el tipo correcto
func _setup_party(player_type: String):
	GameEvents.active_party = [player_type]
	GameEvents.update_turn_order()

# Spawnear enemigo en posición fija
func spawn_enemy(enemy_scene: PackedScene) -> Node2D:
	if enemy_scene == null:
		return null
	
	var enemy = enemy_scene.instantiate()
	characters_container.add_child(enemy)
	enemy.global_position = enemy_spawn_point.global_position
	enemy.add_to_group("Enemy")
	
	return enemy

# Obtener la posición REAL del jugador
func get_player_position() -> Vector2:
	if player_instance and is_instance_valid(player_instance):
		return player_instance.global_position
	return Vector2.ZERO

# Verificar si el jugador está vivo
func is_player_alive() -> bool:
	return player_instance != null and is_instance_valid(player_instance)

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
