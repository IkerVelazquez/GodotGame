# Item.gd (modificado)
extends Resource
class_name Item

@export var icon: Texture2D
@export var name: String
@export var recipe: Array[Item]
@export var id: String

@export_enum("Material", "Weapon", "Tool", "Consumable", "Currency") 
var type: String = "Material"

@export var tool_type: String = ""  # "pickaxe", "axe", "sword", etc.
@export var tool_level: int = 1    # Fuerza de la herramienta (1=basico, 2=medio, 3=avanzado)

@export var value: int = 0

@export_multiline var description: String

@export_enum("Common", "Rare", "Epic", "Legendary", "Unique", "Magic")
var rarity: String = "Common"
