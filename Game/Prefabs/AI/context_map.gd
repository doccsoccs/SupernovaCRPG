extends Node

var directional_array : Array[Vector2] = [Vector2(1,0), Vector2(1,-1).normalized(), Vector2(0,-1), Vector2(-1,-1).normalized(),
										  Vector2(-1,0), Vector2(-1,1).normalized(), Vector2(0,1), Vector2(1,1).normalized()]
var length: float = 150

var interest_array : Array[float]
var danger_array : Array[float]
var context_map : Array[float]
var raycast_array : Array
var desired_vec : Vector2 = Vector2.ZERO

const danger: float = 5
const minor_danger: float = 2
var increase_danger_of_next: bool = false

var character: CharacterBody2D

func _ready():
	# Get raycasts in node
	raycast_array = get_children()
	for i in raycast_array.size():
		raycast_array[i].target_position = directional_array[i] * length
	
	# Get parent node
	character = get_parent()

func pathfinding(target_pos: Vector2):
	for i in 8:
		# initialize interest array
		interest_array.append(directional_array[i].dot((target_pos - character.position).normalized()))
		
		# get danger array
		if raycast_array[i].is_colliding():
			danger_array.append(danger)
			if i - 1 >= 0:
				danger_array[i-1] += minor_danger
			if i + 1 <= 7:
				increase_danger_of_next = true
			if i + 1 > 7:
				danger_array[0] += minor_danger
		else:
			if increase_danger_of_next:
				danger_array.append(minor_danger)
			else:
				danger_array.append(0.0)
			increase_danger_of_next = false
		
		# calculate context map
		context_map.append(interest_array[i] - danger_array[i])
	
	# Get the index of the highest value in the context map
	var highest_val: float = context_map.max()
	var dir_index: int = context_map.find(highest_val)
	desired_vec = directional_array[dir_index]
	
	interest_array.clear()
	danger_array.clear()
	context_map.clear()
	
	return desired_vec
