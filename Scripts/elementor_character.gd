extends CharacterBody2D

var anim 
var type = "elementor"
var current_mp: float = 0.0
var max_mp: float = 100.0
var special_available: bool = false
@export var health: int = 100
@export var max_health: int = 100
@export var portrait: Texture2D
@export var projectile_scene: PackedScene


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
				$player_animations.play("Attack")  # Cambiar esta línea
		else:
			$Control.visible = false
	else:
		$Control.visible = false

func basic_attack():
	$Effects.play("Aura")
	launch_projectile()
	
	
func launch_projectile():
	var enemy = find_enemy()
	if enemy == null:
		push_warning("No se encontró enemigo para apuntar el proyectil.")
		return
	
	if special_available:
		print("💥 ¡USANDO ATAQUE ESPECIAL!")
		special_available = false
		$Control/Especial.visible = false
		$Control/MP.modulate = Color.WHITE  # Restaurar color
		
		# GASTAR TODO EL MP
		current_mp = 0
		$Control/MP.value = current_mp
		
	# Crear proyectil en la posición del elementor
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(50, 0)  # Un poco adelante del personaje
	
	# Configurar el proyectil para que vaya hacia el enemigo
	var target_pos = enemy.global_position
	projectile.setup(target_pos)

func find_enemy():
	if get_tree().has_group("Enemy"):
		var enemies = get_tree().get_nodes_in_group("Enemy")
		if enemies.size() > 0:
			return enemies[0]
	return null
	
	
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
		$player_animations.play("Idle")
		GameEvents.atack = false 
		GameEvents.next_turn()
		
	elif $player_animations.animation == "Hurt":
		$player_animations.play("Idle")
		
	if GameEvents.current_turn > GameEvents.turn_order.size():
		GameEvents.current_turn = 1  # reinicia el ciclo de turnos
	


func _on_player_animations_frame_changed() -> void:
	if $player_animations.animation == "Attack" and $player_animations.frame == 2:
		basic_attack()
