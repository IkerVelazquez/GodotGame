extends Sprite2D

@export var item: Item
 
func _ready():
	texture = item.icon
 
 


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.add_item(item)
		queue_free()
