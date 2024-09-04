extends CharacterBody2D
class_name Character

@export var move_speed : float = 1000.0
var direction : Vector2 = Vector2.ZERO
var min_dist : float = 20.0
var arrived_at_flag : bool = true
var target_pos : Vector2 = Vector2.ZERO

var selected : bool = false
var hovering : bool = false
var entered_drag_select : bool = false

@onready var anim_player = $AnimationPlayer
@onready var party_controller = $"../.."
@onready var eds_test = $Sprite2D # eds = "entered_drag_select"

var move_flag: Node2D
var mf_index: int

func _process(_delta):
	# LMB to select a PC
	# Adds the selected PC to the list of selected PCs in the party controller
	if hovering and Input.is_action_just_pressed("Select"):
		party_controller.deselect_all()
		select()
		party_controller.entered_ds_array.clear()
	
	# Selected VS Base Animation
	if selected:
		anim_player.play("selected")
	else:
		anim_player.play("base")
	
	## TEST CODE
	if entered_drag_select:
		eds_test.visible = true
	else:
		eds_test.visible = false

func _physics_process(delta):
	if !arrived_at_flag:
		move(delta)
	move_and_slide()

# Move the PC - runs every physics frame 
func move(delta):
	direction = (target_pos - position).normalized()
	velocity += direction * move_speed * delta
	position += velocity
	velocity = Vector2.ZERO
	
	# Show Move Flag at target position
	move_flag.visible = true
	
	# Once reaches target...
	if position.distance_to(target_pos) < min_dist:
		move_flag.visible = false # hide move flag
		arrived_at_flag = true

# Sets new move target
func move_to(new_target_pos : Vector2):
	target_pos = new_target_pos
	arrived_at_flag = false
	move_flag.position = target_pos

# Selects this player character and adds them to the selected pcs array
func select():
	selected = true
	party_controller.selected_pcs.append(self)

# Mouse Over Area Signal that determines if the user is hovering over a player character
func _on_hover():
	hovering = true
func _on_stop_hover():
	hovering = false

# Area2D Signal Called when a DragSelector overlaps while monitoring
func _selected_by_drag_selector(_area):
	if !entered_drag_select:
		entered_drag_select = true
		party_controller.entered_ds_array.append(self)
func _exited_selection(_area):
	if entered_drag_select:
		entered_drag_select = false
		party_controller.entered_ds_array.erase(self)
