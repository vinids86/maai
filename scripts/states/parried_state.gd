class_name ParriedState
extends State

@export var parried_duration: float = 0.1

var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	time_left_in_phase = parried_duration
	owner_node.velocity = Vector2.ZERO
	_emit_phase_signal()

func process_physics(delta: float, walk_direction: float, is_running: bool):
	time_left_in_phase -= delta
	if time_left_in_phase <= 0:
		state_machine.on_current_state_finished()


func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "STUNNED"
	}
	state_machine.emit_phase_change(phase_data)

func allow_parry() -> bool: 
	return true
