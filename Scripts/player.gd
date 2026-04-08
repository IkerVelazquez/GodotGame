extends CharacterBody2D

@export var speed := 100.0
@onready var anim = $AnimatedSprite2D
@onready var inventory = $Inventory
@onready var recipes = $Recipes
@onready var inventory_label = $InventoryLabel
@onready var recipes_label = $RecipesLabel
@onready var equipment_label = $EquipmentLabel
@onready var equipment_ui_node = $EquipmentUI
@onready var currency_panel = $CurrencyPanel
@onready var minimap = $Minimap
@onready var equipment_ui = null



var tooltip = preload("res://Scenes/tooltip.tscn").instantiate()
var inventory_open: bool = false

func _ready():
	
	add_child(tooltip)
	tooltip.hide_tooltip()

	
	tooltip.hide_tooltip()
	
	GlobalData.mouse_disable = true
	
	equipment_ui = $EquipmentUI
	
	# Configurar inventario
	if inventory:
		inventory.visible = false
		recipes.visible = false
		inventory_label.visible = false
		recipes_label.visible = false
		equipment_label.visible = false
		equipment_ui.visible = false
		currency_panel.visible = false
		minimap.visible = true
	
	if not equipment_ui:
		equipment_ui = find_child("EquipmentUI", true, false)
	
	# ✅ Conectar señales del sistema de misiones
	MisionSystem.mision_agregada.connect(_on_misiones_actualizadas)
	MisionSystem.mision_completada.connect(_on_misiones_actualizadas)
	
	# ✅ Verificar estado inicial de misiones
	actualizar_visibilidad_misiones()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	
	SaveSystem.load_game()

func _on_misiones_actualizadas(_nombre_mision = null):
	"""Se llama cuando se añade o completa una misión"""
	actualizar_visibilidad_misiones()

func actualizar_visibilidad_misiones():
	"""Actualiza la visibilidad del panel de misiones"""
	var misiones_activas = MisionSystem.get_active_missions()
	var tiene_misiones = misiones_activas.size() > 0
	
	if tiene_misiones:
		$Missions.show()
		print("📋 Mostrando panel de misiones - Misiones activas: ", misiones_activas.size())
		# Opcional: imprimir nombres de misiones activas
		for mision in misiones_activas:
			print("  - ", mision.nombre)
	else:
		$Missions.hide()
		print("📋 Ocultando panel de misiones - No hay misiones activas")

func _physics_process(delta):
	
	var misiones_activas = MisionSystem.get_active_missions()
	
	if misiones_activas.size() > 0:
		$Missions.show()
	else:
		$Missions.hide()
		
	if Levels.in_cutscene:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle")
		move_and_slide()
		return
		
	if inventory_open:
		minimap.visible = false
		velocity = Vector2.ZERO
		$AnimatedSprite2D.play("idle")
		move_and_slide()
		return
		
	if Input.is_action_just_pressed("close-open_map"):
		minimap.visible = !minimap.visible
	
	# Movimiento normal
	velocity.x = 0
	velocity.y = 0
	
	if Input.is_action_pressed("right"):
		velocity.x += speed
	if Input.is_action_pressed("left"):
		velocity.x -= speed
	if Input.is_action_pressed("down"):
		velocity.y += speed
	if Input.is_action_pressed("up"):
		velocity.y -= speed
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0:
				anim.play("right")
			else:
				anim.play("left")
		else:
			if velocity.y > 0:
				anim.play("down")
			else:
				anim.play("up")
	else:
		anim.play("idle")
	
	move_and_slide()
	
	# ❌ ELIMINAR esta línea, ya no es necesaria
	# if misiones.size() > 0:

func _input(event: InputEvent):
	if event.is_action_pressed("inventory"):
		GlobalData.mouse_disable = false
		toggle_inventory()

func toggle_inventory():
	if Levels.in_cutscene:
		return
		
	if inventory:
		inventory_open = !inventory_open
		inventory.visible = inventory_open
		recipes.visible = inventory_open
		equipment_ui.visible = inventory_open
		inventory_label.visible = inventory_open
		recipes_label.visible = inventory_open
		equipment_label.visible = inventory_open
		currency_panel.visible = inventory_open
		
		if inventory_open:
			GlobalData.mouse_disable = false
		else:
			GlobalData.mouse_disable = true

func add_item(item):
	if inventory:
		inventory.add_item(item)

func get_equipped_tool():
	if equipment_ui_node:
		return equipment_ui_node.get_equipped_tool()
	return null

func has_tool_of_type(tool_type: String) -> bool:
	return get_tool_level(tool_type) > 0

func get_tool_level(tool_type: String) -> int:
	var tool = get_equipped_tool()
	if tool and tool.type == "Tool" and tool.tool_type == tool_type:
		return tool.tool_level
	return 0

func equip_tool(tool: Item):
	if equipment_ui_node:
		equipment_ui_node.equip_tool(tool)
		print("🔧 Player equipó herramienta: ", tool.name)
	else:
		print("❌ Player: No se encontró EquipmentUI")


func unequip_tool():
	if equipment_ui:
		var tool_slot = equipment_ui.get_node_or_null("ToolSlot")
		if tool_slot:
			var current_tool = tool_slot.tool
			tool_slot.clear()
			return current_tool
	return null
	
func start_cutscene():
	Levels.in_cutscene = true
	if inventory_open:
		toggle_inventory()
	$CurrencyPanel.visible = false
	$Minimap.visible = false

func end_cutscene():
	Levels.in_cutscene = false
	$CurrencyPanel.visible = true
	$Minimap.visible = true
	
func get_tooltip():
	return tooltip
