# enemy_melee.gd - COMPLETO CON PARRY Y ANIMATEDSPRITE2D
extends CharacterBody2D

@export var health: int = 30
var attack_power: int = 10
var is_attacking: bool = false
var original_position: Vector2

@export var attack_duration: float = 2.0
@export var return_duration: float = 1.5
@export var stop_distance: float = 50.0

# Variables para parry
@export var parry_chance: float = 0.25  # 30% de probabilidad
var is_parrying: bool = false
var parry_window_active: bool = false

var current_attack_animation: String = "Attack"

@onready var damage_popup_scene = preload("res://Scenes/damage_popup.tscn")
@onready var parry_effect_sprite: AnimatedSprite2D = $ParryEffect

func _ready():
	await get_tree().process_frame
	original_position = global_position
	print("✅ Enemigo listo en posición REAL: ", original_position)
	
	# Configurar AnimatedSprite2D para parry
	if parry_effect_sprite:
		parry_effect_sprite.visible = false
		parry_effect_sprite.animation_finished.connect(_on_parry_effect_finished)
	
	$Area_to_attack/CollisionShape2D.disabled = true
	GameEvents.add_enemy(self)

func start_enemy_turn():
	if is_attacking:
		return
	
	print("Enemigo comenzando turno...")
	attack_player()

func attack_player():
	is_attacking = true
	
	var player_position = _get_real_player_position()
	
	if player_position != Vector2.ZERO:
		_perform_player_attack(player_position)
	else:
		finish_turn()

func _get_real_player_position() -> Vector2:
	var player = get_tree().get_first_node_in_group("Player")
	if player and is_instance_valid(player):
		return player.global_position
	
	var characters_node = get_node_or_null("../characters")
	if characters_node:
		for child in characters_node.get_children():
			if child.is_in_group("Player") and is_instance_valid(child):
				return child.global_position
	
	return Vector2.ZERO

func _calculate_stop_position(current_pos: Vector2, target_pos: Vector2) -> Vector2:
	var direction = (target_pos - current_pos).normalized()
	var stop_pos = target_pos - (direction * stop_distance)
	return stop_pos

func _get_random_attack_animation() -> String:
	var random_value = randf()
	if random_value < 0.5:
		return "Attack"
	else:
		return "Attack2"

func _perform_player_attack(player_pos: Vector2):
	current_attack_animation = _get_random_attack_animation()
	
	var stop_pos = _calculate_stop_position(global_position, player_pos)
	
	$enemy_animations.play("Walk")
	
	var tween = get_tree().create_tween()
	
	tween.tween_property(self, "global_position", stop_pos, attack_duration * 0.6)
	tween.tween_callback(Callable(self, "_start_attack_phase"))
	tween.tween_interval(0.9)
	tween.tween_callback(Callable(self, "_start_return_phase"))
	tween.tween_property(self, "global_position", original_position, return_duration)
	tween.tween_callback(Callable(self, "_on_attack_completed"))

func _start_attack_phase():
	$enemy_animations.play(current_attack_animation)

func _start_return_phase():
	$enemy_animations.play("Return")
	$Area_to_attack/CollisionShape2D.disabled = true
	$enemy_animations.scale = Vector2(1.0, 1.0)

func _on_attack_completed():
	finish_turn()

func finish_turn():
	$enemy_animations.play("Idle")
	is_attacking = false
	GameEvents.next_turn()
	$Area_to_attack/CollisionShape2D.disabled = true

# ============================================
# SISTEMA DE PARRY CON ANIMATEDSPRITE2D
# ============================================
func try_parry() -> bool:
	var random_value = randf()
	var success = random_value < parry_chance
	
	if success:
		print("✨ ¡ENEMIGO HACE PARRY! ✨")
		_activate_parry()
	else:
		print("❌ Enemigo NO logra hacer parry")
	
	return success

func _activate_parry():
	is_parrying = true
	parry_window_active = true
	
	# Reproducir animación de parry del enemigo
	AudioManager.play_sfx("res://Sounds/Parry_sound.mp3")
	$enemy_animations.play("Parry")
	
	# Mostrar efecto visual de parry
	_show_parry_effect()
	
	# Shake de cámara
	GameEvents.request_camera_shake(2.0, 0.2)
	
	# Desactivar parry después de la animación
	await get_tree().create_timer(0.5).timeout
	parry_window_active = false
	is_parrying = false
	
	if $enemy_animations.animation == "Parry":
		$enemy_animations.play("Idle")

