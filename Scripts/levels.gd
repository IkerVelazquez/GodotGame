extends Node

var in_cutscene: bool = false

signal house_out_triggered #James sale de la casa y manda la señal al primer diálogo

func trigger_house_out():
	emit_signal("house_out_triggered") #Emite la señal de que salió de la casa la primera vez
