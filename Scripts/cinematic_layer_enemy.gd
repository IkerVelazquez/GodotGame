extends CanvasLayer

func _ready() -> void:
	play_zombie_cinematic()
	
func play_zombie_cinematic():
	var tween = create_tween()
	
	# Barras negras
	tween.tween_property($TopBar, "offset_bottom", 150, 0.3)
	tween.parallel().tween_property($BottomBar, "offset_top", -150, 0.3)
	
	# 🧟 Zombies entran (de derecha a izquierda)
	tween.tween_property($ZombiesContainer/Zombie1, "position:x", 700, 0.4)
	tween.parallel().tween_property($ZombiesContainer/Zombie2, "position:x", 400, 0.5)
	tween.parallel().tween_property($ZombiesContainer/Zombie3, "position:x", 30, 0.6)
	
	# Pausa dramática
	tween.tween_interval(1.5)
	
	# Salen
	tween.tween_property($ZombiesContainer/Zombie1, "position:x", -400, 0.4)
	tween.parallel().tween_property($ZombiesContainer/Zombie2, "position:x", -400, 0.4)
	tween.parallel().tween_property($ZombiesContainer/Zombie3, "position:x", -400, 0.4)
	
	# Quitar barras
	tween.tween_property($TopBar, "offset_bottom", 0, 0.3)
	tween.parallel().tween_property($BottomBar, "offset_top", 0, 0.3)