func _show_parry_effect():
	if not parry_effect_sprite:
		return
	
	# Posicionar el efecto sobre el enemigo
	parry_effect_sprite.global_position = global_position + Vector2(0, -30)
	parry_effect_sprite.visible = true
	parry_effect_sprite.play()
	
	# Efecto de escala para más impacto
	var tween = create_tween()
	tween.tween_property(parry_effect_sprite, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(parry_effect_sprite, "scale", Vector2(1.0, 1.0), 0.2)

func _on_parry_effect_finished():
	if parry_effect_sprite:
		parry_effect_sprite.visible = false
		parry_effect_sprite.stop()


# ============================================
# TOMAR DAÑO CON PARRY
# ============================================
func take_damage(damage: int, is_critical: bool = false):
	# Verificar si puede hacer parry
	if not is_parrying and not parry_window_active:
		var parry_success = try_parry()
		
		if parry_success:
			# Parry exitoso - NO recibe daño
			print("🛡️ ¡PARRY EXITOSO! El enemigo no recibe daño")
			_show_parry_popup()
			return
	
	# Si no hay parry o falló, aplicar daño normalmente
	health -= damage
	show_damage_popup(damage, is_critical)
	$enemy_animations.play("Hurt")
	play_random_attack_sound()
	print("💥 Enemigo recibe ", damage, " de daño. Vida restante: ", health)
	
	if health <= 0:
		die()

func _show_parry_popup():
	var popup = Label.new()
	popup.text = "¡PARRY!"
	popup.add_theme_color_override("font_color", Color(1, 0, 0))
	popup.add_theme_font_size_override("font_size", 24)
	add_child(popup)
	popup.global_position = global_position + Vector2(0, -80)
	
	var tween = create_tween()
	tween.tween_property(popup, "position", popup.position - Vector2(0, 30), 0.5)
	tween.parallel().tween_property(popup, "modulate:a", 0, 0.5)
	popup.scale = Vector2(-1, 1)
	await tween.finished
	popup.queue_free()

func show_damage_popup(damage: int, is_critical: bool = false):
	var popup = damage_popup_scene.instantiate()
	get_parent().add_child(popup)
	popup.global_position = global_position + Vector2(0, -30)
	
	if is_critical:
		popup.setup(damage, popup.DamageType.CRITICAL)
	else:
		popup.setup(damage, popup.DamageType.NORMAL)
	
	popup.start_animation()

func die():
	$enemy_animations.play("Die")
	await get_tree().create_timer(0.5).timeout
	GameEvents.remove_enemy(self)
	print("💀 Enemigo derrotado")
	GameEvents.enemy_died.emit()
	queue_free()

# ============================================
# SEÑALES DE ANIMACIÓN
# ============================================
func _on_enemy_animations_frame_changed() -> void:
	if $enemy_animations.animation == "Attack" and $enemy_animations.frame == 2:
		_activate_attack_area()
		play_random_attack_sound()
	elif $enemy_animations.animation == "Attack2" and $enemy_animations.frame == 2:
		_activate_attack_area()
		play_random_attack_sound()

func _activate_attack_area():
	GameEvents.request_camera_shake(1,0.3)
	$Area_to_attack/CollisionShape2D.disabled = false

func _on_area_to_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			print("🎯 ¡Daño aplicado a ", body.name, "!")
			body.take_damage(attack_power)

func _on_enemy_animations_animation_finished() -> void:
	if $enemy_animations.animation == "Hurt":
		$enemy_animations.play("Idle")

func play_random_attack_sound():
	
	# 50% probabilidad para cada sonido
	var random_value = randf()
	
	if is_attacking:
		if random_value < 0.5:
			AudioManager.play_sfx("res://Sounds/Zombie_atack.wav")
		else:
			AudioManager.play_sfx("res://Sounds/Zombie_atack2.wav")
	else:
		if random_value < 0.5:
			AudioManager.play_sfx("res://Sounds/Zombie_hurt.wav")
		else:
			AudioManager.play_sfx("res://Sounds/Zombie_hurt2.wav")
