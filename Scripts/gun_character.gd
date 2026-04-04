extends CharacterBody2D

var anim 
var type = "ranger"
var is_shooting := false
var current_mp: float = 0.0
var max_mp: float = 100.0
var special_available: bool = false
@export var health: int = 100
@export var max_health: int = 100
@export var portrait: Texture2D
@export var projectile_scene: PackedScene  # Crea una escena para el proyectil que cae
@export var projectile_count := 3
@export var projectile_spread := 100.0  # Separación entre proyectiles


func _ready() -> void:
	
	$Control/HP.max_value = max_health
	$Control/HP.value = health
	
	$Control/MP.max_value = max_mp
	$Control/MP.value = current_mp
	
	anim = $player_animations
	if type in GameEvents.turn_order:
		print("Mi turno es:", GameEvents.turn_order[type])
	
func _physics_process(delta: float) -> void:
	
	if type in GameEvents.turn_order:
		if GameEvents.turn_order[type] == GameEvents.current_turn:
			$Control.visible = true

			if GameEvents.atack == true:
				$player_animations.play("Attack")
				is_shooting = true
				GameEvents.atack = false
				$Control.visible = false
		else:
			$Control.visible = false
			
		if is_shooting:
			$Control.visible = false
	else:
		$Control.visible = false  # Ocultar durante turno enemigo
			
func super_shoot() -> void:
	is_shooting = true
	$player_animations.play("Attack2")
	$Shot_sound.play()
	GameEvents.request_camera_shake(2,0.3)
	# Esperar y disparar 3 veces con intervalos
	await get_tree().create_timer(0.4).timeout
	$player_animations.play("Attack2")
	$Shot_sound.play()
	GameEvents.request_camera_shake(2,0.3)
	await get_tree().create_timer(0.4).timeout
	$player_animations.play("Attack2")
	$Shot_sound.play()
	GameEvents.request_camera_shake(2,0.3)
	await get_tree().create_timer(0.4).timeout
	
	# Esperar 0.5 segundos adicionales antes de hacer caer los proyectiles
	await get_tree().create_timer(0.5).timeout
	
	# Hacer caer los proyectiles desde el aire
	spawn_falling_projectiles()
	
	# Esperar a que terminen de caer los proyectiles antes de cambiar animación
	await get_tree().create_timer(1.0).timeout  # Ajusta este tiempo según la duración de la caída
	
	$player_animations.play("Crouched")
	GameEvents.next_turn()
	is_shooting = false
	if GameEvents.current_turn > GameEvents.turn_order.size():
		GameEvents.current_turn = 1
		
	if special_available:
		print("💥 ¡USANDO ATAQUE ESPECIAL!")
		special_available = false
		$Control/Especial.visible = false
		$Control/MP.modulate = Color.WHITE  # Restaurar color
		
		# GASTAR TODO EL MP
		current_mp = 0
		$Control/MP.value = current_mp

func spawn_falling_projectiles():
	var enemy = find_enemy()
	if enemy == null:
		push_warning("No se encontró enemigo para apuntar los proyectiles.")
		return
	
	var enemy_pos = enemy.global_position
	
	for i in range(projectile_count):
		# Calcular posición horizontal con spread
		var x_offset = (i - (projectile_count - 1) / 2.0) * projectile_spread
		var spawn_pos = Vector2(enemy_pos.x + x_offset, enemy_pos.y - 900)  # 300 píxeles arriba
		
		# Crear proyectil
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)  # Agregar al nivel, no al jugador
		projectile.global_position = spawn_pos
		
		# Configurar el proyectil para que caiga hacia la posición del enemigo
		var target_pos = Vector2(enemy_pos.x + x_offset, enemy_pos.y)
		projectile.setup(target_pos)
	
func find_enemy():
	if get_tree().has_group("Enemy"):
		var enemies = get_tree().get_nodes_in_group("Enemy")
		if enemies.size() > 0:
			return enemies[0]
	return null
			
			

# Método para recibir daño
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
		
	show_damage_popup(int(final_damage))
	$Control/HP.max_value = max_health
	$Control/HP.value = health
	# Efecto visual de daño (opcional)
	$player_animations.play("Hurt")
	_start_damage_effect()
	await get_tree().create_timer(1.0).timeout
	if health <= 0:
			die()

func _start_damage_effect():
	# Efecto visual simple - parpadeo
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
func die():
	print(type, " ha sido derrotado!")
	$player_animations.play("Die")
	# Notificar a GameEvents que este personaje murió
	GameEvents.character_died(type)
	
	# Liberar posición de spawn
	var test_node = get_node_or_null("/root/Test/Tests")
	if test_node and test_node.has_method("free_spawn_position"):
		test_node.free_spawn_position(self)
	
	# Eliminar del grupo Player
	remove_from_group("Player")
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_player_animations_animation_finished() -> void:
	
	if anim.animation == "Attack":
		$player_animations.play("Crouched")
		GameEvents.next_turn()
		is_shooting = false
		$Effects.visible = false
	elif anim.animation == "Hurt":
		$player_animations.play("Crouched")
		
	if GameEvents.current_turn > GameEvents.turn_order.size():
		GameEvents.current_turn = 1  # reinicia el ciclo de turnos
	

func _on_player_animations_frame_changed() -> void:
	if  $player_animations.animation == "Attack" and $player_animations.frame == 2:
		$Effects.visible = true
		$Effects.play("Shot")
		$Shot_sound.play()
		GameEvents.request_camera_shake(2,0.3)
		
	if  $player_animations.animation == "Attack2" and $player_animations.frame == 2:
		$Effects2.play("Shot")
