extends Node2D

@export var test_scene: NodePath
@onready var test_ref: Node = get_node(test_scene)


# Texturas de los personajes (asígnalas en el editor)
@export var james_texture: Texture2D
@export var kai_texture: Texture2D
@export var nerine_texture: Texture2D  
@export var kinima_texture: Texture2D
@export var wildkinima_texture: Texture2D
@export var lucius_texture: Texture2D
@export var futuristlucius_texture: Texture2D
@export var vandice_texture: Texture2D
@export var kira_texture: Texture2D
@export var therese_texture: Texture2D
@export var thai_texture: Texture2D
@export var kamura_texture: Texture2D


# Contenedores para mostrar el equipo seleccionado
@onready var roster_slots = [
	{"sprite": $Slot1/Sprite2D, "label": $Slot1/Label, "button": $Slot1/RemoveButton1, "character": null},
	{"sprite": $Slot2/Sprite2D, "label": $Slot2/Label, "button": $Slot2/RemoveButton2, "character": null},
	{"sprite": $Slot3/Sprite2D, "label": $Slot3/Label, "button": $Slot3/RemoveButton3, "character": null}
]

# Diccionario que define la clase de cada personaje
var character_classes = {
	"james": {"class": "melee", "texture": james_texture},
	"kai": {"class": "melee", "texture": kai_texture},
	"nerine": {"class": "melee", "texture": nerine_texture}, 
	"kinima": {"class": "ranger", "texture": kinima_texture},
	"wildkinima": {"class": "ranger", "texture": wildkinima_texture},
	"lucius": {"class": "elementor", "texture": lucius_texture},
	"futuristlucius": {"class": "elementor", "texture": futuristlucius_texture},
	"vandice": {"class": "ranger", "texture": vandice_texture},
	"kira": {"class": "melee", "texture": kira_texture},
	"therese": {"class": "paladin", "texture": therese_texture},
	"thai": {"class": "paladin", "texture": thai_texture},
	"kamura": {"class": "ninja", "texture": kamura_texture},
}

# Array para llevar registro de personajes seleccionados
var selected_characters: Array = []
var spawned_characters: Array = []

func _ready():
	_load_textures_from_buttons()
	
	selected_characters = []
	spawned_characters = []
	_update_roster_display()
	$ConfirmButton.visible = false

func _load_textures_from_buttons():
	# Obtener las texturas de los botones existentes
	james_texture = $Buttons/JamesButton.icon
	kai_texture = $Buttons/KaiButton.icon
	nerine_texture = $Buttons/NerineButton.icon
	kinima_texture = $Buttons/KinimaButton.icon
	wildkinima_texture = $Buttons/WildkinimaButton.icon
	lucius_texture = $Buttons/LuciusButton.icon
	futuristlucius_texture = $Buttons/FuturistluciusButton.icon
	kira_texture = $Buttons/KiraButton.icon
	therese_texture = $Buttons/ThereseButton.icon
	thai_texture = $Buttons/ThaiButton.icon
	kamura_texture = $Buttons/KamuraButton.icon
	
	# Actualizar el diccionario
	character_classes["james"]["texture"] = james_texture
	character_classes["kai"]["texture"] = kai_texture
	character_classes["nerine"]["texture"] = nerine_texture
	character_classes["kinima"]["texture"] = kinima_texture
	character_classes["wildkinima"]["texture"] = wildkinima_texture
	character_classes["lucius"]["texture"] = lucius_texture
	character_classes["futuristlucius"]["texture"] = futuristlucius_texture
	character_classes["vandice"]["texture"] = vandice_texture
	character_classes["kira"]["texture"] = kira_texture
	character_classes["therese"]["texture"] = therese_texture
	character_classes["thai"]["texture"] = thai_texture
	character_classes["kamura"]["texture"] = kamura_texture
	
func _on_james_pressed() -> void:
	_add_character_to_roster("james")
func _on_kai_pressed() -> void:
	_add_character_to_roster("kai")
