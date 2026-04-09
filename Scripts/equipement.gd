# EquipmentUI.gd
extends HBoxContainer

@onready var tool_slot = $ToolSlot
var current_tool: Item = null
signal tool_equipped(tool: Item)

func _ready():
	print("✅ EquipmentUI inicializado")
	# Asegurar que tool_slot existe
	if not tool_slot:
		tool_slot = find_child("ToolSlot", true, false)
		if not tool_slot:
			print("❌ ERROR CRÍTICO: No se encontró ToolSlot")
			return
	
	# Conectar con el sistema de guardado
	await get_tree().process_frame
	if SaveSystem.has_signal("level_ready") and not SaveSystem.level_ready.is_connected(_on_save_loaded):
		SaveSystem.level_ready.connect(_on_save_loaded)

func _on_save_loaded():
	# Ya no necesitas hacer nada aquí porque SaveSystem ya llama a load()
	print("📀 EquipmentUI: Sistema de guardado listo")

func equip_tool(tool: Item):
	if not tool:
		print("⚠️ EquipmentUI: Intentando equipar tool null")
		return
	
	print("🔧 EquipmentUI equipando: ", tool.name, " (ID: ", tool.id, ", Level: ", tool.tool_level, ")")
	current_tool = tool
	
	if tool_slot:
		tool_slot.tool = tool
		emit_signal("tool_equipped", tool)
		if MisionSystem.is_mission_active("construye un pico de madera"):
			MisionSystem.complete_mission("construye un pico de madera")
	else:
		print("❌ ERROR: tool_slot es null en equip_tool")

func get_equipped_tool():
	if tool_slot:
		return tool_slot.get_tool()
	return null

func unequip_tool():
	print("🔨 EquipmentUI: Unequip tool")
	if tool_slot:
		tool_slot.clear()
	current_tool = null

func save():
	var save_data = {}
	if current_tool and current_tool.id:
		save_data["tool"] = current_tool.id
		print("💾 EquipmentUI guardando: ", current_tool.id)
	else:
		print("⚠️ EquipmentUI: No hay herramienta equipada para guardar")
	return save_data

func load(data: Dictionary):
	print("📀 EquipmentUI cargando datos: ", data)
	
	if data.is_empty():
		print("⚠️ EquipmentUI: No hay datos para cargar")
		return
	
	if data.has("tool"):
		var tool_id = data["tool"]
		print("🔍 EquipmentUI buscando item: ", tool_id)
		
		# Esperar a que ItemDatabase esté listo
		if not ItemDatabase.loaded:
			print("⏳ EquipmentUI esperando ItemDatabase...")
			await ItemDatabase.item_database_loaded
		
		var tool = ItemDatabase.get_item(tool_id)
		if tool:
			print("✅ EquipmentUI encontrado: ", tool.name)
			equip_tool(tool)
		else:
			print("❌ EquipmentUI: No se encontró item con ID: ", tool_id)
