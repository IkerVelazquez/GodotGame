extends CharacterBody2D

var anim 
var type = "paladin"
var original_position: Vector2
var is_dashing := false
var is_attacking := false
var enemy_node: Node2D = null
var current_mp: float = 0.0
var max_mp: float = 100.0
var special_available: bool = false
@export var health: int = 100
@export var max_health: int = 100

@export var portrait: Texture2D
@export var stomp_duration := 0.2
@export var attack_duration := 1.0
@export var return_duration := 1.0
@export var attack_velocity := 0.45
@export var stomp_jump_height: float = 100.0 
@export var stop_distance: float = 50.0  # ← NUEVO: distancia de parada

@onready var jump_effect_scene = preload("res://Scenes/jump_effect.tscn")  
@onready var land_effect_scene = preload("res://Scenes/land_effect.tscn")  
@onready var tween := get_tree().create_tween()

func _ready() -> void:
	$Control/HP.max_value = max_health
	$Control/HP.value = health
	
	$Control/MP.max_value = max_mp
	$Control/MP.value = current_mp
	
	anim = $player_animations
	if type in GameEvents.turn_order:
		print("Mi turno es:", GameEvents.turn_order[type])
	
func _physics_process(delta: float) -> void:
	if GameEvents.is_player_turn and type in GameEvents.turn_order:
		if GameEvents.turn_order[type] == GameEvents.current_turn:
			$Control.visible = true
			if GameEvents.atack == true:
				$player_animations.play("Attack")
				GameEvents.atack = false
		else:
			$Control.visible = false
	else:
		$Control.visible = false  # Ocultar durante turno enemigo
			
	if is_dashing:
		$Control.visible = false
	elif is_attacking:
		$Control.visible = false
		
func find_enemy():
	if get_tree().has_group("Enemy"):
		var enemies = get_tree().get_nodes_in_group("Enemy")
		if enemies.size() > 0:
			return enemies[0]
	return null
	
