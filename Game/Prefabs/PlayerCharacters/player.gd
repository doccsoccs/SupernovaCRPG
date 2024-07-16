extends CharacterBody2D
class_name Character

@export var move_speed : float = 1000.0
var direction : Vector2 = Vector2.ZERO
var min_dist : Vector2 = Vector2(10, 10)

func move_to(target_pos : Vector2, delta):
	direction = (target_pos - position).normalized()
	velocity += direction * move_speed * delta
	position += velocity
	velocity = Vector2.ZERO
	
	# Once reaches target...
	if position - target_pos < min_dist and position - target_pos > -min_dist:
		owner.arrive_at_flag.emit()
