extends Node2D

@onready var player_spawn_point = $PlayerSpawnPoint
@onready var enemy_spawn_point = $EnemySpawnPoint
@onready var characters_container = $Characters
@onready var camera: Camera2D = $Camera2D  # ← Ahora es hija de esta escena
@onready var puppet_zombie: AnimatedSprite2D = $PuppetZombie

var original_camera_position: Vector2 = Vector2.ZERO
var player_instance: Node2D = null
var enemy_instance: Node2D = null

var shake_intensity: float = 0.0
var shake_duration: float = 0.0

# Precargar las escenas
@onready var player_scene = preload("res://Characters/james_axe_1.tscn")
@onready var enemy_scene = preload("res://Characters/zombie_enemy.tscn")

var first_duialogue = load("res://james_vs_zombies.dialogue")


@export var total_enemies: int = 3

var enemies_spawned: int = 0
var enemies_killed: int = 0

func _ready() -> void:
	# Configurar cámara como CURRENT
	if camera:
		camera.enabled = true
		camera.make_current()  # Forzar que sea la cámara activa
		original_camera_position = camera.position
		print("✅ Cámara configurada - Posición original: ", original_camera_position)
	
	# Conectar señales
	GameEvents.camera_shake.connect(_on_camera_shake_requested)
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.enemy_died.connect(_on_enemy_died)
	
	if not GlobalData.first_mision:
		DialogueManager.show_dialogue_balloon(first_duialogue, "start")
		$ColorRect.position = Vector2(-1920, -1080)
		$ColorRect/AnimationPlayer.play("fade_in")
		GlobalData.first_mision = false
		
	puppet_zombie.visible = false
	GlobalData.mouse_disable = false
	
	GameEvents.max_party_size = 1
	GameEvents.turn_changed.connect(_on_turn_changed)
	
	spawn_characters()
	
	await get_tree().create_timer(0.5).timeout
	$ColorRect.position = Vector2(-982, -256)

func _process(delta):
	if shake_duration > 0:
		shake_duration -= delta
		var shake_x = randf_range(-shake_intensity, shake_intensity)
		var shake_y = randf_range(-shake_intensity, shake_intensity)
		camera.position = original_camera_position + Vector2(shake_x, shake_y)
		
		if shake_duration <= 0:
			camera.position = original_camera_position

func _on_camera_shake_requested(intensity: float, duration: float):
	print("📷 SHAKE RECIBIDO - Intensidad: ", intensity, " Duración: ", duration)
	shake_intensity = intensity
	shake_duration = duration

# ... (resto de tu código existente sin cambios) ...
			
# Función para spawnear todos los personajes
func spawn_characters():
	# Spawnear jugador
	player_instance = spawn_player(player_scene)
	
	# Spawnear enemigo
	spawn_next_enemy()
	
func spawn_enemy_with_puppet():
	if enemies_spawned >= total_enemies:
		print("🎉 TODOS LOS ENEMIGOS DERROTADOS")
		_on_all_enemies_defeated()
		return

	enemies_spawned += 1

	print("🧟 Spawn enemigo ", enemies_spawned, "/", total_enemies)

	# Posición inicial fuera de pantalla (izquierda)
	puppet_zombie.global_position =  Vector2(
	enemy_spawn_point.global_position.x - 1500, # fuera de pantalla
	enemy_spawn_point.global_position.y
	)        # MISMA ALTURA
	puppet_zombie.visible = true
	puppet_zombie.play("default") # animación correr

	var tween = create_tween()

	# Mover hacia el punto
	tween.tween_property(
		puppet_zombie,
		"global_position",
		enemy_spawn_point.global_position,
		2.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Al llegar
	tween.tween_callback(Callable(self, "_on_puppet_arrived"))

func _on_puppet_arrived():
	print("🧟 Puppet llegó")

	puppet_zombie.stop()
	puppet_zombie.visible = false

	# Spawnear enemigo real
	var enemy = enemy_scene.instantiate()
	characters_container.add_child(enemy)
	enemy.global_position = enemy_spawn_point.global_position
	enemy.add_to_group("Enemy")
	GameEvents.next_turn()
	
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

func spawn_next_enemy():
	if enemies_spawned >= total_enemies:
		return
	
	var enemy = enemy_scene.instantiate()
	characters_container.add_child(enemy)
	enemy.global_position = enemy_spawn_point.global_position
	enemy.add_to_group("Enemy")
	
	enemies_spawned += 1
	
	print("👹 Enemigo generado: ", enemies_spawned, "/", total_enemies)
	
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

func _on_enemy_died():
	enemies_killed += 1
	
	print("💀 Enemigos eliminados: ", enemies_killed, "/", total_enemies)
	await get_tree().create_timer(1.0).timeout
	GameEvents.heal_player.emit()
	spawn_enemy_with_puppet()
	
	
func _on_all_enemies_defeated():
	print("🏆 NIVEL COMPLETADO")
	await get_tree().create_timer(2.0).timeout
	
	$ColorRect.position = Vector2(-1920,-1080)
	$ColorRect/AnimationPlayer.play("fade_out")
	
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Scenario/forest.tscn")

func _on_player_died():
	print("💀 PERDISTE")
	enemies_killed = 0
	enemies_spawned = 0
	$ColorRect.position = Vector2(-1920,-1080)
	$ColorRect/AnimationPlayer.play("fade_out")
	await get_tree().create_timer(2.0).timeout
	$ColorRect/AnimationPlayer.play("fade_in")
	await get_tree().create_timer(0.5).timeout
	$ColorRect.position = Vector2(-982,-256)
	get_tree().reload_current_scene()
