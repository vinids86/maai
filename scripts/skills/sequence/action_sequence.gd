class_name ActionSequence
extends RefCounted

var _profiles: Array[AttackProfile]
var _current_index: int = -1

func _init(profiles: Array[AttackProfile]):
	self._profiles = profiles

func get_next_profile() -> AttackProfile:
	_current_index += 1
	if _current_index < _profiles.size():
		return _profiles[_current_index]
	return null
