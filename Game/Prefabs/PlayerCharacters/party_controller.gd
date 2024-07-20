extends Node2D

var party_members : Array[Character]
var selected_pcs : Array[Character]

@onready var pc_component = $PCComponent
var pc_count : int = 0

# Party Movement
var moving_pcs : Array[Character]
var clicked_pos : Vector2 = Vector2.ZERO
var can_set_move_flag : bool = false

@export var formation_offsets : Array[Vector2] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for pc in pc_component.get_children():
		party_members.append(pc)
	pc_count = party_members.size()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# After the player has clicked to move any selected characters
	# they will move towards the position of the move flag
	if moving_pcs.size() > 1:
		for i in moving_pcs.size():
			if !moving_pcs[i].arrived_at_flag:
				moving_pcs[i].move_to(clicked_pos + formation_offsets[i], delta)
	# Don't use formations if only selecting 1 PC
	elif moving_pcs.size() == 1:
		if !moving_pcs[0].arrived_at_flag:
			moving_pcs[0].move_to(clicked_pos, delta)
	
	reset_move_check()
	
	## WILL HAVE TO ADAPT TO ALL WORLD ENTITIES !!!!
	# Sorts PC's Z-INDEX by height on the Y-AXIS
	# Z-INDECES start from 1 and increment by 1
	var temp_pc_array = party_members.duplicate()
	temp_pc_array.sort_custom(func(a, b): return a.position.y < b.position.y)
	for i in temp_pc_array.size():
		temp_pc_array[i].z_index = i + 1

func _physics_process(_delta):
	# Only be able to set a new move flag if not hovering over a selectable game object
	for p in party_members:
		if p.hovering:
			can_set_move_flag = false
			break
		else:
			can_set_move_flag = true
	
	# LMB to Move Selected Character(s) to the clicked position
	if Input.is_action_just_pressed("Select") and selected_pcs.size() > 0 and can_set_move_flag:
		# If there are any, mark any pcs that are actively part of a move that 
		# have already arrived as not having arrived since we're now giving them a new destination
		if !moving_pcs.is_empty():
			for p in moving_pcs:
				p.arrived_at_flag = false
		
		# Get mouse position to move pcs to
		clicked_pos = get_local_mouse_position()
		moving_pcs = selected_pcs.duplicate()

# Checks whether or not all moving pcs have finished moving
# if they have remove them from the moving_pcs array and reset their
# arrived_at_flag bool
func reset_move_check():
	var reset_moving_pcs : bool = false
	for p in moving_pcs:
		if !p.arrived_at_flag:
			reset_moving_pcs = false
			break
		else:
			reset_moving_pcs = true
	if reset_moving_pcs:
		for p in moving_pcs:
			p.arrived_at_flag = false
		moving_pcs.clear()
