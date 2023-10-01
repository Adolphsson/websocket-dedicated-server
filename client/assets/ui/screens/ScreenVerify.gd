extends Control

@onready var codeInput = $Panel/CodeInput

func _process(delta):
	pass

func _on_cancel_button_pressed():
	GlobalSignals.emit_signal("CHANGE_SCREEN","Register")

func _on_verify_button_pressed():
	Database.confirm(Database.email, codeInput.text)
	codeInput.text = ""

func _on_code_input_text_submitted(new_text):
	if new_text != "":
		if new_text.length() == 6:
			Database.confirm(Database.email, codeInput.text)
		else:
			GlobalSignals.emit_signal("SEND_NOTIFICATION","Code is not in right format...")
	else:
		GlobalSignals.emit_signal("SEND_NOTIFICATION","Code not filled...")

func _on_password_input_2_text_submitted(new_text):
	pass # Replace with function body.
