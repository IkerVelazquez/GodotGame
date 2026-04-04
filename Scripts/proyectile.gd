extends Node2D

@export var speed := 600.0
@export var rotation_speed := 10.0
var target_position: Vector2
var is_moving := true

func setup(target_pos: Vector2):
	target_position = target_pos
	# Apuntar hacia el objetivo
	look_at(target_pos)

func _ready():
	# Efecto de aparición
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _process(delta):
	if is_moving:
		
		# Mover hacia el objetivo
		var direction = (target_position - global_position).normalized()
		global_position += direction * speed * delta
		
		# Verificar si llegó al objetivo (o está muy cerca)
		if global_position.distance_to(target_position) < 10.0:
			is_moving = false
			on_impact()

func on_impact():
	# Reproducir animación de impacto
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("impact")
		$AnimatedSprite2D.scale = Vector2(0.4, 0.4)
		GameEvents.request_camera_shake(5, 0.3)
		await $AnimatedSprite2D.animation_finished
	
	queue_free()
