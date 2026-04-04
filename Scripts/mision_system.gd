extends Node

# Diccionario para almacenar todas las misiones
var misiones_activas = {}

# Señal para notificar cuando se añade una misión
signal mision_agregada(nombre_mision)
signal mision_completada(nombre_mision)

func add_mission(nombre_mision: String, descripcion: String = ""):
	"""Añade una nueva misión activa"""
	if not misiones_activas.has(nombre_mision):
		misiones_activas[nombre_mision] = {
			"nombre": nombre_mision,
			"descripcion": descripcion,
			"completada": false,
			"fecha_agregada": Time.get_unix_time_from_system()
		}
		print("✅ Misión añadida: ", nombre_mision)
		mision_agregada.emit(nombre_mision)
		return true
	else:
		print("⚠️ La misión ya existe: ", nombre_mision)
		return false

func complete_mission(nombre_mision: String):
	"""Marca una misión como completada"""
	if misiones_activas.has(nombre_mision):
		misiones_activas[nombre_mision].completada = true
		print("🎉 Misión completada: ", nombre_mision)
		mision_completada.emit(nombre_mision)
		return true
	else:
		print("❌ Misión no encontrada: ", nombre_mision)
		return false

func remove_mission(nombre_mision: String):
	"""Elimina una misión (completada o cancelada)"""
	if misiones_activas.has(nombre_mision):
		misiones_activas.erase(nombre_mision)
		print("🗑️ Misión eliminada: ", nombre_mision)
		return true
	return false

func get_active_missions() -> Array:
	"""Devuelve un array con todas las misiones activas (no completadas)"""
	var activas = []
	for key in misiones_activas:
		if not misiones_activas[key].completada:
			activas.append(misiones_activas[key])
	return activas

func get_all_missions() -> Dictionary:
	"""Devuelve el diccionario completo de misiones"""
	return misiones_activas

func clear_all_missions():
	"""Limpia todas las misiones"""
	misiones_activas.clear()
	print("🧹 Todas las misiones eliminadas")
