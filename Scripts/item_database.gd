extends Node

signal item_database_loaded  # 🔥 Nueva señal

var items = {}
var loaded = false

func _ready():
	load_items()
	loaded = true
	emit_signal("item_database_loaded")  # 🔥 Emitir señal cuando termine
	print("✅ ItemDatabase completamente cargado")

func load_items():
	var path = "res://Resources/"
	var dir = DirAccess.open(path)
	
	if dir == null:
		print("❌ No se pudo abrir carpeta Items")
		return
	
	for file in dir.get_files():
		if file.ends_with(".tres"):
			var item = load(path + file)
			
			if item == null:
				print("❌ Error cargando:", file)
				continue
			
			if item.id == "":
				print("⚠️ Item sin ID:", file)
				continue
			
			var id = item.id.to_lower()
			items[id] = item
			print("✅ Registrado:", id, " - ", item.name)
	
	print("📦 Total items cargados: ", items.size())

func get_item(id: String):
	if not loaded:
		print("⚠️ ItemDatabase no ha terminado de cargar")
		return null
	
	id = id.to_lower()
	var item = items.get(id, null)
	
	if item == null:
		print("❌ No existe item con id:", id)
		print("IDs disponibles: ", items.keys())
	
	return item
