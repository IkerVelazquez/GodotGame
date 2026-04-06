extends CharacterBody2D

var anim 
var type = "melee"
var original_position: Vector2
var is_dashing := false
var is_attacking := false
var enemy_node: Node2D = null
var current_attack_damage: int = 0
var current_is_critical: bool = false
var current_mp: float = 0.0
var special_available: bool = false

@export var health: int = 100
@export var max_health: int = 100

@export var max_mp: float = 100.0

@export var portrait: Texture2D
@export var dash_duration := 0.2
@export var attack_duration := 1.0
@export var return_duration := 1.0
@export var attack_velocity := 1.0
@export var stop_distance: float = 50.0 
@export var base_attack_damage: int = 10

@export var balance_icon_sound: AudioStream
var audio_player: AudioStreamPlayer


@onready var tween := get_tree().create_tween()
@onready var jump_effect_scene = preload("res://Scenes/jump_effect.tscn")  
@onready var timing_bar = $TimingBar  # Asegúrate de instanciar la barra en tu escena del jugador
var is_in_timing_minigame: bool = false

@onready var damage_popup_scene = preload("res://Scenes/damage_popup.tscn")

@onready var stance_icons = {
	"OFFENSIVE": preload("res://Images/attack_icon.png"),  # Cambia la ruta
	"DEFENSIVE": preload("res://Images/defense_icon.png"),  # Cambia la ruta
	"BALANCED": preload("res://Images/balanced_icon.png")     # Cambia la ruta
}

func _ready() -> void:
	
	GameEvents.heal_player.connect(heal_full)
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	audio_player.stream = balance_icon_sound
	
	$Control/HP.max_value = max_health
	$Control/HP.value = health
	
	$Control/MP.max_value = max_mp
	$Control/MP.value = current_mp
	
	$Control/Especial.visible = false
	
	anim = $player_animations
	if type in GameEvents.turn_order:
		print("Mi turno es:", GameEvents.turn_order[type])
		
	setup_ui()
	update_stance_visuals()
		

func setup_ui():
	# Configurar botón de postura
	$Control2/StanceButton.pressed.connect(_change_stance)
	update_stance_ui()

func update_stance_ui():
	var icon = $Control2/StanceButton/HBoxContainer/StanceIcon
	var label = $Control2/StanceButton/HBoxContainer/StanceLabel
	
	match GameEvents.current_stance:
		GameEvents.Stance.OFFENSIVE:
			icon.texture = preload("res://Images/attack_icon.png")
			label.text = "Postura: OFENSIVA"
		GameEvents.Stance.DEFENSIVE:
			icon.texture = preload("res://Images/defense_icon.png")
			label.text = "Postura: DEFENSIVA"
		GameEvents.Stance.BALANCED:
			icon.texture = preload("res://Images/balanced_icon.png")
			label.text = "Postura: BALANCEADA"

func _change_stance():
	match GameEvents.current_stance:
		GameEvents.Stance.BALANCED:
			GameEvents.set_stance(GameEvents.Stance.OFFENSIVE)
		GameEvents.Stance.OFFENSIVE:
			GameEvents.set_stance(GameEvents.Stance.DEFENSIVE)
		GameEvents.Stance.DEFENSIVE:
			GameEvents.set_stance(GameEvents.Stance.BALANCED)
	
	update_stance_ui()
	update_stance_visuals()
	_create_stance_change_effect()
	
	

func get_stance_name(stance):
	match stance:
		GameEvents.Stance.OFFENSIVE: return "OFENSIVA"
		GameEvents.Stance.DEFENSIVE: return "DEFENSIVA"
		_: return "BALANCEADA"
	
