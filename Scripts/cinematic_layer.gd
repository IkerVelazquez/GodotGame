extends CanvasLayer


func _ready() -> void:
	play_cinematic()
	
func play_cinematic():
	var tween = create_tween()
	
	# Barras
	tween.tween_property($TopBar, "offset_bottom", 150, 0.3)
	tween.parallel().tween_property($BottomBar, "offset_top", -150, 0.3)
	
	# Cara entra
	tween.tween_property($Face, "position:x", 200, 0.5)
	
	tween.tween_interval(1.5)
	
	# Salida
	tween.tween_property($Face, "position:x", 1200, 0.4)
	
	# Quitar barras
	tween.tween_property($TopBar, "offset_bottom", 0, 0.3)
	tween.parallel().tween_property($BottomBar, "offset_top", 0, 0.3)
