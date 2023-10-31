extends Area2D

@onready var big_circle = $BigCircle
@onready var knob = $BigCircle/Knob

@onready var max_distance = $CollisionShape2D.shape.radius
@onready var dead_zone = 0.25

@onready var right_action = "move_right"
@onready var left_action = "move_left"
@onready var up_action = "move_forward"
@onready var down_action = "move_backward"

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
			touched = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if touched:
		knob.global_position = get_global_mouse_position()
		#clamp the small circle
		knob.position = big_circle.position + (knob.position - big_circle.position).limit_length(max_distance)
		var normal_velocity = knob.position / max_distance
		if normal_velocity.x < dead_zone:
			if action_right:
				action_right = false
				Input.action_release(right_action)
			Input.action_press(left_action, -normal_velocity.x)
			action_left = true
		elif normal_velocity.x > dead_zone:
			if action_left:
				action_left = false
				Input.action_release(left_action)
			Input.action_press(right_action, normal_velocity.x)
			action_right = true
		else:
			if action_left:
				action_left = false
				Input.action_release(left_action)
			if action_right:
				action_right = false
				Input.action_release(right_action)

		if normal_velocity.y < dead_zone:
			if action_down:
				action_down = false
				Input.action_release(down_action)
			Input.action_press(up_action, -normal_velocity.y)
			action_up = true
		elif normal_velocity.y > dead_zone:
			if action_up:
				action_up = false
				Input.action_release(up_action)
			Input.action_press(down_action, normal_velocity.y)
			action_down = true
		else:
			if action_up:
				action_up = false
				Input.action_release(up_action)
			if action_down:
				action_down = false
				Input.action_release(down_action)
	else:
		if action_left:
			action_left = false
			Input.action_release(left_action)
		if action_right:
			action_right = false
			Input.action_release(right_action)
		if action_up:
			action_up = false
			Input.action_release(up_action)
		if action_down:
			action_down = false
			Input.action_release(down_action)
		if knob.position.x != 0.0 or knob.position.y != 0.0:
			knob.position = lerp(knob.position, Vector2(0, 0), delta)


func get_velocity():
	return knob.position / max_distance
