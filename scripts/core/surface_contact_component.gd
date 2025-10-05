class_name SurfaceContactComponent
extends Node

signal landed

var _body: CharacterBody2D
var _was_on_floor: bool = false
var is_grounded: bool = false
var _enabled: bool = false

func _ready():
	set_physics_process(false)

func setup(body: CharacterBody2D) -> void:
	_body = body
	_was_on_floor = _body.is_on_floor()
	is_grounded = _was_on_floor
	_enabled = true
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not _enabled or _body == null:
		return
	var grounded := _body.is_on_floor()
	if grounded and not _was_on_floor:
		is_grounded = true
		_was_on_floor = true
		emit_signal("landed")
		return
	is_grounded = grounded
	_was_on_floor = grounded
