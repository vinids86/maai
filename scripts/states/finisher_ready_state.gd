class_name FinisherReadyState
extends State

var current_profile: FinisherProfile

var time_left_in_phase: float = 0.0

func enter(args: Dictionary = {}):
	self.current_profile = args.get("profile")

	if not current_profile:
		push_warning("FinisherReadyState: Não recebeu um FinisherProfile. A abortar.")
		state_machine.on_current_state_finished()
		return

	time_left_in_phase = current_profile.ready_duration
	_emit_phase_signal()


func process_physics(delta: float, walk_direction: float, is_running: bool):
	if not current_profile:
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
		"profile": current_profile,
		"animation_to_play": current_profile.animation_name,
		"sfx_to_play": current_profile.sfx
	}
	state_machine.emit_phase_change(phase_data)
