# enemy_melee.gd - MODIFICADO
extends CharacterBody2D

@export var health: int = 30
var attack_power: int = 10
var is_attacking: bool = false
var original_position: Vector2

@export var attack_duration: float = 2.0
@export var return_duration: float = 1.5
@export var stop_distance: float = 50.0

@onready var damage_popup_scene = preload("res://Scenes/damage_popup.tscn")

func _ready():
	await get_tree().process_frame
	original_position = global_position
	print("✅ Enemigo listo en posición REAL: ", original_position)
	
	$Area_to_attack/CollisionShape2D.disabled = true
	GameEvents.add_enemy(self)

func start_enemy_turn():
	if is_attacking:
		return
	
	print("Enemigo comenzando turno...")
	print("   - Posición actual: ", global_position)
	print("   - Posición original guardada: ", original_position)
	attack_player()

func attack_player():
	is_attacking = true
	
	var player_position = _get_real_player_position()
	print("🎯 Jugador encontrado en posición: ", player_position)
	
	if player_position != Vector2.ZERO:
		print("⚔️ Atacando al jugador REAL")
		_perform_player_attack(player_position)
	else:
		print("💤 No se encontró jugador para atacar")
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

func _perform_player_attack(player_pos: Vector2):
	var stop_pos = _calculate_stop_position(global_position, player_pos)
	
	print("🎯 Enemigo atacando jugador REAL")
	print("   - Desde: ", global_position)
	print("   - Hacia: ", stop_pos)
	print("   - Regresará a: ", original_position)
	
	$enemy_animations.play("Walk")
	
	var tween = get_tree().create_tween()
	
	tween.tween_property(self, "global_position", stop_pos, attack_duration * 0.6)
	tween.tween_callback(Callable(self, "_start_attack_phase"))
	tween.tween_interval(0.9)
	tween.tween_callback(Callable(self, "_start_return_phase"))
	tween.tween_property(self, "global_position", original_position, return_duration)
	tween.tween_callback(Callable(self, "_on_attack_completed"))

func _start_attack_phase():
	print("⚔️ Ataque al jugador REAL")
	$enemy_animations.play("Attack")

func _start_return_phase():
	print("🔙 Regresando a posición original: ", original_position)
	$enemy_animations.play("Return")
	$Area_to_attack/CollisionShape2D.disabled = true
	$enemy_animations.scale = Vector2(1.0, 1.0)

func _on_attack_completed():
	print("✅ Ataque completado")
	print("   - Posición final: ", global_position)
	print("   - Debería estar en: ", original_position)
	finish_turn()

func finish_turn():
	$enemy_animations.play("Idle")
	is_attacking = false
	print("✅ Turno enemigo terminado")
	GameEvents.next_turn()
	$Area_to_attack/CollisionShape2D.disabled = true

func take_damage(damage: int, is_critical: bool = false):
	health -= damage
	show_damage_popup(damage, is_critical)
	$enemy_animations.play("Hurt")
	print("💥 Enemigo recibe ", damage, " de daño. Vida restante: ", health)
	if health <= 0:
		die()

func show_damage_popup(damage: int, is_critical: bool = false):
	var popup = damage_popup_scene.instantiate()
	get_parent().add_child(popup)
	popup.global_position = global_position + Vector2(0, -30)
	
	print("🎯 Mostrando popup - Daño: ", damage, " ¿Es crítico?: ", is_critical)
	
	if is_critical:
		popup.setup(damage, popup.DamageType.CRITICAL)
	else:
		popup.setup(damage, popup.DamageType.NORMAL)
	
	popup.start_animation()
	
func die():
	GameEvents.remove_enemy(self)
	print("💀 Enemigo derrotado")
	queue_free()

func _on_enemy_animations_frame_changed() -> void:
	if $enemy_animations.animation == "Attack" and $enemy_animations.frame == 2:
		GameEvents.request_camera_shake(2.0, 0.3)
		$Area_to_attack/CollisionShape2D.disabled = false

func _on_area_to_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			print("🎯 ¡Daño aplicado a ", body.name, "!")
			# ELIMINADO: show_damage_popup(attack_power, false)
			# Solo llamar a take_damage, el jugador mostrará su propio popup
			body.take_damage(attack_power)

func _on_enemy_animations_animation_finished() -> void:
	if $enemy_animations.animation == "Hurt":
		$enemy_animations.play("Idle")
