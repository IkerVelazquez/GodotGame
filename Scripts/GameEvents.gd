extends Node

var atack = false
var roster = ["melee", "elementor", "ranger", "wizard"]
var continue_pressed = false

enum Stance { OFFENSIVE, DEFENSIVE, BALANCED }
var current_stance: Stance = Stance.BALANCED

# Los personajes que entran al combate
var active_party: Array = []
var enemies: Array = [] 
@export var max_party_size: int = 3

var turn_order := { "melee": 1, "ranger": 2 }
var is_player_turn: bool = true  # <- NUEVO: controla de quién es el turno

var current_turn = 1

var critical_damage = false
var base_damage = false
var minimum_damage = false

var close_shop = false

static var is_timing_attack: bool = false
static var current_accuracy: float = 1.0
static var base_attack_power: int = 10  


signal party_updated  # señal para avisar cuando cambia el equipo
signal camera_shake(intensity: float, duration: float)
signal turn_changed(is_player_turn: bool)

signal timing_attack_started()
signal timing_attack_completed(accuracy: float)

var in_cutscene: bool = false

func _ready():
	# Asegurar que el primer turno sea del jugador
	current_turn = 1
	is_player_turn = true
	print("--- TURNO DEL JUGADOR INICIADO --- Turno actual: ", current_turn)
	
func update_turn_order():

	turn_order.clear()
	
	# SOLO usar personajes que están en active_party
	for i in range(active_party.size()):
		var character_type = active_party[i]
		turn_order[character_type] = i + 1
		print("   - Added to turn_order: ", character_type, " -> ", i + 1)
	
	
func set_party(party_array: Array):
	active_party = party_array
	update_turn_order()
	emit_signal("party_updated")

func add_to_party(member):
	if active_party.size() < max_party_size:
		active_party.append(member)
		update_turn_order()
		emit_signal("party_updated")

func remove_from_party(member):
	if member in active_party:
		active_party.erase(member)
		update_turn_order()  # Esto actualiza el turn_order
		emit_signal("party_updated")
		print("Personaje ", member, " removido del party. Party actual: ", active_party)

func add_enemy(enemy):
	if not enemy in enemies:
		enemies.append(enemy)
		print("✅ ENEMY ADDED SUCCESSFULLY")
		print("   - Current enemies after: ", enemies.size())
	else:
		print("❌ Enemy already in array")

func remove_enemy(enemy):  # <- NUEVO: función para remover enemigos
	enemies.erase(enemy)
	
func _assign_turns():
	turn_order.clear()
	for i in range(active_party.size()):
		turn_order[active_party[i]] = i + 1

func next_turn():
	
	if is_player_turn:
		current_turn += 1
		print("Avanzando turno jugador: ", current_turn)
		
		# VERIFICACIÓN CRÍTICA: Usar active_party.size() en lugar de turn_order.size()
		if current_turn > active_party.size():  # ← CAMBIO IMPORTANTE
			# Terminaron los turnos del jugador
			is_player_turn = false
			current_turn = 0
			emit_signal("turn_changed", false)
			print("--- TURNO DEL ENEMIGO ---")
			_start_enemy_turn()
		else:
			print("Siguiente turno jugador: ", current_turn)
	else:
		# Terminó el turno del enemigo
		is_player_turn = true
		current_turn = 1
		emit_signal("turn_changed", true)
		print("--- TURNO DEL JUGADOR --- Turno actual: ", current_turn)
		
func _start_enemy_turn():
	
	if enemies.size() > 0:
		for i in range(enemies.size()):
			var enemy = enemies[i]
			print("   - Checking enemy ", i, ": ", enemy)
			
			if is_instance_valid(enemy):
				print("   ✅ Enemy ", i, " is valid")
				print("   - Has method 'start_enemy_turn': ", enemy.has_method("start_enemy_turn"))
				
				if enemy.has_method("start_enemy_turn"):
					print("   🚀 CALLING start_enemy_turn() on enemy ", i)
					enemy.start_enemy_turn()
					return  # Solo un enemigo actúa por turno
			else:
				print("   ❌ Enemy ", i, " is NOT valid")
	else:
		print("❌ No enemies found in array")
		# Si no hay enemigos, pasar directamente al siguiente turno
		next_turn()
		
func request_camera_shake(intensity: float = 10.0, duration: float = 0.3):
	emit_signal("camera_shake", intensity, duration)

# En GameEvents.gd - AGREGAR esta función
func character_died(character_type: String):
	print("GameEvents: Personaje ", character_type, " ha muerto")
	
	# Remover del party (esto ya actualiza turn_order)
	remove_from_party(character_type)
	
	# Ajustar el turno actual si es necesario
	_adjust_turn_after_death(character_type)

func _adjust_turn_after_death(character_type: String):
	var dead_character_turn = turn_order.get(character_type, -1)
	
	if dead_character_turn != -1 and dead_character_turn <= current_turn:
		# Si el personaje muerto tenía un turno menor o igual al actual,
		# disminuir el turno actual
		current_turn = max(1, current_turn - 1)
		print("Turno ajustado después de muerte: ", current_turn)
	
	# Si no quedan personajes, pasar turno al enemigo
	if active_party.size() == 0:
		print("Todos los personajes han muerto, pasando turno al enemigo")
		is_player_turn = false
		current_turn = 0
		emit_signal("turn_changed", false)

func start_timing_attack():
	is_timing_attack = true
	timing_attack_started.emit()

func calculate_damage(base_damage: int) -> int:
	var multiplier = 0.5 + (current_accuracy * 0.5)  # 0.5x a 1.0x
	var final_damage = base_damage * multiplier
	print("💥 Daño calculado: ", base_damage, " * ", multiplier, " = ", final_damage)
	return int(final_damage)

func set_stance(stance: Stance):
	current_stance = stance
	match stance:
		Stance.OFFENSIVE:
			print("⚔️ Postura OFENSIVA: +25% daño, -25% defensa")
		Stance.DEFENSIVE:
			print("🛡️ Postura DEFENSIVA: +25% defensa, -25% daño")
		Stance.BALANCED:
			print("⚖️ Postura BALANCEADA: estadísticas normales")
			
func get_damage_multiplier() -> float:
	match current_stance:
		Stance.OFFENSIVE: return 1.25
		Stance.DEFENSIVE: return 0.75
		_: return 1.0


func get_defense_multiplier() -> float:
	match current_stance:
		Stance.OFFENSIVE: return 1.25
		Stance.DEFENSIVE: return 0.75
		_: return 1.0
