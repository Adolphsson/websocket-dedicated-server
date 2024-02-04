extends Control

@onready var chatAll = get_node("TabContainer/All")
@onready var chatClan = get_node("TabContainer/Clan")
@onready var chatPM = get_node("TabContainer/PM")
@onready var chatSystem = get_node("TabContainer/System")

var groups = [
	{'name': 'All', 'color': '#34c5f1'},
	{'name': 'Clan', 'color': '#f1c234'},
	{'name': 'PM', 'color': '#ffffff'},
	{'name': 'System', 'color': '#ffffff'}
]

var group_index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	#chatLog.add_theme_font_size_override("normal_font_size", 32)
	GlobalSignals.connect("RECEIVE_TEXT", update_received_text)
	GlobalSignals.connect("PLAYER_CONNECTED", update_player_connect)
	GlobalSignals.connect("PLAYER_DISCONNECTED", update_player_disconnect)

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_TAB:
			change_group(1)

func update_received_text(peerID, new_text, group = 0):
	if new_text.contains('@' + Database.username):
		chatPM.text += '\n[color=' + groups[group].color + '][' + peerID + ']: ' + new_text + '[/color]'
		chatAll.text += '\n[color=' + groups[group].color + '][' + peerID + ']: ' + new_text + '[/color]'
	else:
		chatAll.text += '\n[color=' + groups[group].color + '][' + peerID + ']: ' + new_text + '[/color]'

func update_player_connect(peerID):
	chatAll.text += '\n[color=#ffffff]' + peerID + ' connected.[/color]'
	chatSystem.text += '\n[color=#ffffff]' + peerID + ' connected.[/color]'

func update_player_disconnect(peerID):
	chatAll.text += '\n[color=#ffffff]' + peerID + ' disconnected.[/color]'
	chatSystem.text += '\n[color=#ffffff]' + peerID + ' disconnected.[/color]'

func change_group(value):
	if group_index + value > (groups.size() - 1):
		group_index = 0
	elif group_index + value < 0:
		group_index = groups.size() - 1
	else:
		group_index += value

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Darker background on hover needs more testing.
func _on_mouse_entered():
	var panel = $TabContainer.get("theme_override_styles/panel")
	#panel.bg_color = Color(0, 0, 0, 0.1)
	#$TabContainer.set("theme_override_styles/panel", panel)

func _on_mouse_exited():
	var panel = $TabContainer.get("theme_override_styles/panel")
	#panel.bg_color = Color(0, 0, 0, 0.8)
	#$TabContainer.set("theme_override_styles/panel", panel)
