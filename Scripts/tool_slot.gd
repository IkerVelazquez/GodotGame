# ToolSlot.gd
extends PanelContainer
class_name ToolSlot

@onready var texture_rect = $TextureRect

var tool: Item = null:
	set(value):
		tool = value
		_update_display()

func _ready():
	_update_display()

func _update_display():
	if tool != null and tool.icon:
		texture_rect.texture = tool.icon
		print("Herramienta equipada: ", tool.name)
	else:
		texture_rect.texture = null
		print("Sin herramienta equipada")

func is_equipped() -> bool:
	return tool != null

func get_tool() -> Item:
	return tool

func clear():
	tool = null
