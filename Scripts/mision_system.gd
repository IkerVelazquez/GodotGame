# MisionSystem.gd (Autoload)
extends Node

# Diccionario para almacenar todas las misiones
var misiones_activas = {}
var misiones_completadas = {}  # Historial de misiones completadas

# Señales
signal mision_agregada(nombre_mision)
signal mision_completada(nombre_mision)
signal mision_progreso_actualizado(nombre_mision, progreso_actual, progreso_total)

# Constantes
const SAVE_PATH = "user://misiones.save"

func _ready():
	# Cargar misiones guardadas al iniciar
	cargar_misiones()
	
	# Asegurar que el autoload persiste
	process_mode = Node.PROCESS_MODE_ALWAYS

# ============================================
# FUNCIONES PRINCIPALES
# ============================================

# MisionSystem.gd - Modificar add_mission()
# MisionSystem.gd
func add_mission(nombre_mision: String, descripcion: String = "", objetivos: Dictionary = {}):
	print("🔍 Agregando misión: ", nombre_mision)
	
	var key = nombre_mision.strip_edges().to_lower()
	
	# Verificar si ya está completada
	if misiones_completadas.has(key):
		print("⚠️ La misión ya fue completada anteriormente: ", nombre_mision)
		return false
	
	# Verificar si ya está activa
	if misiones_activas.has(key):
		print("⚠️ La misión ya está activa: ", nombre_mision)
		return false
	
	# 🔥 IMPORTANTE: Convertir objetivos a formato serializable
	var objetivos_serializables = {}
	for objetivo in objetivos:
		# Si el objetivo es un Item, guardar su ID
		if objetivos[objetivo] is Item:
			objetivos_serializables[objetivo] = objetivos[objetivo].id
		else:
			objetivos_serializables[objetivo] = objetivos[objetivo]
	
	# Crear misión con objetivos serializables
	misiones_activas[key] = {
		"nombre": nombre_mision,
		"descripcion": descripcion,
		"completada": false,
		"objetivos": objetivos_serializables,  # Usar versión serializable
		"progreso": {},
		"fecha_agregada": Time.get_unix_time_from_system(),
		"recompensas": {}
	}
	
	# Inicializar progreso
	for objetivo in objetivos_serializables.keys():
		misiones_activas[key]["progreso"][objetivo] = 0
	
	print("✅ Misión añadida: ", nombre_mision)
	print("📋 Objetivos guardados: ", objetivos_serializables)
	mision_agregada.emit(nombre_mision)
	
	# Guardar inmediatamente
	guardar_misiones()
	
	return true

# MisionSystem.gd - Completar update_mission_progress
# MisionSystem.gd
# MisionSystem.gd
func update_mission_progress(nombre_mision: String, objetivo: String, cantidad: int = 1):
	var key = nombre_mision.strip_edges().to_lower()
	
	print("📊 Actualizando progreso - Misión: ", nombre_mision, " Objetivo: ", objetivo, " Cantidad: ", cantidad)
	
	if not misiones_activas.has(key):
		print("❌ Misión no encontrada: ", nombre_mision)
		return false
	
	var mision = misiones_activas[key]
	
	# Verificar si la misión ya está completada
	if mision.completada:
		print("⚠️ La misión ya está completada")
		return false
	
	# Verificar si el objetivo existe
	if not mision.objetivos.has(objetivo):
		print("⚠️ Objetivo no encontrado en misión: ", objetivo)
		print("📋 Objetivos disponibles: ", mision.objetivos.keys())
		return false
	
	# Asegurar que el progreso existe
	if not mision.progreso.has(objetivo):
		mision.progreso[objetivo] = 0
	
	# Actualizar progreso
	var progreso_anterior = mision.progreso[objetivo]
	var progreso_necesario = mision.objetivos[objetivo]
	var nuevo_progreso = min(progreso_anterior + cantidad, progreso_necesario)
	mision.progreso[objetivo] = nuevo_progreso
	
	print("📊 Progreso: ", nuevo_progreso, "/", progreso_necesario)
	
	# Emitir señal
	mision_progreso_actualizado.emit(nombre_mision, nuevo_progreso, progreso_necesario)
	
	# Verificar si la misión está completa
	if _check_mission_completion(key):
		complete_mission(key)
	
	# Guardar cambios
	guardar_misiones()
	
	return true