func _on_kinima_pressed() -> void:
	_add_character_to_roster("kinima")
func _on_wildkinima_pressed() -> void:
	_add_character_to_roster("wildkinima")
func _on_lucius_pressed() -> void:
	_add_character_to_roster("lucius")
func _on_futuristlucius_pressed() -> void:
	_add_character_to_roster("futuristlucius")
func _on_nerine_pressed() -> void:
	_add_character_to_roster("nerine")
func _on_vandice_pressed() -> void:
	_add_character_to_roster("vandice")
func _on_kira_pressed() -> void:
	_add_character_to_roster("kira")
func _on_therese_pressed() -> void:
	_add_character_to_roster("therese")
func _on_thai_pressed() -> void:
	_add_character_to_roster("thai")
func _on_kamura_pressed() -> void:
	_add_character_to_roster("kamura")

# Función para agregar personaje al roster
func _add_character_to_roster(character_name: String):
	print("Agregando personaje: ", character_name)
	
	# Verificar si ya está en el equipo
	for slot in roster_slots:
		if slot["character"] == character_name:
			print("  ❌ Ya está en el equipo")
			return
	
	# Verificar si hay slot disponible
	var empty_slot = null
	for slot in roster_slots:
		if slot["character"] == null:
			empty_slot = slot
			print("  ✅ Slot disponible encontrado")
			break
	
	if empty_slot == null:
		print("  ❌ No hay slots disponibles")
		return
	
	var char_data = character_classes[character_name]
	print("  Datos del personaje:")
	print("    - Clase: ", char_data["class"])
	print("    - Textura: ", char_data["texture"] != null)
	
	# Cargar la escena en el momento de spawnear
	var character_scene = _get_character_scene(character_name)
	if character_scene == null:
		push_error("No se pudo cargar la escena para: " + character_name)
		return
	
	# Spawnear personaje en la escena de prueba
	var spawned_char = test_ref.spawn_character(character_scene)
	if spawned_char:
		spawned_characters.append({"name": character_name, "node": spawned_char})
		
		# DEBUG: Estado del slot antes de asignar
		print("  Estado del slot antes de asignar:")
		print("    - Sprite visible: ", empty_slot["sprite"].visible)
		print("    - Label visible: ", empty_slot["label"].visible)
		print("    - Button visible: ", empty_slot["button"].visible)
		
		# Agregar al roster UI
		empty_slot["character"] = character_name
		empty_slot["sprite"].texture = char_data["texture"]
		empty_slot["label"].text = char_data["class"].capitalize()
		empty_slot["sprite"].visible = true
		empty_slot["label"].visible = true
		empty_slot["button"].visible = true
		
		# DEBUG: Estado del slot después de asignar
		print("  Estado del slot después de asignar:")
		print("    - Sprite visible: ", empty_slot["sprite"].visible)
		print("    - Label visible: ", empty_slot["label"].visible)
		print("    - Button visible: ", empty_slot["button"].visible)
		print("    - Textura asignada: ", empty_slot["sprite"].texture != null)
		print("    - Texto del label: ", empty_slot["label"].text)
		
		# Deshabilitar botones de la misma clase
		_disable_class_buttons(char_data["class"])
		
		# Mostrar botón de confirmar
		$ConfirmButton.visible = true
		
		# AGREGAR AL PARTY - ESTO ES LO MÁS IMPORTANTE
		GameEvents.add_to_party(char_data["class"])
		
		if selected_characters == null:
			selected_characters = []
		selected_characters.append(character_name)
		
		print("  ✅ Personaje agregado exitosamente")
	else:
		print("  ❌ Error al spawnear personaje")

