class_name ServerHeader
extends Node

@onready var world = get_node("/root/World")

@export var autojoin := false
@export var lobby := "" # Will create a new lobby if empty.
@export var mesh := true # Will use the lobby host as relay otherwise.

enum MessageType {
	ERROR = 0, 
	BROADCAST = 1, 
	WORLD_STATE = 2, 
	PLAYER_STATE = 3, 
	PING = 4, 
	READY_PLAYER = 5, 
	JOIN = 6, 
	ID = 7, 
	PEER_CONNECT = 8, 
	PEER_DISCONNECT = 9, 
	OFFER = 10, 
	ANSWER = 11, 
	CANDIDATE = 12, 
	SEAL = 13, 
	ASSIGNED_ID = 14
}

var ws := WebSocketPeer.new()
var rtc_mp: WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
var server_url := "wss://game.adolphsson.se:444"
var is_connected := false
var is_reconnecting := false
var uuid = null
var playerID = null
var is_sealed := false

var code = 1000
var reason = "Unknown"
var old_state = WebSocketPeer.STATE_CLOSED
