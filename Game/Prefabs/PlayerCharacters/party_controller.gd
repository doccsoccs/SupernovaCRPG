extends Node2D

var party_members : Array[Character]
var move_flags : Array[Node2D]
var preview_mfs : Array[Node2D]
var selected_pcs : Array[Character]

# Components
@onready var pc_component = $PCComponent
@onready var mf_component = $MFComponent
@onready var mf_preview_component = $MFPreviewComponent
@onready var drag_selector = $DragSelector
@onready var ds_collision_component = $DragSelector/CollisionComponent
@onready var camera = $"../MapCamera"
@onready var map = $"../MapSprite"
@onready var collision_tester = $TerrainCollisionTester

# Counts / Index
var pc_count : int = 0
var mf_count : int = 0
var mf_index_assigner : int = 0

# Party Movement
var moving_pcs : Array[Character]
var clicked_pos : Vector2 = Vector2.ZERO
var hovering_on_pc: bool = false
var hovering_on_oob: bool = false # oob = out of bounds
var adjusted_legal_pos: Vector2 = Vector2.ZERO
var adjust_for_oob: bool = false

# Drag Selecting
var init_pos : Vector2 = Vector2.ZERO
var ds_width : float
var ds_height : float
var dragging : bool = true
var current_mpos : Vector2 = Vector2.ZERO
var center_pos : Vector2 = Vector2.ZERO

# RMB Controls
var holding_rmb: bool = false
var formation_angle: float
var use_rmb_rotated_offsets: bool = false
var valid_rmb_input: bool = false

# Terrain Info
@onready var terrain_component = $"../Terrain"

# Used to determine how the user is intending to interact with the interface
enum ClickInputType { PlaceMoveFlag, DragSelect, None }
var current_input_type : ClickInputType
var entered_ds_array : Array[Character]
var deciding_input : bool = false
var timer_active : bool = false
var input_timer : float = 0.0
var pmf_input_time : float = 0.1 # place move flag input time
var min_drag_dist : float = 50.0 # how far must be drawn for a SELECT input to count as a DragSelect
var assume_pmf : bool = false

@export var formation_offsets : Array[Vector2] = []

# Called when the node enters the scene tree fodsr the first time.
func _ready():
	for pc in pc_component.get_children():
		party_members.append(pc)
	for mf in mf_component.get_children():
		move_flags.append(mf)
	for pmf in mf_preview_component.get_children():
		preview_mfs.append(pmf)
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
		if input_timer <= pmf_input_time:
			assume_pmf = true
		elif init_pos.distance_to(get_local_mouse_position()) > min_drag_dist:
			current_input_type = ClickInputType.DragSelect
			assume_pmf = false
		elif !hovering_on_oob:
			assume_pmf = true
	
	# Get the angle between the RMB Clicked Pos and current mouse position
	if holding_rmb and selected_pcs.size() > 1:
		if clicked_pos != get_local_mouse_position():
			formation_angle = (clicked_pos - get_local_mouse_position()).angle()
		else:
			formation_angle = (clicked_pos - selected_pcs[0].position).angle() + PI
		
		# Reveals preview move flags here to prevent jarring movement from 
		# the assumed LMB angle to the initial manual RMB angle
		for i in selected_pcs.size():
			preview_mfs[i].position = clicked_pos + formation_offsets[i].rotated(formation_angle)
			preview_mfs[i].visible = true
			
			if !is_point_in_bounds(preview_mfs[i].position):
				var temp_pos: Vector2 = preview_mfs[i].position
				const inbounds_adjust: int = 80
				var w: float = map.map_width * map.scale.x
				var h: float = map.map_height * map.scale.x
				if temp_pos.x >= w:
					preview_mfs[i].position.x = w - inbounds_adjust
				elif temp_pos.x <= 0:
					preview_mfs[i].position.x = 0 + inbounds_adjust
				if temp_pos.y >= h:
					preview_mfs[i].position.y = h - inbounds_adjust
				elif temp_pos.y <= 0:
					preview_mfs[i].position.y = 0 + inbounds_adjust
		
	else:
		for i in preview_mfs.size():
			preview_mfs[i].visible = false

func _physics_process(_delta):
	# Only be able to set a new move flag if not hovering over a selectable game object
	for p in party_members:
		if p.hovering:
			hovering_on_pc = true
			break
		else:
			hovering_on_pc = false
	
	# Calls the draw function for DRAG SELECT
	queue_redraw()

# Draws the Drag Select Indicator
func _draw():
	if current_input_type == ClickInputType.DragSelect:
		var rect : Rect2 = Rect2(init_pos.x, init_pos.y, current_mpos.x - init_pos.x, current_mpos.y - init_pos.y)
		draw_rect(rect, Color.GOLD, false, 10.0)
		draw_rect(rect, Color(0.85, 0.65, 0.12, 0.2), true)

