extends Control

@onready var sprite = $Portrait
@onready var especial = $Especial
#@onready var anim = $Especial/AnimationPlayer
@onready var atacar = $VBoxContainer/Atacar

func _ready():
	var parent = get_parent()
	if "portrait" in parent:
		sprite.texture = parent.portrait
	especial.visible = false


func _on_atacar_pressed() -> void:
	GameEvents.atack = true
	#$Especial/AnimationPlayer.play("Hide")
	#await get_tree().create_timer(0.05).timeout
	#especial.visible = false
	
	var player = get_parent() # UI es hija del Player
	if player.type == "melee":
		player.start_attack()
	elif player.type == "paladin":
		player.start_attack()
	elif player.type == "ninja":
		player.start_attack()
		
	

#func _on_atacar_mouse_entered() -> void:
	#especial.visible = true
	#anim.play("Apear")
#
#
#func _on_atacar_mouse_exited() -> void:
	## Espera un pequeño tiempo y verifica si el mouse no está sobre "atacar" ni "especial"
	#await get_tree().create_timer(0.1).timeout
	#if not atacar.get_global_rect().has_point(get_viewport().get_mouse_position()) \
	#and not especial.get_global_rect().has_point(get_viewport().get_mouse_position()):
		#anim.play("Hide")


#func _on_especial_mouse_exited() -> void:
	#await get_tree().create_timer(0.05).timeout
	#if not atacar.get_global_rect().has_point(get_viewport().get_mouse_position()) \
	#and not especial.get_global_rect().has_point(get_viewport().get_mouse_position()):
		#anim.play("Hide")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Hide":
		especial.visible = false


func _on_especial_pressed() -> void:
	var player = get_parent() # UI es hija del Player
	if player.type == "melee":
		player.dash_to_enemy()
		#anim.play("Hide")
		await get_tree().create_timer(0.05).timeout
		especial.visible = false
	elif player.type == "ranger":
		player.super_shoot()
		#anim.play("Hide")
		await get_tree().create_timer(0.05).timeout
		especial.visible = false
	elif player.type == "paladin":
		player.dash_to_enemy()
		#anim.play("Hide")
		await get_tree().create_timer(0.05).timeout
	elif player.type == "ninja":
		player.dash_to_enemy()
		#anim.play("Hide")
		await get_tree().create_timer(0.05).timeout
		