func complete_mission(nombre_mision: String):
	"""Marca una misión como completada"""
	if not misiones_activas.has(nombre_mision):
		print("❌ Misión no encontrada: ", nombre_mision)
		return false
	
	var mision = misiones_activas[nombre_mision]
	
	if mision.completada:
		print("⚠️ La misión ya estaba completada: ", nombre_mision)
		return false
	
	# Marcar como completada
	mision.completada = true
	mision.fecha_completada = Time.get_unix_time_from_system()
	
	# Mover a misiones completadas
	misiones_completadas[nombre_mision] = mision.duplicate(true)
	
	# Opcional: Dar recompensas aquí
	_entregar_recompensas(nombre_mision)
	
	print("🎉 Misión completada: ", nombre_mision)
	mision_completada.emit(nombre_mision)
	
	# Eliminar de activas (opcional, puedes mantenerla para mostrar completadas)
	SaveSystem.save_game()
	guardar_misiones()
	return true

func remove_mission(nombre_mision: String):
	"""Elimina una misión activa (útil para misiones fallidas o canceladas)"""
	if misiones_activas.has(nombre_mision):
		misiones_activas.erase(nombre_mision)
		print("🗑️ Misión eliminada: ", nombre_mision)
		guardar_misiones()
		return true
	return false

# ============================================
# FUNCIONES DE VERIFICACIÓN
# ============================================

# MisionSystem.gd
func _check_mission_completion(key: String) -> bool:
	"""Verifica si todos los objetivos de una misión están completos"""
	if not misiones_activas.has(key):
		return false
	
	var mision = misiones_activas[key]
	
	# Si no hay objetivos, considerar completada inmediatamente
	if mision.objetivos.is_empty():
		print("⚠️ Misión sin objetivos, completando automáticamente")
		return true
	
	for objetivo in mision.objetivos.keys():
		var progreso_actual = mision.progreso.get(objetivo, 0)
		var progreso_necesario = mision.objetivos[objetivo]
		
		print("🔍 Verificando objetivo '", objetivo, "': ", progreso_actual, "/", progreso_necesario)
		
		if progreso_actual < progreso_necesario:
			return false
	
	print("✅ Todos los objetivos completados para: ", mision.nombre)
	return true

func _entregar_recompensas(nombre_mision: String):
	"""Entrega recompensas al completar una misión"""
	match nombre_mision:
		"Habla con Leonard":
			# Ejemplo: Dar experiencia o items
			print("🏆 Recompensa: +100 XP")
			# GlobalData.add_xp(100)
		_:
			print("🏆 Misión completada sin recompensas especiales")

func is_mission_active(nombre_mision: String) -> bool:
	"""Verifica si una misión está activa y no completada"""
	return misiones_activas.has(nombre_mision) and not misiones_activas[nombre_mision].completada

func is_mission_completed(nombre_mision: String) -> bool:
	"""Verifica si una misión ya fue completada"""
	return misiones_completadas.has(nombre_mision) or (misiones_activas.has(nombre_mision) and misiones_activas[nombre_mision].completada)

func get_mission_progress(nombre_mision: String) -> float:
	"""Obtiene el progreso total de una misión como porcentaje (0.0 a 1.0)"""
	if not misiones_activas.has(nombre_mision):
		return 0.0
	
	var mision = misiones_activas[nombre_mision]
	var progreso_total = 0.0
	var objetivos_totales = 0.0
	
	for objetivo in mision.objetivos.keys():
		var progreso = mision.progreso[objetivo]
		var maximo = mision.objetivos[objetivo]
		progreso_total += progreso
		objetivos_totales += maximo
	
	if objetivos_totales == 0:
		return 1.0 if mision.completada else 0.0
	
	return progreso_total / objetivos_totales

# ============================================
# FUNCIONES DE OBTENCIÓN DE DATOS
# ============================================

func get_active_missions() -> Array:
	"""Devuelve un array con todas las misiones activas (no completadas)"""
	var activas = []
	for key in misiones_activas:
		if not misiones_activas[key].completada:
			activas.append(misiones_activas[key])
	return activas

func get_completed_missions() -> Array:
	"""Devuelve todas las misiones completadas"""
	var completadas = []
	for key in misiones_completadas:
		completadas.append(misiones_completadas[key])
	
	# También incluir completadas que aún están en activas
	for key in misiones_activas:
		if misiones_activas[key].completada:
			completadas.append(misiones_activas[key])
	
	return completadas

func get_all_missions() -> Dictionary:
	"""Devuelve el diccionario completo de misiones activas"""
	print("🔍 get_all_missions() llamado - Retornando: ", misiones_activas)
	return misiones_activas

func get_mission_data(nombre_mision: String) -> Dictionary:
	"""Obtiene los datos de una misión específica"""
	if misiones_activas.has(nombre_mision):
		return misiones_activas[nombre_mision]
	elif misiones_completadas.has(nombre_mision):
		return misiones_completadas[nombre_mision]
	return {}

