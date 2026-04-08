# Recipe.gd
extends HBoxContainer

@onready var craft = $ResultContainer/craft
@onready var name_label = $ResultContainer/craft/NameLabel
@onready var materials_container = $MaterialsContainer
@export var item: Item = null
@onready var recipe = item.recipe if item else []

var slot_template: PackedScene = preload("res://Scenes/recipe_slot.tscn")

func _ready():
	if not item:
		print("ERROR: Recipe sin item asignado")
		return
	
	# Asegurar que los contenedores existen
	_ensure_containers()
	
	# Limpiar slots existentes
	_clear_slots()
	
	# Crear slots de materiales
	_create_material_slots()
	
	# Configurar el resultado
	_setup_result()
	
	# Verificar si ya está equipado
	_check_if_already_equipped()
	
	check()

func _ensure_containers():
	# Crear MaterialsContainer si no existe
	if not has_node("MaterialsContainer"):
		var container = HBoxContainer.new()
		container.name = "MaterialsContainer"
		container.add_theme_constant_override("separation", 8)
		add_child(container)
		move_child(container, 0)
	
	# Crear Separator si no existe
	if not has_node("Separator"):
		var separator = VSeparator.new()
		separator.name = "Separator"
		add_child(separator)
		move_child(separator, 1)
	
	# Crear ResultContainer si no existe
	if not has_node("ResultContainer"):
		var result_container = VBoxContainer.new()
		result_container.name = "ResultContainer"
		result_container.add_theme_constant_override("separation", 4)
		add_child(result_container)
		move_child(result_container, 2)
		
		# Crear botón craft dentro de ResultContainer
		var craft_button = Button.new()
		craft_button.name = "craft"
		craft_button.flat = false
		craft_button.custom_minimum_size = Vector2(64, 64)
		result_container.add_child(craft_button)
		
		# Crear label para el nombre
		var name_label_node = Label.new()
		name_label_node.name = "NameLabel"
		name_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		result_container.add_child(name_label_node)

func _clear_slots():
	# Limpiar solo los slots dentro de MaterialsContainer
	if materials_container:
		for child in materials_container.get_children():
			child.queue_free()
	
	await get_tree().process_frame

func _create_material_slots():
	if not slot_template:
		print("ERROR: No se encontró slot_template")
		return
	
	if not recipe or recipe.is_empty():
		return
	
	if not materials_container:
		print("ERROR: materials_container no existe")
		return
	
	# Agrupar items
	var items_needed = {}
	for i in recipe:
		if items_needed.has(i):
			items_needed[i] += 1
		else:
			items_needed[i] = 1
	
	# Crear slots dentro de MaterialsContainer
	for needed_item in items_needed.keys():
		var slot = slot_template.instantiate()
		slot.item = needed_item
		
		var amount = items_needed[needed_item]
		if slot.has_node("Label"):
			slot.get_node("Label").text = "x" + str(amount)
		
		materials_container.add_child(slot)

func _setup_result():
	if not is_instance_valid(craft):
		print("ERROR: craft button no encontrado")
		return
	
	if craft and item and item.icon:
		craft.icon = item.icon
		craft.expand_icon = true
		craft.tooltip_text = item.description if item.description else item.name
	
	if name_label and item and item.name:
		name_label.text = item.name

# Recipe.gd - Parte de verificación de materiales
func check():
	# Asegurar que inventory existe
	var inventory = get_tree().current_scene.find_child("Inventory", true, false)
	if not inventory:
		if is_instance_valid(craft):
			craft.disabled = true
		return
	
	# Verificar materiales
	var can_craft = true
	var items_needed = {}
	
	for i in recipe:
		if items_needed.has(i):
			items_needed[i] += 1
		else:
			items_needed[i] = 1
	
	for needed_item in items_needed.keys():
		var needed = items_needed[needed_item]
		var available = inventory.get_item_count_total(needed_item)
		
		if available < needed:
			can_craft = false
			break
	
	# 🔥 Verificar herramientas (MEJORADO)
	if can_craft and item.type == "Tool":
		if _has_better_or_equal_tool():  # Cambiar a esta función
			can_craft = false
			if is_instance_valid(craft):
				craft.tooltip_text = "Ya tienes una herramienta igual o mejor"
		elif _is_tool_already_equipped():
			can_craft = false
			if is_instance_valid(craft):
				craft.tooltip_text = "Ya tienes esta herramienta equipada"
	
	if is_instance_valid(craft):
		craft.disabled = not can_craft
	
	# Actualizar visual de slots
	_update_slots_visual(items_needed, inventory)

