extends Node2D

# SIGNALS
signal arrive_at_flag

var party_members : Array[Character]

# TEST PLAYER
@onready var player = $Player
@onready var move_flag = $MoveFlag

# Party Movement
var move_flag_pos : Vector2 = Vector2.ZERO
var active_move_flag : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	party_members.append(player)
	arrive_at_flag.connect(_cancel_flag)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if active_move_flag:
		move_flag.visible = true
		move_flag.position = move_flag_pos
		for p in party_members:
			p.move_to(move_flag_pos, delta)
	else:
		move_flag.visible = false

func _physics_process(_delta):
	if Input.is_action_just_pressed("Select"):
		move_flag_pos = get_local_mouse_position()
		active_move_flag = true

func _cancel_flag():
	active_move_flag = false
