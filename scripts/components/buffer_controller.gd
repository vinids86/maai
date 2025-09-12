class_name BufferController
extends Node

var has_buffered_attack: bool = false

func capture_attack():
	has_buffered_attack = true

func consume_attack() -> bool:
	if has_buffered_attack:
		has_buffered_attack = false
		return true
	return false

func has_buffer() -> bool:
	return has_buffered_attack

func clear():
	has_buffered_attack = false
