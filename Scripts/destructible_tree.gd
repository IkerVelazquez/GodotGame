extends Node2D

@export var drop_items: Array[Item] = []  # Items a dropear
@export var drop_amounts: Array[int] = []  # Cantidades correspondientes
@export var respawn_time_min: float = 5.0
@export var respawn_time_max: float = 10.0
@export var explosion_time: float = 1.5
@export var chop_time: float = 3.0

var is_alive: bool = true
var is_choping: bool = false
var chop_progress: float = 0.0

@onready var tree_sprite = $tree_sprite
@onready var leaf2 = $Leaf2
@onready var leaf = $Leaf
@onready var animated_sprite = $AnimatedSprite2D
@onready var log_sprite = $log_sprite
@onready var area_2d = $Area2D
@onready var progress_bar = $ProgressBar
@onready var interaction_label = $InteractionLabel

var dialogue = preload("res://Dialogues/first_tree.dialogue")
# Clase interna para definir drops
class DropItem:
	var item: Item
	var amount: int
	var probability: float  # 0.0 a 1.0
	
	func _init(p_item: Item, p_amount: int, p_probability: float = 1.0):
		item = p_item
		amount = p_amount
		probability = p_probability

func _ready() -> void:
	reset_tree()
	progress_bar.visible = false
	interaction_label.visible = false

func _process(delta: float) -> void:
	if not is_alive:
		return
	
	if is_choping:
		chop_progress += delta
		progress_bar.value = (chop_progress / chop_time) * 100
		
		if chop_progress >= chop_time:
			complete_chop()
	else:
		if chop_progress > 0:
			chop_progress = 0
			progress_bar.value = 0

func _input(event: InputEvent) -> void:
	if not is_alive:
		return
		
	if event.is_action_pressed("interact"):
		if is_player_in_area():
			start_chop()
	
	if event.is_action_released("interact"):
		if is_choping:
			cancel_chop()

func start_chop() -> void:
	is_choping = true
	progress_bar.visible = true
	interaction_label.text = "Talando..."
	interaction_label.visible = true

func cancel_chop() -> void:
	is_choping = false
	chop_progress = 0
	progress_bar.visible = false
	interaction_label.text = "Talar [F]"

func complete_chop() -> void:
	is_choping = false
	progress_bar.visible = false
	interaction_label.visible = false
	
	# Dar todos los drops al jugador
	drop_item()
	
	# Destruir el árbol
	destroy_tree()

func drop_item() -> void:
	var player = get_player_in_area()
	if not player:
		return
	
	# Entregar items según los arrays
	for i in range(drop_items.size()):
		if i < drop_amounts.size():
			var prob = 1.0
			
			
			if randf() <= prob:
				for j in range(drop_amounts[i]):
					player.add_item(drop_items[i])

func is_player_in_area() -> bool:
	var overlapping_bodies = area_2d.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("Player"):
			return true
	return false

func get_player_in_area():
	var overlapping_bodies = area_2d.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.is_in_group("Player"):
			return body
	return null

func reset_tree() -> void:
	tree_sprite.visible = true
	leaf2.visible = false
	leaf.visible = false
	animated_sprite.visible = false
	log_sprite.visible = false
	
	area_2d.set_deferred("monitoring", true)
	area_2d.set_deferred("monitoringable", true)
	
	is_alive = true
	is_choping = false
	chop_progress = 0
	progress_bar.visible = false
	interaction_label.visible = false

func destroy_tree() -> void:
	if not is_alive:
		return
		
	is_alive = false
	
	if is_choping:
		cancel_chop()
	area_2d.set_deferred("monitoring", false)
	progress_bar.visible = false
	interaction_label.visible = false
	
	tree_sprite.visible = false
	leaf2.visible = true
	leaf.visible = true
	animated_sprite.visible = true
	log_sprite.visible = true
	
	$Leaf2/AnimationPlayer.play("leaf_fallin")
	$Leaf/AnimationPlayer.play("leaf_fallin")
	animated_sprite.play("default")
	$choped.play()
	
	await get_tree().create_timer(explosion_time).timeout
	leaf.visible = false
	leaf2.visible = false
	_on_madera_recolectada(1)
	start_respawn()
	

func start_respawn() -> void:
	var random_time = randf_range(respawn_time_min, respawn_time_max)
	await get_tree().create_timer(random_time).timeout
	reset_tree()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not is_alive:
		return
	
	if body.is_in_group("Player"):
		interaction_label.text = "Talar [F]"
		interaction_label.visible = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		interaction_label.visible = false
		if is_choping:
			cancel_chop()

# En tu script de recolección de madera (ej: árbol, player, etc.)
func _on_madera_recolectada(cantidad: int):
	print("🪵 Madera recolectada: ", cantidad)
	
	# Actualizar progreso de la misión "Recolecta madera"
	if MisionSystem.is_mission_active("recolecta madera"):
		MisionSystem.update_mission_progress("recolecta madera", "madera", cantidad)
		
		
		# Verificar si la misión se completó después de actualizar
		# No es necesario verificar otra vez porque update_mission_progress ya llama a complete_mission si es necesario
		# Pero si quieres hacer algo específico al completar, conecta la señal mision_completada
	else:
		print("⚠️ Misión 'Recolecta madera' no está activa")
