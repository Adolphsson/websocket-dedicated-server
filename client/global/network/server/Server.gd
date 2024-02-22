extends ServerFunctions

@onready var networkTimer = $Timer

const SIGNALING_TYPE_OFFER = 4
const SIGNALING_TYPE_ANSWER = 5
const SIGNALING_TYPE_CANDIDATE = 6

var rtc_mp: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()

func _ready():
	set_process(false)
	GlobalSignals.connect("LOAD_PLAYER_STATE", load_player_state)

func _process(_delta: float):
	ws.poll()
	var state = ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if !connected:
			broadcast("readyPlayer", { "username": Database.username })
			GlobalSignals.emit_signal("CHANGE_PLAYER_STATE", true)
			GlobalSignals.emit_signal("SEND_NOTIFICATION", "Connected...")
			$PingTimer.start()
		reconnecting = false
		connected = true
		while ws.get_available_packet_count():
			on_data_received()
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CONNECTING:
		GlobalSignals.emit_signal("SEND_NOTIFICATION", "Connecting...")
	elif state == WebSocketPeer.STATE_CLOSED:
		GlobalSignals.emit_signal("CHANGE_PLAYER_STATE", false)
		connected = false
		$PingTimer.stop()
		#var code = _ws.get_close_code()
		var reason = ws.get_close_reason()
		GlobalSignals.emit_signal("CHANGE_SCREEN", "Menu")
		GlobalSignals.emit_signal("SEND_NOTIFICATION", "Disconnected: " + reason)
		try_server_connection(server_url)
		networkTimer.start(1)
		set_process(false) # Stop processing.


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
		broadcast("readyPlayer", { "username": Database.username })
		GlobalSignals.emit_signal("CHANGE_PLAYER_STATE", true)
		GlobalSignals.emit_signal("SEND_NOTIFICATION", "Connected...")


func on_data_received():
	var package = ws.get_packet().get_string_from_utf8()
	var parsedPackage = JSON.parse_string(package)
	if "action" in parsedPackage:
		match parsedPackage["action"]:
			"pong":
				if "data" in parsedPackage:
					if "sent" in parsedPackage["data"]:
						print("rtt: %s ms" % str(Time.get_ticks_msec() - parsedPackage["data"]["sent"]))
			"receive_world_state":
				world.update_world_state(parsedPackage["data"])
			"assignUUID":
				uuid = parsedPackage["uuid"]
			"error":
				GlobalSignals.emit_signal("SEND_NOTIFICATION", parsedPackage["message"])
			"broadcast":
				if "data" in parsedPackage:
					if "function" in parsedPackage["data"]:
						if "parameters" in parsedPackage["data"]:
							call(parsedPackage["data"]["function"], parsedPackage["data"]["parameters"])
			"signaling":
				if "data" in parsedPackage:
					if (("type" in parsedPackage["data"]) and ("id" in parsedPackage["data"]) and ("data" in parsedPackage["data"])):
						var src_id = str(parsedPackage["data"]["id"]).to_int()
						var data = parsedPackage["data"]["data"]
						match parsedPackage["data"]["type"]:
							SIGNALING_TYPE_OFFER:
								if rtc_mp.has_peer(src_id):
									rtc_mp.get_peer(src_id).connection.set_remote_description("offer", data)
							SIGNALING_TYPE_ANSWER:
								if rtc_mp.has_peer(src_id):
									rtc_mp.get_peer(src_id).connection.set_remote_description("answer", data)
							SIGNALING_TYPE_CANDIDATE:
								var candidate: PackedStringArray = data.split("\n", false)
								if candidate.size() != 3:
									return false
								if not candidate[1].is_valid_int():
									return false
								if rtc_mp.has_peer(src_id):
									rtc_mp.get_peer(src_id).connection.add_ice_candidate(candidate[0], candidate[1].to_int(), candidate[2])
	else:
#		print("Invalid action: ", parsedPackage)
		pass

func load_player_state(userData):
	var peer: WebRTCPeerConnection = WebRTCPeerConnection.new()
	peer.initialize({
		"iceServers": [ { "urls": ["stun:stun.l.google.com:19302"] } ]
	})
	peer.session_description_created.connect(self._offer_created.bind(userData["playerID"]))
	peer.ice_candidate_created.connect(self._new_ice_candidate.bind(userData["playerID"]))
	rtc_mp.add_peer(peer, userData["playerID"])
	if userData["playerID"] < rtc_mp.get_unique_id(): # So lobby creator never creates offers.
		peer.create_offer()

func _new_ice_candidate(mid_name, index_name, sdp_name, id):
	send_candidate(id, mid_name, index_name, sdp_name)


func _offer_created(type, data, id):
	if not rtc_mp.has_peer(id):
		return
	print("created", type)
	rtc_mp.get_peer(id).connection.set_local_description(type, data)
	if type == "offer": send_offer(id, data)
	else: send_answer(id, data)

func send_candidate(id, mid, index, sdp) -> int:
	return _send_msg(SIGNALING_TYPE_CANDIDATE, id, "\n%s\n%d\n%s" % [mid, index, sdp])


func send_offer(id, offer) -> int:
	return _send_msg(SIGNALING_TYPE_OFFER, id, offer)

func send_answer(id, answer) -> int:
	return _send_msg(SIGNALING_TYPE_ANSWER, id, answer)


func _send_msg(type: int, id: int, data:="") -> int:
	return ws.send_text(JSON.stringify({
		"action": "signaling",
		"data": {
			"type": type,
			"id": id,
			"data": data
		}
	}))

func _on_ping_timer_timeout():
	broadcast("ping", { "sent": Time.get_ticks_msec() })
	pass # Replace with function body.
