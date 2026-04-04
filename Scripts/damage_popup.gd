extends Node2D

@onready var label = $Label

enum DamageType { NORMAL, CRITICAL }

func _ready():
	# Configuración base
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func setup(damage: int, type: DamageType = DamageType.NORMAL) -> void:
	match type:
		DamageType.CRITICAL:
			_setup_critical(damage)
		DamageType.NORMAL:
			_setup_normal(damage)

func _setup_critical(damage: int):
	label.text = str(damage) 
	label.modulate = Color(1.0, 0.9, 0.3)  # Amarillo dorado
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color(0.8, 0.4, 0.0, 0.8))

func _setup_normal(damage: int):
	label.text = str(damage)
	label.modulate = Color(1.0, 1.0, 1.0)  # Blanco puro
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))

func start_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Animación base
	tween.tween_property(self, "position:y", position.y - 40, 0.8)
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.2)
	
	# Efecto extra para críticos
	if label.modulate.r > 0.8 and label.modulate.g > 0.8:  # Si es color crítico
		tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.15)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_delay(0.15)
	
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
