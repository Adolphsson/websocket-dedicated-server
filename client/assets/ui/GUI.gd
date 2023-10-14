class_name GUI
extends Control

@onready var animations = $Animations
@onready var states = $StateManager
@onready var gameNotifications = $GameNotifications
@onready var notificationAnim = $NotificationAnim
@onready var notificationTimer = $NotificationTimer

var INPUT_KEYBOARD = 0
var INPUT_CONTROLLER = 1
var INPUT_TOUCH = 2
var current_input_mode = INPUT_KEYBOARD

var screens
var player
func _ready() -> void:
	player = get_node("/root/World/Player")
	screens = fetch_screens()
	for child in screens:
		screens[child].hide()
	states.init(self)
	GlobalSignals.connect("CHANGE_SCREEN",change_state)
	GlobalSignals.connect("SEND_NOTIFICATION", call_notification)
	GlobalSignals.connect("CHANGE_BUTTON_STATE",change_button_state)

func _unhandled_input(event: InputEvent) -> void:
	states.input(event)

func _physics_process(delta: float) -> void:
	states.physics_process(delta)

func _process(delta: float) -> void:
	states.process(delta)

func fetch_screens() -> Dictionary:
	var screens = {}
	for child in $Screens.get_children():
		screens[child.name] = child
	return screens

func change_state(newState):
	states.change_state(states.get_node(newState))

func call_notification(text):
	gameNotifications.text = text
	notificationAnim.play("show_notification")
	notificationTimer.start(3)

func _on_timer_timeout():
	notificationAnim.play("hide_notification")
	gameNotifications.text = ""

func change_button_state(value):
	$Screens/Menu/Panel/UserInput.editable = !value
	$Screens/Menu/Panel/PasswordInput.editable = !value
	$Screens/Menu/Panel/LoginButton.disabled = value 
	$Screens/Menu/Panel/RegisterButton.disabled = value 
	$Screens/Register/Panel/UserInput.editable = !value
	$Screens/Register/Panel/PasswordInput.editable = !value
	$Screens/Register/Panel/EmailInput.editable = !value
	$Screens/Register/Panel/RegisterButton.disabled = value  
	$Screens/Register/Panel/CancelButton.disabled = value 
	$Screens/Verify/Panel/VerifyButton.disabled = value 
	$Screens/Verify/Panel/CancelButton.disabled = value 
	$Screens/Verify/Panel/CodeInput.editable = !value

func _input(event):
	if(event is InputEventKey):
		current_input_mode = INPUT_KEYBOARD
	elif(event is InputEventJoypadButton):
		current_input_mode = INPUT_CONTROLLER
	elif(event is InputEventMouseButton):
		current_input_mode = INPUT_KEYBOARD
	elif(event is InputEventScreenTouch):
		current_input_mode = INPUT_TOUCH
	#else:
	#	# Do stuff
	#	print('??')


func _on_user_input_focus_entered():
	if (current_input_mode == INPUT_TOUCH || current_input_mode == INPUT_CONTROLLER):
		DisplayServer.virtual_keyboard_show($Screens/Menu/Panel/UserInput.text)

func _on_input_focus_exited():
	DisplayServer.virtual_keyboard_hide()
