# shop_npc.gd
extends Area2D

@export var shop_name: String = "Tienda"
@export var shop_items: Array[ShopItemResource] = []

var player_in_area = false
var shop_ui = null
var shop_open = false

@onready var interaction_label = $InteractionLabel

func _ready():
	# Cargar la UI de la tienda
	var shop_ui_scene = load("res://Scenes/shop_ui.tscn")
	if shop_ui_scene:
		shop_ui = shop_ui_scene.instantiate()
		add_child(shop_ui)
		shop_ui.visible = false
		shop_ui.process_mode = Node.PROCESS_MODE_ALWAYS
		
		# Configurar título
		var title = shop_ui.get_node("Panel/Title")
		if title:
			title.text = shop_name
		
		# Conectar botón cerrar
		var close_btn = shop_ui.get_node("Panel/CloseButton")
		if close_btn:
			close_btn.pressed.connect(_close_shop)
		
		# Crear botones de items
		_create_item_buttons()
	
	interaction_label.visible = false

func _create_item_buttons():
	var grid = shop_ui.get_node("Panel/ItemsGrid")
	if not grid:
		return
	
	var coin_icon = load("res://items/item420.png")
	var font = load("res://pixel_art_font.ttf")
	
	for shop_item in shop_items:
		var item = shop_item.item
		var price = shop_item.price
		
		var button = Button.new()
		button.custom_minimum_size = Vector2(250, 160)
		button.clip_contents = true

		# CONTENEDOR PRINCIPAL
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		button.add_child(vbox)

		# ======================
		# ICONO DEL ITEM
		# ======================
		var item_icon = TextureRect.new()
		item_icon.texture = item.icon
		item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item_icon.custom_minimum_size = Vector2(64, 64)
		item_icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Pixel perfect (opcional pero recomendado)
		item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		vbox.add_child(item_icon)

		# ======================
		# NOMBRE DEL ITEM
		# ======================
		var name_label = Label.new()
		name_label.text = item.name
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		if font:
			name_label.add_theme_font_override("font", font)
		
		vbox.add_child(name_label)

		# ======================
		# PRECIO
		# ======================
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(hbox)

		var coin = TextureRect.new()
		coin.texture = coin_icon
		coin.custom_minimum_size = Vector2(24, 24)
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		hbox.add_child(coin)

		var price_label = Label.new()
		price_label.text = str(price)
		
		if font:
			price_label.add_theme_font_override("font", font)
		
		hbox.add_child(price_label)

		# ======================
		# VALIDACIÓN DE COMPRA (TOOLS)
		# ======================
		var player = _get_player()
		var can_buy = true
		
		if item.type == "Tool" and player and player.has_method("get_equipped_tool"):
			var current_tool = player.get_equipped_tool()
			
			if current_tool and current_tool.tool_level >= item.tool_level:
				can_buy = false
				button.tooltip_text = "Ya tienes una herramienta mejor o igual"
		
		button.disabled = not can_buy

		# ======================
		# METADATA Y SEÑAL
		# ======================
		button.set_meta("item", item)
		button.set_meta("price", price)
		button.pressed.connect(_on_buy_pressed.bind(button))

		grid.add_child(button)

# En shop_npc.gd, modifica _on_buy_pressed
func _on_buy_pressed(button):
	var item = button.get_meta("item")
	var price = button.get_meta("price")
	
	var inventory = get_tree().current_scene.find_child("Inventory", true, false)
	
	print("=== COMPRA ===")
	print("Item: ", item.name)
	print("Precio: ", price)
	print("Dinero actual: ", inventory.get_total_currency() if inventory else 0)
	
	if not inventory:
		print("ERROR: Inventory no encontrado")
		return
	
	# =========================
	# 🔥 VALIDAR ANTES DE COBRAR
	# =========================
	if item.type == "Tool":
		var player = _get_player()
		
		if player and player.has_method("get_equipped_tool"):
			var current_tool = player.get_equipped_tool()
			
			if current_tool and current_tool.tool_level >= item.tool_level:
				_show_message("Ya tienes una herramienta mejor o igual")
				return
	
	# =========================
	# 💰 VALIDAR DINERO
	# =========================
	if inventory.get_total_currency() < price:
		print("No tienes suficiente dinero")
		_show_message("No tienes suficiente dinero")
		return
	
	# =========================
	# 💸 COBRAR
	# =========================
	if not inventory.remove_currency(price):
		print("ERROR: No se pudo remover el dinero")
		return
	
	# =========================
	# 🎒 PROCESAR COMPRA
	# =========================
	if item.type == "Tool":
		var player = _get_player()
		
		if player and player.has_method("equip_tool"):
			var new_tool = item.duplicate()
			player.equip_tool(new_tool)
			
			print("Herramienta equipada: ", new_tool.name)
			_show_message("Compraste y equipaste " + item.name)
		else:
			print("ERROR: Player no encontrado")
	else:
		inventory.add_item(item)
		print("Compra exitosa")
		print("Dinero restante: ", inventory.get_total_currency())
		_show_message("Compraste " + item.name)

func _show_message(text):
	var msg = Label.new()
	msg.text = text
	msg.position = Vector2(200, 400)
	add_child(msg)
	await get_tree().create_timer(2).timeout
	msg.queue_free()

func _close_shop():
	
	shop_open = false
	
	if shop_ui:
		print("Ocultando shop_ui...")
		shop_ui.visible = false
		print("shop_ui.visible = ", shop_ui.visible)
	else:
		print("shop_ui es null")
	
	print("Reanudando juego...")
	get_tree().paused = false
	GlobalData.mouse_disable = true

func open_shop():
	
	if shop_open:
		return
	shop_open = true
	if shop_ui:
		shop_ui.visible = true
	get_tree().paused = true
	GlobalData.mouse_disable = false

func _input(event):
	if not player_in_area:
		return
	if event.is_action_pressed("interact"):
		if not shop_open:
			GlobalData.mouse_disable = false
			open_shop()
		else:
			_close_shop()

func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_area = true
		interaction_label.text = "Presiona [E] para comprar"
		interaction_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_area = false
		interaction_label.visible = false
		if shop_open:
			_close_shop()
func _get_player():
	return get_tree().current_scene.find_child("Player", true, false)
