extends GridContainer

signal item_changed
signal currency_changed

var currency_panel = null
var items: Array = []
 
##region Testing
@export var ITEM : Item
#@export var ITEM2 : Item
#@export var ITEM3 : Item
func _ready():
	var player = get_parent()  # Porque Inventory es hijo directo de Player
	if player:
		currency_panel = player.find_child("CurrencyPanel", true, false)
	
	# Si no está en player, buscar en toda la escena
	if not currency_panel:
		currency_panel = get_tree().current_scene.find_child("CurrencyPanel", true, false)
		
	var slots = get_children()
	for i in range(slots.size()):
		slots[i].inventory = self
		slots[i].slot_index = i
	
	
	await get_tree().create_timer(2).timeout
	for i in range(1000):
		add_item(ITEM)
		#await get_tree().create_timer(0.1).timeout
	#await get_tree().create_timer(2).timeout
	#add_item(ITEM2)
	#await get_tree().create_timer(2).timeout
	#add_item(ITEM3)
##endregion
 
# 1. Buscar si ya existe ese item (stack)
func add_item(item):
	if item.type == "Currency":
		_add_currency(item)
		return

	# Buscar stack
	for i in get_children():
		if i is Slot and i.item == item:
			i.amount += 1
			item_changed.emit()
			return
	
	# Buscar vacío
	for i in get_children():
		if i is Slot and i.item == null:
			i.item = item
			i.amount = 1
			item_changed.emit()
			return
	
	# 2. Si no existe, usar slot vacío
	for i in get_children():
		if i.item == null:
			i.item = item
			i.amount = 1
			item_changed.emit()
			return
 
func remove_item(item):
	for i in get_children():
		if i is Slot and i.item == item:
			i.amount -= 1
			
			if i.amount <= 0:
				i.item = null
				i.amount = 0
			
			item_changed.emit()
			return
 
func is_available(item):
	for i in get_children():
		if i.item == item and i.amount > 0:
			return true
	return false
	
func get_item_count(item):
	var count = 0
	
	for i in get_children():
		if i is Slot and i.item == item:
			count += i.amount
	
	return count

func get_item_count_total(item: Item) -> int:
	var count = 0
	
	if item.type == "Currency":
		return _get_currency_amount(item)
	
	# Contar en inventario
	for i in get_children():
		if i is Slot and i.item == item:
			count += i.amount
	
	# Contar si es una herramienta y está equipada
	if item.type == "Tool":
		var player = _get_player()
		if player and player.has_method("get_equipped_tool"):
			var equipped = player.get_equipped_tool()
			if equipped and equipped.name == item.name:
				count += 1
	
	return count
	
func _get_currency_amount(coin: Item) -> int:
	if not currency_panel:
		return 0
	
	match coin.name:
		"Moneda de Cobre":
			return currency_panel.copper_coins
		"Moneda de Plata":
			return currency_panel.silver_coins
		"Moneda de Oro":
			return currency_panel.gold_coins
	return 0
	
func has_enough(item: Item, needed: int) -> bool:
	return get_item_count_total(item) >= needed
	
func is_available_total(item: Item) -> bool:
	return get_item_count_total(item) > 0

# Remover item (incluyendo desequipar si es necesario)
func remove_item_total(item: Item, amount: int = 1) -> bool:
	
	if item.type == "Currency":
		return _remove_currency(item, amount)
		
	var removed = 0
	
	# Primero remover del inventario
	for i in get_children():
		if i.item == item and removed < amount:
			var to_remove = min(i.amount, amount - removed)
			i.amount -= to_remove
			removed += to_remove
			
			if i.amount <= 0:
				i.item = null
				i.amount = 0
	
	# Si aún falta por remover y es herramienta, desequipar
	if removed < amount and item.type == "Tool":
		var player = _get_player()
		if player and player.has_method("get_equipped_tool"):
			var equipped = player.get_equipped_tool()
			if equipped and equipped.name == item.name:
				player.unequip_tool()
				removed += 1
	
	if removed > 0:
		item_changed.emit()
	
	return removed >= amount

func _get_player():
	return get_tree().current_scene.find_child("Player", true, false)

func _add_currency(coin: Item):
	
	
	if not currency_panel:
		
		return
	
	match coin.name:
		"Moneda de Cobre":
			# 1 moneda de cobre = 1 cobre
			currency_panel.add_copper(coin.value)
			
			
		"Moneda de Plata":
			# 1 moneda de plata = 1 plata (que equivale a 10 cobre)
			currency_panel.add_silver(coin.value)
		
			
		"Moneda de Oro":
			# 1 moneda de oro = 1 oro (que equivale a 100 cobre)
			currency_panel.add_gold(coin.value)
			
	
	currency_changed.emit()
	
func remove_currency(amount: int) -> bool:
	if currency_panel:
		var result = currency_panel.remove_copper(amount)
		return result
	return false

func get_currency_total() -> int:
	if currency_panel:
		return currency_panel.get_total_value()
	return 0

func _remove_currency(coin: Item, amount: int) -> bool:
	if not currency_panel:
		return false
	
	var total_value = coin.value * amount
	
	match coin.name:
		"Moneda de Cobre":
			return currency_panel.remove_copper(total_value)
		"Moneda de Plata":
			currency_panel.silver_coins -= amount
			currency_panel._convert_currency()
			currency_panel._update_display()
			return true
		"Moneda de Oro":
			currency_panel.gold_coins -= amount
			currency_panel._convert_currency()
			currency_panel._update_display()
			return true
	
	return false

# Inventory.gd - Añadir esta función
func get_total_currency() -> int:
	if currency_panel:
		return currency_panel.get_total_value()
	return 0

func set_slot_data(index: int, new_item: Item, new_amount: int):
	var slots = []
	
	for child in get_children():
		if child is Slot:
			slots.append(child)
	
	if index < 0 or index >= slots.size():
		return
	
	var slot = slots[index]
	slot.item = new_item
	slot.amount = new_amount
	
	item_changed.emit()
