extends Control

@onready var chatLog = get_node("VBoxContainer/RichTextLabel")

var groups = [
	{'name': 'Team', 'color': '#34c5f1'},
	{'name': 'Match', 'color': '#f1c234'},
	{'name': 'Global', 'color': '#ffffff'}
]

var group_index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	#chatLog.add_theme_font_size_override("normal_font_size", 32)
	GlobalSignals.connect("RECEIVE_TEXT", update_received_text)

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_TAB:
			change_group(1)

func update_received_text(peerID, new_text, group = 0):
	chatLog.text += '\n[color=' + groups[group].color + '][' + peerID + ']: ' + new_text + '[/color]'

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
