extends TextureRect


func _ready():
	get_child(0).emitting = true


func _process(_delta: float):
	if !get_child(0).emitting:
		self.queue_free()
