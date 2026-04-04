extends Node

# Nodos de audio
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# Volumen (valores de -80 a 24, donde 0 es volumen normal)
var music_volume: float = 0.0:
	set(value):
		music_volume = clamp(value, -80.0, 24.0)
		if music_player:
			music_player.volume_db = music_volume
			# Guardar preferencia
			save_volume_prefs()

var sfx_volume: float = 0.0:
	set(value):
		sfx_volume = clamp(value, -80.0, 24.0)
		if sfx_player:
			sfx_player.volume_db = sfx_volume
			# Guardar preferencia
			save_volume_prefs()

# Referencia a la música actual
var current_music: AudioStream = null

func _ready():
	# Crear los players de audio
	music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	
	# Configurar nombres para identificarlos
	music_player.name = "MusicPlayer"
	sfx_player.name = "SFXPlayer"
	
	# Añadir al árbol
	add_child(music_player)
	add_child(sfx_player)
	
	# Cargar preferencias guardadas
	load_volume_prefs()
	
	# Evitar que se detenga al cambiar de escena
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS

# --- Funciones para música ---
func play_music(music_path: String, fade_in_time: float = 0.0):
	# Verificar si ya está sonando la misma música
	if current_music and current_music.resource_path == music_path:
		return
	
	# Cargar el nuevo archivo de música
	var new_music = load(music_path)
	if not new_music:
		push_error("No se pudo cargar la música: ", music_path)
		return
	
	current_music = new_music
	
	if fade_in_time > 0:
		# Fundido de entrada
		music_player.volume_db = -80.0
		music_player.stream = new_music
		music_player.play()
		
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", music_volume, fade_in_time)
	else:
		music_player.stream = new_music
		music_player.volume_db = music_volume
		music_player.play()

func stop_music(fade_out_time: float = 0.0):
	if fade_out_time > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, fade_out_time)
		await tween.finished
		music_player.stop()
		music_player.volume_db = music_volume  # Restaurar volumen
	else:
		music_player.stop()

func pause_music():
	music_player.stream_paused = true

func resume_music():
	music_player.stream_paused = false

# --- Funciones para efectos de sonido ---
# --- Funciones para efectos de sonido ---
func play_sfx(sfx_path: String, volume_override: float = -999.0):  # Usa -999 como valor centinela
	var sfx = load(sfx_path)
	if not sfx:
		push_error("No se pudo cargar el SFX: ", sfx_path)
		return
	
	# Crear player temporal para SFX (permite superposición)
	var temp_player = AudioStreamPlayer.new()
	temp_player.stream = sfx
	# Si volume_override es -999, usa sfx_volume; si no, usa el valor proporcionado
	if volume_override != -999.0:
		temp_player.volume_db = volume_override
	else:
		temp_player.volume_db = sfx_volume
	add_child(temp_player)
	
	temp_player.play()
	# Eliminar automáticamente cuando termine
	await temp_player.finished
	temp_player.queue_free()
# --- Funciones de persistencia ---
func save_volume_prefs():
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save("user://audio_prefs.cfg")

func load_volume_prefs():
	var config = ConfigFile.new()
	if config.load("user://audio_prefs.cfg") == OK:
		music_volume = config.get_value("audio", "music_volume", 0.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.0)
	else:
		music_volume = 0.0
		sfx_volume = 0.0

# --- Funciones de control de volumen para UI ---
func set_music_volume(value: float):
	music_volume = value

func set_sfx_volume(value: float):
	sfx_volume = value

func get_music_volume_percent() -> float:
	# Convertir dB ( -80 a 24 ) a porcentaje (0 a 100)
	return (music_volume + 80.0) / 104.0 * 100.0

func set_music_volume_percent(percent: float):
	var clamped_percent = clamp(percent, 0.0, 100.0)
	music_volume = (clamped_percent / 100.0) * 104.0 - 80.0
