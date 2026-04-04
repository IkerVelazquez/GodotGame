extends Control

@onready var misiones_container = $VBoxContainer

var fuente_personalizada: Font
var stylebox_imagen: StyleBoxTexture
var label_style: StyleBoxFlat

func _ready():
	cargar_recursos()
	
	# Conectar señales
	MisionSystem.mision_agregada.connect(_on_mision_agregada)
	MisionSystem.mision_completada.connect(_on_mision_completada)
	
	crear_estilo_labels()
	actualizar_todas_las_misiones()

func cargar_recursos():
	# Cargar fuente
	fuente_personalizada = load("res://pixel_art_font.ttf")
	
	# Crear StyleBoxTexture con imagen de fondo
	stylebox_imagen = StyleBoxTexture.new()
	var textura_fondo = load("res://Images/paper_text.png")
	if textura_fondo:
		stylebox_imagen.texture = textura_fondo
		
		# Márgenes para evitar que se deforme la imagen
		stylebox_imagen.expand_margin_left = 29
		stylebox_imagen.expand_margin_right = 29
		stylebox_imagen.expand_margin_top = 3
		stylebox_imagen.expand_margin_bottom = 3
		
		# Espacio interno para el texto
		stylebox_imagen.content_margin_left = 12
		stylebox_imagen.content_margin_right = 12
		stylebox_imagen.content_margin_top = 6
		stylebox_imagen.content_margin_bottom = 6
	else:
		print("⚠️ No se pudo cargar la textura de fondo")

func crear_estilo_labels():
	"""Crea un estilo visual alternativo para los labels (fallback)"""
	label_style = StyleBoxFlat.new()
	label_style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	label_style.corner_radius_top_left = 5
	label_style.corner_radius_top_right = 5
	label_style.corner_radius_bottom_left = 5
	label_style.corner_radius_bottom_right = 5
	label_style.border_width_left = 2
	label_style.border_width_right = 2
	label_style.border_width_top = 2
	label_style.border_width_bottom = 2
	label_style.border_color = Color(0.8, 0.6, 0.2, 1.0)

func actualizar_todas_las_misiones():
	"""Limpia y recrea todos los labels según las misiones activas"""
	# Limpiar labels existentes
	for child in misiones_container.get_children():
		if child is Label:
			child.queue_free()
	
	# Obtener misiones activas
	var misiones_activas = MisionSystem.get_active_missions()
	
	# Crear un label por cada misión
	for mision in misiones_activas:
		crear_label_mision(mision.nombre, mision.get("descripcion", ""))

func crear_label_mision(nombre: String, descripcion: String = ""):
	"""Crea un nuevo Label para una misión"""
	var label = Label.new()
	label.name = "Mision_" + nombre.replace(" ", "_").replace(".", "")
	
	# Configurar texto
	if descripcion != "":
		label.text = nombre + "\n   " + descripcion
	else:
		label.text = nombre
	
	# ✅ Aplicar la fuente
	if fuente_personalizada:
		label.add_theme_font_override("font", fuente_personalizada)
	label.add_theme_font_size_override("font_size", 16)
	
	# ✅ Aplicar el StyleBoxTexture con la imagen de fondo
	if stylebox_imagen and stylebox_imagen.texture:
		label.add_theme_stylebox_override("normal", stylebox_imagen)
	else:
		# Fallback: usar StyleBoxFlat
		label.add_theme_stylebox_override("normal", label_style)
	
	# Colores del texto
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Añadir al contenedor
	misiones_container.add_child(label)
	
	# Animación de entrada
	label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)

func _on_mision_agregada(nombre_mision):
	"""Callback cuando se añade una nueva misión"""
	# Verificar si la misión ya existe
	for child in misiones_container.get_children():
		if child is Label and child.name == "Mision_" + nombre_mision.replace(" ", "_").replace(".", ""):
			return
	
	# Obtener los detalles de la misión
	var misiones = MisionSystem.get_active_missions()
	for mision in misiones:
		if mision.nombre == nombre_mision:
			crear_label_mision(mision.nombre, mision.get("descripcion", ""))
			break

func _on_mision_completada(nombre_mision):
	"""Callback cuando se completa una misión"""
	var nombre_label = "Mision_" + nombre_mision.replace(" ", "_").replace(".", "")
	for child in misiones_container.get_children():
		if child is Label and child.name == nombre_label:
			# Cambiar estilo visual
			child.queue_free()
			break
			
	
		

func limpiar_misiones_completadas():
	"""Elimina todas las misiones completadas"""
	var misiones = MisionSystem.get_all_missions()
	for key in misiones.keys():
		if misiones[key].completada:
			var nombre_label = "Mision_" + key.replace(" ", "_").replace(".", "")
			for child in misiones_container.get_children():
				if child is Label and child.name == nombre_label:
					child.queue_free()
					break
			MisionSystem.remove_mission(key)
