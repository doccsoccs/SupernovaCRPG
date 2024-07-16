extends Camera2D

# CAMERA ZOOM VARIABLES
@export var zoom_speed : Vector2 = Vector2(2.0, 2.0)
@export var zoom_min : Vector2 = Vector2(0.2, 0.2)
@export var zoom_max : Vector2 = Vector2(2.0, 2.0)
@export var zoom_mult : float = 0.1

# CAMERA MOVE VARIABLES
@export var move_speed : float = 1000.0
var velocity : Vector2 = Vector2.ZERO
var direction : Vector2 = Vector2.ZERO
var push_up : bool = false
var push_down : bool = false
var push_left : bool = false
var push_right : bool = false
var using_keyboard : bool = false

# CAMERA BOUNDS VARIABLES
var xbound : float
var ybound : float
@export var bounds_buffer : float = 500.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED # prevents mouse from leaving screen

func _physics_process(delta):
	
	## CAMERA CONTROLS
	# Zooming
	if Input.is_action_just_released("CameraZoomIn"):
		if zoom + zoom_speed < zoom_max:
			zoom = zoom.lerp(zoom + (zoom_speed * zoom), zoom_mult)
		else:
			zoom = zoom.lerp(zoom_max, zoom_mult)
	
	if Input.is_action_just_released("CameraZoomOut"):
		if zoom - zoom_speed > zoom_min:
			zoom = zoom.lerp(zoom - (zoom_speed * zoom), zoom_mult)
		else:
			zoom = zoom.lerp(zoom_min, zoom_mult)
	
	# Keyboard Screen Movement Input
	if Input.is_action_pressed("CameraUp"):
		direction += Vector2(0,-1)
		using_keyboard = true
	if Input.is_action_pressed("CameraDown"):
		direction += Vector2(0,1)
		using_keyboard = true
	if Input.is_action_pressed("CameraLeft"):
		direction += Vector2(-1,0)
		using_keyboard = true
	if Input.is_action_pressed("CameraRight"):
		direction += Vector2(1,0)
		using_keyboard = true
	
	# Screen Push
	if push_up and !using_keyboard:
		direction += Vector2(0,-1)
	if push_down and !using_keyboard:
		direction += Vector2(0,1)
	if push_left and !using_keyboard:
		direction += Vector2(-1,0)
	if push_right and !using_keyboard:
		direction += Vector2(1,0)
	
	# Movement
	velocity += direction * move_speed * delta * (1 / zoom.x)
	position += velocity
	
	# Reset Vectors
	direction = Vector2.ZERO
	velocity = Vector2.ZERO
	
	# MISC Camera Update
	using_keyboard = false
	sync_camera_scale()

func sync_camera_scale():
	scale.x = 1 / zoom.x
	scale.y = 1 / zoom.y

# SCREEN PUSHING
func _push_up():
	push_up = true
func _stop_push_up():
	push_up = false
func _push_down():
	push_down = true
func _stop_push_down():
	push_down = false
func _push_left():
	push_left = true
func _stop_push_left():
	push_left = false
func _push_right():
	push_right = true
func _stop_push_right():
	push_right = false