# ============================================
# PERSISTENCIA
# ============================================

func guardar_misiones():
	"""Guarda todas las misiones en un archivo"""
	var save_data = {
		"misiones_activas": _serializar_misiones(misiones_activas),
		"misiones_completadas": _serializar_misiones(misiones_completadas),
		"version": "1.0",
		"fecha_guardado": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		print("💾 Misiones guardadas correctamente")
	else:
		print("❌ Error al guardar las misiones")

func cargar_misiones():
	"""Carga las misiones desde el archivo"""
	if not FileAccess.file_exists(SAVE_PATH):
		print("📁 No hay archivo de misiones guardado - Iniciando SIN misiones")
		print("🔍 Verificando si hay misiones por defecto...")
		
		# 🔥 IMPORTANTE: Limpiar cualquier misión que pudiera existir
		misiones_activas.clear()
		misiones_completadas.clear()
		
		# Debug: Verificar que no haya misiones
		print("📊 Estado después de limpiar - Misiones activas: ", misiones_activas.size())
		return
	
	# ... resto del código existente ...

func _serializar_misiones(misiones: Dictionary) -> Dictionary:
	"""Serializa misiones para guardarlas (convierte diccionarios internos)"""
	var serializado = {}
	for key in misiones:
		serializado[key] = misiones[key].duplicate(true)
	return serializado

func _deserializar_misiones(misiones_data: Dictionary) -> Dictionary:
	"""Deserializa misiones desde el archivo guardado"""
	var misiones = {}
	for key in misiones_data:
		misiones[key] = misiones_data[key]
	return misiones

# ============================================
# FUNCIONES DE UTILIDAD
# ============================================

func clear_all_missions():
	"""Limpia todas las misiones (activas y completadas)"""
	misiones_activas.clear()
	misiones_completadas.clear()
	print("🧹 Todas las misiones eliminadas")
	guardar_misiones()

func reset_missions():
	"""Resetea todas las misiones (útil para nuevo juego)"""
	clear_all_missions()
	print("🔄 Sistema de misiones reseteado")

func print_all_missions():
	"""Imprime todas las misiones en consola (útil para debugging)"""
	print("========== MISIONES ACTIVAS ==========")
	for key in misiones_activas:
		var mision = misiones_activas[key]
		var estado = "✅ COMPLETADA" if mision.completada else "⏳ EN PROGRESO"
		print("- ", mision.nombre, " [", estado, "]")
		if mision.objetivos:
			print("   Objetivos:")
			for obj in mision.objetivos:
				var progreso = mision.progreso.get(obj, 0)
				var total = mision.objetivos[obj]
				print("     • ", obj, ": ", progreso, "/", total)
	
	print("========== MISIONES COMPLETADAS ==========")
	for key in misiones_completadas:
		print("- ", misiones_completadas[key].nombre)
	print("=====================================")

# MisionSystem.gd (añadir estos métodos)

func get_completed_missions_data() -> Dictionary:
	"""Devuelve las misiones completadas para guardar"""
	return misiones_completadas

func load_missions_from_data(misiones_data: Dictionary, completadas_data: Dictionary):
	"""Carga misiones desde datos externos (SaveSystem)"""
	print("📀 Cargando misiones desde SaveSystem")
	
	# Limpiar misiones actuales
	misiones_activas.clear()
	misiones_completadas.clear()
	
	# Cargar nuevas misiones
	misiones_activas = _deserializar_misiones(misiones_data)
	misiones_completadas = _deserializar_misiones(completadas_data)
	
	print("✅ Misiones cargadas:")
	print("   - Activas: ", misiones_activas.size())
	print("   - Completadas: ", misiones_completadas.size())
	
	# Emitir señales para actualizar UI
	for mision_key in misiones_activas:
		mision_agregada.emit(misiones_activas[mision_key].nombre)

# Modificar guardar_misiones() para que sea opcional
func guardar_misiones_auto():
	"""Auto-guarda misiones (puedes llamarlo periódicamente)"""
	guardar_misiones()

func debug_print_misiones():
	print("=== DEBUG MISIONES SYSTEM ===")
	print("Archivo existe?: ", FileAccess.file_exists(SAVE_PATH))
	print("Misiones activas en memoria: ", misiones_activas.size())
	for key in misiones_activas:
		print("  - ", key, ": ", misiones_activas[key].nombre)
	print("Misiones completadas: ", misiones_completadas.size())
	print("============================")

func debug_print_internal_state():
	print("=== ESTADO INTERNO DE MISIONSYSTEM ===")
	print("misiones_activas: ", misiones_activas)
	for key in misiones_activas:
		print("  ", key, ": ", misiones_activas[key])
	print("=====================================")
