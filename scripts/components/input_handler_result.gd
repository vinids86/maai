class_name InputHandlerResult
extends RefCounted

enum Status {
	REJECTED,
	ACCEPTED,
	CONSUMED,
}

var status: Status
var context: Dictionary

func _init(p_status: Status, p_context: Dictionary = {}):
	self.status = p_status
	self.context = p_context
