# MissionManager.gd (Agregar como Autoload)
extends Node

func _ready():
	# Conectar la señal al iniciar
	MisionSystem.mision_completada.connect(_on_mision_completada)
	print("✅ MissionManager listo, escuchando misiones completadas")

func _on_mision_completada(nombre_mision: String):
	print("📢 Misión completada: ", nombre_mision)
	
	match nombre_mision.to_lower():
		"recolecta madera":
			_activar_mision_pico()
		
		"construye un pico de madera":
			_activar_mision_piedra()
		
		"recolecta piedra":
			_activar_mision_combate()

func _activar_mision_pico():
	if not MisionSystem.is_mission_active("construye un pico de madera") and not MisionSystem.is_mission_completed("construye un pico de madera"):
		print("🔨 Activando misión: Construye un pico de madera")
		MisionSystem.add_mission("Construye un pico de madera", "Craftea un pico de madera en el inventario")
	else:
		print("⚠️ La misión del pico ya está activa o completada")

func _activar_mision_piedra():
	if not MisionSystem.is_mission_active("recolecta piedra") and not MisionSystem.is_mission_completed("recolecta piedra"):
		print("⛏️ Activando misión: Recoleca piedra")
		var objetivos = {"piedra": 10}
		MisionSystem.add_mission("Recolecta piedra", "Rompe trozos grande de piedra", objetivos)

func _activar_mision_combate():
	if not MisionSystem.is_mission_active("derrota slimes") and not MisionSystem.is_mission_completed("derrota slimes"):
		print("⚔️ Activando misión: Derrota slimes")
		var objetivos = {"slimes": 3}
		MisionSystem.add_mission("Derrota slimes", "Elimina los slimes que aparecen en el bosque", objetivos)
