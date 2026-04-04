extends CanvasLayer

@onready var icons_container = $IconsContainer

func _ready():
	Minimapglobal.icons_container = icons_container
