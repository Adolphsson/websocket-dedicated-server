extends ServerFunctions

@onready var networkTimer = $Timer

func _ready():
	set_process(false)
	GlobalSignals.connect("LOAD_PLAYER_STATE",load_player_state)
	GlobalSignals.connect("PLAYER_DISCOVERED", update_player_connect)

func _process(_delta: float):
	ws.poll()
	var state = ws.get_ready_state()
	
	if state != old_state and state == WebSocketPeer.STATE_OPEN and autojoin:
		join_lobby(lobby)
	if state == WebSocketPeer.STATE_OPEN:
		if !connected:
			broadcast(MessageType.READY_PLAYER, { "username": Database.username })
			GlobalSignals.emit_signal("CHANGE_PLAYER_STATE", true)
			GlobalSignals.emit_signal("SEND_NOTIFICATION", "Connected...")
			$PingTimer.start()
		is_reconnecting = false
		is_connected = true
		while state == WebSocketPeer.STATE_OPEN and ws.get_available_packet_count():
			if not on_data_received():
				print("Error parsing message from server.")
	elif state == WebSocketPeer.STATE_CONNECTING:
		GlobalSignals.emit_signal("SEND_NOTIFICATION", "Connecting...")
	if state != old_state and state == WebSocketPeer.STATE_CLOSED:
		GlobalSignals.emit_signal("CHANGE_PLAYER_STATE", false)
		is_connected = false
		$PingTimer.stop()
		code = ws.get_close_code()
		reason = ws.get_close_reason()
		GlobalSignals.emit_signal("CHANGE_SCREEN", "Menu")
		GlobalSignals.emit_signal("SEND_NOTIFICATION", "Disconnected: " + reason)
		try_server_connection(server_url)
		networkTimer.start(1)
		set_process(false) # Stop processing.
		disconnected.emit()
	old_state = state

func _on_timer_timeout():
	try_server_connection(server_url)


func try_server_connection(url: String):
	var state = ws.get_ready_state()
	set_process(true)
	if state == WebSocketPeer.STATE_CLOSED:
		GlobalSignals.emit_signal("CHANGE_PLAYER_STATE", false)
		GlobalSignals.emit_signal("SEND_NOTIFICATION", "Disconnected...")
		ws.connect_to_url(url)
	elif state == WebSocketPeer.STATE_CONNECTING:
		GlobalSignals.emit_signal("CHANGE_PLAYER_STATE", false)
		GlobalSignals.emit_signal("SEND_NOTIFICATION", "Connecting...")
	elif state == WebSocketPeer.STATE_OPEN:
		networkTimer.stop()
		broadcast(MessageType.READY_PLAYER, { "username": Database.username })
		GlobalSignals.emit_signal("CHANGE_PLAYER_STATE", true)
		GlobalSignals.emit_signal("SEND_NOTIFICATION", "Connected...")


func on_data_received():
	var package = ws.get_packet().get_string_from_utf8()
	var parsedPackage = JSON.parse_string(package)
	if "type" in parsedPackage:
		var src_id = str(parsedPackage["id"]).to_int()
		var data = parsedPackage["data"]

		match parsedPackage["type"]:
			MessageType.PING:
				if "sent" in data:
					print("rtt: %s ms" % str(Time.get_ticks_msec() - data["sent"]))
				else:
					return false
			MessageType.WORLD_STATE:
				world.update_world_state(data)
			MessageType.ERROR:
				GlobalSignals.emit_signal("SEND_NOTIFICATION", data["message"])
			MessageType.BROADCAST:
				if "function" in data and "parameters" in data:
					call(data["function"], data["parameters"])
				else:
					return false
			MessageType.ASSIGNED_ID:
				uuid = data["uuid"]
				playerID = data["id"]
			MessageType.ID:
				connected.emit(src_id, data == "true")
			MessageType.JOIN:
				lobby_joined.emit(data)
			MessageType.SEAL:
				lobby_sealed.emit()
			MessageType.PEER_CONNECT:
				# Client connected
				peer_connected.emit(src_id)
			MessageType.PEER_DISCONNECT:
				# Client connected
				peer_disconnected.emit(src_id)
			MessageType.OFFER:
				if rtc_mp.has_peer(src_id):
					rtc_mp.get_peer(src_id).connection.set_remote_description("offer", data)
			MessageType.ANSWER:
				if rtc_mp.has_peer(src_id):
					rtc_mp.get_peer(src_id).connection.set_remote_description("answer", data)
			MessageType.CANDIDATE:
				var candidate: PackedStringArray = data.split("\n", false)
				if candidate.size() != 3:
					return false
				if not candidate[1].is_valid_int():
					return false
				if rtc_mp.has_peer(src_id):
					rtc_mp.get_peer(src_id).connection.add_ice_candidate(candidate[0], candidate[1].to_int(), candidate[2])
			_:
				print("Invalid signaling type: ", parsedPackage["data"]["type"])
				return false
	else:
#		print("Invalid action: ", parsedPackage)
		return false
	return true
		
func load_player_state(userData):
	rtc_mp.create_mesh(playerID)
	pass

func update_player_connect(userData):
	if userData.ID == playerID:
		pass

	var peer: WebRTCPeerConnection = WebRTCPeerConnection.new()
	peer.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	peer.session_description_created.connect(self._offer_created.bind(userData.ID))
	peer.ice_candidate_created.connect(self._new_ice_candidate.bind(userData.ID))
	rtc_mp.add_peer(peer, userData.ID)
	if userData.ID < rtc_mp.get_unique_id(): # So lobby creator never creates offers.
		peer.create_offer()

func _on_ping_timer_timeout():
	broadcast(MessageType.PING, { "sent": Time.get_ticks_msec() })
	pass # Replace with function body.
