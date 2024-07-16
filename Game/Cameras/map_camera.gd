extends Camera2D

# CAMERA ZOOM VARIABLES
@export var zoom_speed : Vector2 = Vector2(0.2, 0.2)
@export var zoom_min : Vector2 = Vector2(0.001, 0.001)
@export var zoom_max : Vector2 = Vector2(1.0, 1.0)

# CAMERA MOVE VARIABLES
@export var move_speed : float = 1000.0
var velocity : Vector2 = Vector2.ZERO
var direction : Vector2 = Vector2.ZERO

# CAMERA BOUNDS VARIABLES
var xbound : float
var ybound : float
@export var bounds_buffer : float = 500.0

func _physics_process(delta):
	
	## CAMERA CONTROLS
	# Zooming
	if Input.is_action_just_released("CameraZoomIn"):
		if zoom + zoom_speed < zoom_max:
			zoom = zoom.lerp(zoom + zoom_speed, 0.09)
	if Input.is_action_just_released("CameraZoomOut"):
		if zoom - zoom_speed > zoom_min:
			zoom = zoom.lerp(zoom - zoom_speed, 0.09)
	
	# Determine Direction
	if Input.is_action_pressed("CameraUp"):
		direction += Vector2(0,-1)
	if Input.is_action_pressed("CameraDown"):
		direction += Vector2(0,1)
	if Input.is_action_pressed("CameraLeft"):
		direction += Vector2(-1,0)
	if Input.is_action_pressed("CameraRight"):
		direction += Vector2(1,0)
	
	# Movement
	velocity += direction * move_speed * delta * (1 / zoom.x)
	position += velocity
	
	# Reset Vectors
	direction = Vector2.ZERO
	velocity = Vector2.ZERO
	
	sync_camera_scale()

func sync_camera_scale():
	scale.x = 1 / zoom.x
	scale.y = 1 / zoom.y
