extends Node

var in_cutscene: bool = false

signal house_out_triggered #James sale de la casa y manda la señal al primer diálogo


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	SaveSystem.load_game()
	#var level = get_tree().get_first_node_in_group("Level")
	#if level.has_method("on_save_loaded"):
		#level.on_save_loaded()
	
	
func trigger_house_out_once():
	if GlobalData.house_out_done:
		return
	
	GlobalData.house_out_done = true
	emit_signal("house_out_triggered") #Emite la señal de que salió de la casa la primera vez

func close_dialogue():
	DialogueManager.hide_dialogue_balloon()
