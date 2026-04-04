extends Control

var label

func _ready():
	label = $Panel/RichTextLabel
	


func show_tooltip(item, position):
	if label == null:
		label = $Panel/RichTextLabel

	label.bbcode_enabled = true
	label.text = "[b]" + item.name + "[/b]\n" + item.description

	global_position = position
	visible = true
	
	label.text = "[b]" + item.name + "[/b]\n" + item.description
	
	# 🎨 COLOR POR RAREZA
	match item.rarity:
		"Common":
			label.modulate = Color.WHITE
		"Rare":
			label.modulate = Color(0.3, 0.6, 1)
		"Epic":
			label.modulate = Color(0.7, 0.3, 1)
		"Legendary":
			label.modulate = Color(1, 0.8, 0.2)

	global_position = position
	visible = true


func hide_tooltip():
	visible = false
