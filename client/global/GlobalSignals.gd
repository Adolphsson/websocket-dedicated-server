extends Node

# CHANGE_INPUT_TYPE values
var INPUT_TYPE_KEYBOARD = 0
var INPUT_TYPE_CONTROLLER = 1
var INPUT_TYPE_TOUCH = 2

signal CHANGE_SCREEN(newScreen)
signal UPDATE_AWAIT_LABEL(value)
signal SEND_NOTIFICATION(text)
signal CHANGE_PLAYER_STATE(value)
signal CHANGE_PLAYER_CONTROL_STATE(value)
signal CHANGE_BUTTON_STATE(value)
signal CHANGE_INPUT_TYPE(value)
# client-signals
signal SEND_TEXT(text)

# database-signals
signal DISPLAY_INFO(type,data)

# server-signals
signal RECEIVE_TEXT(peerID,text)
signal LOAD_PLAYER_STATE(state)
