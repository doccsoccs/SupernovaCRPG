extends CharacterBody2D
class_name Character

@export var move_speed : float = 1000.0
var direction : Vector2 = Vector2.ZERO
var min_dist : float = 8.5
var arrived_at_flag

var selected : bool = false
var hovering : bool = false

@onready var move_flag = $MoveFlag
@onready var anim_player = $AnimationPlayer
@onready var party_controller = $"../.."

func _process(_delta):
	# LMB to select a PC
	# Adds the selected PC to the list of selected PCs in the party controller
	if hovering and Input.is_action_just_pressed("Select") and !selected: # only be able to select if not already selected
		selected = true
		party_controller.selected_pcs.append(self)
	
	# Selected VS Base Animation
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
		arrived_at_flag = true
	else:
		arrived_at_flag = false

func _on_hover():
	hovering = true
func _on_stop_hover():
	hovering = false
