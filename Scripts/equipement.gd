# EquipmentUI.gd
extends HBoxContainer

@onready var tool_slot = $ToolSlot  # Asegúrate que el hijo se llame ToolSlot

var current_tool: Item = null

func _ready():
	print("EquipmentUI listo")
	if tool_slot:
		tool_slot.tool = null
	else:
		print("ERROR: No se encontró ToolSlot como hijo de EquipmentUI")

func equip_tool(tool: Item):
	print("Equipando: ", tool.name)
	current_tool = tool
	if tool_slot:
		tool_slot.tool = tool
	else:
		print("ERROR: tool_slot es null")

func get_equipped_tool():
	if tool_slot:
		return tool_slot.tool
	return null

func unequip_tool():
	if tool_slot:
		tool_slot.tool = null
	current_tool = null
