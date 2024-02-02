extends Node

var httpRequest := HTTPRequest.new()
var dbURL := "https://game.adolphsson.se/api"

var username := ""
var email := ""
var guest_id := ""

func _ready():
	httpRequest.request_completed.connect(self._on_request_completed)
	self.add_child(httpRequest)


func register(p_username, p_password, p_email):
	var data = { "username": p_username, "password": p_password, "email": p_email }
	http_request(dbURL + "/register", data)
	GlobalSignals.emit_signal("SEND_NOTIFICATION", "Registering account...")


func confirm(p_email, p_code):
	var data = { "email": p_email,"code": p_code }
	http_request(dbURL + "/confirm_code", data)
	GlobalSignals.emit_signal("SEND_NOTIFICATION", "Verifying account...")


func guest_login(p_guest_id):
	var data = {"guest_id": p_guest_id}
	http_request(dbURL + "/guest", data)

func login(p_username, p_password, p_guest_id):
	if p_guest_id == "":
		p_guest_id = null
	var data = {"email": p_username, "password": p_password, "guest_id": p_guest_id}
	http_request(dbURL + "/login", data)
	GlobalSignals.emit_signal("SEND_NOTIFICATION", "Trying login...")


func request_player_info(p_playerID):
	var data = { "username": p_playerID }
	http_request(dbURL + "/requestPlayerInfo", data)


func update_player_info(p_description, p_arrestInfo):
	var data = { "username": username, "description": p_description, "arrestInfo": p_arrestInfo }
	http_request(dbURL + "/updatePlayerInfo", data)


func http_request(p_url, p_data) -> void:
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify(p_data)
	var error = httpRequest.request(p_url, headers, HTTPClient.METHOD_POST, body)
	if error == OK:
		GlobalSignals.emit_signal("CHANGE_BUTTON_STATE", true)
		"Request sent"
	else:
		GlobalSignals.emit_signal("CHANGE_BUTTON_STATE", false)
		GlobalSignals.emit_signal("SEND_NOTIFICATION", "Error sending request.")


func _on_request_completed(_result, p_response_code, _headers, p_body):
	if p_response_code == 200:
		var json = JSON.new()
		json.parse(p_body.get_string_from_utf8())
		var response = json.get_data()
		match response["action"]:
			"login_successful":
				GlobalSignals.emit_signal("CHANGE_SCREEN", "Play")
				GlobalSignals.emit_signal("SEND_NOTIFICATION", response["message"])
				username = response["username"]
				Server.try_server_connection(Server.server_url)
				DirAccess.remove_absolute("user://guest.txt")
			"register_successful":
				GlobalSignals.emit_signal("CHANGE_SCREEN", "Verify")
				GlobalSignals.emit_signal("SEND_NOTIFICATION", response["message"])
				email = response["email"]
			"guest_successful":
				GlobalSignals.emit_signal("CHANGE_SCREEN", "Play")
				GlobalSignals.emit_signal("SEND_NOTIFICATION", response["message"])
				guest_id = response["guest_id"]
				username = response["username"]
				Server.try_server_connection(Server.server_url)
			"verify_successful":
				GlobalSignals.emit_signal("CHANGE_SCREEN", "Menu")
				GlobalSignals.emit_signal("SEND_NOTIFICATION", response["message"])
			"retrieve_player_info":
				GlobalSignals.emit_signal("DISPLAY_INFO", "user", response["userInfo"])
			"update_successful":
				GlobalSignals.emit_signal("SEND_NOTIFICATION", response["message"])
				
		httpRequest.request_completed.disconnect(self._on_request_completed)
	else:
		var json = JSON.new()
		var resp = p_body.get_string_from_utf8()
		json.parse(resp)
		var response = json.get_data()
		if response != null and "action" in response:
			match response["action"]:
				"login_failed":
					GlobalSignals.emit_signal("SEND_NOTIFICATION", response["message"])
				"register_failed":
					GlobalSignals.emit_signal("SEND_NOTIFICATION", response["message"])
				"guest_failed":
					GlobalSignals.emit_signal("SEND_NOTIFICATION", response["message"])
				"verify_failed":
					GlobalSignals.emit_signal("SEND_NOTIFICATION", response["message"])
				"update_failed":
					GlobalSignals.emit_signal("SEND_NOTIFICATION", response["message"])
				"player_info_not_found":
					GlobalSignals.emit_signal("SEND_NOTIFICATION", response["message"])
				"player_info_failed":
					GlobalSignals.emit_signal("SEND_NOTIFICATION", response["message"])
		else:
			GlobalSignals.emit_signal("SEND_NOTIFICATION", "Unknown error")
	GlobalSignals.emit_signal("CHANGE_BUTTON_STATE", false)
