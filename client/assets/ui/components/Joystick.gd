extends Area2D

@onready var big_circle = $BigCircle
@onready var small_circle = $BigCircle/SmallCircle

@onready var max_distance = $CollisionShape2D.shape.radius

var touched = false
var action_up = false
var action_down = false
var action_right = false
var action_left = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if event is InputEventScreenTouch:
		var distance = event.position.distance_to(big_circle.global_position)
		if not touched:
			if distance < max_distance:
				touched = true
		else:
			small_circle.position = Vector2(0, 0)
			touched = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if touched:
		small_circle.global_position = get_global_mouse_position()
		#clamp the small circle
		small_circle.position = big_circle.position + (small_circle.position - big_circle.position).limit_length(max_distance)
		var normal_velocity = small_circle.position / max_distance
		if normal_velocity.x < 0.5:
			if action_right:
				Input.action_release("move_right")
				action_right = false
			Input.action_press("move_left", -normal_velocity.x)
			action_left = true
		elif normal_velocity.x > 0.5:
			if action_left:
				Input.action_release("move_left")
				action_left = false
			Input.action_press("move_right", normal_velocity.x)
			action_right = true
		else:
			if action_left:
				action_left = false
				Input.action_release("move_left")
			if action_right:
				action_right = false
				Input.action_release("move_right")
		if normal_velocity.y < 0.5:
			if action_down:
				Input.action_release("move_backward")
				action_down = false
			Input.action_press("move_forward", -normal_velocity.y)
			action_up = true
		elif normal_velocity.y > 0.5:
			if action_up:
				Input.action_release("move_forward")
				action_up = false
			Input.action_press("move_backward", normal_velocity.y)
			action_down = true
		else:
			if action_up:
				action_up = false
				Input.action_release("move_forward")
			if action_down:
				action_down = false
				Input.action_release("move_backward")
	else:
		if action_left:
			action_left = false
			Input.action_release("move_left")
		if action_right:
			action_right = false
			Input.action_release("move_right")
		if action_up:
			action_up = false
			Input.action_release("move_forward")
		if action_down:
			action_down = false
			Input.action_release("move_backward")


func get_velocity():
	var joystick_velocity = Vector2(0, 0)
	joystick_velocity.x = small_circle.position.x / max_distance
	joystick_velocity.y = small_circle.position.y / max_distance
	return joystick_velocity
