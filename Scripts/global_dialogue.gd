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
		
func save_data():
	var config = ConfigFile.new()
	config.set_value("game", "first_mision", first_mision)
	config.save("user://game_data.cfg")

func load_data():
	var config = ConfigFile.new()
	if config.load("user://game_data.cfg") == OK:
		first_mision = config.get_value("game", "first_mision", true)
	else:
		first_mision = true

func complete_first_mission():
	first_mision = false
	save_data()
		
func write_sound():
	AudioManager.play_sfx("res://Sounds/write.mp3",+10)
		
		
