# enemy_melee.gd - VERSIÓN DEFINITIVA
extends CharacterBody2D

var health: int = 100
var attack_power: int = 100
var is_attacking: bool = false
var original_position: Vector2

@export var attack_duration: float = 2.0
@export var return_duration: float = 1.5
@export var stop_distance: float = 50.0

func _ready():
	GameEvents.add_enemy(self)
	original_position = global_position
	$Area_to_attack/CollisionShape2D.disabled = true

func start_enemy_turn():
	if is_attacking:
		return
	attack_all_players()

func attack_all_players():
	is_attacking = true
	
	# USAR LA INFORMACIÓN REAL que encontramos
	var occupied_spawn_positions = _get_real_occupied_spawn_positions()
	
	if occupied_spawn_positions.size() > 0:
		_perform_position_attack(occupied_spawn_positions, 0)
	else:
		finish_turn()

# FUNCIÓN MEJORADA: Usar la información real del characters_container
func _get_real_occupied_spawn_positions() -> Array:
	var occupied_positions = []
	
	# Acceder directamente al characters_container que SÍ funciona
	var characters_node = get_node_or_null("../characters")
	if characters_node:
		var children = characters_node.get_children()
		
		# Para cada personaje, encontrar en qué spawn point está
		for character in children:
			if is_instance_valid(character) and character is CharacterBody2D:
				var character_pos = character.global_position
				var spawn_point_index = _find_spawn_point_for_position(character_pos)
				
				if spawn_point_index != -1:
					var spawn_pos = _get_spawn_position_by_index(spawn_point_index)
					occupied_positions.append(spawn_pos)
					print("   ✅ ", character.name, " en Spawn Point ", spawn_point_index + 1, " - ", spawn_pos)
				else:
					print("   ⚠️  ", character.name, " no está en un spawn point conocido")
		
		# Eliminar duplicados (por si hay múltiples personajes en el mismo spawn)
		occupied_positions = _remove_duplicate_positions(occupied_positions)
	else:
		print("❌ No se pudo acceder a characters")
	
	return occupied_positions

# Encontrar qué spawn point corresponde a una posición
func _find_spawn_point_for_position(position: Vector2) -> int:
	var spawn_positions = [
		Vector2(569.0, 400.0),  # SpawnPoint1
		Vector2(708.0, 465.0),  # SpawnPoint2  
		Vector2(615.0, 544.0)   # SpawnPoint3
	]
	
	for i in range(spawn_positions.size()):
		var spawn_pos = spawn_positions[i]
		var distance = position.distance_to(spawn_pos)
		if distance < 50.0:  # Margen de 50 píxeles
			return i
	
	return -1

# Obtener la posición de un spawn point por índice
func _get_spawn_position_by_index(index: int) -> Vector2:
	var spawn_positions = [
		Vector2(569.0, 400.0),  # SpawnPoint1
		Vector2(708.0, 465.0),  # SpawnPoint2  
		Vector2(615.0, 544.0)   # SpawnPoint3
	]
	
	if index >= 0 and index < spawn_positions.size():
		return spawn_positions[index]
	else:
		return Vector2.ZERO

# Eliminar posiciones duplicadas
func _remove_duplicate_positions(positions: Array) -> Array:
	var unique_positions = []
	for pos in positions:
		var is_duplicate = false
		for unique_pos in unique_positions:
			if pos.distance_to(unique_pos) < 10.0:  # Margen pequeño
				is_duplicate = true
				break
		if not is_duplicate:
			unique_positions.append(pos)
	return unique_positions

func _calculate_stop_position(current_pos: Vector2, target_pos: Vector2) -> Vector2:
	var direction = (target_pos - current_pos).normalized()
	var stop_pos = target_pos - (direction * stop_distance)
	return stop_pos

func _perform_position_attack(positions: Array, index: int):
	if index >= positions.size():
		finish_turn()
		return
	
	var target_pos = positions[index]
	var stop_pos = _calculate_stop_position(global_position, target_pos)
	
	
	$enemy_animations.play("Walk")
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", stop_pos, attack_duration * 0.6)
	tween.tween_callback(Callable(self, "_start_attack_phase").bind(target_pos))
	tween.tween_interval(0.9)
	tween.tween_callback(Callable(self, "_start_return_phase"))
	tween.tween_property(self, "global_position", original_position, return_duration)
	tween.tween_callback(Callable(self, "_next_position_attack").bind(positions, index + 1))

func _start_attack_phase(target_pos: Vector2):
	$enemy_animations.play("Attack")

func _start_return_phase():
	$enemy_animations.play("Return")
	$Area_to_attack/CollisionShape2D.disabled = true
	$enemy_animations.scale = Vector2(1.0, 1.0)

func _next_position_attack(positions: Array, next_index: int):
	if next_index < positions.size():
		var pause_tween = get_tree().create_tween()
		pause_tween.tween_interval(0.5)
		$enemy_animations.play("Idle")
		pause_tween.tween_callback(Callable(self, "_perform_position_attack").bind(positions, next_index))
	else:
		finish_turn()

func finish_turn():
	$enemy_animations.play("Idle")
	is_attacking = false
	GameEvents.next_turn()
	$Area_to_attack/CollisionShape2D.disabled = true

func take_damage(damage: int):
	health -= damage
	if health <= 0:
		die()

func die():
	GameEvents.remove_enemy(self)
	queue_free()

func _on_enemy_animations_frame_changed() -> void:
	if $enemy_animations.animation == "Attack" and $enemy_animations.frame == 2:
		GameEvents.request_camera_shake(2.0, 0.3)
		$Area_to_attack/CollisionShape2D.disabled = false

func _on_area_to_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(attack_power)
