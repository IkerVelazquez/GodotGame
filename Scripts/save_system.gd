# SaveSystem.gd
extends Node

const SAVE_PATH = "user://savegame.json"
signal level_ready

	
# En SaveSystem.gd
func save_game():
	var inventory = get_inventory()
	var currency = get_currency()
	var equipment = get_equipment()
	
	# 🔥 Debug: Verificar qué se está guardando
	print("🔍 Datos a guardar:")
	print("  - Equipment: ", equipment.save() if equipment else "null")
	print("  - Inventory: ", inventory.save() if inventory else "null")
	print("  - Currency: ", currency.save() if currency else "null")
	
	var data = {
		"global": GlobalData.save(),
		"misiones": MisionSystem.misiones_activas,
		"misiones_completadas": MisionSystem.misiones_completadas,
		"inventory": inventory.save() if inventory else [],
		"currency": currency.save() if currency else {},
		"equipment": equipment.save() if equipment else {}
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	print("💾 Juego guardado completo")

func load_game():
	
		
	if not FileAccess.file_exists(SAVE_PATH):
		emit_signal("level_ready")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	if data:
		# 🔥 ESPERAR A QUE TODO EXISTA
		await get_tree().process_frame
		await get_tree().process_frame
		
		var inventory = get_inventory()
		var currency = get_currency()
		var equipment = get_equipment()
		
		print("Inventory:", inventory)
		
		if inventory == null:
			print("❌ Inventory no encontrado")
			return
		
		GlobalData.load(data.get("global", {}))
		MisionSystem.misiones_activas = data.get("misiones", {})
		MisionSystem.misiones_completadas = data.get("misiones_completadas", {})
		
		inventory.load(data.get("inventory", []))
		currency.load(data.get("currency", {}))
		equipment.load(data.get("equipment", {}))
		
		emit_signal("level_ready")
		print("Ya cargó el save:" , GlobalData.first_mision)
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
