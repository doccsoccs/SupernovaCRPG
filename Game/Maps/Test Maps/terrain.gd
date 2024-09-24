extends Node

var terrain_array: Array[StaticBody2D]
var hovered_polygon: CollisionPolygon2D
@onready var party_controller = $"../PartyController"

func _ready():
	for child in get_children():
		if child is StaticBody2D:
			terrain_array.append(child)
			
			# bind() passes a variable into the connected callable
			# get_child(0) returns the collision polygon component of the moused over static body
			child.mouse_entered.connect(_on_mouse_entered.bind(child.get_child(0)))
			child.mouse_exited.connect(_on_mouse_exited)

# INPUT / PICKABLE (must be true to work)
func _on_mouse_entered(polygon):
	party_controller.hovering_on_oob = true
	hovered_polygon = polygon
func _on_mouse_exited():
	party_controller.hovering_on_oob = false
