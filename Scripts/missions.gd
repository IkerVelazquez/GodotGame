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
	MisionSystem.mision_progreso_actualizado.connect(_on_mision_progreso_actualizado)
	
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
	print("📋 ACTUALIZANDO TODAS LAS MISIONES")
	
	# Limpiar labels existentes
	for child in misiones_container.get_children():
		if child is Label:
			child.queue_free()
	
	# Obtener misiones activas
	var misiones_activas = MisionSystem.get_active_missions()
	
	print("📊 Misiones activas obtenidas: ", misiones_activas.size())
	
	for mision in misiones_activas:
		print("  - Misión encontrada: ", mision.nombre)
		print("    Completada: ", mision.get("completada", false))
		print("    Objetivos: ", mision.get("objetivos", {}))
	
	# Crear un label por cada misión
	for mision in misiones_activas:
		print("🔨 Llamando a crear_label_mision para: ", mision.nombre)
		crear_label_mision(mision.nombre, mision.get("descripcion", ""))
	

func crear_label_mision(nombre: String, descripcion: String = ""):
	"""Crea un nuevo Label para una misión"""
	print("🔨=== CREANDO LABEL ===🔨")
	print("  Nombre: ", nombre)
	print("  Descripción: ", descripcion)
	
	var label = Label.new()
	label.name = "Mision_" + nombre.replace(" ", "_").replace(".", "")
	label.set_meta("nombre_mision", nombre)
	
	# Texto simple por ahora para probar
	label.text = nombre + "\n   • Cargando..."
	
	# Aplicar estilos
	if fuente_personalizada:
		label.add_theme_font_override("font", fuente_personalizada)
	label.add_theme_font_size_override("font_size", 16)
	
	if stylebox_imagen and stylebox_imagen.texture:
		label.add_theme_stylebox_override("normal", stylebox_imagen)
	else:
		label.add_theme_stylebox_override("normal", label_style)
	
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	
	misiones_container.add_child(label)
	print("  Label añadido al contenedor. Hijos ahora: ", misiones_container.get_child_count())
	
	# Animación de entrada
	label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	
	# Intentar actualizar con datos reales después de un momento
	await get_tree().create_timer(0.2).timeout
	_actualizar_texto_mision(label, nombre)
	
	print("✅ Label creado: ", label.name)

func _on_mision_agregada(nombre_mision):
	"""Callback cuando se añade una nueva misión"""
	print("📌=== MISIÓN AGREGADA SIGNAL RECIBIDA ===📌")
	print("  Nombre: ", nombre_mision)
	print("  ¿Está completada? ", MisionSystem.is_mission_completed(nombre_mision))
	
	# Verificar si la misión ya está completada
	if MisionSystem.is_mission_completed(nombre_mision):
		print("⚠️ La misión ya está completada, no se muestra en UI")
		return
	
	# Esperar un frame
	await get_tree().process_frame
	
	print("  Después de esperar - ¿Está completada? ", MisionSystem.is_mission_completed(nombre_mision))
	
	# Verificar si la misión ya existe en UI
	var nombre_label_ui = "Mision_" + nombre_mision.replace(" ", "_").replace(".", "")
	for child in misiones_container.get_children():
		if child is Label and child.name == nombre_label_ui:
			print("⚠️ La misión ya existe en UI")
			return
	
	# Obtener los detalles de la misión
	var nombre_buscar = nombre_mision.strip_edges().to_lower()
	var mision_data = MisionSystem.get_mission_data(nombre_buscar)
	
	print("  Datos de misión obtenidos: ", mision_data)
	
	if mision_data.is_empty():
		print("❌ No se encontraron datos para la misión: ", nombre_mision)
		await get_tree().create_timer(0.1).timeout
		mision_data = MisionSystem.get_mission_data(nombre_buscar)
		if mision_data.is_empty():
			print("❌ Aún sin datos, abortando creación de label")
			return
	
	var nombre = mision_data.get("nombre", nombre_mision)
	var descripcion = mision_data.get("descripcion", "")
	
	print("✅ Creando label para misión: ", nombre)
	crear_label_mision(nombre, descripcion)

func _on_mision_completada(nombre_mision):
	"""Callback cuando se completa una misión"""
	print("🎉 Misión completada en UI: ", nombre_mision)
	
	var nombre_label = "Mision_" + nombre_mision.replace(" ", "_").replace(".", "")
	
	for child in misiones_container.get_children():
		if child is Label:
			if child.name.to_lower() == nombre_label.to_lower():
				print("✅ Label encontrado, aplicando efecto verde")
				child.modulate = Color(0.0, 1.0, 0.0)
				await get_tree().create_timer(1.0).timeout
				child.queue_free()
				break
			
	
		
