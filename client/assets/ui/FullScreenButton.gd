extends Button

const EDITOR_EXPAND_ICON := preload("res://icon.png")
const EDITOR_COLLAPSE_ICON := preload("res://icon.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_feature("JavaScript"):
		# Fullscreen does not work well in various browsers, so we use our own JS
		# code on the browser's side
		icon = null
		tooltip_text = ""
		disabled = true
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		custom_minimum_size = Vector2(custom_minimum_size.x, custom_minimum_size.y)
		focus_mode = Control.FOCUS_NONE
		return
	
	connect("pressed", _on_pressed)
	GlobalSignals.connect("FULLSCREEN_TOGGLED", _update_icon)
	_update_icon()


func _on_pressed() -> void:
	GlobalValues.is_fullscreen = not GlobalValues.is_fullscreen
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if GlobalValues.is_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


func _update_icon() -> void:
	icon = EDITOR_COLLAPSE_ICON if GlobalValues.is_fullscreen else EDITOR_EXPAND_ICON
