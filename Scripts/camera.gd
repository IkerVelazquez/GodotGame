extends Camera2D

func _ready() -> void:
	GameEvents.camera_shake.connect(_on_camera_shake)
	
func _on_camera_shake(intensity: float, duration: float):
	shake_camera(intensity, duration)

func shake_camera(intensity: float = 10.0, duration: float = 0.3):
	var tween = create_tween()
	var original_offset = offset
	for i in range(5):
		tween.tween_property(self, "offset", Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		), duration / 10)
	tween.tween_property(self, "offset", original_offset, duration / 10)
