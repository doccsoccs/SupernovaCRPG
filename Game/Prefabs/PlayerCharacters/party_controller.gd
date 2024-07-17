extends Node2D

# SIGNALS
signal arrive_at_flag

var party_members : Array[Character]
@onready var player_characters = $PlayerCharacters
var pc_count : int = 0
var mf_count : int = 0

# Party Movement
var any_selected : bool = false
var move_flag_pos : Vector2 = Vector2.ZERO
var active_move_flag : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	for pc in player_characters.get_children():
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

func _physics_process(_delta):
	# LMB to Move Selected Character(s) to the clicked position
	if Input.is_action_just_pressed("Select") and any_selected:
		move_flag_pos = get_local_mouse_position()
		active_move_flag = true

func _cancel_flag():
	active_move_flag = false