# Missions.gd - Versión que maneja múltiples objetivos por misión
func _actualizar_texto_mision(label: Label, nombre_mision: String):
	"""Actualiza el texto del label mostrando todos los objetivos"""
	print("📝 Actualizando texto para: ", nombre_mision)
	
	# 🔥 Normalizar el nombre para buscar
	var nombre_buscar = nombre_mision.strip_edges().to_lower()
	var mision_data = MisionSystem.get_mission_data(nombre_buscar)
	
	# Verificar si la misión existe
	if mision_data.is_empty():
		print("⚠️ No se encontraron datos para la misión: ", nombre_mision)
		label.text = nombre_mision
		return
	
	var objetivos = mision_data.get("objetivos", {})
	var progreso = mision_data.get("progreso", {})
	var descripcion = mision_data.get("descripcion", "")
	
	print("📊 Objetivos encontrados: ", objetivos)
	print("📈 Progreso encontrado: ", progreso)
	
	var texto = mision_data.get("nombre", nombre_mision)
	
	# Mostrar cada objetivo con su progreso
	if not objetivos.is_empty():
		texto += "\n"
		for objetivo in objetivos.keys():
			var actual = progreso.get(objetivo, 0)
			var total = objetivos[objetivo]
			var porcentaje = (float(actual) / total) * 100 if total > 0 else 0
			
			# Nombre legible del objetivo
			var nombre_objetivo = _obtener_nombre_objetivo(objetivo)
			
			# Agregar al texto
			texto += "   • " + nombre_objetivo + ": " + str(actual) + "/" + str(total)
			if total > 0:
				texto += " (" + str(floor(porcentaje)) + "%)"
			
			texto += "\n"
	
	# Si tiene descripción y no hay objetivos, mostrarla
	elif descripcion != "":
		texto += "\n   " + descripcion
	
	# Eliminar el último salto de línea si existe
	texto = texto.rstrip("\n")
	
	label.text = texto
	print("✅ Texto actualizado: ", texto)
	
	# Cambiar color según progreso
	_actualizar_color_segun_progreso(label, objetivos, progreso)

func _obtener_nombre_objetivo(objetivo: String) -> String:
	"""Convierte el ID del objetivo a un nombre legible"""
	var nombres = {
		"madera": "Madera",
		"piedra": "Piedra", 
		"mineral": "Mineral",
		"slimes": "Slimes",
		"zombies": "Zombies",
		"enemigos": "Enemigos"
	}
	return nombres.get(objetivo, objetivo.capitalize())

func _crear_barra_progreso(actual: int, total: int, ancho_maximo: int = 20) -> String:
	"""Crea una barra de progreso visual (opcional)"""
	if total == 0:
		return ""
	
	var porcentaje = float(actual) / total
	var filled = int(ancho_maximo * porcentaje)
	var empty = ancho_maximo - filled
	
	return "\n     [" + "█" * filled + "░" * empty + "]"

func _actualizar_color_segun_progreso(label: Label, objetivos: Dictionary, progreso: Dictionary):
	"""Cambia el color del texto según el progreso"""
	if objetivos.is_empty():
		return
	
	# Calcular progreso total
	var total_actual = 0
	var total_necesario = 0
	
	for objetivo in objetivos.keys():
		total_actual += progreso.get(objetivo, 0)
		total_necesario += objetivos[objetivo]
	
	var porcentaje = float(total_actual) / total_necesario if total_necesario > 0 else 0
	
	# Cambiar color según porcentaje
	if porcentaje >= 1.0:
		label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))  # Verde
	elif porcentaje >= 0.5:
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))  # Amarillo
	else:
		label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))  # Naranja
		
func _on_mision_progreso_actualizado(nombre_mision: String, progreso_actual: int, progreso_total: int):
	"""Se llama cuando se actualiza el progreso de una misión"""
	print("🔄 Progreso actualizado: ", nombre_mision, " - ", progreso_actual, "/", progreso_total)
	
	# 🔥 Normalizar el nombre para buscar el label
	var nombre_label = "Mision_" + nombre_mision.replace(" ", "_").replace(".", "")
	
	for child in misiones_container.get_children():
		if child is Label and child.name.to_lower() == nombre_label.to_lower():
			# Pasar el nombre original para que _actualizar_texto_mision lo normalice
			_actualizar_texto_mision(child, nombre_mision)
			break
			
func limpiar_misiones_completadas():
	"""Elimina todas las misiones completadas con animación"""
	var misiones = MisionSystem.get_all_missions()
	
	for key in misiones.keys():
		if misiones[key].completada:
			var nombre_label = "Mision_" + key.replace(" ", "_").replace(".", "")
			
			for child in misiones_container.get_children():
				if child is Label and child.name == nombre_label:
					# Animación de salida
					var tween = create_tween()
					tween.tween_property(child, "modulate:a", 0.0, 0.3)
					await tween.finished
					child.queue_free()
					break
			
			MisionSystem.remove_mission(key)