# Handles MouseButton controls for environment maps
func _input(_event):
	# Determine which input behavior is being used
	# If short interval between click and release --> PlaceMoveFlag
	# If held and move mouse between click and release --> DragSelect
	# If held and don't move between click and release --> PlaceMoveFlag
	
	# Movement when clicking on inaccessible terrain (LMB)
	# Get the clicked point, compare distances between all edges and verteces of clicked polygon
	# Get the closest point to the outside of the polygon
	# Any points that fall out of bounds are thrown out
	# Place move flags some distance away from the closest point outside the polygon
	
	# Movement when angling formation inside inaccessible terrain (RMB)
	# Determine which move flags are inside inaccessible terrain
	# Place move flags some distance away from the closest point outside the polygon
	
#region Movement Input Determination
	#----------------------------------------------------------------------------------------------
	#                                      LEFT MOUSE BUTTON
	#----------------------------------------------------------------------------------------------
	# LMB while not hovering on a PC and while having at least one PC selected
	# Potential for either PLACE MOVE FLAG or DRAG SELECT
	if Input.is_action_just_pressed("Select") and selected_pcs.size() > 0 and !hovering_on_pc:
		deciding_input = true
		timer_active = true
		init_pos = get_local_mouse_position()
		
		if hovering_on_oob:
			adjust_for_oob = true
	
	# ELSE IF --> LMB while not hovering on a PC and while no PCs are selected 
	# Must be drag select
	elif Input.is_action_just_pressed("Select") and selected_pcs.size() == 0 and !hovering_on_pc:
		init_pos = get_local_mouse_position()
		current_input_type = ClickInputType.DragSelect
		
		if hovering_on_oob:
			adjust_for_oob = true
	
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
	
	# ---------------------------------------------------------------------------------------------
	#                                      RIGHT MOUSE BUTTON
	# ---------------------------------------------------------------------------------------------
	# RMB can be used to place a move flag too
	# If held RMB can be used to change the angle of the move formation
	if Input.is_action_just_pressed("AngledMoveSelect") and selected_pcs.size() > 0 and \
	!hovering_on_pc and !hovering_on_oob and !deciding_input:
		# Display angled move flags
		clicked_pos = get_local_mouse_position()
		
		# Tells the game to let the input go through on RMB released
		# matters for rmb movement where the mouse moves into unaccessible terrain
		if selected_pcs.size() > 1:
			holding_rmb = true
			valid_rmb_input = true
		else:
			holding_rmb = false
			valid_rmb_input = false
	
	# RMB is Released, set moveflag on
	if Input.is_action_just_released("AngledMoveSelect") and !deciding_input and valid_rmb_input:
		holding_rmb = false
		use_rmb_rotated_offsets = true
		current_input_type = ClickInputType.PlaceMoveFlag
		valid_rmb_input = false # reset value
#endregion
	
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
	
	# SELECT ALL PARTY CHARACTERS
	if Input.is_action_just_pressed("SelectAllCharacters"):
		selected_pcs.clear()
		for i in party_members.size():
			party_members[i].select()

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

# Initializes a movement operation for selected party members 
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
	# Rotates formation offsets based on 1st position party member and clicked position
	if moving_pcs.size() > 1 and is_point_in_bounds(clicked_pos):
		
		for i in moving_pcs.size():
			if adjust_for_oob: # LMB into OOB terrain
				var target_vertex: Vector2 = get_nearest_inbound_pos(terrain_component.hovered_polygon, clicked_pos)
				moving_pcs[i].move_to(get_valid_move_pos(moving_pcs[i].position, target_vertex))
				
			elif use_rmb_rotated_offsets: # RMB formation rotation
				if get_colliding_polygon(preview_mfs[i].position) != null:
					var vertex: Vector2 = get_nearest_inbound_pos(get_colliding_polygon(preview_mfs[i].position), clicked_pos)
					preview_mfs[i].position = get_valid_move_pos(moving_pcs[i].position, vertex)
				moving_pcs[i].move_to(preview_mfs[i].position)
			
			else: # regular placement
				var pos: Vector2 = clicked_pos + formation_offsets[i].rotated(get_move_rotation(moving_pcs[0]))
				if get_colliding_polygon(pos) != null:
					var vertex: Vector2 = get_nearest_inbound_pos(get_colliding_polygon(pos), clicked_pos)
					pos = get_valid_move_pos(moving_pcs[i].position, vertex)
				moving_pcs[i].move_to(out_of_bounds_adjust(pos))
			
	# Don't use formations if only selecting 1 PC
	elif moving_pcs.size() == 1 and is_point_in_bounds(clicked_pos):
		if adjust_for_oob: # LMB into OOB terrain
			var target_vertex: Vector2 = get_nearest_inbound_pos(terrain_component.hovered_polygon, clicked_pos)
			moving_pcs[0].move_to(get_valid_move_pos(moving_pcs[0].position, target_vertex))
		else: # regular placement
			moving_pcs[0].move_to(clicked_pos)
	
	use_rmb_rotated_offsets = false
	adjust_for_oob = false
	
	# Reset Input Type
	current_input_type = ClickInputType.None