func _create_stance_change_effect():
	# Efecto de partículas o animación simple
	var tween = create_tween()
	tween.tween_property($player_animations, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property($player_animations, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Sonido (si tienes)
	# $StanceChangeSound.play()
	
func _physics_process(delta: float) -> void:
	if is_in_timing_minigame:
		$Control.visible = false
		$Control2.visible = false
		return
		
	if GameEvents.is_player_turn and type in GameEvents.turn_order:
		if GameEvents.turn_order[type] == GameEvents.current_turn:
			$Control.visible = true
			$Control2.visible = true
			if GameEvents.atack == true:
				GameEvents.atack = false
		else:
			$Control.visible = false
			$Control2.visible = false
	else:
		$Control.visible = false  # Ocultar durante turno enemigo
		$Control2.visible = false
			
	if is_dashing:
		$Control.visible = false
		$Control2.visible = false
	elif is_attacking:
		$Control.visible = false
		$Control2.visible = false

func find_enemy():
	if get_tree().has_group("Enemy"):
		var enemies = get_tree().get_nodes_in_group("Enemy")
		if enemies.size() > 0:
			return enemies[0]
	return null

# NUEVA FUNCIÓN: Calcular posición de parada
func _calculate_stop_position(current_pos: Vector2, target_pos: Vector2) -> Vector2:
	var direction = (target_pos - current_pos).normalized()
	var stop_pos = target_pos - (direction * stop_distance)
	return stop_pos
	
func start_attack() -> void:
	var enemy = find_enemy()
	if enemy == null:
		push_warning("No se encontró enemigo para atacar.")
		return
		
	start_timing_minigame()

func heal_full():
	var heal_amount = max_health - health
	
	health = max_health
	$Control/HP.value = health
	
	# Mostrar popup de curación
	var popup = damage_popup_scene.instantiate()
	get_parent().add_child(popup)
	popup.global_position = global_position + Vector2(0, -50)
	
	popup.setup(heal_amount) # puedes modificar tu popup para que sea verde
	popup.start_animation()
	
	print("💚 Curado completamente: +", heal_amount)
	
# NUEVA FUNCIÓN: Minijuego de timing
func start_timing_minigame():
	is_in_timing_minigame = true
	GameEvents.start_timing_attack()
	
	if timing_bar.attack_completed.is_connected(_on_timing_attack_completed):
		timing_bar.attack_completed.disconnect(_on_timing_attack_completed)
	
	# CONECTAR señal
	timing_bar.attack_completed.connect(_on_timing_attack_completed)
	timing_bar.start_timing()
	
# NUEVA FUNCIÓN: Cuando se completa el timing
func _on_timing_attack_completed(accuracy: float):
	GameEvents.current_accuracy = accuracy
	
	var damage_multiplier = GameEvents.get_damage_multiplier()
	current_attack_damage = GameEvents.calculate_damage(base_attack_damage * damage_multiplier)
	
	# REDONDEAR correctamente
	current_attack_damage = int(round(current_attack_damage))
	
	# Determinar crítico basado en precisión
	current_is_critical = accuracy >= 0.7
	
	print("🎯 TIMING COMPLETADO:")
	print("   - Precisión: ", accuracy)
	print("   - Daño calculado y redondeado: ", current_attack_damage)
	
	timing_bar.attack_completed.disconnect(_on_timing_attack_completed)
	is_in_timing_minigame = false
	execute_attack_with_accuracy(current_is_critical)

# NUEVA FUNCIÓN: Ejecutar ataque con daño calculado
func execute_attack_with_accuracy(is_critical: bool = false):  # ← Recibir parámetro
	var enemy = find_enemy()
	if enemy == null:
		return
	
	# GUARDAR si es crítico para usarlo después
	current_is_critical = is_critical
	
	original_position = global_position
	var target_pos = enemy.global_position
	var stop_pos = _calculate_stop_position(global_position, target_pos)
	
	is_attacking = true
	
	print("🎯 Jugador atacando con precisión: ", GameEvents.current_accuracy, " - Crítico: ", is_critical)
	
	$player_animations.play("Walk")
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", stop_pos, attack_duration)
	tween.tween_callback(Callable(self, "_play_attack"))
	tween.tween_interval(attack_velocity)
	tween.tween_callback(Callable(self, "_flip_back"))
	tween.tween_property(self, "global_position", original_position, return_duration)
	tween.tween_callback(Callable(self, "_play_idle"))
	tween.finished.connect(_on_attack_finished)
	
func dash_to_enemy() -> void:
	if is_dashing:
		return

	var enemy = find_enemy()
	if enemy == null:
		push_warning("No se encontró enemigo para hacer dash.")
		return
		
	if special_available:
		print("💥 ¡USANDO ATAQUE ESPECIAL!")
		special_available = false
		$Control/Especial.visible = false
		$Control/MP.modulate = Color.WHITE  # Restaurar color
		
	
	is_dashing = true
	original_position = global_position
	var target_pos = enemy.global_position
	var stop_pos = _calculate_stop_position(global_position, target_pos)  # ← NUEVO
	
	
	$player_animations.play("Special")
	_create_dash_effect(original_position)
	
	var tween = get_tree().create_tween()

	# Dash hacia el enemigo (hasta la posición de parada)
	tween.tween_property(self, "global_position", stop_pos, dash_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Intervalo para simular ataque
	tween.tween_interval(0.2)

	# Girar y volver al original
	tween.tween_callback(Callable(self, "_flip_back"))
	tween.tween_property(self, "global_position", original_position, return_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Al llegar al original, reproducir Idle
	tween.tween_callback(Callable(self, "_play_idle"))

	# Fin del dash
	tween.finished.connect(_on_dash_finished)

func _create_dash_effect(position: Vector2):
	var jump_effect = jump_effect_scene.instantiate()
	get_parent().add_child(jump_effect)  # Añadir al nivel, no al personaje
	jump_effect.global_position = position
	jump_effect.play("Dash")
	
	# Opcional: eliminar el efecto después de que termine la animación
	jump_effect.animation_finished.connect(_on_effect_animation_finished.bind(jump_effect))

func take_damage(damage: int):
	# Calcular daño final según postura
	var final_damage = damage * GameEvents.get_defense_multiplier()
	health -= int(final_damage)
	
	var mp_gain = final_damage * 0.5  # 50% del daño se convierte en MP
	current_mp = min(current_mp + mp_gain, max_mp)
	$Control/MP.value = current_mp
	
	if current_mp >= max_mp and not special_available:
		special_available = true
		$Control/Especial.visible = true
		print("✨ ¡ATAQUE ESPECIAL DISPONIBLE! ✨")
		
	# Crear popup con el daño REAL
	var popup = damage_popup_scene.instantiate()
	get_parent().add_child(popup)
	popup.global_position = global_position + Vector2(0, -50)
	
	# Mostrar el número CORRECTO
	popup.setup(int(final_damage))
	popup.start_animation()
	
	print(type, " recibe ", int(final_damage), " de daño (", damage, " base)")
	$Control/HP.max_value = max_health
	$Control/HP.value = health
	$player_animations.play("Hurt")
	play_random_attack_sound()
	_start_damage_effect()
	await get_tree().create_timer(1.0).timeout
	if health <= 0:
		die()

func show_damage_popup(damage: int):
	var popup = damage_popup_scene.instantiate()
	
	# Añadir al nivel
	get_parent().add_child(popup)
	
	# Posicionar sobre el jugador
	popup.global_position = global_position + Vector2(0, -50)
	
	
	# Configurar y animar
	popup.setup(damage)
	popup.start_animation()
	
func _start_damage_effect():
	# Efecto visual simple - parpadeo
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	

func die():
	print(type, " ha sido derrotado!")
	$player_animations.play("Die")
	await $player_animations.animation_finished
	# Notificar a GameEvents que este personaje murió
	GameEvents.character_died(type)
	
	# Liberar posición de spawn
	var test_node = get_node_or_null("/root/Test/Tests")
	if test_node and test_node.has_method("free_spawn_position"):
		test_node.free_spawn_position(self)
	
	# Eliminar del grupo Player
	remove_from_group("Player")
	await get_tree().create_timer(1.0).timeout
	GameEvents.player_died.emit()
	queue_free()

func _on_effect_animation_finished(effect_node):
	effect_node.queue_free()
	
# ----------------------------------------
func _play_attack():
	$player_animations.play("Attack")

func _flip_back():
	$player_animations.scale.x = 1 # gira de vuelta
	$player_animations.play("Return")

func _play_idle():
	$player_animations.play("Idle")

func _on_dash_finished() -> void:
	is_dashing = false
	GameEvents.next_turn()
	if GameEvents.current_turn > GameEvents.turn_order.size():
		GameEvents.current_turn = 1  # reinicia el ciclo de turnos
		
	# GASTAR TODO EL MP
	current_mp = 0
	$Control/MP.value = current_mp
	$Control/Especial.visible = false
	
func _on_attack_finished() -> void:
	is_attacking = false
	GameEvents.next_turn()
	if GameEvents.current_turn > GameEvents.turn_order.size():
		GameEvents.current_turn = 1  # reinicia el ciclo de turnos
	
func _on_player_animations_animation_finished() -> void:
	if anim.animation == "Attack":
		$player_animations.play("Attack2")
	elif anim.animation == "Attack2":
		$player_animations.play("Attack3")
	elif anim.animation == "Hurt":
		$player_animations.play("Idle")
		
	if GameEvents.current_turn > GameEvents.turn_order.size():
		GameEvents.current_turn = 1  # reinicia el ciclo de turnos

func _on_player_animations_frame_changed() -> void:
	if $player_animations.animation == "Attack" and $player_animations.frame == 2:
		call_deferred("play_hit_effect")
		GameEvents.request_camera_shake(1,0.3)
		play_random_attack_sound()
		$Area_to_attack/CollisionShape2D.disabled = false
		var is_critical_now = current_attack_damage > base_attack_damage * 1.2
		apply_damage_with_accuracy(current_is_critical)
	elif $player_animations.animation == "Attack" and $player_animations.frame == 3:
		$Area_to_attack/CollisionShape2D.disabled = true
		
	if $player_animations.animation == "Attack2" and $player_animations.frame == 2:
		call_deferred("play_hit_effect")
		GameEvents.request_camera_shake(0.5, 0.2)
		$Area_to_attack/CollisionShape2D.disabled = false
	elif $player_animations.animation == "Attack2" and $player_animations.frame == 3:
		$Area_to_attack/CollisionShape2D.disabled = true
		
	if $player_animations.animation == "Attack3" and $player_animations.frame == 2:
		call_deferred("play_hit_effect")
		GameEvents.request_camera_shake(0.5, 0.2)
		$Area_to_attack/CollisionShape2D.disabled = false
	elif $player_animations.animation == "Attack3" and $player_animations.frame == 3:
		$Area_to_attack/CollisionShape2D.disabled = true
		
	if $player_animations.animation == "Special" and $player_animations.frame == 2:
		call_deferred("play_hit_effect")
		GameEvents.request_camera_shake(2,0.2)
		$Area_to_attack/CollisionShape2D.disabled = true

func apply_damage_with_accuracy(is_critical: bool = false):
	var enemy = find_enemy()
	if enemy and enemy.has_method("take_damage"):
		print("💥 APLICANDO DAÑO FINAL:")
		print("   - Daño: ", current_attack_damage)
		print("   - ¿Es crítico? ", is_critical)
		
		enemy.take_damage(current_attack_damage, is_critical)
		
		if enemy.health <= 0:
			print("🎉 Enemigo derrotado por el ataque!")
			
		current_attack_damage = base_attack_damage
		current_is_critical = false  # ← RESETEAR
		
func play_hit_effect():
	$Effect.play("Hit")


func _on_area_to_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		if body.has_method("take_damage"):
			body.take_damage(base_attack_damage)

func update_stance_visuals():
	match GameEvents.current_stance:
		GameEvents.Stance.OFFENSIVE:
			$player_animations.modulate = Color(1.0, 0.8, 0.8)  # Tono rojizo
			$ofensive_icon_sound.play()
		GameEvents.Stance.DEFENSIVE:
			$player_animations.modulate = Color(0.8, 0.8, 1.0)  # Tono azulado
			$defensive_icon_sound.play()
		GameEvents.Stance.BALANCED:
			$player_animations.modulate = Color.WHITE
			audio_player.play()
			
func play_random_attack_sound():
	
	# 50% probabilidad para cada sonido
	var random_value = randf()
	
	if is_attacking:
		if random_value < 0.5:
			AudioManager.play_sfx("res://Sounds/Female_attack.wav")
		else:
			AudioManager.play_sfx("res://Sounds/Female_attack2.wav")
	else:
		if random_value < 0.5:
			AudioManager.play_sfx("res://Sounds/Female_damage.wav")
		else:
			AudioManager.play_sfx("res://Sounds/Female_damage2.wav")
