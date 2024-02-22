class_name GUI
extends Control

@onready var animations = $Animations
@onready var states = $StateManager
@onready var gameNotifications = $GameNotifications
@onready var notificationAnim = $NotificationAnim
@onready var notificationTimer = $NotificationTimer

var current_input_mode = GlobalSignals.INPUT_TYPE_KEYBOARD

var screens
var player


func _ready() -> void:
	player = get_node("/root/World/Player")
	screens = fetch_screens()
	for child in screens:
		screens[child].hide()
	states.init(self)
	GlobalSignals.connect("CHANGE_SCREEN", change_state)
	GlobalSignals.connect("SEND_NOTIFICATION", call_notification)
	GlobalSignals.connect("CHANGE_BUTTON_STATE", change_button_state)


func _unhandled_input(event: InputEvent) -> void:
	states.input(event)


func _physics_process(delta: float) -> void:
	states.physics_process(delta)


func _process(delta: float) -> void:
	states.process(delta)


func fetch_screens() -> Dictionary:
	var screensResult = {}
	for child in $Screens.get_children():
		screensResult[child.name] = child
	return screensResult


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
	var new_input_mode = current_input_mode
	if(event is InputEventKey):
		new_input_mode = GlobalSignals.INPUT_TYPE_KEYBOARD
	elif(event is InputEventJoypadButton):
		new_input_mode = GlobalSignals.INPUT_TYPE_CONTROLLER
	elif(event is InputEventScreenTouch):
		new_input_mode = GlobalSignals.INPUT_TYPE_TOUCH
	
	if current_input_mode != new_input_mode:
		current_input_mode = new_input_mode
		if new_input_mode == GlobalSignals.INPUT_TYPE_TOUCH and DisplayServer.screen_get_dpi() > 120:
			get_tree().root.content_scale_factor = 2.0
		else:
			get_tree().root.content_scale_factor = 1.0
		GlobalSignals.emit_signal("CHANGE_INPUT_TYPE", new_input_mode)
