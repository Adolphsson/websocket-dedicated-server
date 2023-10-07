extends Control

@onready var userInput = $Panel/UserInput
@onready var passwordInput = $Panel/PasswordInput

const LOGIN_FILE = "user://login.txt"

# Called when the node enters the scene tree for the first time.
func _ready():
	if FileAccess.file_exists(LOGIN_FILE):
		var file = FileAccess.open(LOGIN_FILE, FileAccess.READ)
		userInput.text = file.get_as_text(true)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_login_button_pressed():
	Database.login(userInput.text,passwordInput.text)
	var file = FileAccess.open(LOGIN_FILE, FileAccess.WRITE)
	file.store_string(userInput.text)

func _on_register_button_pressed():
	GlobalSignals.emit_signal("CHANGE_SCREEN","Register")
	userInput.text = ""
	passwordInput.text = ""

func _on_password_input_text_submitted(new_text):
	if new_text != "":
		if new_text.length() >= 6:
			Database.login(userInput.text,passwordInput.text)
		else:
			GlobalSignals.emit_signal("SEND_NOTIFICATION","Password needs at least 6 characters...")
	else:
		GlobalSignals.emit_signal("SEND_NOTIFICATION","Password not filled...")

func _on_user_input_text_submitted(new_text):
	if new_text != "":
		if new_text.length() >= 4:
			Database.login(userInput.text,passwordInput.text)
		else:
			GlobalSignals.emit_signal("SEND_NOTIFICATION","Username needs at least 4 characters...")
	else:
		GlobalSignals.emit_signal("SEND_NOTIFICATION","Username not filled...")
