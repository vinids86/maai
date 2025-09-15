class_name FinisherReadyState
extends State

@export var finisher_profile: FinisherProfile

var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	if not finisher_profile:
		push_warning("FinisherReadyState: Nenhum FinisherProfile foi atribuído. A abortar.")
		state_machine.on_current_state_finished()
		return

	time_left_in_phase = finisher_profile.ready_duration
	_emit_phase_signal()


func process_physics(delta: float, walk_direction: float, is_running: bool):
	if not finisher_profile:
		return

	time_left_in_phase -= delta
	if time_left_in_phase <= 0:
		state_machine.on_current_state_finished()


func can_initiate_attack() -> bool:
	return true


func _emit_phase_signal():
	var phase_data = {
		"state_name": self.name,
		"phase_name": "FINISHER_READY",
		"profile": finisher_profile,
		"animation_to_play": finisher_profile.animation_name,
		"sfx_to_play": finisher_profile.sfx
	}
	state_machine.emit_phase_change(phase_data)