# 🔥 Nueva función que reemplaza a _has_better_tool
func _has_better_or_equal_tool() -> bool:
	# Solo aplica para herramientas
	if item.type != "Tool":
		return false
	
	var equipment = get_tree().current_scene.find_child("EquipmentUI", true, false)
	if not equipment:
		print("⚠️ No se encontró EquipmentUI en _has_better_or_equal_tool")
		return false
	
	var current_tool = equipment.get_equipped_tool()
	if not current_tool:
		return false  # No hay herramienta equipada, se puede craftear
	
	# Comparar niveles: si la herramienta equipada tiene nivel mayor o IGUAL, no se puede craftear
	if current_tool.tool_level >= item.tool_level:
		print("🚫 No se puede craftear ", item.name, " (nivel ", item.tool_level, 
			  ") porque ya tienes ", current_tool.name, " (nivel ", current_tool.tool_level, ")")
		return true
	
	return false


func _update_slots_visual(items_needed: Dictionary, inventory):
	if not materials_container:
		return
		
	for child in materials_container.get_children():
		if not is_instance_valid(child):
			continue
		
		# Obtener el item del slot
		var slot_item = null
		if child.has_method("get_item"):
			slot_item = child.get_item()
		elif "item" in child:
			slot_item = child.item
		
		if slot_item and items_needed.has(slot_item):
			var needed = items_needed[slot_item]
			var available = inventory.get_item_count_total(slot_item)
			
			if available >= needed:
				child.modulate = Color(1, 1, 1, 1)  # Normal
			else:
				child.modulate = Color(0.5, 0.5, 0.5, 1)  # Gris

func _is_tool_already_equipped() -> bool:
	var equipment = get_tree().current_scene.find_child("EquipmentUI", true, false)
	if not equipment:
		return false
	
	var equipped = equipment.get_equipped_tool()
	if equipped and item and equipped.id == item.id:  # Comparar por ID en lugar de nombre
		print("🚫 Ya tienes esta herramienta específica equipada: ", item.name)
		return true
	
	return false

func _check_if_already_equipped():
	if not is_instance_valid(craft):
		return
	
	if item and item.type == "Tool" and _is_tool_already_equipped():
		craft.disabled = true
		craft.tooltip_text = "Ya tienes este " + item.name

func _on_craft_pressed():
	if not is_instance_valid(self) or not is_instance_valid(craft):
		return
	
	craft.disabled = true
	
	var inventory = get_tree().current_scene.find_child("Inventory")
	
	if not inventory:
		print("ERROR: No se encontró Inventory")
		return
	
	# Verificar materiales
	var items_needed = {}
	for i in recipe:
		if items_needed.has(i):
			items_needed[i] += 1
		else:
			items_needed[i] = 1
	
	# Verificar que hay suficientes materiales
	for needed_item in items_needed.keys():
		var needed = items_needed[needed_item]
		var available = inventory.get_item_count_total(needed_item)
		
		if available < needed:
			print("ERROR: Materiales insuficientes - ", needed_item.name)
			if is_instance_valid(craft):
				craft.disabled = false
			return
	
	# Remover materiales
	for needed_item in items_needed.keys():
		var needed = items_needed[needed_item]
		for i in range(needed):
			inventory.remove_item_total(needed_item)
	
	# Crear el item resultante
	if item.type == "Tool":
		var player = _get_player()
		
		if player and player.has_method("equip_tool"):
			var new_tool = item.duplicate()
			player.equip_tool(new_tool)
			print("Herramienta equipada: ", new_tool.name)
		else:
			inventory.add_item(item)
	else:
		inventory.add_item(item)
	
	# REFRESCAR TODAS LAS RECETAS INMEDIATAMENTE
	_refresh_all_recipes()
	
	# Actualizar UI
	await get_tree().create_timer(0.05).timeout
	
	if is_instance_valid(self) and is_instance_valid(craft):
		check()

func _refresh_all_recipes():
	# Buscar el nodo de recetas y refrescar
	var recipes = get_tree().current_scene.find_child("Recetas", true, false)
	if recipes and recipes.has_method("refresh"):
		recipes.refresh()

			
func _has_better_tool() -> bool:
	# Solo aplica para herramientas
	if item.type != "Tool":
		return false
	
	var player = get_tree().current_scene.find_child("Player", true, false)
	if not player or not player.has_method("get_equipped_tool"):
		return false
	
	var current_tool = player.get_equipped_tool()
	if not current_tool:
		return false
	
	# Comparar niveles: si la herramienta equipada tiene nivel mayor o igual, no se puede craftear
	if current_tool.tool_level >= item.tool_level:
		return true
	
	return false

func _get_player():
	return get_tree().current_scene.find_child("Player", true, false)

func _get_best_tool_level() -> int:
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player and player.has_method("get_equipped_tool"):
		var tool = player.get_equipped_tool()
		if tool:
			return tool.tool_level
	return 0
