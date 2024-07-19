extends Node2D

# SIGNALS
signal arrive_at_flag

var party_members : Array[Character]
@onready var pc_component = $PCComponent
var pc_count : int = 0
var mf_count : int = 0

# Party Movement
var any_selected : bool = false
var move_flag_pos : Vector2 = Vector2.ZERO
var active_move_flag : bool = false
var can_set_move_flag : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	for pc in pc_component.get_children():
		party_members.append(pc)
	pc_count = party_members.size()
	mf_count = pc_count
	
	# Connect Signals
	arrive_at_flag.connect(_cancel_flag)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Check to see if any player characters are actively selected
	for p in party_members:
		if p.selected:
			any_selected = true
			break
		else:
			any_selected = false
	
	# After the player has clicked to move any selected characters
	# they will move towards the position of the move flag
	if active_move_flag:
		for p in party_members:
			if p.selected:
				p.move_to(move_flag_pos, delta)
	
	# Sorts PC's Z-INDEX by height on the Y-AXIS
	# Z-INDECES start from 1 and increment by 1
	var temp_pc_array : Array[Character] = []
	for p in party_members:
		temp_pc_array.append(p)
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
	if Input.is_action_just_pressed("Select") and any_selected and can_set_move_flag:
		move_flag_pos = get_local_mouse_position()
		active_move_flag = true

func _cancel_flag():
	active_move_flag = false
