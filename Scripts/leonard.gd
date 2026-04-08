extends CharacterBody2D

var first_dialogue = load("res://Dialogues/leonard-james_intro.dialogue")

var minimap_icon
var icon = preload("res://portraits/Leonard.png")

func _process(delta):
	pass
	
func _on_area_to_interact_body_entered(body: Node2D) -> void:
	if GlobalData.leonard_first_talk:
		if body.is_in_group("Player"):
			$Marker.visible = true
			Levels.in_cutscene = true
			GlobalData.mouse_disable = true
			GlobalData.mouse_disable = false
			DialogueManager.show_dialogue_balloon(first_dialogue,"start")
			
	else:
			GlobalData.mouse_disable = true
			$Marker.visible = false
		
