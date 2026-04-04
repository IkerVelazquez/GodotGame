# CurrencyPanel.gd - Versión corregida
extends VBoxContainer

@onready var copper_label = $Copper/Label
@onready var silver_label = $Silver/Label
@onready var gold_label = $Gold/Label

var copper_coins: int = 0
var silver_coins: int = 0
var gold_coins: int = 0

func _ready():
	_update_display()

func add_copper(amount: int):
	copper_coins += amount
	_convert_currency()
	_update_display()

func add_silver(amount: int):
	silver_coins += amount
	_convert_currency()
	_update_display()

func add_gold(amount: int):
	gold_coins += amount
	_convert_currency()
	_update_display()

func remove_copper(amount: int) -> bool:
	
	# Calcular total en cobre
	var total_copper = copper_coins + (silver_coins * 10) + (gold_coins * 100)
	
	if total_copper < amount:
		print("No hay suficiente dinero")
		return false
	
	# Restar
	total_copper -= amount
	
	# Reconvertir
	gold_coins = total_copper / 100
	total_copper -= gold_coins * 100
	
	silver_coins = total_copper / 10
	total_copper -= silver_coins * 10
	
	copper_coins = total_copper
	
	
	_update_display()
	return true

func get_total_value() -> int:
	return copper_coins + (silver_coins * 10) + (gold_coins * 100)

func _convert_currency():
	# Convertir cobre a plata (10 cobre = 1 plata)
	var copper_to_silver = copper_coins / 10
	if copper_to_silver > 0:
		silver_coins += copper_to_silver
		copper_coins -= copper_to_silver * 10
	
	# Convertir plata a oro (10 plata = 1 oro)
	var silver_to_gold = silver_coins / 10
	if silver_to_gold > 0:
		gold_coins += silver_to_gold
		silver_coins -= silver_to_gold * 10
	
	copper_coins = max(copper_coins, 0)
	silver_coins = max(silver_coins, 0)
	gold_coins = max(gold_coins, 0)

func _update_display():
	if copper_label:
		copper_label.text = str(copper_coins)
	if silver_label:
		silver_label.text = str(silver_coins)
	if gold_label:
		gold_label.text = str(gold_coins)
	
func save() -> Dictionary:
	return {
		"copper": copper_coins,
		"silver": silver_coins,
		"gold": gold_coins
	}

func load(data: Dictionary):
	copper_coins = data.get("copper", 0)
	silver_coins = data.get("silver", 0)
	gold_coins = data.get("gold", 0)
	_convert_currency()
	_update_display()
