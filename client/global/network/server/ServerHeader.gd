class_name ServerHeader
extends Node

@onready var world = get_node("/root/World")

@export var autojoin := true
@export var lobby := "" # Will create a new lobby if empty.
@export var mesh := true # Will use the lobby host as relay otherwise.

enum MessageType {ERROR, BROADCAST, WORLD_STATE, PLAYER_STATE, PING, READY_PLAYER, JOIN, ID, PEER_CONNECT, PEER_DISCONNECT, OFFER, ANSWER, CANDIDATE, SEAL, ASSIGNED_ID}

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
