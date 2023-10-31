extends Area2D

@onready var big_circle = $BigCircle
@onready var knob = $BigCircle/Knob

@onready var max_distance = $CollisionShape2D.shape.radius
@onready var dead_zone = 0.5

@onready var left_action = "move_left"
@onready var right_action = "move_right"
@onready var up_action = "move_forward"
@onready var down_action = "move_backward"

var touched = false
var current_action = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	current_action[left_action] = false
	current_action[right_action] = false
	current_action[up_action] = false
	current_action[down_action] = false
	pass # Replace with function body.

func _input(event):
	if event is InputEventScreenTouch:
		var distance = event.position.distance_to(big_circle.global_position)
		if not touched:
			if distance < max_distance:
				touched = true
		else:
			touched = false


func _action(action, pressed):
	if current_action[action] != pressed:
		current_action[action] = pressed
		var evt = InputEventAction.new()
		evt.action = action
		evt.pressed = pressed
		Input.parse_input_event(evt)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if touched:
		knob.global_position = get_global_mouse_position()
		#clamp the small circle
		knob.position = big_circle.position + (knob.position - big_circle.position).limit_length(max_distance)
		var normal_velocity = knob.position / max_distance
		if normal_velocity.x < -dead_zone:
			_action(right_action, false)
			_action(left_action, true)
		elif normal_velocity.x > dead_zone:
			_action(left_action, false)
			_action(right_action, true)
		else:
			_action(left_action, false)
			_action(right_action, false)

		if normal_velocity.y < -dead_zone:
			_action(down_action, false)
			_action(up_action, true)
		elif normal_velocity.y > dead_zone:
			_action(up_action, false)
			_action(down_action, true)
		else:
			_action(up_action, false)
			_action(down_action, false)
	else:
		_action(left_action, false)
		_action(right_action, false)
		_action(up_action, false)
		_action(down_action, false)
		if knob.position.x != 0.0 or knob.position.y != 0.0:
			knob.position = lerp(knob.position, Vector2(0, 0), delta * 25.0)


func get_velocity():
	return knob.position / max_distance
