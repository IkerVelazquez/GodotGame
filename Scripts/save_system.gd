# SaveSystem.gd (modificado)
extends Node

const SAVE_PATH = "user://savegame.json"
signal level_ready

# SaveSystem.gd
func save_game():
	print("💾 INICIANDO GUARDADO...")
	
	var inventory = get_inventory()
	var currency = get_currency()
	var equipment = get_equipment()
	
	# 🔥 Obtener datos FRESCOS de MisionSystem
	print("🔍 Obteniendo datos de MisionSystem...")
	var misiones_data = MisionSystem.get_all_missions()
	var misiones_completadas_data = MisionSystem.get_completed_missions_data()
	
	# 🔥 DEBUG DETALLADO
	print("📊 Misiones en MisionSystem (activas):")
	for key in misiones_data:
		var mision = misiones_data[key]
		print("  - ", key)
		print("    Nombre: ", mision.get("nombre", "sin nombre"))
		print("    Objetivos: ", mision.get("objetivos", {}))
		print("    Progreso: ", mision.get("progreso", {}))
		print("    Completada: ", mision.get("completada", false))
	
	print("📊 Misiones completadas: ", misiones_completadas_data.size())
	
	# También verificar directamente desde las variables internas de MisionSystem
	print("🔍 Verificando variables internas de MisionSystem:")
	print("  misiones_activas: ", MisionSystem.misiones_activas)
	
	var data = {
		"global": GlobalData.save(),
		"misiones": misiones_data,
		"misiones_completadas": misiones_completadas_data,
		"inventory": inventory.save() if inventory else [],
		"currency": currency.save() if currency else {},
		"equipment": equipment.save() if equipment else {}
	}
	
	# 🔥 Verificar qué se va a guardar
	print("📦 Datos que se guardarán:")
	print("  misiones en data: ", data["misiones"])
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var json_string = JSON.stringify(data)
	file.store_string(json_string)
	print("💾 Juego guardado completo")
	print("🔍 JSON guardado: ", json_string)
	
func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("📁 No hay archivo de guardado - Iniciando nuevo juego")
		emit_signal("level_ready")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	if data:
		await get_tree().process_frame
		await get_tree().process_frame
		
		var inventory = get_inventory()
		var currency = get_currency()
		var equipment = get_equipment()
		
		# Cargar datos globales
		GlobalData.load(data.get("global", {}))
		
		# 🔥 Cargar misiones desde el save principal
		print("📀 Cargando misiones desde savegame.json")
		MisionSystem.load_missions_from_data(
			data.get("misiones", {}), 
			data.get("misiones_completadas", {})
		)
		
		if inventory:
			inventory.load(data.get("inventory", []))
		if currency:
			currency.load(data.get("currency", {}))
		if equipment:
			equipment.load(data.get("equipment", {}))
		
		emit_signal("level_ready")
		print("📀 Juego cargado completo")

# Helpers
func get_inventory():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		return player.get_node("Inventory")
	return null
	
func get_currency():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		return player.get_node("CurrencyPanel")
	return null

func get_equipment():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		return player.get_node("EquipmentUI")
	return null
