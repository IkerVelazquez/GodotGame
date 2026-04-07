# AudioManager.gd (Autoload)
extends Node

# Nodos de audio para música (crossfade)
var music_bus_a: AudioStreamPlayer
var music_bus_b: AudioStreamPlayer
var active_bus := 1  # 1 para bus A, 2 para bus B

# Nodos para SFX
var sfx_pool: Array[AudioStreamPlayer] = []
var sfx_pool_size := 8
var next_sfx_index := 0
var sfx_pool_initialized := false

# Volúmenes por bus
var music_volume_db: float = -10.0:
	set(value):
		music_volume_db = clampf(value, -80.0, 24.0)
		_update_music_volumes()
		save_preferences()

var sfx_volume_db: float = 0.0:
	set(value):
		sfx_volume_db = clampf(value, -80.0, 24.0)
		_update_sfx_volumes()
		save_preferences()

# Configuración de fade
var current_fade_tween: Tween = null

func _ready():
	# Inicializar todo de forma segura
	_initialize_audio_system()
	
	# Cargar preferencias
	load_preferences()
	
	# Configurar procesamiento siempre activo
	process_mode = Node.PROCESS_MODE_ALWAYS

func _initialize_audio_system():
	
	# Verificar buses de audio
	_check_audio_buses()
	
	# Crear players de música
	music_bus_a = AudioStreamPlayer.new()
	music_bus_b = AudioStreamPlayer.new()
	music_bus_a.name = "MusicBusA"
	music_bus_b.name = "MusicBusB"
	
	# Asignar buses personalizados
	if _bus_exists("Music"):
		music_bus_a.bus = "Music"
		music_bus_b.bus = "Music"
	else:
		print("⚠️ Usando bus 'Master' para música")
		music_bus_a.bus = "Master"
		music_bus_b.bus = "Master"
	
	add_child(music_bus_a)
	add_child(music_bus_b)
	
	# Crear pool de SFX de forma segura
	sfx_pool.clear()  # Limpiar por si acaso
	for i in range(sfx_pool_size):
		var sfx = AudioStreamPlayer.new()
		sfx.name = "SFXPlayer_" + str(i)
		
		if _bus_exists("SFX"):
			sfx.bus = "SFX"
		else:
			sfx.bus = "Master"
		
		add_child(sfx)
		sfx_pool.append(sfx)
	
	sfx_pool_initialized = true

func _check_audio_buses():
	# Verificar si los buses existen
	if not _bus_exists("Music"):
		print("⚠️ Advertencia: Bus 'Music' no existe. Créalo en Project Settings > Audio")
		print("   Ve a Project > Project Settings > Audio > Bus Layout")
	
	if not _bus_exists("SFX"):
		print("⚠️ Advertencia: Bus 'SFX' no existe. Créalo en Project Settings > Audio")

func _bus_exists(bus_name: String) -> bool:
	for i in range(AudioServer.bus_count):
		if AudioServer.get_bus_name(i) == bus_name:
			return true
	return false

func _update_music_volumes():
	if music_bus_a and music_bus_b:
		music_bus_a.volume_db = music_volume_db if music_bus_a.playing else -80
		music_bus_b.volume_db = music_volume_db if music_bus_b.playing else -80

func _update_sfx_volumes():
	if not sfx_pool_initialized:
		return
	for sfx in sfx_pool:
		if sfx:
			sfx.volume_db = sfx_volume_db

# --- FUNCIONES DE MÚSICA MEJORADAS ---
func play_music(music_path: String, fade_in_duration: float = 1.0, target_volume: float = -10.0):
	if not music_bus_a or not music_bus_b:
		push_error("Sistema de audio no inicializado")
		return
	
	var stream = load(music_path)
	if not stream:
		push_error("No se pudo cargar música: ", music_path)
		return
	
	# Detener cualquier fade en curso
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()
	
	var target_db = target_volume
	
	# Usar el bus activo actual
	var active = music_bus_a if active_bus == 1 else music_bus_b
	var inactive = music_bus_b if active_bus == 1 else music_bus_a
	
	# Configurar nueva música
	active.stream = stream
	active.volume_db = -80
	active.play()
	
	# Hacer fade in
	current_fade_tween = create_tween()
	current_fade_tween.tween_property(active, "volume_db", target_db, fade_in_duration)
	
	# Si hay música sonando en el otro bus, hacer fade out
	if inactive.playing:
		current_fade_tween.parallel().tween_property(inactive, "volume_db", -80, fade_in_duration)
		await current_fade_tween.finished
		inactive.stop()

