class_name BufferComponent
extends Node

@export var buffer_profile: BufferProfile

enum BufferedAction { NONE, ATTACK, DODGE, PARRY }

var _buffered_action: BufferedAction = BufferedAction.NONE
var _buffered_context: Dictionary = {}
var _time_left: float = 0.0

func _physics_process(delta: float):
	if _time_left > 0:
		_time_left -= delta
		if _time_left <= 0:
			print("clear: ", Time.get_ticks_msec())
			clear()

func capture(action: BufferedAction, context: Dictionary = {}):
	if not buffer_profile:
		push_warning("BufferComponent: Nenhum BufferProfile foi atribuído.")
		return

	_buffered_action = action
	_buffered_context = context
	_time_left = buffer_profile.buffer_window
	print("capture: ", Time.get_ticks_msec())

func consume() -> Dictionary:
	if has_buffer():
		var buffered_data = {
			"action": _buffered_action,
			"context": _buffered_context
		}
		clear()
		print("consume: ", Time.get_ticks_msec())
		return buffered_data
	return {}

func has_buffer() -> bool:
	return _time_left > 0 and _buffered_action != BufferedAction.NONE

func clear():
	_buffered_action = BufferedAction.NONE
	_buffered_context = {}
	_time_left = 0.0