# Función para cargar la escena según el personaje
func _get_character_scene(character_name: String) -> PackedScene:
	match character_name:
		"james":
			return preload("res://Characters/james_axe_1.tscn")
		"kai":
			return preload("res://Characters/kai.tscn")
		"nerine":
			return preload("res://Characters/nerine_sword_1.tscn")
		"kinima":
			return preload("res://Characters/kinima.tscn")
		"wildkinima":
			return preload("res://Characters/wild_kinima.tscn")
		"lucius":
			return preload("res://Characters/lucius.tscn")
		"futuristlucius":
			return preload("res://futurist_lucius.tscn")
		"vandice":
			return preload("res://Characters/vandice.tscn")
		"kira":
			return preload("res://Characters/kira.tscn")
		"therese":
			return preload("res://Characters/therese.tscn")
		"thai":
			return preload("res://Characters/thai.tscn")
		"kamura":
			return preload("res://Characters/kamura.tscn")
		_:
			return null

# Función para eliminar personaje del roster
# Función para eliminar personaje del roster
func _remove_character_from_roster(slot_index: int):
	print("=== ELIMINANDO PERSONAJE DEL SLOT ", slot_index + 1, " ===")
	var slot = roster_slots[slot_index]
	var character_name = slot["character"]
	
	if character_name:
		print("  Eliminando: ", character_name)
		var char_data = character_classes[character_name]
		
		# Eliminar personaje de la escena
		for i in range(spawned_characters.size()):
			if spawned_characters[i]["name"] == character_name:
				if is_instance_valid(spawned_characters[i]["node"]):
					# IMPORTANTE: Liberar la posición de spawn ANTES de eliminar
					test_ref.free_spawn_position(spawned_characters[i]["node"])
					spawned_characters[i]["node"].queue_free()
				spawned_characters.remove_at(i)
				break
		
		# Limpiar slot
		slot["character"] = null
		slot["sprite"].visible = false
		slot["label"].visible = false
		slot["button"].visible = false
		
		# Remover de selected_characters
		if selected_characters != null:
			selected_characters.erase(character_name)
		
		# Re-habilitar botones de la misma clase
		_enable_class_buttons(char_data["class"])
		
		GameEvents.remove_from_party(char_data["class"])
		
		# Ocultar botón de confirmar si no hay personajes
		if _get_selected_count() == 0:
			$ConfirmButton.visible = false
		
		print("  ✅ Personaje eliminado")
	else:
		print("  ❌ No hay personaje en este slot")

func _disable_class_buttons(class_type: String):
	for char_name in character_classes:
		if character_classes[char_name]["class"] == class_type:
			var button = get_node("Buttons/" + char_name.capitalize() + "Button")
			if button:
				button.disabled = true
				button.modulate.a = 0.5

func _enable_class_buttons(class_type: String):
	var class_still_in_use = false
	for slot in roster_slots:
		if slot["character"] != null:
			var char_name = slot["character"]
			if character_classes[char_name]["class"] == class_type:
				class_still_in_use = true
				break
	
	if not class_still_in_use:
		for char_name in character_classes:
			if character_classes[char_name]["class"] == class_type:
				var button = get_node("Buttons/" + char_name.capitalize() + "Button")
				if button:
					button.disabled = false
					button.modulate.a = 1.0

func _on_confirm_button_pressed():
	for char_name in character_classes:
		var button = get_node("Buttons/" + char_name.capitalize() + "Button")
		if button:
			button.disabled = true
			button.modulate.a = 0.5
	
	for slot in roster_slots:
		slot["button"].visible = false
	
	$ConfirmButton.visible = false

func _get_selected_count() -> int:
	var count = 0
	if selected_characters == null:
		return 0
	for slot in roster_slots:
		if slot["character"] != null:
			count += 1
	return count

func _update_roster_display():
	for slot in roster_slots:
		slot["sprite"].visible = slot["character"] != null
		slot["label"].visible = slot["character"] != null
		slot["button"].visible = slot["character"] != null

func _on_remove_button_1_pressed():
	_remove_character_from_roster(0)

func _on_remove_button_2_pressed():
	_remove_character_from_roster(1)

func _on_remove_button_3_pressed():
	_remove_character_from_roster(2)

func _on_continue_pressed() -> void:
	visible = false
	GameEvents.continue_pressed = true
