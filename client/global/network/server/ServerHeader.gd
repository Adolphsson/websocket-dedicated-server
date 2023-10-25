class_name ServerHeader
extends Node

@onready var world = get_node("/root/World")

var ws := WebSocketPeer.new()
var server_url := "wss://game.adolphsson.se:444"
var connected := false
var reconnecting := false
var uuid = null
