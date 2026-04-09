# GlobalData.gd
extends Node

var leonard_first_talk = true #Tutorial
var mouse_disable = false

var first_mision = true  #Tutorial
var first_dialogue_done: bool = false #Tutorial
var house_out_done: bool = false #Tutorial
var return_tutorial = false #Tutorial
var block_mats_tutorial = false #Tutorial
var first_tree = false #Tutorial

func _physics_process(delta: float) -> void:
	
	if mouse_disable == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		

		
func write_sound():
	AudioManager.play_sfx("res://Sounds/write.mp3",+10)
		
		
func save():
	return {
		"first_mision": first_mision,
		"mouse_disable": mouse_disable,
		"leonard_first_talk": leonard_first_talk,
		"first_dialogue_done": first_dialogue_done,
		"return_tutorial": return_tutorial,
		"block_mats_tutorial": block_mats_tutorial,
	}
	
func load(data: Dictionary):
	first_mision = data.get("first_mision", true)
	mouse_disable = data.get("mouse_disable", false)
	leonard_first_talk = data.get("leonard_first_talk", true)
	first_dialogue_done = data.get("first_dialogue_done", false)
	return_tutorial = data.get("return_tutorial", false)
	block_mats_tutorial = data.get("block_mats_tutorial", false)
	print("📀 GlobalData cargado:", "first mison: ", first_mision, 
	" return tutorial: ",return_tutorial, 
	" leonard first talk: ", leonard_first_talk, 
	" first dialogue done: ", first_dialogue_done, 
	" block mats tutorial: ", block_mats_tutorial)
