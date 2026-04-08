extends VBoxContainer

func _ready():
	var inventory = get_tree().current_scene.find_child("Inventory", true, false)
	
	if inventory:
		inventory.item_changed.connect(_on_inventory_item_changed)
	else:
		print("❌ No se encontró Inventory")
		
func _on_inventory_item_changed():
	for recipe in get_children():
		recipe.check()