# Determines dimensions of drag select area
func drag_select():
	current_mpos = get_local_mouse_position()
	center_pos.x = (current_mpos.x + init_pos.x) / 2
	center_pos.y = (current_mpos.y + init_pos.y) / 2
	ds_collision_component.position = center_pos
	ds_collision_component.shape.size.x = abs(current_mpos.x - init_pos.x)
	ds_collision_component.shape.size.y = abs(current_mpos.y - init_pos.y)

# Returns a radian value used to denote the rotation of a party formation after LMB 
func get_move_rotation(first_selected: CharacterBody2D) -> float:
	return (clicked_pos - first_selected.position).angle() + PI

# Calculates the nearest valid position for a party member to move when the user 
# clicks on inaccessible terrain. 
# Polygon is assumed to have more than 2 verteces.
func get_nearest_inbound_pos(terrain: CollisionPolygon2D, target_pos: Vector2) -> Vector2:
	var polygon_verteces: PackedVector2Array = terrain.polygon
	
	# Append all verteces and perpendicular edge points to an array to test for which is closest
	var test_pts: Array[Vector2] = []
	for i in polygon_verteces.size():
		test_pts.append(polygon_verteces[i])
	
	var closest_pos: Vector2 = test_pts[0]
	
	# Check distances between the clicked pos and relevant verteces and edges
	for i in range(1, test_pts.size()):
		if target_pos.distance_to(test_pts[i]) < target_pos.distance_to(closest_pos)\
		and is_point_in_bounds(test_pts[i]): # don't return an out of bounds point
			closest_pos = test_pts[i]
	
	return closest_pos

func get_valid_move_pos(initial_flag_pos: Vector2, vertex: Vector2) -> Vector2:
	const segments: int = 10
	var test_pos: Vector2 = initial_flag_pos
	var init_to_vertex: Vector2 = vertex - initial_flag_pos
	var segment: Vector2 = init_to_vertex / segments 
	var found: bool = false
	var nearest_valid_pos: Vector2 = initial_flag_pos
	
	for i in segments:
		test_pos += segment
		if !get_colliding_polygon(test_pos):
			nearest_valid_pos = test_pos
			found = true
	
	if found:
		return nearest_valid_pos
	else:
		return Vector2.ZERO

# Returns true if the given point detects a collision with layer 1 (World), and false if not
# Used for detecting move flag overlap with inaccessible terrain
func get_colliding_polygon(pos: Vector2) -> CollisionPolygon2D:
	collision_tester.position = pos
	var collision_info: KinematicCollision2D = collision_tester.move_and_collide(collision_tester.velocity * get_process_delta_time(), true)
	if collision_info != null:
		if collision_info.get_collider() is StaticBody2D: # breaks if detects a staticbody2d with no child
			return collision_info.get_collider().get_child(0)
		else:
			return null
	else:
		return null

# Returns a bool dependent on whether or not a Vector2 falls in or out of a map bounds
# Returns true if the point is within bounds, and false if not
func is_point_in_bounds(pos: Vector2) -> bool:
	var w: float = map.map_width * map.scale.x
	var h: float = map.map_height * map.scale.x
	if pos.x < 0 or pos.x > w or pos.y < 0 or pos.y > h:
		return false 
	else:
		return true

# Adjusts the inputed point to be within bounds if it is out of bounds
func out_of_bounds_adjust(pos: Vector2) -> Vector2:
	var temp_pos: Vector2 = pos
	if !is_point_in_bounds(pos):
		const inbounds_adjust: int = 80
		var w: float = map.map_width * map.scale.x
		var h: float = map.map_height * map.scale.x
		if temp_pos.x >= w:
			temp_pos.x = w - inbounds_adjust
		elif temp_pos.x <= 0:
			temp_pos.x = 0 + inbounds_adjust
		if temp_pos.y >= h:
			temp_pos.y = h - inbounds_adjust
		elif temp_pos.y <= 0:
			temp_pos.y = 0 + inbounds_adjust
	
	return temp_pos
