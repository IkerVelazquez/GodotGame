extends SubViewport

@onready var player: CharacterBody2D = $"../../.."
@onready var camera_2d: Camera2D = $Camera2D

var npc_icons = {}
var player_icon = null
var icon_layer: CanvasLayer
var minimap_size: Vector2
var minimap_center: Vector2

# Escala calculada para tu minimapa de 512x512
# Con esta escala, un NPC a 100 unidades se verá a 100 píxeles del centro
var minimap_scale_factor: float = 2.0

func _ready() -> void:
	world_2d = get_tree().root.world_2d
	
	camera_2d.zoom = Vector2(2.1, 2.1)
	camera_2d.position = player.position
	
	await get_tree().process_frame
	minimap_size = size  # Será (512, 512)
	minimap_center = minimap_size / 2  # (256, 256)
	
	
	setup_icon_layer()
	create_player_icon()
	create_npc_icons()

func setup_icon_layer() -> void:
	icon_layer = CanvasLayer.new()
	icon_layer.layer = 10
	add_child(icon_layer)

func create_player_icon() -> void:
	player_icon = Sprite2D.new()
	var rect = ColorRect.new()
	rect.color = Color(0, 1, 0)
	rect.size = Vector2(32, 32)  # Un poco más grande para 512x512
	player_icon.add_child(rect)
	icon_layer.add_child(player_icon)
	player_icon.name = "PlayerIcon"

func create_npc_icons() -> void:
	var npcs = get_tree().get_nodes_in_group("npcs")
	
	for npc in npcs:
		var npc_icon = Sprite2D.new()
		var rect = ColorRect.new()
		rect.color = Color(0, 0, 1)
		rect.size = Vector2(32, 32)  # Un poco más grande para 512x512
		npc_icon.add_child(rect)
		icon_layer.add_child(npc_icon)
		npc_icons[npc] = npc_icon

func _physics_process(delta: float) -> void:
	camera_2d.position = player.position
	
	if player_icon:
		player_icon.position = minimap_center
	
	for npc in npc_icons.keys():
		if is_instance_valid(npc):
			var relative_world = npc.position - player.position
			
			# Con escala 1.0: 72 unidades = 72 píxeles de distancia en el minimapa
			var scaled_position = relative_world * minimap_scale_factor
			var icon_position = minimap_center + scaled_position
			
			# Verificar si está dentro del minimapa (radio de 256 píxeles)
			var distance_from_center = (icon_position - minimap_center).length()
			var is_visible = distance_from_center <= 500  # 256 - 20 (margen para el icono)
			
			npc_icons[npc].position = icon_position
			npc_icons[npc].visible = is_visible
			
		else:
			if npc_icons.has(npc):
				npc_icons[npc].queue_free()
				npc_icons.erase(npc)
