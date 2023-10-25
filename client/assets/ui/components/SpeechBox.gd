extends Label

@onready var timer = $Timer


func _ready():
	GlobalSignals.connect("SEND_TEXT", update_text)


func update_text(new_text):
	if get_parent() is Player:
		self.show()
		self.text = new_text
		timer.start(3)


func _on_timer_timeout():
	self.text = ""
	self.hide()
