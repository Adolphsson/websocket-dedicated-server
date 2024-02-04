extends Label

@onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	self.show()
	#self.text = new_text
	timer.start(3)

func _on_timer_timeout():
	self.text = ""
	self.hide()
	self.queue_free()
