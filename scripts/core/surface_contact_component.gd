class_name SurfaceContactComponent
extends Node

signal landed

var _body: CharacterBody2D
var _was_on_floor: bool = false
var _frames_on_floor: int = 0 

func _ready():
	set_physics_process(false)

func setup(body: CharacterBody2D) -> void:
	_body = body
	_was_on_floor = _body.is_on_floor()
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if _body == null:
		return
		
	var is_currently_on_floor = _body.is_on_floor()

	if is_currently_on_floor:
		_frames_on_floor += 1
	else:
		_frames_on_floor = 0
	
	# Mantemos o debounce para garantir estabilidade física
	var grounded_stable = _frames_on_floor >= 2
	
	if grounded_stable and not _was_on_floor:
		_was_on_floor = true
		emit_signal("landed")
		return

	if not grounded_stable and _was_on_floor:
		_was_on_floor = false
