extends Button

@onready var content = $".."
var tween

func _ready():
	pivot_offset = size / 2
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
func _on_mouse_entered():
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_parallel(true)
	
	# Escala suave
	tween.tween_property(content, "scale", Vector2(1.12, 1.12), 0.15)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# Brillo
	tween.tween_property(content, "modulate", Color(1.2, 1.2, 1.2), 0.15)
	
func _on_mouse_exited():
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_parallel(true)
	
	# Regresa a normal
	tween.tween_property(content, "scale", Vector2(1, 1), 0.15)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(content, "modulate", Color(1, 1, 1), 0.15)
