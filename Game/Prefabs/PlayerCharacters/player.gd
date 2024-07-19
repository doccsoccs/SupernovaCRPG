extends CharacterBody2D
class_name Character

@export var move_speed : float = 1000.0
var direction : Vector2 = Vector2.ZERO
var min_dist : float = 8.2

var selected : bool = false
var hovering : bool = false

@onready var move_flag = $MoveFlag
@onready var anim_player = $AnimationPlayer

func _process(_delta):
	# LMB to select a PC
	if hovering and Input.is_action_just_pressed("Select"):
		selected = true
	
	# Selected VS Base Anim
	if selected:
		anim_player.play("selected")
	else:
		anim_player.play("base")

func _physics_process(_delta):
	move_and_slide()

func move_to(target_pos : Vector2, delta):	
	direction = (target_pos - position).normalized()
	velocity += direction * move_speed * delta
	position += velocity
	velocity = Vector2.ZERO
	
	# Show Move Flag at target position
	move_flag.visible = true
	move_flag.position = target_pos - position
	
	# Once reaches target...
	if position.distance_to(target_pos) < min_dist:
		move_flag.visible = false # hide move flag
		owner.arrive_at_flag.emit()

func _on_hover():
	hovering = true
func _on_stop_hover():
	hovering = false
