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
# MisionSystem.gd - Asegurar que esta parte esté completa
func update_mission_progress(nombre_mision: String, objetivo: String, cantidad: int = 1):
	var key = nombre_mision.strip_edges().to_lower()
	
	if not misiones_activas.has(key):
		print("❌ Misión no encontrada: ", nombre_mision)
		return false
	
	var mision = misiones_activas[key]
	
	if not mision.progreso.has(objetivo):
		print("⚠️ Objetivo no encontrado: ", objetivo)
		return false
	
	var progreso_anterior = mision.progreso[objetivo]
	var progreso_necesario = mision.objetivos[objetivo]
	var nuevo_progreso = min(progreso_anterior + cantidad, progreso_necesario)
	mision.progreso[objetivo] = nuevo_progreso
	
	print("📊 Progreso: ", nuevo_progreso, "/", progreso_necesario)
	
	# 🔥 EMITIR SEÑAL DE PROGRESO ACTUALIZADO
	mision_progreso_actualizado.emit(nombre_mision, nuevo_progreso, progreso_necesario)
	
	if _check_mission_completion(key):
		complete_mission(key)
	
	SaveSystem.save_game()	
	guardar_misiones()
	return true

# MisionSystem.gd - En complete_mission()
func complete_mission(nombre_mision: String):
	"""Marca una misión como completada"""
	var key = nombre_mision.strip_edges().to_lower()
	
	if not misiones_activas.has(key):
		print("❌ Misión no encontrada: ", nombre_mision)
		return false
	
	var mision = misiones_activas[key]
	
	if mision.completada:
		print("⚠️ La misión ya estaba completada: ", nombre_mision)
		return false
	
	mision.completada = true
	mision.fecha_completada = Time.get_unix_time_from_system()
	
	# 🔥 Mover a completadas
	misiones_completadas[key] = mision.duplicate(true)
	
	# 🔥 Eliminar de activas (IMPORTANTE)
	misiones_activas.erase(key)
	
	_entregar_recompensas(key)
	
	print("🎉 Misión completada: ", mision.nombre)
	mision_completada.emit(mision.nombre)
	
	guardar_misiones()
	SaveSystem.save_game()  # Guardar inmediatamente
	
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

# MisionSystem.gd
# MisionSystem.gd
func get_active_missions() -> Array:
	"""Devuelve un array con todas las misiones activas (NO completadas)"""
	print("🔍 get_active_missions() llamado")
	print("  misiones_activas keys: ", misiones_activas.keys())
	
	var activas = []
	for key in misiones_activas:
		var mision = misiones_activas[key]
		print("  Revisando misión: ", key, " - completada: ", mision.get("completada", false))
		if not mision.get("completada", false):
			activas.append(mision)
			print("    → Agregada a activas")
	
	print("  Total activas: ", activas.size())
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

# MisionSystem.gd
func get_mission_data(nombre_mision: String) -> Dictionary:
	"""Obtiene los datos de una misión específica"""
	var key = nombre_mision.strip_edges().to_lower()  # 🔥 Normalizar a minúsculas
	
	if misiones_activas.has(key):
		return misiones_activas[key]
	elif misiones_completadas.has(key):
		return misiones_completadas[key]
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
		misiones_activas.clear()
		misiones_completadas.clear()
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var save_data = JSON.parse_string(content)
		
		if save_data:
			# 🔥 Cargar misiones activas
			misiones_activas.clear()
			for key in save_data.get("misiones_activas", {}):
				misiones_activas[key] = save_data["misiones_activas"][key]
			
			# 🔥 Cargar misiones completadas
			misiones_completadas.clear()
			for key in save_data.get("misiones_completadas", {}):
				misiones_completadas[key] = save_data["misiones_completadas"][key]
			
			print("📀 Misiones cargadas correctamente")
			print("   - Activas: ", misiones_activas.size())
			print("   - Completadas: ", misiones_completadas.size())
			
			# Mostrar progreso de cada misión activa
			for key in misiones_activas:
				var mision = misiones_activas[key]
				print("     * ", mision.nombre, " - Progreso: ", mision.progreso)
		else:
			print("❌ Error al parsear archivo de misiones")

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

# En MisionSystem.gd, al cargar misiones
func load_missions_from_data(misiones_data: Dictionary, completadas_data: Dictionary):
	"""Carga misiones desde datos externos (SaveSystem)"""
	print("📀 Cargando misiones desde SaveSystem")
	
	# Limpiar misiones actuales
	misiones_activas.clear()
	misiones_completadas.clear()
	
	# 🔥 Solo cargar misiones NO completadas en activas
	for key in misiones_data:
		var mision = misiones_data[key]
		if not mision.get("completada", false):
			misiones_activas[key] = mision
		else:
			misiones_completadas[key] = mision
	
	# Cargar completadas
	for key in completadas_data:
		misiones_completadas[key] = completadas_data[key]
	
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
