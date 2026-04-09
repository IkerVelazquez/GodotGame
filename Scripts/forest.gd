extends Node2D

@export var first_door_closed: AudioStream
var play_first_door: AudioStreamPlayer
var dialogue_triggered := false  # Control para evitar múltiples ejecuciones
var mission_given := false  # Control para evitar misiones duplicadas

var resource = load("res://Dialogues/intro.dialogue")
var tutorial_complete = load("res://Dialogues/return_tutorial.dialogue")
var keys_tutorial = load("res://Dialogues/keys_tutorial.dialogue")
var barriers = load("res://Dialogues/barreras.dialogue")


func _ready() -> void:
	
	print("=== INICIANDO ESCENA FOREST ===")
	print("🔍 Verificando misiones antes de cualquier operación:")
	MisionSystem.debug_print_misiones()  # Agrega este método
	SaveSystem.level_ready.connect(on_save_loaded)
	
func setup_scene():
	$CinematicLayer.visible = false
	$CinematicLayerEnemy.visible = false
	
	# Reproducir música
	AudioManager.crossfade_music("res://Music/village_theme.mp3", 0.0, -10)
	AudioManager.set_music_volume(60)
	
	# Crear player para puerta
	play_first_door = AudioStreamPlayer.new()
	add_child(play_first_door)
	
	# Verificar si es la primera misión y no se ha ejecutado antes
	if GlobalData.first_mision and not GlobalData.first_dialogue_done:
		_start_first_mission_dialogue()
		$AreaToFight.monitoring = true
		$Player.position = Vector2(1471,882)
		$Leonard.position = Vector2(1576,904)
	else:
		# No es primera misión, iniciar directamente
		$ColorRect/AnimationPlayer.play("change_level")
		$AreaToFight.monitoring = false
		$Player.position = Vector2(1827,1666)
		$Leonard.position = Vector2(1868,1666)
		if not GlobalData.return_tutorial:
			Levels.in_cutscene = true
			DialogueManager.show_dialogue_balloon(tutorial_complete, "start")
			var objetivos = {
				"madera": 2
			}
			MisionSystem.add_mission("Recolecta madera", "", objetivos)
			MisionSystem.debug_print_misiones()  # Usa el método que creamos
#			EL JUEGO SE VUELVE A GUARDAR EN EL DIALOGUEMANAGER PARA QUE NO SE VUELVA A REPRODUCIR EL DIALOGO
		else:
			Levels.in_cutscene = false
		
func _start_first_mission_dialogue():
	play_first_door.stream = first_door_closed
	Levels.in_cutscene = true
	
	await get_tree().create_timer(2.0).timeout
	play_first_door.play()
	
	await get_tree().create_timer(2.52).timeout
	
	# Conectar la señal una sola vez
	if not Levels.house_out_triggered.is_connected(_on_house_out):
		Levels.house_out_triggered.connect(_on_house_out)
	
	# Mostrar diálogo
	DialogueManager.show_dialogue_balloon(resource, "house_out")

func _on_house_out():
	# Esta función se llama desde el diálogo con Levels.trigger_house_out()
	$ColorRect/AnimationPlayer.play("fade_out")

func _on_area_to_fight_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GlobalData.first_mision = false
		GlobalData.leonard_first_talk = false
		GlobalData.first_dialogue_done = true
		print("=== ANTES DE GUARDAR PREVIO A LA ESCENA DE PELEA===")
		MisionSystem.debug_print_internal_state()
		SaveSystem.save_game()  #GUARDA EL JUEGO
		# Cambio de música
		AudioManager.crossfade_music("res://Music/funky_loop.mp3", 4.0, -4)
		
		# Reproducir sonido de arbusto
		AudioManager.play_sfx("res://Sounds/bush_moving.mp3")  # Asume que tienes este sonido
		
		Levels.in_cutscene = true
		await get_tree().create_timer(2.0).timeout
		
		$CinematicLayer.visible = true
		$Player.visible = false
		$Player.get_node("Minimap").visible = false
		$CinematicLayer.play_cinematic()
		await get_tree().create_timer(0.3).timeout
		AudioManager.play_sfx("res://Sounds/Epic_transition.mp3")
		
		await get_tree().create_timer(3.0).timeout
		
		$CinematicLayerEnemy.visible = true
		
		# Reproducir SFX de zombie
		AudioManager.play_sfx("res://Sounds/zombie_roar.mp3")  # Cambia a .wav si es necesario
		AudioManager.play_sfx("res://Sounds/zombie_laugh.mp3", -6.0, 1.2)
		
		$CinematicLayerEnemy.play_zombie_cinematic()
		await get_tree().create_timer(2.0).timeout
		AudioManager.play_sfx("res://Sounds/Whoosh.mp3")
		await get_tree().create_timer(1.0).timeout
		$ColorRect/AnimationPlayer.play("fade_in")
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://Scenario/village_scenario.tscn")


func _on_area_2d_body_entered(body: Node2D) -> void: #Barreras
	if body.is_in_group("Player"):
		DialogueManager.show_dialogue_balloon(barriers,"start")


func _on_keys_tutrial_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		if not GlobalData.first_mision and not GlobalData.block_mats_tutorial:
			DialogueManager.show_dialogue_balloon(keys_tutorial,"start")
			$Keys_tutrial.call_deferred("set", "monitoring", false)
			$Keys_tutrial/CollisionShape2D.call_deferred("set", "disabled", true)
			GlobalData.block_mats_tutorial = true
			print("=== ANTES DE GUARDAR REGRESANDO DE LA ESCENA DE ATAQUE ===")
			MisionSystem.debug_print_internal_state()
			SaveSystem.save_game()
		else:
			$Keys_tutrial.call_deferred("set", "monitoring", false)
			$Keys_tutrial/CollisionShape2D.call_deferred("set", "disabled", true)
			

func on_save_loaded():
	print("ON SAVE LOADED LLAMADA")
	await get_tree().process_frame
	var recetas = find_child("Recetas", true, false)
	if recetas and recetas.has_method("refresh"):
		recetas.refresh()
		print("✅ Recetas refrescadas después de cargar")
	setup_scene()

func _input(event):
	if event.is_action_pressed("ui_f12"):  # F12 para debug
		print("\n=== DEBUG MISIONES ===")
		print("Misiones activas:", MisionSystem.get_active_missions().size())
		for m in MisionSystem.get_active_missions():
			print("  - ", m.nombre)
		print("===================\n")
