# EquipmentUI.gd
extends HBoxContainer

@onready var tool_slot = $ToolSlot
var current_tool: Item = null

func _ready():
	print("EquipmentUI listo")
	if tool_slot:
		tool_slot.tool = null
	else:
		print("ERROR: No se encontró ToolSlot como hijo de EquipmentUI")
	
	# Esperar a que ItemDatabase esté listo
	await get_tree().process_frame
	if not ItemDatabase.loaded:
		await ItemDatabase.item_database_loaded  # Necesitas agregar esta señal

func equip_tool(tool: Item):
	if tool == null:
		print("⚠️ Intentando equipar tool null")
		return
	
	print("✅ Equipando: ", tool.name, " (ID: ", tool.id, ")")
	current_tool = tool
	if tool_slot:
		tool_slot.tool = tool
	else:
		print("ERROR: tool_slot es null")

func get_equipped_tool():
	if tool_slot:
		return tool_slot.tool
	return null

func unequip_tool():
	print("🔨 Unequip tool")
	if tool_slot:
		tool_slot.tool = null
	current_tool = null

func save():
	var save_data = {}
	
	if current_tool and current_tool.id:
		save_data["tool"] = current_tool.id
		print("💾 Guardando herramienta equipada: ", current_tool.id)
	else:
		print("⚠️ No hay herramienta equipada para guardar")
	
	return save_data

func load(data: Dictionary):
	print("📀 Cargando EquipmentUI con datos: ", data)
	
	if data.is_empty():
		print("⚠️ No hay datos de equipo para cargar")
		return
	
	if data.has("tool"):
		var tool_id = data["tool"]
		print("🔍 Buscando item con ID: ", tool_id)
		
		# Esperar a que ItemDatabase esté listo
		if not ItemDatabase.loaded:
			print("⏳ Esperando a que ItemDatabase cargue...")
			await ItemDatabase.item_database_loaded
		
		var tool = ItemDatabase.get_item(tool_id)
		if tool:
			print("✅ Item encontrado: ", tool.name)
			equip_tool(tool)
		else:
			print("❌ No se encontró item con ID: ", tool_id)
	else:
		print("⚠️ No se encontró 'tool' en los datos guardados")
