extends Button

func _ready() -> void:
	$"../../ColorRect".visible = false
	
func _process(delta: float) -> void:
	if $".".disabled == true:
		$TextureRect.visible = false
	else:
		$TextureRect.visible = true



func _on_button_pressed() -> void:
	$"../../ColorRect".visible = true
	$"../../ColorRect/AnimationPlayer".play("flash")
	await get_tree().create_timer(0.4).timeout
	$"../../ColorRect".visible = false
	
