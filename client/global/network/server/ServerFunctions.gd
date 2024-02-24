class_name ServerFunctions
extends ServerHeader

signal lobby_joined(lobby)
signal connected(id, use_mesh)
signal disconnected()
signal peer_connected(id)
signal peer_disconnected(id)
signal offer_received(id, offer)
signal answer_received(id, answer)
signal candidate_received(id, mid, index, sdp)
signal lobby_sealed()

func connect_to_url(url):
	close()
	code = 1000
	reason = "Unknown"
	ws.connect_to_url(url)

func close():
	ws.close()

#client-server
func broadcast(msgType:int, data):
	var message = {
		"type": msgType,
		"data": data,
	}
	var parsedData = JSON.stringify(message)
	ws.send_text(parsedData)


#client-requests
func send_text(text, pos):
	randomize()
	var username = Database.username
	var audioIndex = randi() % AudioController.audioLibrary["gibberish"].size()
	var data = {"parameters": { "username":username, "text":text, "position":pos, "audioIndex":audioIndex }, "function": "receive_text"}
	broadcast(MessageType.BROADCAST, data)


func request_play_audio(audio, position):
	AudioController.play_audio(audio, position)
	var data = {"parameters": { "audio":audio, "position":position, "user": Database.username }, "function": "play_audio"}
	broadcast(MessageType.BROADCAST, data)


#server-callables
func receive_server_notification(params):
	GlobalSignals.emit_signal("SEND_NOTIFICATION", params["message"])


func despawn_player(params):
	world.despawn_player(params["username"])


func receive_text(params):
	AudioController.play_audio("gibberish", params["position"], params["audioIndex"])
	GlobalSignals.emit_signal("RECEIVE_TEXT", params["username"], params["text"])


func load_player_state(params):
	GlobalSignals.emit_signal("LOAD_PLAYER_STATE", params["userData"])


func play_audio(params):
	if params["user"] != Database.username:
		AudioController.play_audio(params["audio"], params["position"])

# webRTC functions
func _new_ice_candidate(mid_name, index_name, sdp_name, id):
	send_candidate(id, mid_name, index_name, sdp_name)


func _offer_created(type, data, id):
	if not rtc_mp.has_peer(id):
		return
	print("created", type)
	rtc_mp.get_peer(id).connection.set_local_description(type, data)
	if type == "offer": send_offer(id, data)
	else: send_answer(id, data)

func join_lobby(lobby: String):
	return _send_msg(MessageType.JOIN, 0 if mesh else 1, lobby)

func seal_lobby():
	return _send_msg(MessageType.SEAL, 0)

func send_candidate(id, mid, index, sdp) -> int:
	return _send_msg(MessageType.CANDIDATE, id, "\n%s\n%d\n%s" % [mid, index, sdp])

func send_offer(id, offer) -> int:
	return _send_msg(MessageType.OFFER, id, offer)

func send_answer(id, answer) -> int:
	return _send_msg(MessageType.ANSWER, id, answer)

func _parse_msg():
	var parsed = JSON.parse_string(ws.get_packet().get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("type") or not parsed.has("id") or \
		typeof(parsed.get("data")) != TYPE_STRING:
		return false

	var msg := parsed as Dictionary
	if not str(msg.type).is_valid_int() or not str(msg.id).is_valid_int():
		return false

	var type := str(msg.type).to_int()
	var src_id := str(msg.id).to_int()

	if type == MessageType.ID:
		connected.emit(src_id, msg.data == "true")
	elif type == MessageType.JOIN:
		lobby_joined.emit(msg.data)
	elif type == MessageType.SEAL:
		lobby_sealed.emit()
	elif type == MessageType.PEER_CONNECT:
		# Client connected
		peer_connected.emit(src_id)
	elif type == MessageType.PEER_DISCONNECT:
		# Client connected
		peer_disconnected.emit(src_id)
	elif type == MessageType.OFFER:
		# Offer received
		offer_received.emit(src_id, msg.data)
	elif type == MessageType.ANSWER:
		# Answer received
		answer_received.emit(src_id, msg.data)
	elif type == MessageType.CANDIDATE:
		# Candidate received
		var candidate: PackedStringArray = msg.data.split("\n", false)
		if candidate.size() != 3:
			return false
		if not candidate[1].is_valid_int():
			return false
		candidate_received.emit(src_id, candidate[0], candidate[1].to_int(), candidate[2])
	else:
		return false
	return true # Parsed

func _send_msg(type: int, id: int, data:="") -> int:
	return ws.send_text(JSON.stringify({
		"type": type,
		"id": id,
		"data": data
	}))
