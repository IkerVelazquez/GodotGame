# BarraTiming.gd - VERSIÓN CORREGIDA
extends Control

@onready var cursor = $Cursor
@onready var target_zone = $TargetZone

var is_active := false
var cursor_speed := 500.0  # Más rápido para mejor feedback
var cursor_direction := 1.0
var cursor_position := 0.0
var bar_width := 0.0

signal attack_completed(accuracy: float)

func _ready():
	hide()
	# Configurar tamaño fijo para evitar problemas
	custom_minimum_size = Vector2(400, 80)
	size = Vector2(400, 80)

func start_timing():
	show()
	is_active = true
	cursor_position = 0.0
	cursor_direction = 1.0
	
	# Calcular bar_width DESPUÉS de mostrar y con tamaño conocido
	bar_width = size.x - cursor.size.x
	
	update_cursor_position()

func _process(delta):
	if not is_active:
		return
	
	# Mover el cursor
	cursor_position += cursor_speed * delta * cursor_direction
	
	# Rebote en los bordes
	if cursor_position >= bar_width:
		cursor_position = bar_width
		cursor_direction = -1.0
	elif cursor_position <= 0:
		cursor_position = 0
		cursor_direction = 1.0
	
	update_cursor_position()
	
	# Detectar input
	if Input.is_action_just_pressed("ui_accept"):
		calculate_accuracy()

func update_cursor_position():
	if cursor:
		cursor.position.x = cursor_position
		#print("➡️ Cursor en: ", cursor_position)  # Debug temporal

func calculate_accuracy():
	is_active = false
	
	var target_center = target_zone.position.x + (target_zone.size.x / 2)
	var cursor_center = cursor_position + (cursor.size.x / 2)
	var target_half_width = target_zone.size.x / 2
	
	var distance_to_center = abs(cursor_center - target_center)
	
	# Calcular precisión (0.0 a 1.0)
	var accuracy = 1.0 - (distance_to_center / target_half_width)
	accuracy = clamp(accuracy, 0.0, 1.0)
	
	show_accuracy_feedback(accuracy)
	
	# Pequeña pausa para el feedback
	await get_tree().create_timer(0.3).timeout
	
	attack_completed.emit(accuracy)
	hide()

func show_accuracy_feedback(accuracy: float):
	if accuracy > 0.8:
		print("💥 ¡CRÍTICO!")
		cursor.modulate = Color.GOLD
	elif accuracy > 0.6:
		print("✅ ¡Excelente!")
		cursor.modulate = Color.GREEN
	elif accuracy > 0.4:
		print("👍 Bueno")
		cursor.modulate = Color.YELLOW
	elif accuracy > 0.2:
		print("⚠️ Regular")
		cursor.modulate = Color.ORANGE
	else:
		print("❌ Débil")
		cursor.modulate = Color.RED

func stop_timing():
	is_active = false
	hide()
