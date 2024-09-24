extends Sprite2D

var map_width: float
var map_height: float

func _ready():
	map_width = texture.get_width()
	map_height = texture.get_height()