func start_attack() -> void:
	var enemy = find_enemy()
	if enemy == null:
		push_warning("No se encontró enemigo para hacer dash.")
		return
		
	original_position = global_position
	var target_pos = enemy.global_position
	is_attacking = true
	
	$player_animations.play("Walk")
	
	var tween = get_tree().create_tween()

	# Dash hacia el enemigo
	tween.tween_property(self, "global_position", target_pos, attack_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Reproducir Special al llegar al enemigo
	tween.tween_callback(Callable(self, "_play_attack"))

	# Intervalo para simular ataque
	tween.tween_interval(attack_velocity)

	# Girar y volver al original
	tween.tween_callback(Callable(self, "_flip_back"))
	tween.tween_property(self, "global_position", original_position, return_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Al llegar al original, reproducir Idle
	tween.tween_callback(Callable(self, "_play_idle"))
	
	tween.finished.connect(_on_attack_finished)
	
	
func dash_to_enemy() -> void:
	if is_dashing:
		return

	var enemy = find_enemy()
	if enemy == null:
		push_warning("No se encontró enemigo para hacer stomp.")
		return
	
	if special_available:
		print("💥 ¡USANDO ATAQUE ESPECIAL!")
		special_available = false
		$Control/Especial.visible = false
		$Control/MP.modulate = Color.WHITE  # Restaurar color
		
		# GASTAR TODO EL MP
		current_mp = 0
		$Control/MP.value = current_mp
		
	is_dashing = true
	original_position = global_position
	var target_pos = enemy.global_position
	
	$player_animations.play("Special")
	$Stomp_sound.play()
	$Weapon_sound.play()
	
	_create_jump_effect(original_position)
	
	# Calcular la trayectoria del salto
	var jump_height = stomp_jump_height
	var original_y = global_position.y
	
	var tween = get_tree().create_tween()
	
	# Animación de salto completa en una sola secuencia
	# Primera mitad: subir al punto más alto
	var mid_point = Vector2(
		(original_position.x + target_pos.x) * 0.5,  # Punto medio en X
		original_y - jump_height  # Punto más alto en Y
	)
	
	tween.tween_property(self, "global_position", mid_point, stomp_duration * 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Segunda mitad: bajar exactamente al enemigo
	tween.tween_property(self, "global_position", target_pos, stomp_duration * 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	
	tween.finished.connect(_on_stomp_landed.bind(target_pos))
	
	

func _create_jump_effect(position: Vector2):
	var jump_effect = jump_effect_scene.instantiate()
	get_parent().add_child(jump_effect)  # Añadir al nivel, no al personaje
	jump_effect.global_position = position
	jump_effect.play("Jump_smoke")
	
	
	# Opcional: eliminar el efecto después de que termine la animación
	jump_effect.animation_finished.connect(_on_effect_animation_finished.bind(jump_effect))

func _create_land_effect(position: Vector2):
	var land_effect = land_effect_scene.instantiate()
	get_parent().add_child(land_effect)  # Añadir al nivel, no al personaje
	# Ajustar la posición un poco más abajo
	var offset_y = 30  # Ajusta este valor según necesites
	var adjusted_position = Vector2(position.x, position.y + offset_y)
	
	land_effect.global_position = adjusted_position
	land_effect.play("Land_smoke")
	land_effect.animation_finished.connect(_on_effect_animation_finished.bind(land_effect))

func take_damage(damage: int):
	var final_damage = damage * GameEvents.get_defense_multiplier()
	health -= int(final_damage)
	print(type, " recibe ", int(final_damage), " de daño (", damage, " base)")
	
	var mp_gain = final_damage * 0.5  # 50% del daño se convierte en MP
	current_mp = min(current_mp + mp_gain, max_mp)
	$Control/MP.value = current_mp
	
	if current_mp >= max_mp and not special_available:
		special_available = true
		$Control/SpecialButton.visible = true
		print("✨ ¡ATAQUE ESPECIAL DISPONIBLE! ✨")
		# Efecto visual de que el especial está listo
		$Control/MP.modulate = Color(1, 1, 0)  # Brillo dorado
		
	#show_damage_popup(int(final_damage))
	$Control/HP.max_value = max_health
	$Control/HP.value = health
	# Efecto visual de daño (opcional)
	_start_damage_effect()
	$player_animations.play("Hurt")
	if health <= 0:
		die()

func _start_damage_effect():
	# Efecto visual simple - parpadeo
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func die():
	print(type, " ha sido derrotado!")
	# Liberar posición de spawn
	var test_node = get_node_or_null("/root/Test/Tests")
	if test_node and test_node.has_method("free_spawn_position"):
		test_node.free_spawn_position(self)
	
	# Eliminar del grupo Player
	remove_from_group("Player")
	
	# Eliminar del juego
	queue_free()
	
	
func _on_effect_animation_finished(effect_node):
	effect_node.queue_free()
	
func _on_stomp_landed(target_pos: Vector2):
	# Pausa en el enemigo
	GameEvents.request_camera_shake(11,0.3)
	var pause_tween = get_tree().create_tween()
	pause_tween.tween_interval(0.2)
	
	# Regreso a posición original
	pause_tween.tween_callback(Callable(self, "_play_walk_return"))
	pause_tween.tween_property(self, "global_position", original_position, return_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	pause_tween.tween_callback(Callable(self, "_play_idle"))
	pause_tween.finished.connect(_on_dash_finished)
	_create_land_effect(target_pos)

# ----------------------------------------
func _play_attack():
	$player_animations.play("Attack")

func _play_walk_return():
	$player_animations.scale.x = -1 # gira de vuelta
	$player_animations.play("Walk")

func _flip_back():
	$player_animations.play("Return")

func _play_idle():
	$player_animations.scale.x = 1 # gira de vuelta
	$player_animations.play("Idle")

func _on_dash_finished() -> void:
	is_dashing = false
	print("Stomp completado")
	GameEvents.next_turn()
	if GameEvents.current_turn > GameEvents.turn_order.size():
		GameEvents.current_turn = 1  # reinicia el ciclo de turnos
	
func _on_attack_finished() -> void:
	is_attacking = false
	print("Ataque completado")
	GameEvents.next_turn()
	if GameEvents.current_turn > GameEvents.turn_order.size():
		GameEvents.current_turn = 1  # reinicia el ciclo de turnos
	
func _on_player_animations_animation_finished() -> void:
	if GameEvents.current_turn > GameEvents.turn_order.size():
		GameEvents.current_turn = 1  # reinicia el ciclo de turnos
		
	if anim.animation == "Attack":
		$Effects.visible = false
		GameEvents.request_camera_shake(3,0.3)
		
	elif anim.animation == "Hurt":
		$player_animations.play("Idle")
		
		
func _on_player_animations_frame_changed() -> void:
	if $player_animations.animation == "Attack" and $player_animations.frame == 2:
		$Effects.visible = true
		$Effects.play("Explosion_hit")
		
	elif $player_animations.animation == "Special" and $player_animations.frame == 2:
		$Effects.visible = true
		$Effects.play("Explosion_hit")
