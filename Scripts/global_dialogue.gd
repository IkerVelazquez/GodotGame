# GlobalData.gd
extends Node

var leonard_first_talk = true
var mouse_disable = false

var first_mision = true

func _physics_process(delta: float) -> void:
	
	if mouse_disable == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
