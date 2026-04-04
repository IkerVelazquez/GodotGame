extends PanelContainer
class_name Slot

@onready var texture_rect = $TextureRect
@onready var label = $TextureRect/Label
@onready var background = $Background

var rarity_textures = {
	"Common": preload("res://UI/common_border.png"),
	"Rare": preload("res://UI/rare_border.png"),
	"Epic": preload("res://UI/epic_border.png"),
	"Legendary": preload("res://UI/legendary_border.png"),
	"Unique": preload("res://UI/unique_border.png"),
	"Magic": preload("res://UI/magic_border.png")
}

var inventory = null
var slot_index: int = -1

var item: Item = null:
	set(value):
		item = value
		
		if item != null:
			texture_rect.texture = item.icon
		# 👇 aplicar fondo por rareza
			if rarity_textures.has(item.rarity):
				background.texture = rarity_textures[item.rarity]
			else:
				background.texture = null
		else:
			texture_rect.texture = null
			background.texture = null

var amount: int = 0:
	set(value):
		amount = value
		update_amount_label()

var flash_time := 0.0
var is_legendary := false

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	if item:
		get_tree().get_first_node_in_group("UI").tooltip.show_tooltip(
			item,
			get_global_mouse_position() + Vector2(-30,4)
		)

func _on_mouse_exited():
	get_tree().get_first_node_in_group("UI").tooltip.hide_tooltip()
	
func update_amount_label():
	if amount > 1:
		label.text = str(amount)
	else:
		label.text = ""

# =========================
# 🖱️ INICIAR DRAG
# =========================
func _get_drag_data(at_position):
	if item == null:
		return null
	
	# 🟫 Fondo (rareza)
	var bg = TextureRect.new()
	bg.texture = rarity_textures.get(item.rarity, null)
	bg.custom_minimum_size = Vector2(6, 6)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# 🖼️ Icono
	var icon = TextureRect.new()
	icon.texture = item.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(7, 7)
	
	# Centrar icono dentro del fondo
	icon.anchor_left = 0.5
	icon.anchor_top = 0.5
	icon.anchor_right = 0.5
	icon.anchor_bottom = 0.5
	icon.offset_left = -8
	icon.offset_top = -8
	icon.offset_right = 8
	icon.offset_bottom = 8
	
	bg.add_child(icon)
	
	# Transparencia ligera (opcional pero pro)
	bg.modulate.a = 0.9
	
	set_drag_preview(bg)
	
	return {
		"item": item,
		"amount": amount,
		"from_slot": self,
		"from_index": slot_index
	}

# =========================
# ✅ VALIDAR DROP
# =========================
func _can_drop_data(at_position, data):
	# Solo permitir si viene de inventario
	if not data.has("from_slot"):
		return false
	
	return data["from_slot"].inventory == inventory

# =========================
# 🔄 SOLTAR (SWAP)
# =========================
func _drop_data(at_position, data):
	var from_slot = data["from_slot"]
	var from_index = data["from_index"]
	
	if from_slot == self:
		return
	
	# Guardar datos actuales
	var temp_item = item
	var temp_amount = amount
	
	# Intercambiar
	inventory.set_slot_data(slot_index, data["item"], data["amount"])
	inventory.set_slot_data(from_index, temp_item, temp_amount)
