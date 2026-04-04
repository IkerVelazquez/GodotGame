extends PanelContainer

var item: Item = null:
	set(value):
		item = value
 
		if value != null:
			$TextureRect.texture = value.icon
		else:
			$TextureRect.texture = null
 
func enable(value = true):
	$Panel.show_behind_parent = value
	return value
	
func get_item():
	return item
 
func check():
	var inventory = get_tree().current_scene.find_child("Inventory")
	
	if item != null:
		var needed = get_parent().recipe.count(item)
		var available = inventory.get_item_count(item)
		
		return enable(available >= needed)
