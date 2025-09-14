class_name StaggerState
extends State

@export var stagger_duration: float = 0.3

var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	time_left_in_phase = stagger_duration
	owner_node.velocity = Vector2.ZERO

func process_physics(delta: float, walk_direction: float, is_running: bool):
	time_left_in_phase -= delta
	if time_left_in_phase <= 0:
		state_machine.on_current_state_finished()
