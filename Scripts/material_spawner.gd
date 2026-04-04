extends Node2D

@export var stick_scene: PackedScene
@export var amount := 30
@export var min_distance := 50.0

# Mejor que usar rutas frágiles
@onready var tilemap = $"../TileMapLayer"

var positions: Array[Vector2] = []

func _ready():
	randomize()
	spawn_items()

# 🔹 Obtener límites reales del TileMap
func get_map_bounds() -> Rect2:
	var rect = tilemap.get_used_rect()
	var cell_size = tilemap.tile_set.tile_size
	
	var position = rect.position * cell_size
	var size = rect.size * cell_size
	
	return Rect2(position, size)

# 🔹 Generar objetos
func spawn_items():
	var bounds = get_map_bounds()
	var tries = 0
	
	while positions.size() < amount and tries < amount * 10:
		tries += 1
		
		var pos = Vector2(
			randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
			randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
		)
		
		if is_far_enough(pos) and is_valid_position(pos):
			positions.append(pos)
			spawn_stick(pos)

# 🔹 Evitar que estén muy juntos
func is_far_enough(new_pos: Vector2) -> bool:
	for pos in positions:
		if pos.distance_to(new_pos) < min_distance:
			return false
	return true

# 🔹 Evitar paredes / colisiones
func is_valid_position(pos: Vector2) -> bool:
	var space = get_world_2d().direct_space_state
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space.intersect_point(query)
	
	return result.is_empty()

# 🔹 Instanciar el objeto
func spawn_stick(pos: Vector2):
	var stick = stick_scene.instantiate()
	stick.position = pos
	add_child(stick)
