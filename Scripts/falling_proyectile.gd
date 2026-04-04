extends Node2D

@export var fall_speed := 1600.0
@export var rotation_speed := 5.0
var target_position: Vector2
var is_falling := true

func setup(target_pos: Vector2):
	target_position = target_pos

func _ready():
	$AnimatedSprite2D.scale = Vector2(1.0, 1.0)
	# Opcional: agregar un efecto de parpadeo o escalado al aparecer
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _process(delta):
	if is_falling:
		# Rotar el proyectil
		rotation += rotation_speed * delta
		
		# Mover hacia abajo
		global_position.y += fall_speed * delta
		
		# Verificar si llegó al objetivo
		if global_position.y >= target_position.y:
			is_falling = false
			on_impact()

func on_impact():
	# Reproducir animación de impacto
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.scale = Vector2(0.4, 0.4)
		$AnimatedSprite2D.play("impact")
		GameEvents.request_camera_shake(10,0.5)
		await $AnimatedSprite2D.animation_finished
	
	# Opcional: agregar efectos de partículas o sonido
	queue_free()
