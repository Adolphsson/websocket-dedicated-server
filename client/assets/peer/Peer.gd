class_name Peer
extends CharacterBody2D

@onready var bubbleObject = preload("res://assets/ui/components/SpeechBubble.tscn")
@onready var animations = $Animations
@onready var traits = $Traits
@onready var speechBubbles = $SpeechBubbles

#Whatever you send to the server via the Player.gd - define_player_state(), gets replicated here to other peers.
func update_state(pos, animation, dir):
	pos = GlobalFunctions.string_to_vector2(pos)
	self.global_position = self.global_position.lerp(pos, 0.1)
	
	if animation != animations.current_animation:
		animations.play(animation)
	traits.currentDirection = dir[0]
	traits.flip_sprite(dir[1])
	traits.traits = dir[2]

func _ready():
	$Name.text = self.name
	GlobalSignals.connect("RECEIVE_TEXT", update_received_text)

func update_received_text(peerID, new_text):
	if peerID == self.name:
		var bubble = bubbleObject.instantiate()
		bubble.text = new_text
		speechBubbles.add_child(bubble)
