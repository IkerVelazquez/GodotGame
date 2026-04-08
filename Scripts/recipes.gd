# Recetas.gd (el VBoxContainer que contiene todas las recetas)
extends VBoxContainer

func _ready():
	var inventory = get_tree().current_scene.find_child("Inventory", true, false)
	if inventory:
		inventory.item_changed.connect(_on_inventory_item_changed)
	else:
		print("❌ No se encontró Inventory")
	
	# 🔥 Conectar señal del EquipmentUI
	var equipment = get_tree().current_scene.find_child("EquipmentUI", true, false)
	if equipment:
		equipment.tool_equipped.connect(_on_tool_equipped)
		print("✅ Recetas conectado a tool_equipped signal")
	else:
		print("⚠️ No se encontró EquipmentUI al inicio")
	
	# Refrescar al cargar la partida
	await get_tree().process_frame
	_refresh_all_recipes()

func _on_inventory_item_changed():
	_refresh_all_recipes()

func _on_tool_equipped(tool: Item):
	print("🔄 Herramienta equipada cambiada: ", tool.name if tool else "ninguna")
	_refresh_all_recipes()

func refresh():
	_refresh_all_recipes()

func _refresh_all_recipes():
	print("🔄 Refrescando todas las recetas...")
	for recipe in get_children():
		if recipe and recipe.has_method("check"):
			recipe.check()
	
	# También refrescar visualmente los slots
	await get_tree().process_frame
