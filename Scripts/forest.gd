extends Node2D

@export var first_door_closed = AudioStream
var play_first_door: AudioStreamPlayer


var resource = load("res://Dialogues/intro.dialogue")
var dialogue_line = await DialogueManager.get_next_dialogue_line(resource, "house_out")
func _ready() -> void:
	
	AudioManager.play_music("res://Music/village_theme.mp3")
	play_first_door = AudioStreamPlayer.new()
	add_child(play_first_door)
	
	play_first_door.stream = first_door_closed
	
	Levels.in_cutscene = true
	await get_tree().create_timer(2.0).timeout
	play_first_door.play()
	await get_tree().create_timer(2.52).timeout
	Levels.house_out_triggered.connect(_on_house_out)
	DialogueManager.show_dialogue_balloon(resource, "house_out")

func _on_house_out():
	$ColorRect/AnimationPlayer.play("fade_out")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		DialogueManager.show_dialogue_balloon(resource, "beginin")
		Levels.in_cutscene = true
		await get_tree().create_timer(1.0).timeout
		$ColorRect/AnimationPlayer.play("fade_in")
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://Scenario/village_scenario.tscn")
		
