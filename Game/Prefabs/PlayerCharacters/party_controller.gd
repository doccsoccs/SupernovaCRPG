extends Node2D

var party_members : Array[Character]
var move_flags : Array[Node2D]
var selected_pcs : Array[Character]

# Components
@onready var pc_component = $PCComponent
@onready var mf_component = $MFComponent
@onready var drag_selector = $DragSelector
@onready var ds_collision_component = $DragSelector/CollisionComponent

# Counts / Index
var pc_count : int = 0
var mf_count : int = 0
var mf_index_assigner : int = 0

# Party Movement
var moving_pcs : Array[Character]
var clicked_pos : Vector2 = Vector2.ZERO
var hovering_on_pc : bool = false

# Drag Selecting
var init_pos : Vector2 = Vector2.ZERO
var ds_width : float
var ds_height : float
var dragging : bool = true
var current_mpos : Vector2 = Vector2.ZERO
var center_pos : Vector2 = Vector2.ZERO

# Used to determine how the user is intending to interact with the interface
enum ClickInputType { PlaceMoveFlag, DragSelect, None }
var current_input_type : ClickInputType
var entered_ds_array : Array[Character]
var deciding_input : bool = false
var timer_active : bool = false
var input_timer : float = 0.0
var pmf_input_time : float = 0.05 # place move flag input time
var min_drag_dist : float = 75.0 # how far must be drawn for a SELECT input to count as a DragSelect
var assume_pmf : bool = false

@export var formation_offsets : Array[Vector2] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for pc in pc_component.get_children():
		party_members.append(pc)
	for mf in mf_component.get_children():
		move_flags.append(mf)
	pc_count = party_members.size()
	mf_count = pc_count
	
	# Assign MoveFlags and MF Indeces to PCs
	for p in party_members:
		if mf_index_assigner < mf_count:
			p.mf_index = mf_index_assigner
			p.move_flag = move_flags[mf_index_assigner]
			mf_index_assigner += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	reset_move_check()
	
	## WILL HAVE TO ADAPT TO ALL WORLD ENTITIES !!!!
	# Sorts PC's Z-INDEX by height on the Y-AXIS
	# Z-INDECES start from 1 and increment by 1
	var temp_pc_array = party_members.duplicate()
	temp_pc_array.sort_custom(func(a, b): return a.position.y < b.position.y)
	for i in temp_pc_array.size():
		temp_pc_array[i].z_index = i + 1
	
	# Timer for Input Checks
	if timer_active:
		input_timer += delta
		if input_timer >= pmf_input_time and init_pos.distance_to(get_local_mouse_position()) > min_drag_dist:
			current_input_type = ClickInputType.DragSelect
			assume_pmf = false
		else:
			assume_pmf = true

func _physics_process(_delta):
	# Only be able to set a new move flag if not hovering over a selectable game object
	for p in party_members:
		if p.hovering:
			hovering_on_pc = true
			break
		else:
			hovering_on_pc = false
	
	# Determine which input behavior is being used
	# If short interval between click and release --> PlaceMoveFlag
	# If held and move mouse between click and release --> DragSelect
	# If held and don't move between click and release --> PlaceMoveFlag
	
	# LMB while not hovering on a PC and while having at least one PC selected
	# Potential for either PLACE MOVE FLAG or DRAG SELECT
	if Input.is_action_just_pressed("Select") and selected_pcs.size() > 0 and !hovering_on_pc:
		deciding_input = true
		timer_active = true
		init_pos = get_local_mouse_position()
	
	# ELSE IF --> LMB while not hovering on a PC and while no PCs are selected 
	# Must be drag select
	elif Input.is_action_just_pressed("Select") and selected_pcs.size() == 0 and !hovering_on_pc:
		init_pos = get_local_mouse_position()
		current_input_type = ClickInputType.DragSelect
	
	# LMB is RELEASED
	# Select objects which have entered and remained inside the SelectArea
	if Input.is_action_just_released("Select") and current_input_type == ClickInputType.DragSelect:
		deselect_all()
		
		# Set all selected pcs to selected
		for p in entered_ds_array:
			p.select()
		
		# Reset AREA2D Component
		init_pos = Vector2.ZERO
		current_mpos = Vector2.ZERO
		center_pos = Vector2.ZERO
		ds_collision_component.position = Vector2.ZERO
		ds_collision_component.shape.size.x = 0
		ds_collision_component.shape.size.y = 0
		
		# Reset ENUM
		current_input_type = ClickInputType.None
	
	# LMB is RELEASED, do for ALL released Select inputs
	if Input.is_action_just_released("Select") and deciding_input:
		deciding_input = false
		timer_active = false
		input_timer = 0.0
		
		# Set ENUM if can confirm PlaceMoveFlag input
		if assume_pmf:
			current_input_type = ClickInputType.PlaceMoveFlag
		else:
			current_input_type = ClickInputType.None
	
	# LMB is RELEASED, must have been in DragSelect mode
	elif Input.is_action_just_released("Select") and !deciding_input:
		current_input_type = ClickInputType.None
	
	# Enact input behavior based on an enum
	match current_input_type:
		# LMB to Move Selected Character(s) to the clicked position
		ClickInputType.PlaceMoveFlag:
			place_move_flag()
		# LMB and Drag to Select Multiple Characters at once
		ClickInputType.DragSelect:
			drag_select()
		# Default if no input
		ClickInputType.None:
			pass
	
	queue_redraw()

# Draws the Drag Select Indicator
func _draw():
	if current_input_type == ClickInputType.DragSelect:
		var rect : Rect2 = Rect2(init_pos.x, init_pos.y, current_mpos.x - init_pos.x, current_mpos.y - init_pos.y)
		draw_rect(rect, Color.GOLD, false, 10.0)
		draw_rect(rect, Color(0.85, 0.65, 0.12, 0.2), true)

# Deselect all selected PCs
func deselect_all():
	for p in selected_pcs:
		p.selected = false
	selected_pcs.clear()

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

func place_move_flag():
	# If there are any, mark any pcs that are actively part of a move that 
	# have already arrived as not having arrived since we're now giving them a new destination
	if !moving_pcs.is_empty():
		for p in moving_pcs:
			p.arrived_at_flag = false
	
	# Get mouse position to move pcs to
	clicked_pos = get_local_mouse_position()
	moving_pcs = selected_pcs.duplicate()
	
	# Set new move flags for the selected pcs
	if moving_pcs.size() > 1:
		for i in moving_pcs.size():
			moving_pcs[i].move_to(clicked_pos + formation_offsets[i])
	# Don't use formations if only selecting 1 PC
	elif moving_pcs.size() == 1:
		moving_pcs[0].move_to(clicked_pos)
	
	# Reset Input Type
	current_input_type = ClickInputType.None

func drag_select():
	current_mpos = get_local_mouse_position()
	center_pos.x = (current_mpos.x + init_pos.x) / 2
	center_pos.y = (current_mpos.y + init_pos.y) / 2
	ds_collision_component.position = center_pos
	ds_collision_component.shape.size.x = abs(current_mpos.x - init_pos.x)
	ds_collision_component.shape.size.y = abs(current_mpos.y - init_pos.y)