func crossfade_music(new_music_path: String, duration: float = 2.0, target_volume_db: float = -10.0):
	if not music_bus_a or not music_bus_b:
		push_error("Sistema de audio no inicializado")
		return
	
	var new_stream = load(new_music_path)
	if not new_stream:
		push_error("No se pudo cargar música: ", new_music_path)
		return
	
	var target_db = target_volume_db
	
	# Cambiar bus activo
	var from_bus = music_bus_a if active_bus == 1 else music_bus_b
	var to_bus = music_bus_b if active_bus == 1 else music_bus_a
	
	# Preparar nueva música
	to_bus.stream = new_stream
	to_bus.volume_db = -80
	to_bus.play()
	
	# Hacer crossfade
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()
	
	current_fade_tween = create_tween()
	current_fade_tween.tween_property(to_bus, "volume_db", target_db, duration)
	current_fade_tween.parallel().tween_property(from_bus, "volume_db", -80, duration)
	
	await current_fade_tween.finished
	from_bus.stop()
	
	# Cambiar bus activo
	active_bus = 2 if active_bus == 1 else 1

func stop_music(fade_out_duration: float = 1.0):
	if not music_bus_a or not music_bus_b:
		return
	
	var active = music_bus_a if active_bus == 1 else music_bus_b
	
	if current_fade_tween and current_fade_tween.is_valid():
		current_fade_tween.kill()
	
	current_fade_tween = create_tween()
	current_fade_tween.tween_property(active, "volume_db", -80, fade_out_duration)
	await current_fade_tween.finished
	active.stop()

func set_music_volume(percent: float):
	# Convertir porcentaje (0-100) a dB (-80 a 24)
	var clamped_percent = clampf(percent, 0.0, 100.0)
	var db = linear_to_db(clamped_percent / 100.0)
	music_volume_db = clampf(db, -80, 24)

func get_music_volume_percent() -> float:
	return db_to_linear(music_volume_db) * 100

# --- FUNCIONES DE SFX MEJORADAS ---
func play_sfx(sfx_path: String, volume_override: float = -999.0, pitch_scale: float = 1.0):
	# Verificar si el pool está inicializado
	if not sfx_pool_initialized or sfx_pool.is_empty():
		push_error("Pool de SFX no inicializado o vacío")
		# Intentar inicializar de nuevo
		_initialize_audio_system()
		if sfx_pool.is_empty():
			return
	
	var stream = load(sfx_path)
	if not stream:
		push_error("No se pudo cargar SFX: ", sfx_path)
		return
	
	# Asegurar que el índice esté dentro del rango
	if next_sfx_index >= sfx_pool.size():
		next_sfx_index = 0
	
	# Obtener siguiente player disponible del pool
	var player = sfx_pool[next_sfx_index]
	next_sfx_index = (next_sfx_index + 1) % sfx_pool.size()
	
	# Verificar que el player exista
	if not player:
		push_error("Player SFX inválido en índice: ", next_sfx_index)
		return
	
	# Configurar y reproducir
	player.stream = stream
	player.pitch_scale = pitch_scale
	
	# Usar volume_override solo si es diferente de -999.0 (valor centinela)
	if volume_override != -999.0:
		player.volume_db = clampf(volume_override, -80, 24)
	else:
		player.volume_db = sfx_volume_db
	
	player.play()

func play_sfx_one_shot(sfx_path: String, volume_override: float = -999.0):
	# Versión que permite solapamiento sin límite (útil para muchos sonidos)
	var temp_player = AudioStreamPlayer.new()
	temp_player.stream = load(sfx_path)
	
	if _bus_exists("SFX"):
		temp_player.bus = "SFX"
	else:
		temp_player.bus = "Master"
	
	if volume_override != -999.0:
		temp_player.volume_db = clampf(volume_override, -80, 24)
	else:
		temp_player.volume_db = sfx_volume_db
	
	add_child(temp_player)
	temp_player.play()
	await temp_player.finished
	temp_player.queue_free()

func set_sfx_volume(percent: float):
	var clamped_percent = clampf(percent, 0.0, 100.0)
	var db = linear_to_db(clamped_percent / 100.0)
	sfx_volume_db = clampf(db, -80, 24)

func get_sfx_volume_percent() -> float:
	return db_to_linear(sfx_volume_db) * 100

# --- PERSISTENCIA ---
func save_preferences():
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume_db", music_volume_db)
	config.set_value("audio", "sfx_volume_db", sfx_volume_db)
	config.save("user://audio_prefs.cfg")

func load_preferences():
	var config = ConfigFile.new()
	if config.load("user://audio_prefs.cfg") == OK:
		music_volume_db = config.get_value("audio", "music_volume_db", -10.0)
		sfx_volume_db = config.get_value("audio", "sfx_volume_db", 0.0)
	else:
		music_volume_db = -10.0
		sfx_volume_db = 0.0

# Funciones auxiliares
func linear_to_db(linear: float) -> float:
	return 24.0 * log(linear) / log(2) if linear > 0 else -80

func db_to_linear(db: float) -> float:
	return pow(2.0, db / 24.0) if db > -80 else 0
