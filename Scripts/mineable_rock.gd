# MineableRock.gd
extends Area2D
class_name MineableRock

@export var drop_item: Item
@export var drop_amount: int = 1
@export var required_tool_level: int = 1
@export var mining_time: float = 2.0
@export var respawn_time: float = 10.0  # Tiempo para regenerarse

var is_mining: bool = false
var mining_progress: float = 0.0
var player_in_area: Node2D = null
var is_alive: bool = true
var is_respawning: bool = false

@onready var progress_bar = $ProgressBar
@onready var interaction_label = $Label
@onready var sprite = $Sprite2D  # Asegúrate de tener un Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	progress_bar.visible = false
	interaction_label.visible = false
	progress_bar.max_value = mining_time
	$AnimatedSprite2D.visible = false
	$stone_sharp.visible = false
	$mini_stone.visible = false
	$mini_stone2.visible = false

func _process(delta):
	if not is_alive or is_respawning:
		return
	
	if not is_mining:
		return
	
	if not player_in_area or not _can_mine():
		cancel_mining()
		return
	
	mining_progress += delta
	progress_bar.value = mining_progress
	
	if mining_progress >= mining_time:
		complete_mining()

func _can_mine() -> bool:
	var player = player_in_area
	if not player:
		return false
	
	var tool = player.get_equipped_tool()
	
	if not tool or tool.tool_type != "pickaxe":
		interaction_label.text = "Necesitas un pico"
		return false
	
	if tool.tool_level < required_tool_level:
		interaction_label.text = "Pico muy débil"
		return false
	
	return true

func start_mining():
	if is_mining or not is_alive or is_respawning:
		return
	
	if not _can_mine():
		return
	
	is_mining = true
	mining_progress = 0
	progress_bar.visible = true
	progress_bar.value = 0
	interaction_label.text = "Picando..."

func cancel_mining():
	is_mining = false
	mining_progress = 0
	progress_bar.visible = false
	if is_alive:
		interaction_label.text = "Picar [F]"

func complete_mining():
	is_mining = false
	progress_bar.visible = false
	
	# Dar el item al jugador
	var inventory = get_tree().current_scene.find_child("Inventory")
	if inventory and drop_item:
		for i in range(drop_amount):
			inventory.add_item(drop_item)
		print("Obtuviste: ", drop_amount, "x ", drop_item.name)
	
	# Desaparecer la piedra
	is_alive = false
	_show_rock(false)
	
	$AnimatedSprite2D.visible = true
	$AnimatedSprite2D.play("default")
	$break.play()
	$mini_stone.visible = true
	$mini_stone2.visible = true
	$mini_stone/AnimationPlayer.play("explosion")
	$mini_stone2/AnimationPlayer.play("explosion")
	$stone_sharp.visible = true
	await get_tree().create_timer(1.5).timeout
	$mini_stone.visible = false
	$mini_stone2.visible = false
	# Iniciar regeneración
	start_respawn()

func start_respawn():
	is_respawning = true
	
	# Esperar el tiempo de regeneración
	await get_tree().create_timer(respawn_time).timeout
	
	# Regenerar
	is_alive = true
	is_respawning = false
	_show_rock(true)
	
	# Cancelar minería si alguien estaba picando
	cancel_mining()
	
	print("Piedra regenerada")

func _show_rock(visible: bool):
	# Mostrar/ocultar visualmente
	if sprite:
		sprite.visible = visible
		$stone_sharp.visible = false
	
	if collision:
		collision.disabled = not visible
	

func _on_body_entered(body: Node2D):
	if not is_alive or is_respawning:
		return
		
	if body.is_in_group("Player"):
		player_in_area = body
		interaction_label.text = "Picar [F]"
		interaction_label.visible = true

func _on_body_exited(body: Node2D):
	if body.is_in_group("Player"):
		player_in_area = null
		interaction_label.visible = false
		cancel_mining()

func _input(event):
	if not player_in_area or not is_alive or is_respawning:
		return
	
	if event.is_action_pressed("interact"):
		if not is_mining:
			start_mining()
	
	if event.is_action_released("interact"):
		if is_mining:
			cancel_mining()
